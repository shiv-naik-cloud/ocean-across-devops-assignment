# AI Usage Log

**Assignment:** DevOps Engineer Technical Assignment
**Company:** Oceans Across Pvt. Ltd.
**Candidate:** Shiv Naik
**Date:** June 2026

The following log documents all significant AI-assisted interactions used during completion of this assignment. AI was used as a productivity and research assistant. All outputs were reviewed, validated, modified, and adapted before inclusion in the final submission.

*** Initial planning session - assignment analysis & architecture diagram ***

*Prompt*
I am giving you one document that i have received for the assignment on one company.

Please refer in details.

tell me step by step what i have instructed to do ?

*Response*
Analyzed the assignment document and produced a detailed breakdown of AWS Infrastructure Setup, Multi-Tenancy Architecture, Security & Access Control, CI/CD Pipeline, Monitoring & Incident Readiness, UK GDPR Compliance, Required Deliverables, and AI Usage Log Requirements - turning the assignment into a step-by-step implementation plan.

*How I adapted/rejected it:*
I used the task breakdown, deliverable checklist, AWS service selection guidance, and submission planning as my starting point. I chose Terraform over CloudFormation since it's my preferred IaC tool and demonstrates infrastructure design skills more clearly, reordered the implementation tasks to fit how I wanted to work, and added extra security considerations from my own experience that weren't in the original breakdown.


*Prompt*
sure

*Response*
Generated a detailed 24-hour implementation plan covering repository structure, Terraform file organization, AWS architecture recommendations, security implementation strategy, CI/CD workflow structure, monitoring design, and incident runbook preparation.

*How I adapted/rejected it:*
I used the repository layout, documentation structure, Terraform planning approach, and task prioritization from this plan. I simplified some of the proposed Terraform components, focused more heavily on the security and IAM sections, and prioritized documentation quality over application complexity - since the assignment places far more weight on architecture, security, and infrastructure decisions than on application development.


*Prompt*
is this the correct architecture diagram ?

(Architecture diagram uploaded)

*Response*
Reviewed the submitted architecture and recommended adding an Application Load Balancer, AWS Secrets Manager, CloudWatch monitoring, SNS notifications, clearer tenant isolation representation, visible IAM role boundaries, S3 prefix segregation, and clearer security group representation.

*How I adapted/rejected it:*
I used the ALB, CloudWatch, SNS, and Secrets Manager recommendations, plus the tenant-specific S3 organization. I added all of these to the diagram since they directly address requirements from Tasks 3, 4, and 5 of the assignment.

*Prompt*
Hello, I’m building like a full-on production payroll platform on AWS, handling super sensitive employee & company data.. I’m thinking 3 EC2s (Companies, Bureaus, Employees) + 1 RDS. Planning to assign IAM roles per tenant & use SGs.. also did VPC/Subnet separation. Am I missing smth else I should care about??? Keep ans short & on point

*Response*
You’ve got the core basics right. A few subtle things to double-check:

Data encryption & key management – ensure RDS, S3, and backups are encrypted; consider using KMS keys per tenant for extra isolation.
Audit & monitoring – enable CloudTrail, GuardDuty, VPC Flow Logs, and alert on any cross-tenant access.
Accidental exposure – confirm no public access anywhere (RDS, S3, EC2 metadata), and enforce strict IAM + SG rules.

Everything else is mostly operational hygiene (patching, backups, DR).

*How I adapted/rejected it:*
I used this response to double-check things that could break tenant isolation or cause security issues  
I accepted the points about encryption at rest (RDS/S3), key management with KMS, & CloudTrail.. I made sure these were reflected in my Terraform plan & README explanations.  
I rejected the GuardDuty suggestion because, for the scope of this assignment, it's overkill & not required


*Prompt*
Ok so, about multi-tenancy.. I wanna go with a shared DB + tenant_id for isolation, so every request just sees its own tenant’s data. Seems cost-effective & scalable.. right?

