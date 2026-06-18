resource "aws_db_subnet_group" "payroll" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier        = "${var.project_name}-db"
  engine            = "postgres"
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

  db_name  = var.db_name
  username = var.db_username

  # AWS generates and owns this password, storing it directly in Secrets Manager
  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.payroll.arn

  storage_encrypted = true
  kms_key_id        = aws_kms_key.payroll.arn

  publicly_accessible = false
  multi_az            = false

  db_subnet_group_name   = aws_db_subnet_group.payroll.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Deliberate: a final snapshot would survive terraform destroy and could
  # linger with real PII in it long after teardown, working against the
  # GDPR/right-to-erasure posture documented in README. Trade-off: a
  # mistaken `terraform destroy` loses all data with no recovery point.
  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-rds"
  }
}
