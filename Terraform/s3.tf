# Bucket names are globally unique across AWS, hence the random suffix
resource "aws_s3_bucket" "payroll_documents" {
  bucket = "${var.project_name}-documents-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "${var.project_name}-documents-bucket"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "payroll_documents" {
  bucket = aws_s3_bucket.payroll_documents.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "payroll_documents" {
  bucket = aws_s3_bucket.payroll_documents.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.payroll.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "payroll_documents" {
  bucket = aws_s3_bucket.payroll_documents.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Empty company/, bureau/, employee/ prefixes for tenant isolation
resource "aws_s3_object" "tenant_prefix" {
  for_each = var.tenants

  bucket  = aws_s3_bucket.payroll_documents.id
  key     = "${each.value}/"
  content = ""
}

# Stages CI-built Docker images so SSM Run Command can pull them onto
# instances that have no SSH/public access for direct scp-style deploys
resource "aws_s3_bucket" "ci_artifacts" {
  bucket = "${var.project_name}-ci-artifacts-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "${var.project_name}-ci-artifacts-bucket"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ci_artifacts" {
  bucket = aws_s3_bucket.ci_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.payroll.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "ci_artifacts" {
  bucket = aws_s3_bucket.ci_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Build artifacts are disposable - don't let them pile up or cost money
resource "aws_s3_bucket_lifecycle_configuration" "ci_artifacts" {
  bucket = aws_s3_bucket.ci_artifacts.id

  rule {
    id     = "expire-old-artifacts"
    status = "Enabled"

    filter {}

    expiration {
      days = 1
    }
  }
}
