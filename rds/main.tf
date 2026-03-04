provider "aws" {
  region = "us-east-1"
}

# Use existing default VPC subnets automatically
data "aws_subnets" "default" {
  filter {
    name   = "defaultForAz"
    values = ["true"]
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "free-tier-subnet-group"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_security_group" "rds_sg" {
  name        = "free-tier-rds-sg"
  description = "Allow PostgreSQL access"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # lock this down in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "free_tier" {
  identifier        = "free-tier-db"
  engine            = "postgres"
  engine_version    = "15.3"
  instance_class    = "db.t3.micro"   # free tier eligible
  allocated_storage = 20              # free tier: up to 20GB

  db_name  = "appdb"
  username = "dbadmin"
  # assign TF_VAR_db_password in environment variables to pull from environment variables
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = true          # set false if using bastion/VPN
  skip_final_snapshot = true          # fine for dev/free-tier
  deletion_protection = false

  # Free tier — disable paid features
  multi_az                     = false
  storage_encrypted            = false
  performance_insights_enabled = false
  monitoring_interval          = 0
  backup_retention_period      = 0    # disables automated backups
}

output "rds_endpoint" {
  value = aws_db_instance.free_tier.endpoint
}

resource "aws_ssm_parameter" "rds_endpoint" {
  name  = "/myapp/rds/endpoint"
  type  = "String"
  value = aws_db_instance.free_tier.endpoint
}

resource "aws_ssm_parameter" "rds_port" {
  name  = "/myapp/rds/port"
  type  = "String"
  value = aws_db_instance.free_tier.port
}

resource "aws_ssm_parameter" "rds_db_name" {
  name  = "/myapp/rds/db_name"
  type  = "String"
  value = aws_db_instance.free_tier.db_name
}

# Store password as SecureString
resource "aws_ssm_parameter" "rds_password" {
  name  = "/myapp/rds/password"
  type  = "SecureString"
  value = var.db_password
}