# DB credentials live in RDS's own auto-managed secret (see rds.tf); this file just holds per-tenant JWT secrets
resource "random_password" "tenant_jwt_secret" {
  for_each = var.tenants

  length  = 48
  special = true
}

resource "aws_secretsmanager_secret" "tenant" {
  for_each = var.tenants

  name        = "${var.project_name}/${each.key}/jwt-secret"
  description = "JWT signing secret + API key for the ${each.key} portal"
  kms_key_id  = aws_kms_key.payroll.arn
}

resource "aws_secretsmanager_secret_version" "tenant" {
  for_each = var.tenants

  secret_id = aws_secretsmanager_secret.tenant[each.key].id

  secret_string = jsonencode({
    jwt_secret = random_password.tenant_jwt_secret[each.key].result
  })
}