*Response*
Yep, that approach is common for SaaS multi-tenancy—it’s cost-efficient and easier to scale than one DB per tenant.

A few sneaky things to watch for:

Row-level security / query enforcement – always filter by tenant_id. Missing it in even one query = data leak.
Indexing & performance – make sure tenant_id is indexed; large tenants can slow down others if not handled.
Backups & restores – shared DB means you can’t restore a single tenant easily unless you plan tenant-level export/import.
Cross-tenant logging – logs or analytics must also respect tenant separation.

Basically, it works, but careful query hygiene is the real risk.

*How I adapted/rejected it:*
I used this response to validate my decision for shared DB with tenant_id scoping
I accepted the point about always filtering by tenant_id.. I reflected this in my README & noted that every query must include tenant context  
I rejected tenant-level backup/restore complexity for now since the assignment only asked for architecture & strategy, not full operational DB restores  


*Prompt*
Ok so I’m planning to deploy all stuff in UK/EU regions, enable encryption everywhere, keep audit logs & handle tenant-level right-to-erasure for all PII.

I get that for GDPR I should do UK/EU regions, encryption at rest + in transit, audit logs, right-to-erasure per tenant..

But I really wanna get it from a DevOps POV.. like why exactly each step matters & are there sneaky things I might miss if I just follow these rules? Basically wanna make sure I’m not just ticking boxes, but actually doing it right

*Response*
1. UK/EU regions
Why it matters: Keeps data physically within GDPR jurisdiction, avoiding cross-border compliance issues.
Sneaky pitfall: Some AWS services replicate data globally by default (e.g., S3 cross-region replication, CloudFront caching). Make sure all replication is explicitly region-restricted.
2. Encryption at rest & in transit
Why it matters: Protects PII if disks, backups, or network traffic are compromised.
Sneaky pitfall: Don’t just enable “default” encryption. Check:
DB snapshots & automated backups are encrypted.
EC2 ephemeral storage (if you store any sensitive files) is encrypted.
TLS certs are enforced for all APIs; avoid self-signed in prod.
3. Audit logs
Why it matters: Detects misconfigurations, unauthorized access, or accidental cross-tenant leaks.
Sneaky pitfall: Logging is useless if:
You don’t monitor/analyze it (CloudWatch alarms, GuardDuty).
Logs themselves contain raw PII – should be redacted or encrypted.
4. Tenant-level right-to-erasure
Why it matters: Legal requirement; must ensure you can remove all traces of a tenant’s PII.
Sneaky pitfall: With a shared DB:
Soft deletes are not enough; orphaned references in backups, logs, or analytics can remain.
RDS snapshots may still contain deleted data; consider tenant-aware snapshot lifecycle.
5. Other DevOps subtleties
Secrets management: Never hardcode tenant credentials in app or infra configs; use Secrets Manager or KMS.
Least privilege: Even if IAM roles are per tenant, double-check EC2 roles, Lambda roles, and service-to-service permissions.
Disaster recovery / failover: Encrypted, GDPR-compliant backups should survive region outages without violating cross-border rules.
Testing & automation: Automated tests to confirm:
No tenant can query another tenant’s data.
Data deletion workflows actually remove data everywhere.

✅ TL;DR DevOps POV: You’re not just ticking boxes; each step protects against real operational risks — but watch default AWS behaviors, shared DB pitfalls, log handling, and backup/data lifecycle.

If you want, I can make a “DevOps cheat sheet for GDPR + multi-tenant AWS infra” — literally the things a 2-year DevOps engineer never wants to forget. Do you want me to do that?

*How I adapted/rejected it:*
I used this response to frame my Task 6 section & GDPR approach
I accepted the reasoning behind UK/EU region selection, encryption at rest & in transit, audit logs, & right-to-erasure, this helped me write the README in a way that shows I understand WHY each step matters from a DevOps perspective
I adapted that S3 replication doesn’t go outside region, backups are encrypted, & logs don’t expose raw PII.. I mentioned these considerations briefly in my README
I rejected suggestions like GuardDuty for this assignment since it’s out of scope I only kept the principle in mind
I also adapted the secrets management & least privilege guidance to reinforce my IAM & Secrets Manager usage across EC2 & Docker services


