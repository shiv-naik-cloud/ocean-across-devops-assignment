output "tenant_ec2_private_ips" {
  description = "Private IP of each tenant's EC2 instance"
  value       = { for k, v in aws_instance.tenant : k => v.private_ip }
}

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.postgres.port
}

output "documents_bucket_name" {
  description = "S3 bucket used for tenant documents and payroll reports"
  value       = aws_s3_bucket.payroll_documents.id
}

output "cloudtrail_bucket_name" {
  description = "S3 bucket used for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail_logs.id
}

output "kms_key_arn" {
  description = "KMS key used to encrypt S3 and RDS"
  value       = aws_kms_key.payroll.arn
}

output "sns_critical_alerts_topic_arn" {
  description = "SNS topic that CloudWatch alarms publish to"
  value       = aws_sns_topic.critical_alerts.arn
}

output "tenant_secrets_arns" {
  description = "Secrets Manager ARN holding each tenant's JWT secret"
  value       = { for k, v in aws_secretsmanager_secret.tenant : k => v.arn }
  sensitive   = true
}

output "rds_master_secret_arn" {
  description = "Secrets Manager ARN holding the AWS-managed RDS master credentials"
  value       = aws_db_instance.postgres.master_user_secret[0].secret_arn
  sensitive   = true
}

output "ci_artifacts_bucket_name" {
  description = "S3 bucket CI/CD stages built Docker images in before SSM pulls them onto instances - set as the CI_ARTIFACTS_BUCKET GitHub secret"
  value       = aws_s3_bucket.ci_artifacts.id
}

output "github_actions_deploy_role_arn" {
  description = "IAM role GitHub Actions assumes via OIDC to deploy - set as the AWS_DEPLOY_ROLE_ARN GitHub secret"
  value       = aws_iam_role.github_actions_deploy.arn
}
