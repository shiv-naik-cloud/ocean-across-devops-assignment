# Non-secret per-tenant config; secrets live in Secrets Manager instead (secrets.tf)
resource "aws_ssm_parameter" "tenant_s3_prefix" {
  for_each = var.tenants

  name  = "/${var.project_name}/${each.key}/s3_prefix"
  type  = "String"
  value = each.value
}

resource "aws_ssm_parameter" "tenant_environment" {
  for_each = var.tenants

  name  = "/${var.project_name}/${each.key}/environment"
  type  = "String"
  value = "production"
}

resource "aws_ssm_parameter" "documents_bucket_name" {
  name  = "/${var.project_name}/shared/documents_bucket_name"
  type  = "String"
  value = aws_s3_bucket.payroll_documents.id
}