*Prompt*
Achha, so I’m already planning to encrypt all PII at rest + in transit, use least-privilege IAM roles, & enable logging..

From a DevOps POV, am I missing any hidden gaps in protecting sensitive payroll data, or does this cover the main risks???

*Response*
1. Cross-tenant leaks
Shared DB with tenant_id: any missed tenant_id filter = full data exposure.
Logs, analytics, or temporary files might accidentally include other tenants’ PII.
2. Backups & snapshots
Encrypted RDS snapshots, S3 backups, and AMIs still need tenant-aware lifecycle; deleted tenants might linger in old snapshots.
3. Secrets & service-to-service access
IAM + SGs per tenant are good, but check:
EC2/ECS metadata exposure (accidental IAM access).
Hardcoded keys or environment variables in containers.
4. Monitoring & alerting gaps
Logging is only useful if you actively monitor and alert on anomalies, e.g., cross-tenant access, public exposure, or unexpected API calls.
5. Disaster recovery & failover
Multi-region failover can unintentionally replicate EU/UK PII outside allowed regions.

✅ TL;DR: Your plan hits the main risks, but tenant separation in queries, backup lifecycle, secrets handling, and monitored alerts are the subtle gaps DevOps often overlook.

If you want, I can make a super crisp “DevOps hidden gotchas checklist” for multi-tenant payroll infra — something you could literally print and keep by your desk. Do you want me to do that?

*How I adapted/rejected it:*
I accepted the points about cross-tenant leaks, backup lifecycle, secrets management, & alerting.. I made sure to note these in my README & Terraform design  
I adapted the disaster recovery note to double check that all backups & failover regions remain within UK/EU boundaries
I rejected creating a full “DevOps hidden gotchas checklist” from AI instead, I wrote my own short notes tailored to the assignment.


*** Claude Code session - Terraform build-out from the architecture diagram ***

*Prompt*
refer arch, diagram image i have submit to you. Based on this generate readme.md file please ask me what you put.

*Response*
Asked clarifying questions before writing anything: whether to replace README.md entirely or keep the existing Task 2-6 answers inline, which sections to include (overview, repo structure, tech stack, setup), and which diagram export to reference (the repo had both an old drawio export and a newly added PNG).

*How I adapted/rejected it:*
I answered the clarifying questions myself: replace README.md with a project-overview document, move the original Task 2-6 written answers into a new ANSWERS.md, keep all four suggested sections, and point at the newly exported diagram PNG.


*Prompt*
please change as per this image.

*Response*
Detected the diagram had been updated (new Architecture_diagram.png) and updated README's architecture bullets to match: tenant compute consolidated into one AZ (the other reserved for future expansion), explicit per-tenant security group rules, CloudTrail feeding the monitoring pipeline.

*How I adapted/rejected it:*
I checked this against the updated diagram myself and confirmed it was a direct, factual sync - accepted as-is, no rejections needed.


*Prompt*
And i wanted to start create resources for all modules showing in image. also do seperate file for possible resources also make code dynamic and simple to understand and simple me to explain them later also use required statements like count , depends_on also do connect to aws write code as well i want you to use s3 file and statefile as explain in image.

*Response*
Asked four clarifying questions before writing any code: AWS region (diagram said eu-west-2, existing code used ap-south-1), whether to bootstrap a dedicated S3+DynamoDB remote-state backend, how much of the diagram to build (everything vs. a smaller core subset), and how far to go with live AWS execution (write-only vs. init+plan vs. full apply). Once I answered, it scaffolded ~20 new .tf files (vpc, security_groups, iam, kms, s3, secrets, ssm, rds, alb, ec2, route53, waf, cloudwatch, sns, cloudtrail, nacl, etc.), each using `count`/`for_each` over a shared tenants map.

