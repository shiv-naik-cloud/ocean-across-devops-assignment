# Ocean Across Payroll Platform

A secure, multi-tenant payroll platform built on AWS, designed to serve three tenant types — **Companies**, **Bureaus**, and **Employees** — with strict data isolation, least-privilege access, and full infrastructure-as-code automation.

This repository contains the Terraform infrastructure, Docker app packaging, CI/CD pipeline, and architecture documentation for the platform.

## Architecture

![Ocean Across Payroll Platform Architecture](Architecture%20Diagram/Architecture_diagram.png)

**Key design points:**

- **Multi-tenant isolation** — each tenant type (Company, Bureau, Employee) gets its own EC2 instance and IAM role, scoped to its own S3 prefix (`company/`, `bureau/`, `employee/`) and database schema.
- **Network security** — deployed across two Availability Zones in a VPC with public subnets (ALB, NAT Gateways) and private subnets (app EC2 instances, RDS). Active tenant compute currently runs in AZ-2's private subnet; AZ-1's private subnet is reserved as future expansion/HA capacity. The database is never publicly accessible.
- **Edge & routing** — Route 53 for DNS (optional, see below), AWS WAF (optional) for protection, and an ALB terminating HTTPS (443) traffic before routing to the tenant portals. The HTTPS listener exists by default using a self-signed cert (no owned domain required); set `enable_dns_and_tls` + `acm_certificate_arn` to swap in a real, CA-signed cert.
- **Secrets & encryption** — AWS Secrets Manager and Systems Manager Parameter Store hold credentials and config; AWS KMS encrypts data at rest (S3, RDS) and all traffic is encrypted in transit (TLS), on by default.
- **Security groups** — SG-Company, SG-Bureau, SG-Employee, and SG-RDS enforce strict rules: ALB → EC2 on 443, EC2 → RDS on 5432, and tenant-to-tenant traffic is denied by default. There's no inbound SSH anywhere - interactive admin access goes through AWS SSM Session Manager instead, so no port 22 is ever open.
- **Monitoring & alerting** — AWS CloudTrail and CloudWatch metrics/logs feed CloudWatch Alarms, which notify the team via SNS and email on issues like high CPU, high DB connections, or failed status checks. Trail logs and app log groups are encrypted with the same KMS CMK as S3/RDS.
- **CI/CD** — GitHub Actions builds and tests the Docker image on every push to `main`, then deploys to each tenant's EC2 independently; environment (dev/production) and per-service redeploys are selectable via manual workflow runs.

## Cost & Free-Tier Notice

The assignment requires free-tier-only services (EC2, RDS, S3, IAM, CloudWatch, SNS, SSM, Secrets Manager) for any live deployment. This build goes beyond that list to match the architecture diagram in full, and the following components are **not** free-tier eligible and will incur real charges for as long as they run:

