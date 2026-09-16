#db subnet group for RDS instance

resource "aws_db_subnet_group" "database_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.db_pvt_subnet_1.id, aws_subnet.db_pvt_subnet_2.id]

  tags = {
    Name = "subnet-group-for-rds"
  }
}

resource "aws_security_group" "postgres_sg" {
  name        = "postgres-rds-sg"
  description = "Allow inbound PostgreSQL traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow app servers to connect"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["12.0.0.0/16"]
  }
}

resource "aws_db_instance" "default" {
  allocated_storage           = 10
  db_name                     = "mydb"
  username                    = jasbinder
  engine                      = "PostgreSQL"
  engine_version              = "17"
  instance_class              = "db.t4g.micro"
  storage_type                = "gp3"
  manage_master_user_password = true
  publicly_accessible         = false
  db_subnet_group_name        = aws_db_subnet_group.database_subnet_group.name
  vpc_security_group_ids      = [aws_security_group.postgres_sg.id]
  skip_final_snapshot         = true

}