*How I adapted/rejected it:*
I made the call on all four open questions myself: eu-west-2 (to stay consistent with my own UK/GDPR answer in Task 6), a dedicated S3+DynamoDB state backend, full diagram scope rather than a smaller subset, and write+plan only (no apply) as my safety boundary so nothing gets created in AWS without me reviewing it first. I then went through the generated files to check the `count`/`for_each` and `depends_on` usage actually matched what I asked for - explicit `depends_on` only where Terraform genuinely couldn't infer ordering (NAT Gateway/IGW, CloudTrail/bucket policy, EC2/IAM policy attachment).


*Prompt*
[Pasted a real AWS access key + secret key directly in chat, twice across two messages]

*Response*
Configured the keys into the local AWS CLI credentials file and tested with `aws sts get-caller-identity`. Both attempts failed with `InvalidClientTokenId`. Investigated and found the real cause: a leftover `aws_session_token` line in `~/.aws/credentials` from an old temporary session, which is incompatible with a plain permanent access key/secret pair - not a problem with the pasted keys themselves.

*How I adapted/rejected it:*
I had it remove the stale `aws_session_token` line (a local, gitignored file outside the repo - never written to anything tracked in git) rather than re-pasting the keys a third time. This fixed authentication immediately. I took on board the flag that pasting raw credentials into chat means treating that key as semi-exposed and needing rotation.

Note: the actual key/secret values are intentionally redacted from this log and were never written to any tracked file - only to the local, gitignored `~/.aws/credentials`.


*Prompt*
can u make list of resources which are creating ? in seperate file ?

*Response*
Generated `Terraform/RESOURCES.md` directly from `terraform show -json` on a real saved plan (parsed with a small Python script), grouped by `.tf` file / diagram section, listing every resource Terraform would create (93, later 100-102 as the code changed).

*How I adapted/rejected it:*
I chose to derive the list from the actual plan output rather than hand-writing it, so the doc would always match reality instead of drifting from the code. I had it re-generated each time the plan changed in later steps.


*Prompt*
configured nacl & security groups both  if no please do so .

*Response*
Found that only security groups existed - NACLs were missing entirely. Added `Terraform/nacl.tf`: a public-subnet NACL (allow 80/443/ephemeral in, all out) and a private-subnet NACL (allow only from the VPC CIDR + ephemeral return traffic, all out), as a second, stateless layer beneath the existing security groups.

*How I adapted/rejected it:*
I asked it to check first because I wasn't sure NACLs were even in place. I agreed with keeping them deliberately coarse (subnet-tier allow rules) rather than duplicating the security groups' per-tenant rules, so there's still only one place (`security_groups.tf`) I need to update for fine-grained access changes.


*Prompt*
all sensitive data including dbpassword or anyother should store inside secrets or parameter store can u check & let fix if not.

*Response*
Audited the codebase and found `var.db_password` was flowing through Terraform state and a local `terraform.tfvars` file in plaintext, and was also duplicated into a custom Secrets Manager secret. Fixed it by switching RDS to AWS-managed master password (`manage_master_user_password = true`), deleting the redundant custom secret, granting tenant IAM roles read access to the AWS-managed secret instead, and removing the now-unused `db_password` variable.

*How I adapted/rejected it:*
I'd asked it to check whether secrets were actually stored properly, and once it found the plaintext flow I chose the AWS-native fix (RDS owns and generates the password itself) over keeping a custom Secrets Manager secret fed by a Terraform variable, since the native approach means Terraform never sees or stores the real password at all - a stronger guarantee than "stored in Secrets Manager but still passed through Terraform."


*Prompt*
can you put secrets sensitive=true ? wherver possible. also i want you to keep only necesssary comments just short comment in all files.

*Response*
Marked `var.db_username` and the two secret-ARN outputs (`tenant_secrets_arns`, `rds_master_secret_arn`) as `sensitive = true`. Left non-secret config (`ssh_allowed_cidr`, `alert_email`) unmarked since they aren't credentials. Then trimmed multi-line/multi-paragraph comments down to a single short line (or removed them entirely where the code was self-explanatory) across all ~23 `.tf` files.

