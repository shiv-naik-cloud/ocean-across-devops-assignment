output "state_bucket_name" {
  description = "S3 bucket name to use as backend-config bucket= when initializing the main config"
  value       = aws_s3_bucket.terraform_state.id
}

output "lock_table_name" {
  description = "DynamoDB table name to use as backend-config dynamodb_table= when initializing the main config"
  value       = aws_dynamodb_table.terraform_lock.name
}