| Component | Why it's not free tier |
|---|---|
| Application Load Balancer | Hourly + LCU charges, no free allowance |
| NAT Gateway (×2) | Hourly + per-GB data processing charges |
| KMS customer-managed key | ~$1/month per key (AWS-managed keys are free, CMKs aren't) |
| AWS WAF | Per Web ACL/month + per rule + per request, no free tier |

The ALB's HTTPS listener always exists (self-signed cert, no domain needed) so transit encryption isn't gated behind owning a domain. Route 53 records and host-based tenant routing are gated behind `enable_dns_and_tls` (default `false`) since they need a real, owned domain. If you apply this for real, **destroy the stack (`terraform destroy`) as soon as you're done testing** to avoid ongoing charges — see [Terraform/RESOURCES.md](Terraform/RESOURCES.md) for the full list of what gets created.

## Repository Structure

```
.
├── Architecture Diagram/        # Architecture diagrams (image + source export)
├── Docker/                      # Dockerfile for the payroll application
├── .github/workflows/ci-cd.yml  # CI/CD pipeline definition
├── .github/scripts/ssm-deploy.sh # Shared deploy script the pipeline calls per tenant
├── Terraform/                   # Infrastructure as code (VPC, EC2, RDS, S3, IAM, security)
└── ai_log.md                    # Log of AI-assisted work on this project
```

## Tech Stack & AWS Components

| Layer               | Technology / Service                                      |
|---------------------|-------------------------------------------------------------|
| Compute             | Amazon EC2 (t3.micro) — one instance per tenant type, per AZ |
| Networking          | VPC, public/private subnets, NAT Gateway, Application Load Balancer |
| DNS & Edge          | Route 53, AWS WAF (optional)                                |
| Database            | Amazon RDS (PostgreSQL, encrypted)                           |
| Storage             | Amazon S3 (versioned, SSE-KMS encrypted, prefix-based tenant isolation) |
| Identity & Access   | IAM roles (least privilege, per tenant type)                 |
| Secrets             | AWS Secrets Manager, AWS Systems Manager Parameter Store      |
| Encryption          | AWS KMS                                                       |
| Monitoring          | Amazon CloudWatch (metrics, logs, alarms), Amazon SNS          |
| Containerization    | Docker (Nginx-based image)                                    |
| CI/CD               | GitHub Actions                                                 |
| Infrastructure as Code | Terraform                                                   |

## Task 2 — Multi-Tenancy Architecture

### 2a. Tenant Isolation Strategy

I went with a shared database model with `tenant_id`-based scoping rather than schema-per-tenant or database-per-tenant. It's more cost-effective and scalable than maintaining a separate database or schema per tenant — as this platform grows to support more companies, a separate database per tenant would get expensive and hard to operate, and the actual isolation guarantee doesn't have to live at the database-engine level to be real.

Every record in the database carries a `tenant_id`, identifying whether it belongs to a Company, Bureau, or Employee. At the application level, every request is tied to a specific tenant: once a user logs in, their tenant context is identified (from their account/token), and every database query is required to filter by that `tenant_id`. This guarantees:

1. A Company can only access its own data
2. A Bureau can only access the clients assigned to it
3. An Employee can only see their own payroll data

Because that enforcement lives in application code, I don't treat it as the only guarantee — isolation is also forced at the infrastructure level using IAM roles and resource-scoped access, so a bug in the application's tenant-filtering logic doesn't automatically mean cross-tenant exposure (see 2b).

**Tenant context & request flow** — after login, the system issues a token (e.g. JWT) carrying `user_id` and `tenant_id`. That token travels with every request; the application extracts `tenant_id` from it and uses it to scope every database query. Multiple tenants share the same database, but no single request can see past its own tenant's `tenant_id`.

**Preventing cross-tenant leakage under a bug or misconfiguration** — application-level filtering is necessary but, on its own, not sufficient for data this sensitive. So the infrastructure layer enforces the same boundary independently:
1. Each tenant's compute instance has an IAM role scoped to only its own S3 prefix (`company/`, `bureau/`, `employee/`) — not just read access, but `ListBucket` itself is scoped via an `s3:prefix` condition, so a tenant role can't even enumerate another tenant's object keys
2. Database access is restricted at the network level via security groups, so only the tenant EC2 instances (not arbitrary services) can reach RDS at all

### 2b. Access Boundaries at the Infrastructure Layer

Each tenant type (Companies, Bureaus, Employees) has its own dedicated EC2 instance and its own IAM role, attached via an instance profile — there's no shared role that all three tenants' compute could use. Those roles are scoped narrowly: each can only read/write its own S3 prefix (`company/*`, `bureau/*`, `employee/*`), only read its own Secrets Manager secret, and only read SSM parameters under its own path.

S3 bucket public access is fully blocked at the bucket level (`block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets` all `true`), so the *only* way into the bucket at all is an IAM-authenticated request — and IAM is what enforces the per-tenant prefix boundary. Even if the application's tenant-scoping logic had a bug, a Company's compute identity has no IAM permission to touch a Bureau's or Employee's objects; the infrastructure layer is a second, independent enforcement point, not just a description of the first one.

### 2c. Tenant Onboarding & Offboarding

**Onboarding** a new Company or Bureau:
1. A unique `tenant_id` is generated and stored in the database
2. All data created for that tenant is tagged with that `tenant_id` from day one
3. Its S3 storage uses the matching prefix, separate from every other tenant's
4. Access permissions are enforced automatically through the existing IAM role/policy pattern — onboarding a tenant doesn't require hand-writing new IAM rules, it reuses the same scoped pattern with a new prefix value

**Offboarding** a tenant:
1. All access for that tenant (IAM role, secrets, SSM parameters) is revoked
2. Data associated with that tenant is deleted from both the database and its S3 prefix
3. The deletion itself is logged via CloudTrail, so there's an audit trail showing the offboarding actually happened and when

## Task 3 — Security & Access Control

### 3a. IAM & Role-Based Access Control

Role-based access control via AWS IAM enforces least privilege across every component. Each tenant type has its own IAM role attached to its EC2 instance through an instance profile — no role has access to another tenant's resources, and no role has more access than its own tenant needs. There are no hardcoded credentials anywhere in the configuration: EC2 instances authenticate to AWS purely through their attached IAM role, never an access key.

### 3b. Secrets Management

The RDS master password is AWS-managed (`manage_master_user_password = true` in `rds.tf`) — AWS generates it and stores it directly in Secrets Manager, and Terraform itself never sees or stores the real value. That's a stronger guarantee than "the secret lives in Secrets Manager but a Terraform variable still fed it," which is what an earlier version of this project did before being corrected.

Per-tenant JWT signing secrets live in their own Secrets Manager secrets, encrypted with the project's KMS CMK, and each tenant's IAM role can only call `secretsmanager:GetSecretValue` on its own secret. Non-secret configuration (S3 prefix, environment name) lives in SSM Parameter Store instead of Secrets Manager — keeping the two genuinely separate: anything an attacker could use to authenticate lives in Secrets Manager, anything else lives in Parameter Store. At runtime, the application reads both via its IAM role, so nothing sensitive needs to appear in code, environment files, or logs.

### 3c. Encryption

**At rest:**
- S3 buckets (documents and CI build artifacts) are SSE-KMS encrypted, versioned, and fully blocked from public access
- RDS has `storage_encrypted = true`, using the same KMS CMK
- CloudTrail logs and CloudWatch application log groups are also encrypted with that same CMK — this needed explicit KMS key-policy grants for the `cloudtrail.amazonaws.com` and `logs.<region>.amazonaws.com` service principals, since AWS service principals aren't covered by the key's "enable IAM user permissions" statement the way IAM roles/users are

**In transit:**
- The ALB's HTTPS (443) listener exists by default using a self-signed certificate, so encryption-in-transit isn't gated behind owning a domain — swap in a real CA-signed cert via `enable_dns_and_tls` + `acm_certificate_arn` once one exists
- RDS connections use the PostgreSQL engine's built-in SSL/TLS support

### 3d. Network Security

The application sits inside a VPC with public and private subnets across two Availability Zones:
1. Public subnets carry only the ALB and the NAT Gateways
2. All tenant EC2 instances are in private subnets — not directly reachable from the internet, no public IP
3. RDS is also in a private subnet, with `publicly_accessible = false` set directly in Terraform

Security groups strictly control traffic:
1. Tenant EC2 instances accept inbound traffic only from the ALB, on port 80 — there is no inbound SSH rule anywhere; interactive admin access goes through AWS SSM Session Manager (`aws ssm start-session --target <instance-id>`) instead, which needs no open port at all
2. RDS accepts connections only from the tenant security groups, on port 5432
3. All other traffic is denied by default

NACLs sit underneath the security groups as a second, stateless layer (coarse subnet-tier allow rules), so there's still exactly one place — the security groups — to update for fine-grained access changes.

**Preventing one tenant's traffic from reaching another tenant's compute or data** — each tenant has its own security group (SG-Company, SG-Bureau, SG-Employee), and none of them reference each other; the only thing they all share is being reachable from the same ALB. Even if one tenant's instance were fully compromised, the security group model gives an attacker no network path to another tenant's instance or to RDS outside the allowed port — and the IAM boundary in 2b means even reaching another tenant's S3 prefix or secret would still be denied at the AWS API layer.

## Setup & Deployment

### Prerequisites

- AWS account with credentials configured locally (`aws configure`)
- [Terraform](https://www.terraform.io/) installed
- Docker installed (for local image builds)
- GitHub repository secrets configured per environment (see [CI/CD Pipeline](#cicd-pipeline-task-4) below)
- For manual admin access to an instance, use SSM Session Manager (`aws ssm start-session --target <instance-id>`) — there's no SSH key or open port 22 to set up

### Provision infrastructure

```bash
cd Terraform
terraform init
terraform plan
terraform apply
```

Review `Terraform/variables.tf` and `Terraform/terraform.tfvars` for configurable values (e.g. `vpc_cidr`, `alert_email`).

### Build and run the app locally

```bash
cd Docker
docker build -t payroll-app .
docker run -d -p 80:80 --name payroll-app payroll-app
```

### CI/CD Pipeline (Task 4)

Defined in [`.github/workflows/ci-cd.yml`](.github/workflows/ci-cd.yml) — this is the path GitHub Actions actually scans for workflows, so it runs automatically.

**On every push to `main`:**
1. `build-and-test` lints the Dockerfile (Hadolint), builds the image, scans it for known CVEs (Trivy, fails on CRITICAL/HIGH), then runs the container and `curl`s it to confirm it actually serves a response. There's no app-level unit test yet since the image is currently static nginx content rather than real application code - lint + vulnerability scanning are the real, automated checks that exist today.
2. Three independent deploy jobs (`deploy-companies`, `deploy-bureaus`, `deploy-employees`) each rebuild the same image, upload it to the `ci_artifacts_bucket_name` S3 bucket, and run [`.github/scripts/ssm-deploy.sh`](.github/scripts/ssm-deploy.sh), which uses **AWS SSM Run Command** to pull the image onto the matching tenant EC2 instance and restart the container. They run in parallel and don't share state, so one tenant's deploy failing doesn't block the others.

No SSH, no public IP, no bastion host: the tenant instances live in private subnets with no internet-facing access, and SSM Agent (preinstalled on the Amazon Linux 2 AMI) reaches AWS over the existing NAT Gateway egress.

GitHub Actions authenticates to AWS via **OIDC** (`aws-actions/configure-aws-credentials` + `role-to-assume`) — no long-lived AWS access keys are stored anywhere. The trust policy on `github_actions_deploy_role_arn` only allows this repo's workflows to assume it.

**Manual runs** (Actions tab → "Run workflow") let you:
- Pick `environment: dev` or `production` — each is a [GitHub Environment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment) with its own secrets, so the same secret *names* in the YAML resolve to different real values depending on which environment you pick. No real values ever appear in the YAML itself.
- Pick `service: companies | bureaus | employees | all` to redeploy just one tenant's instance without touching the others — this is how one team can ship their own service independently.

**Required GitHub secrets** (set per-environment, under repo Settings → Environments):
- `AWS_DEPLOY_ROLE_ARN` — value of the Terraform output `github_actions_deploy_role_arn`
- `CI_ARTIFACTS_BUCKET` — value of the Terraform output `ci_artifacts_bucket_name`

> Note: provisioning the OIDC role requires `var.github_repository` in Terraform to match this repo's actual `owner/repo` (defaults to this one). If your AWS account already has a GitHub OIDC provider from another project, see the comment in `Terraform/github_oidc.tf` before applying.

## Task 5 — Monitoring & Incident Readiness

### Monitoring

- CloudWatch alarms track EC2 CPU utilization (alarm above 80%) and EC2 status-check failures for each tenant instance individually, plus RDS connection count (alarm above 80 connections)
- Each tenant has its own CloudWatch Log Group (`/payroll/<tenant>/app`) with a 30-day retention period, so logs don't grow unbounded, and KMS encryption, so they're not sitting in plaintext
- Every alarm notifies the same SNS topic (`critical_alerts`), which fans out to email — a single place to add more notification targets (Slack, PagerDuty, etc.) later without touching each alarm

### Incident Response Runbook

**Scenario: the database is accidentally made publicly accessible**

**Detection**
1. CloudWatch alerts or AWS Config can detect changes to RDS public-accessibility settings
2. Unexpected external traffic or a spike in connections can also indicate exposure

**Investigation**
1. Check the RDS configuration directly to confirm whether public access is actually enabled
2. Review security group rules for any wide-open (`0.0.0.0/0`) ingress
3. Check AWS CloudTrail logs to find exactly when and by what/whom the change was made

**Recovery**
1. Immediately disable public access on the RDS instance
2. Restrict security group rules back to internal VPC access only
3. Rotate DB credentials to invalidate anything an attacker may have captured
4. Review logs covering the exposure window to identify any unauthorized access that did occur

**Prevention**
1. Enforce infrastructure changes through Terraform only, never the console — this is also why `publicly_accessible = false` is set directly in `rds.tf` rather than configured by hand after the fact
2. Keep IAM least-privilege so even a compromised credential can't widen RDS's network exposure
3. Keep monitoring and alerting on configuration changes in place — CloudTrail (now KMS-encrypted, see Task 3c) and the CloudWatch alarms above already cover the detection half of this runbook, not just the recovery half

## Decisions & Trade-offs

**Multi-tenancy & compute** — Chose shared database + `tenant_id` scoping over database-per-tenant: cheaper and easier to operate at this scale, at the cost of every query needing to filter by `tenant_id` correctly (no DB-level guardrail) and no per-tenant backup/restore. One EC2 instance per tenant *type* (not per individual customer) satisfies the assignment's compute-isolation requirement without taking on per-customer infrastructure overhead. Full reasoning in [Task 2](#task-2--multi-tenancy-architecture) above.

**Architecture scope vs. free tier** — Built the full diagram (ALB, NAT Gateway ×2, KMS CMK, WAF) rather than stripping it down to bare free-tier services, since the assignment evaluates well-structured IaC equally with a live deployment and only requires free-tier-only services *if* deployed live. The real cost of each non-free-tier component is documented above in [Cost & Free-Tier Notice](#cost--free-tier-notice) rather than left implicit.

**TLS** — Defaulted to a self-signed certificate on the ALB's HTTPS listener instead of leaving HTTPS off until a real domain exists, so encryption-in-transit isn't gated behind something outside this project's control. Trade-off: browsers flag the cert as untrusted until a real owned domain + CA-signed cert is swapped in via `enable_dns_and_tls`.

**Secrets** — RDS uses an AWS-managed master password (`manage_master_user_password`) instead of a Terraform-variable-fed secret, so Terraform itself never sees the real credential.

**CI/CD deploy path & admin access** — Tenant EC2 instances are intentionally in private subnets with no public IP (defense in depth), which rules out SSH-based deploys regardless of key setup. Chose AWS SSM Run Command (staged through a small, disposable S3 bucket) over adding a bastion host, since it needs no extra instance to patch or manage. GitHub Actions authenticates via OIDC rather than a stored AWS access key — more IAM/trust-policy setup up front, but no long-lived credentials anywhere. Once SSM was wired up for CI/CD, an EC2 keypair + an open, CIDR-restricted port 22 for human admin access became redundant attack surface for the same capability SSM already provides (`aws ssm start-session`) - removed both rather than keeping a second, weaker access path alongside the better one.

**CloudTrail & log encryption** — CloudTrail logs and CloudWatch app log groups now use the same KMS CMK as S3/RDS, rather than AWS's default encryption. This needed explicit key-policy grants for the `cloudtrail.amazonaws.com` and `logs.<region>.amazonaws.com` service principals (service principals aren't covered by the key's "enable IAM user permissions" statement the way IAM roles are) - more key policy to maintain, but consistent encryption ownership across every component that touches account activity or sensitive operational data.

**RDS teardown behavior** — `skip_final_snapshot = true` is deliberate, not an oversight: a final snapshot would survive `terraform destroy` and could leave real PII sitting in a forgotten snapshot, which works against the right-to-erasure posture in Task 6. The trade-off is real - an accidental `destroy` loses all data with no recovery point - but for this assignment's teardown-after-testing model, not leaving PII behind won out over recoverability.

**CI/CD job structure** — Three near-identical, fully self-contained deploy jobs instead of one DRY matrix job, so each tenant's deploy reads top-to-bottom on its own and one tenant's failure can't block another's, at the cost of some repeated YAML.

**CI/CD test step** — No application unit tests exist yet because the image is currently static nginx content rather than real app code. Used Dockerfile linting (Hadolint) and image vulnerability scanning (Trivy) as the automated check instead of inventing placeholder tests against code that doesn't exist.

## Task 6 — UK Compliance Considerations

**1) Data Protection & GDPR**

All employee PII & bank details are stored securely. Encryption is enforced at rest & in transit, least-privilege IAM roles control access, and logging tracks who accesses sensitive data. S3 versioning & RDS encryption ensure no data is lost & all access is auditable.

**2) Data Residency**

All resources are deployed in AWS regions located in the UK or EU (this build uses `eu-west-2` / London) to meet data residency requirements. This includes RDS, S3, & all compute resources. Replication or backups outside these regions are explicitly not configured.

**3) Right to Erasure**

If an employee requests data deletion, their records are removed from the database & any related S3 files are deleted (scoped by tenant prefix). Logs/audit trails are updated to reflect the deletion without exposing sensitive information, in line with GDPR's "right to be forgotten."

## Further Reading

- [Terraform/RESOURCES.md](Terraform/RESOURCES.md) — full list of AWS resources this Terraform config creates.
- [ai_log.md](ai_log.md) — log of AI-assisted contributions to this project.
