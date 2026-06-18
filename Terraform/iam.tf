# One role + policy + instance profile per tenant, scoped to its own S3 prefix and secrets
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "tenant" {
  for_each = var.tenants

  name               = "${var.project_name}-${each.key}-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "${var.project_name}-${each.key}-role"
  }
}

data "aws_iam_policy_document" "tenant" {
  for_each = var.tenants

  statement {
    sid       = "S3TenantPrefixReadWrite"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.payroll_documents.arn}/${each.value}/*"]
  }

  # ListBucket must target the bucket itself, but the prefix condition keeps
  # it from revealing other tenants' object keys
  statement {
    sid       = "S3TenantPrefixList"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.payroll_documents.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${each.value}/*"]
    }
  }

  statement {
    sid     = "OwnSecretAccess"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      aws_secretsmanager_secret.tenant[each.key].arn,
      aws_db_instance.postgres.master_user_secret[0].secret_arn,
    ]
  }

  statement {
    sid       = "OwnSsmParameterAccess"
    effect    = "Allow"
    actions   = ["ssm:GetParameter", "ssm:GetParametersByPath"]
    resources = ["arn:aws:ssm:${var.aws_region}:*:parameter/${var.project_name}/${each.key}/*"]
  }

  statement {
    sid       = "KmsDecryptForOwnData"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = [aws_kms_key.payroll.arn]
  }

  # Lets the SSM-driven CI/CD deploy pull the built image onto this instance
  statement {
    sid       = "CiArtifactsRead"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.ci_artifacts.arn}/${each.value}/*"]
  }
}

resource "aws_iam_policy" "tenant" {
  for_each = var.tenants

  name   = "${var.project_name}-${each.key}-policy"
  policy = data.aws_iam_policy_document.tenant[each.key].json
}

resource "aws_iam_role_policy_attachment" "tenant" {
  for_each = var.tenants

  role       = aws_iam_role.tenant[each.key].name
  policy_arn = aws_iam_policy.tenant[each.key].arn
}

# Lets SSM Agent register the instance and run the CI/CD deploy command -
# instances stay in private subnets with no SSH/public IP needed for deploys
resource "aws_iam_role_policy_attachment" "tenant_ssm" {
  for_each = var.tenants

  role       = aws_iam_role.tenant[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "tenant" {
  for_each = var.tenants

  name = "${var.project_name}-${each.key}-profile"
  role = aws_iam_role.tenant[each.key].name
}