*How I adapted/rejected it:*
I had it limit "sensitive = true wherever possible" to genuinely secret-adjacent values rather than applying it to every variable/output indiscriminately, so non-sensitive plan output (like `rds_endpoint`) stays visible and useful - my call, not a blanket apply.


*Prompt*
ok now i want you to remove the file created by terraform plan & all not necessary please keep only  those are necessary and required from terraform

*Response*
Removed `*.tfplan` files and the regenerable `.terraform/` + `.terraform.lock.hcl` caches in both `Terraform/` and `Terraform/backend-bootstrap/`. Deliberately did **not** delete `backend-bootstrap/terraform.tfstate`, since it's the live record of the real S3 bucket + DynamoDB table already created in AWS - deleting it would make Terraform try to recreate resources that already exist.

*How I adapted/rejected it:*
I agreed with flagging the state-file exception explicitly rather than treating every "generated-looking" file the same way, since deleting that one specifically would have been destructive to real infrastructure already created in AWS.


*Prompt*
backend.hcl , teraform.tfvars,backend.hcl are necessary ? also scan others if not necessary

*Response*
Scanned every remaining file in `Terraform/` and classified each as: required (Terraform reads it directly, e.g. the `.tf` files and `terraform.tfvars`), practically necessary (needed for the documented workflow, e.g. `backend.hcl` for the chosen `init` pattern), or documentation-only (`.example` files, `RESOURCES.md`, `.gitignore`).

*How I adapted/rejected it:*
I asked for the scan because I wasn't sure which files were actually load-bearing. I decided not to delete anything since the scan found every file served a real purpose (the `.example` files specifically exist so a second person cloning the repo can reconstruct the gitignored real files) - I wanted the classification reported, not files removed for the sake of it.


*Prompt*
[Uploaded "Ocean Across DevOps Assignment.pdf"] can u check this assignment document let me know if anything remaing in terraform resources all will work accordingly ?

*Response*
Cross-checked the full assignment doc against the implementation. Confirmed Task 1/3/5 Terraform requirements were covered, but surfaced six gaps: (1) a real bug - `s3:ListBucket` was granted on the whole bucket with no prefix condition, letting any tenant role list every other tenant's object keys; (2) the ALB/NAT Gateways/KMS CMK/WAF added per the diagram aren't AWS free-tier eligible, conflicting with the assignment's mandatory free-tier-only constraint for live deployment; (3) TLS is off by default since `enable_dns_and_tls` defaults to `false`; (4) Task 6 answers lived in ANSWERS.md instead of README.md, where the assignment explicitly requires them; (5) the CI/CD pipeline is missing a test step, dev/prod handling, and multi-team independence; (6) this AI log was stale.

*How I adapted/rejected it:*
I had it fix the S3 `ListBucket` bug immediately since it was unambiguous (a separate `ListBucket` statement scoped with an `s3:prefix` condition). For the rest, I made the calls myself rather than letting it unilaterally rewrite things: kept the free-tier-exceeding architecture as-is with a documentation note in README (rather than stripping ALB/NAT/KMS/WAF to bare free tier), moved the Task 6 answers into README.md as required, and updated this log. I left the CI/CD pipeline gaps (test step, dev/prod, multi-team) as an open follow-up rather than having everything fixed in one pass.


*Prompt*
tell me from document what is still remaining ?

*Response*
Summarized remaining gaps against the assignment doc without making changes: TLS off by default (3c), the CI/CD pipeline missing a test step / dev-prod handling / multi-team independence (Task 4), and a missing "Decisions & Trade-offs" section in README. Also caught a new finding: the backend-bootstrap DynamoDB lock table isn't on the assignment's named free-tier-safe service list either, and it (plus its S3 state bucket) is the only thing actually live in AWS right now - the main stack was only ever planned, never applied.

