resource "aws_db_subnet_group" "db_subnet_group" {
  name = "payroll-db-subnet-group"

  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  tags = {
    Name = "db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier         = "payroll-db"
  engine             = "postgres"
  instance_class     = "db.t3.micro"
  allocated_storage  = 20

  db_name  = "payrolldb"
  username = "admin"
  password = var.db_password

  publicly_accessible = false
  multi_az            = false   # free tier safe

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  skip_final_snapshot = true

  tags = {
    Name = "payroll-rds"
  }
}