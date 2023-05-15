//Define informações sobre o terraform
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
  }
}

//Define o provider
provider "aws" {
  region = "us-east-1"
}

//Cria o EFS
resource "aws_efs_file_system" "EFS" {
  creation_token = "EFS-compass"
  tags = {
    Name = "EFS-compass"
  }
}

//Cria os mount-targets do EFS
resource "aws_efs_mount_target" "EFS_mount" {
  count           = 2
  file_system_id  = aws_efs_file_system.EFS.id
  subnet_id       = aws_subnet.subnet-priv[count.index].id
  security_groups = [aws_security_group.sg-principal.id]
}

//Cria o SG do rds
resource "aws_security_group" "sg-rds" {
  name        = "sgrds"
  description = "sgrds"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sg-principal.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

//Cria o RDS
resource "aws_db_instance" "RDS" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0.32"
  instance_class         = "db.t3.micro"
  //identifier             = "db-compass"
  db_name                = "wordpress"
  username               = "admin"
  password               = "admin123"
  parameter_group_name   = "default.mysql8.0"
  vpc_security_group_ids = [aws_security_group.sg-rds.id]
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.group_rds.name
  skip_final_snapshot    = true //Usado para não criar um backup quando o db for terminado
}

//Cria o subnet-group para o rds
resource "aws_db_subnet_group" "group_rds" {
  name        = "group_rds"
  description = "group_rds"
  subnet_ids = [
    aws_subnet.subnet-priv[0].id,
    aws_subnet.subnet-priv[1].id,
    aws_subnet.subnet-pub[0].id,
    aws_subnet.subnet-pub[1].id
  ]
}