*How I adapted/rejected it:*
I asked for a status report on purpose - no code changes, just gathering the full picture so I could decide what to tackle next myself.


*Prompt*
can you start working on  cicd part make cicd file simple and easy to explainable.

*Response*
Before touching the pipeline logic, found a more fundamental bug: the workflow file lived in `GitHub Actions Workflow/ci-cd.yml`, a plain folder GitHub Actions never scans - it had never actually run on GitHub at all. Also found the `docker build -t payroll-app .` command would fail since it ran from the repo root while the Dockerfile lives in `Docker/`. Rewrote the pipeline at the real `.github/workflows/ci-cd.yml` location: a shared `build-and-test` job (build, run, curl-based smoke test) feeding three independent, parallel per-tenant deploy jobs (`deploy-companies`/`deploy-bureaus`/`deploy-employees`), each scoped to its own `EC2_HOST_*` secret. Added `workflow_dispatch` inputs for `environment` (dev/production, resolved via GitHub Environments so the YAML never contains real values) and `service` (lets one team redeploy just their own tenant without touching the others).

*How I adapted/rejected it:*
I'd specifically asked for something simple and easy to explain, so I reviewed the three near-identical, fully self-contained jobs (each re-running checkout+build) against a DRY matrix with dynamic secret lookups and confirmed the repetitive version was the better fit for that goal - repetition that reads top-to-bottom beats a clever abstraction here. I agreed with deleting the old non-functional `GitHub Actions Workflow/` folder rather than leaving a confusing duplicate, and noted the flagged gap (EC2 instances still missing an SSH key pair, so SSH deploys won't authenticate yet) as a Terraform fix I still owe outside this task's scope.


*** Note (2026-06-18) ***
From this point on I'm shifting how I prompt: asking for explanations, trade-offs, and review of my own decisions rather than direct "build/do X" requests, so the log reflects guidance sought rather than implementation handed off.


*Prompt*
I asked it to scan the repo against the assignment PDF and tell me what's still missing, then asked it to fix two specific gaps: the EC2 instances having no `key_name` (so SSH deploys would fail auth), and `enable_dns_and_tls` defaulting to false (so TLS was off by default).

*Response*
While wiring up the key pair, it found a bigger problem than the one I asked about: the tenant EC2 instances sit in private subnets with no public IP and no inbound route from the internet (`Terraform/vpc.tf`), so GitHub Actions could never reach them over SSH regardless of the key. It asked me how I wanted to solve connectivity instead of silently leaving the fix half-done, and separately asked how I wanted default TLS to work given I don't own a real domain.

*How I adapted/rejected it:*
For the SSH key, I chose to have it create the keypair from a public key I supply rather than letting Terraform generate the private key - the private half never has to touch Terraform state, same principle as the RDS password fix earlier. For TLS, I chose a self-signed cert on by default (so encryption-in-transit isn't gated behind owning a domain) over leaving it off and just documenting why. For the connectivity gap, I chose to replace the SSH-based deploy entirely with AWS SSM Run Command, and to have GitHub Actions authenticate via OIDC instead of storing a long-lived AWS access key - both are more secure than the alternatives offered (SSH+bastion, or a static IAM user key), even though they took more to set up: a new IAM role/policy for SSM, a small disposable S3 bucket to stage build artifacts (SSM can't `scp`), a GitHub OIDC provider + trust policy scoped to this repo, and a rewrite of the three deploy jobs in `ci-cd.yml` to call a shared `.github/scripts/ssm-deploy.sh` instead of `appleboy/ssh-action`. I ran `terraform fmt` and `terraform validate` to check the result was syntactically correct, but haven't run a real `terraform plan` against the live backend yet - that's still open before I'd trust this is deployable as-is.


*Prompt*
I asked it to add a real test step to the CI/CD pipeline, since the existing one was just a curl-based smoke test.

*Response*
It pointed out before building anything that the Docker image has no real application code to unit-test - `Docker/Dockerfile` is just `nginx:latest` copying a mostly-empty build context into the html folder - so it asked me what "a real test" should actually mean here before picking an approach.

