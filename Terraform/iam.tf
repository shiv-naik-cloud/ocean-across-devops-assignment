data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "companies_role" {
  name               = "companies-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role" "bureaus_role" {
  name               = "bureaus-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role" "employees_role" {
  name               = "employees-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_policy" "companies_policy" {
  name = "companies-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject"]
        Resource = "${aws_s3_bucket.payroll_bucket.arn}/companies/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "companies_attach" {
  role       = aws_iam_role.companies_role.name
  policy_arn = aws_iam_policy.companies_policy.arn
}

resource "aws_iam_policy" "bureaus_policy" {
  name = "bureaus-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject"]
        Resource = "${aws_s3_bucket.payroll_bucket.arn}/bureaus/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bureaus_attach" {
  role       = aws_iam_role.bureaus_role.name
  policy_arn = aws_iam_policy.bureaus_policy.arn
}

resource "aws_iam_policy" "employees_policy" {
  name = "employees-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject"]
        Resource = "${aws_s3_bucket.payroll_bucket.arn}/employees/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "employees_attach" {
  role       = aws_iam_role.employees_role.name
  policy_arn = aws_iam_policy.employees_policy.arn
}

resource "aws_iam_instance_profile" "companies_profile" {
  name = "companies-profile"
  role = aws_iam_role.companies_role.name
}

resource "aws_iam_instance_profile" "bureaus_profile" {
  name = "bureaus-profile"
  role = aws_iam_role.bureaus_role.name
}

resource "aws_iam_instance_profile" "employees_profile" {
  name = "employees-profile"
  role = aws_iam_role.employees_role.name
}