# outputs.tf

output "companies_ec2_private_ip" {
  description = "Private IP of Companies EC2 instance"
  value       = aws_instance.companies.private_ip
}

output "bureaus_ec2_private_ip" {
  description = "Private IP of Bureaus EC2 instance"
  value       = aws_instance.bureaus.private_ip
}

output "employees_ec2_private_ip" {
  description = "Private IP of Employees EC2 instance"
  value       = aws_instance.employees.private_ip
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.postgres.port
}

output "s3_bucket_name" {
  description = "S3 bucket used for documents and payroll reports"
  value       = aws_s3_bucket.payroll_bucket.id
}