*How I adapted/rejected it:*
I chose security scanning (Hadolint for the Dockerfile, Trivy for image CVEs) over inventing placeholder app content just to have something to assert against - those are genuine, automated checks that matter for a payroll app regardless of whether real app code exists yet. It also pinned the base image to `nginx:1.27-alpine` instead of `:latest` since Hadolint flags floating tags, which I agreed with since it also shrinks the image and reduces CVE surface for the Trivy scan.


*Prompt*
I asked it to add the README "Decisions & Trade-offs" section from my checklist, and to figure out where the incident response runbook should live.

*Response*
Before writing anything, it re-read the actual assignment PDF for the exact wording rather than relying on the earlier gap-scan's summary, and found the runbook requirement says "can be included in the README or as a separate file" - so ANSWERS.md (already linked from this README) already satisfies it as written, no move needed. It then drafted a "Decisions & Trade-offs" section synthesizing reasoning that was already scattered across ANSWERS.md and this log (multi-tenancy model, free-tier-vs-diagram scope, TLS, secrets/SSH, CI/CD deploy path, job structure, test step) into one place, placed right before Task 6 to match the assignment's own ordering.

*How I adapted/rejected it:*
I agreed the runbook didn't need moving since the assignment text itself allows either location - rejected the earlier scan's framing of that as a hard gap. I reviewed the drafted trade-offs section and confirmed it was just restating decisions I'd already made and explained earlier in this project, not inventing new reasoning, before accepting it into the README.


*Prompt*
I asked it to run `terraform validate` and a real `terraform plan` against the live backend, and tell me honestly whether the CI/CD pipeline would actually work on GitHub as written.

