# Split per-tenant so SG-Company/Bureau/Employee can never reach each other
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Public-facing ALB: allow HTTPS/HTTP in, anywhere out to the tenant SGs"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from the internet (redirected to HTTPS by the listener)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# One SG per tenant: SG-Company, SG-Bureau, SG-Employee
resource "aws_security_group" "tenant" {
  for_each = var.tenants

  name        = "${var.project_name}-${each.key}-sg"
  description = "Tenant EC2 SG for ${each.key}: only the ALB can reach it, no inbound SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App traffic from the ALB only (ALB terminates HTTPS, forwards plain HTTP to the app on 80)"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # No inbound SSH - admin access goes through SSM Session Manager instead
  # (see iam.tf's AmazonSSMManagedInstanceCore attachment), so there's no
  # need for an open port 22 anywhere, even scoped to one CIDR

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${each.key}-sg"
  }
}

# RDS only accepts Postgres connections from the tenant SGs
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "RDS Postgres: only reachable from tenant EC2 security groups on 5432"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = aws_security_group.tenant
    content {
      description     = "Postgres from ${ingress.key}"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value.id]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}
