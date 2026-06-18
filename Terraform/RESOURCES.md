# Resources created by `terraform apply`

Generated from `terraform plan` against AWS account `222348769973` (eu-west-2)
on 2026-06-18. **100 resources to add, 0 to change, 0 to destroy.**

Re-generate after any code change with:
```bash
terraform plan -out=main.tfplan
terraform show -json main.tfplan   # or terraform show main.tfplan for a human-readable plan
```

## vpc.tf — Networking (17 resources)
- `aws_vpc.main`
- `aws_internet_gateway.igw`
- `aws_subnet.public[0]`, `aws_subnet.public[1]` — one per AZ
- `aws_subnet.private[0]`, `aws_subnet.private[1]` — one per AZ
- `aws_route_table.public`
- `aws_route_table_association.public[0]`, `aws_route_table_association.public[1]`
- `aws_eip.nat[0]`, `aws_eip.nat[1]` — one per AZ, for the NAT Gateways
- `aws_nat_gateway.nat[0]`, `aws_nat_gateway.nat[1]` — one per AZ
- `aws_route_table.private[0]`, `aws_route_table.private[1]`
- `aws_route_table_association.private[0]`, `aws_route_table_association.private[1]`

## security_groups.tf — Security Groups (5 resources)
- `aws_security_group.alb` — public ALB SG
- `aws_security_group.tenant["companies"]` — SG-Company
- `aws_security_group.tenant["bureaus"]` — SG-Bureau
- `aws_security_group.tenant["employees"]` — SG-Employee
- `aws_security_group.rds` — SG-RDS

## nacl.tf — Network ACLs (9 resources)
Subnet-level, stateless defense-in-depth on top of the security groups above.
- `aws_network_acl.public` (covers both public subnets) + 4 rules: allow 443 in, allow 80 in, allow ephemeral 1024-65535 in, allow all out
- `aws_network_acl.private` (covers both private subnets) + 4 rules: allow all in from VPC CIDR only, allow ephemeral 1024-65535 in, allow all out

## iam.tf — IAM Roles (Least Privilege) (12 resources)
- `aws_iam_role.tenant["companies" | "bureaus" | "employees"]`
- `aws_iam_policy.tenant["companies" | "bureaus" | "employees"]`
- `aws_iam_role_policy_attachment.tenant["companies" | "bureaus" | "employees"]`
- `aws_iam_instance_profile.tenant["companies" | "bureaus" | "employees"]`

## kms.tf — Encryption (2 resources)
- `aws_kms_key.payroll` — CMK for S3 + RDS
- `aws_kms_alias.payroll`

## s3.tf — Amazon S3 (payroll-documents-bucket) (5 resources)
- `aws_s3_bucket.payroll_documents`
- `aws_s3_bucket_versioning.payroll_documents`
- `aws_s3_bucket_server_side_encryption_configuration.payroll_documents`
- `aws_s3_bucket_public_access_block.payroll_documents`
- `aws_s3_object.tenant_prefix["companies" | "bureaus" | "employees"]` — `company/`, `bureau/`, `employee/` prefixes

## secrets.tf — AWS Secrets Manager (9 resources)
DB master credentials are **not** created here — RDS generates and owns that
secret itself (`manage_master_user_password` in rds.tf), so Terraform never
sees the real password. This file only holds per-tenant JWT secrets.
- `aws_secretsmanager_secret.tenant["companies" | "bureaus" | "employees"]` — per-tenant JWT secret
- `aws_secretsmanager_secret_version.tenant["companies" | "bureaus" | "employees"]`
- `random_password.tenant_jwt_secret["companies" | "bureaus" | "employees"]`

## ssm.tf — AWS Systems Manager (Parameter Store) (7 resources)
- `aws_ssm_parameter.tenant_s3_prefix["companies" | "bureaus" | "employees"]`
- `aws_ssm_parameter.tenant_environment["companies" | "bureaus" | "employees"]`
- `aws_ssm_parameter.documents_bucket_name`

## rds.tf — RDS PostgreSQL (2 resources)
- `aws_db_subnet_group.payroll`
- `aws_db_instance.postgres` — db.t3.micro, encrypted, master password auto-managed in Secrets Manager (no `var.db_password` anywhere)

## alb.tf — Application Load Balancer (HTTPS 443) (8 resources)
- `aws_lb.main`
- `aws_lb_target_group.tenant["companies" | "bureaus" | "employees"]`
- `aws_lb_target_group_attachment.tenant["companies" | "bureaus" | "employees"]`
- `aws_lb_listener.http`
  *(`aws_lb_listener.https` and `aws_lb_listener_rule.tenant_host_routing` are skipped — `enable_dns_and_tls = false`)*

## ec2.tf — Tenant Portal EC2 Instances (3 resources)
- `aws_instance.tenant["companies"]` — Company Portal
- `aws_instance.tenant["bureaus"]` — Bureau Portal
- `aws_instance.tenant["employees"]` — Employee Portal

## waf.tf — AWS WAF (Optional) (2 resources)
- `aws_wafv2_web_acl.main[0]`
- `aws_wafv2_web_acl_association.main[0]`

## cloudwatch.tf — Monitoring & Alerting (10 resources)
- `aws_cloudwatch_log_group.tenant_app["companies" | "bureaus" | "employees"]`
- `aws_cloudwatch_metric_alarm.tenant_high_cpu["companies" | "bureaus" | "employees"]`
- `aws_cloudwatch_metric_alarm.tenant_status_check_failed["companies" | "bureaus" | "employees"]`
- `aws_cloudwatch_metric_alarm.rds_high_connections`

## sns.tf — Amazon SNS (Critical Alerts Topic) (2 resources)
- `aws_sns_topic.critical_alerts`
- `aws_sns_topic_subscription.email`

## cloudtrail.tf — CloudTrail (4 resources)
- `aws_s3_bucket.cloudtrail_logs` + `aws_s3_bucket_public_access_block.cloudtrail_logs`
- `aws_s3_bucket_policy.cloudtrail_logs`
- `aws_cloudtrail.main`

## Misc (random IDs)
- `random_id.bucket_suffix` — suffix shared by `payroll_documents` and `cloudtrail_logs` bucket names

---

**Not yet created** (gated behind `var.enable_dns_and_tls = false` and `var.enable_waf` is on by default):
- `aws_route53_record.tenant[...]` and `data.aws_route53_zone.main` — needs a real domain (`var.domain_name`)
- `aws_lb_listener.https` and `aws_lb_listener_rule.tenant_host_routing` — needs `var.acm_certificate_arn`

**Already provisioned separately** (one-time, in `backend-bootstrap/`, not part of this 93):
- `aws_s3_bucket.terraform_state` → `payroll-tfstate-8b2bdda4`
- `aws_dynamodb_table.terraform_lock` → `payroll-tfstate-lock`