*Response*
`terraform validate` passed and a real `terraform plan` against the live S3/DynamoDB backend came back clean: 116 to add, 0 to change, 0 to destroy - confirming nothing from the main stack has been applied yet, only the backend bootstrap exists. It also checked the AWS account for an existing GitHub OIDC provider (none found, so the new one won't conflict) before answering the CI/CD question. While double-checking the pipeline instead of assuming it would just work, it found two real bugs that would have broken the very first run: `aquasecurity/trivy-action@0.28.0` was missing the required `v` prefix (the actual tag is `v0.28.0`) and the deploy steps invoked `.github/scripts/ssm-deploy.sh` directly, which depends on git preserving the executable bit - risky for a script added from a Windows checkout.

*How I adapted/rejected it:*
I had it fix both: added the missing `v` to the Trivy action tag, and changed the deploy steps to call `bash .github/scripts/ssm-deploy.sh ...` instead of executing the script directly, so it can't fail on a missing executable bit regardless of how it was checked in. I deleted the local `tfplan.out` after reviewing it rather than committing it, since plan files can contain unredacted sensitive values and this repo's existing convention is to keep them out of git entirely.


*Prompt*
I asked it to confirm whether every folder in this project actually met the assignment's bar - "decisions are deliberate, well-reasoned, and security-first" - rather than just taking the existing README/ai_log documentation at face value.

*Response*
Instead of summarizing what was already written down, it re-read the actual `.tf` files for the security-relevant settings (RDS encryption/public access, S3 bucket policies, IAM scoping, WAF, etc.) and found four real, concrete gaps that hadn't been caught before: the CloudTrail logs bucket and CloudWatch app log groups were relying on AWS's default encryption instead of the project's own KMS CMK (inconsistent with every other encrypted resource in the project); the tenant security groups still had an open, CIDR-restricted SSH port 22 even though the CI/CD redesign had already made SSH unnecessary; and `skip_final_snapshot = true` on RDS was a real, undocumented trade-off rather than an oversight.

*How I adapted/rejected it:*
I asked it to fix all four. For the KMS gaps, I accepted adding explicit key-policy statements for the CloudTrail and CloudWatch Logs service principals (required since service principals aren't covered by the key's IAM-permissions statement the way roles/users are) rather than switching those resources to a separate AWS-managed key, so there's still one CMK for everything. For SSH, I agreed to remove the inbound rule, the EC2 keypair resource, and the now-unused `ssh_public_key`/`ssh_allowed_cidr` variables entirely rather than just closing the port and leaving dead config behind - SSM Session Manager already covers the same admin-access need with zero open ports. For the snapshot trade-off, I had it write down the actual reasoning (avoiding a lingering PII-bearing snapshot after teardown, weighed against losing all data on an accidental destroy) instead of changing the default. I had it re-run `terraform validate` and a real `terraform plan` after each fix, which caught one more thing it had missed on the first pass - the security group's own `description` field still said "SSH limited to an admin CIDR" after the rule itself was gone - before confirming the final plan was clean (116 to add, 0 to change, 0 to destroy, no errors).


*Prompt*
I asked it to make sure every piece of information lives in README.md, "includes all." It asked me to clarify whether that meant merging ANSWERS.md's content into README, or just auditing README for completeness while keeping the two files separate - I chose the merge.

*Response*
It merged ANSWERS.md's Task 2/3/5 written answers into README under matching `## Task 2` / `## Task 3` / `## Task 5` headings, then deleted ANSWERS.md. While merging it found the content wasn't just a copy-paste job - parts of it were stale, written before this project's later security fixes: Task 3b still described the DB password as "a Terraform variable marked sensitive" when it's actually been AWS-managed since the secrets audit earlier in this project; Task 3c said RDS encryption "can be enabled" when it already is; Task 3d still mentioned SSH as the admin access method after SSH had just been fully removed in favor of SSM. It rewrote those parts to match what's actually implemented rather than copying the outdated original wording, and skipped merging Task 4's original text entirely since README's own CI/CD Pipeline section was already the accurate, current version of that same answer.

*How I adapted/rejected it:*
I accepted the correction of the stale technical claims rather than asking it to preserve my original wording verbatim, since presenting outdated information as current would be worse for a security-sensitive payroll project than updating it. I agreed with deleting ANSWERS.md rather than leaving a redundant, now-orphaned duplicate behind, and with retitling the existing CI/CD Pipeline section to "(Task 4)" instead of duplicating that content a second time under a separate heading.

*Prompt*
[Pasted real GitHub Actions runner log output] Download action repository 'hadolint/hadolint-action@v3.1.0'... Download action repository 'aquasecurity/trivy-action@v0.28.0'... Error: Unable to resolve action `aquasecurity/setup-trivy@v0.2.1`, unable to find version `v0.2.1`

*Response*
This was the first real run of the pipeline on GitHub, and it failed at the Trivy step. Investigated by pulling `trivy-action@v0.28.0`'s own `action.yaml` from GitHub directly: it calls `aquasecurity/setup-trivy@v0.2.1` internally as a nested action, but that exact tag no longer exists in the `setup-trivy` repo (only v0.2.6/v0.3.0/v0.3.1 remain) - it was deleted upstream at some point after `v0.28.0` was released, breaking anyone still pinned to that release. Checked newer `trivy-action` releases (v0.30.0 through v0.36.0) and found the project fixed this exact failure mode itself: from v0.32.0 onward, `setup-trivy` is pinned by commit SHA instead of a floating tag, so it can't break this way again.

*How I adapted/rejected it:*
I had it bump to `aquasecurity/trivy-action@v0.36.0` (latest at the time) rather than just hunting for a setup-trivy tag that happened to still exist, since that would only delay the same failure until the next tag cleanup upstream. Verified the three action inputs I was already using (`image-ref`, `severity`, `exit-code`) are all still valid in v0.36.0 before swapping the version, so the scan behavior itself doesn't change - only the broken dependency does.


*** Candidate Declaration ***
I confirm that AI tools were used as an assistant to support research, planning, documentation, and architectural review. Final implementation decisions, validation, modifications, and submission materials were completed and reviewed by me before submission.