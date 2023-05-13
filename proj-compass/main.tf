terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
  }
  backend "s3" {
    bucket = "bucket-terraform-proj-compass"
    key    = "aws-proj/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "sg-bastion" {
  name        = "sgbastion"
  description = "sgbastion"

  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg-principal" {
  name        = "sgprincipal"
  description = "sgprincipal"
  vpc_id      = aws_vpc.vpc.id


  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg-bastion.id]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 111
    to_port     = 111
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 111
    to_port     = 111
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

resource "aws_instance" "bastion" {
  ami           = "ami-06a0cd9728546d178"
  instance_type = "t2.micro"
  key_name      = "chave"
  tags = {
    Name       = "PB UNIVEST URI - bastion"
    CostCenter = "C092000004"
    Project    = "PB UNIVEST URI"
  }

  vpc_security_group_ids = [aws_security_group.sg-bastion.id]
  subnet_id              = aws_subnet.subnet-pub[0].id

  volume_tags = {
    Name       = "PB UNIVEST URI - bastion"
    CostCenter = "C092000004"
    Project    = "PB UNIVEST URI"
  }
}

resource "aws_instance" "principal" {
  ami           = "ami-06a0cd9728546d178"
  instance_type = "t2.micro"
  key_name      = "chave"
  tags = {
    Name       = "PB UNIVEST URI - principal"
    CostCenter = "C092000004"
    Project    = "PB UNIVEST URI"
  }

  vpc_security_group_ids = [aws_security_group.sg-principal.id]
  subnet_id              = aws_subnet.subnet-priv[0].id


  volume_tags = {
    Name       = "PB UNIVEST URI - principal"
    CostCenter = "C092000004"
    Project    = "PB UNIVEST URI"
  }
}

resource "aws_autoscaling_group" "asg_principal" {
  name                 = "asg_principal"
  min_size             = 1
  max_size             = 2
  desired_capacity     = 2
  vpc_zone_identifier  = aws_subnet.subnet-priv[*].id
  launch_configuration = aws_launch_configuration.lc_principal.name
}

resource "aws_launch_configuration" "lc_principal" {
  name_prefix     = "my-lc"
  image_id        = aws_instance.principal.ami
  instance_type   = aws_instance.principal.instance_type
  security_groups = [aws_security_group.sg-principal.id]
  key_name        = aws_instance.principal.key_name
  user_data       = aws_instance.principal.user_data
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "ALB-compass" {
  name               = "ABL-compass"
  load_balancer_type = "application"
  subnets            = [aws_subnet.subnet-pub[0].id, aws_subnet.subnet-pub[1].id]

  security_groups = [aws_security_group.sg-principal.id]

  tags = {
    Name = "ABL-compass"
  }
}

resource "aws_lb_target_group" "TG-compass" {
  name     = "TG-compass"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group_attachment" "attALB" {
  target_group_arn = aws_lb_target_group.TG-compass.arn
  target_id        = aws_instance.principal.id
  port             = 80
}
