provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "sg-bastion" {
  name        = "sgbastion"
  description = "sgbastion"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
resource "aws_security_group" "sg-principal" {
  name        = "sgprincipal"
  description = "sgprincipal"

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
  key_name      = "Charizard"
  tags = {
    Name       = "PB UNIVEST URI - bastion"
    CostCenter = "C092000004"
    Project    = "PB UNIVEST URI"
  }

  vpc_security_group_ids = [aws_security_group.sg-bastion.id]

  volume_tags = {
    Name       = "PB UNIVEST URI - bastion"
    CostCenter = "C092000004"
    Project    = "PB UNIVEST URI"
  }
}

resource "aws_instance" "principal" {
  ami           = "ami-06a0cd9728546d178"
  instance_type = "t2.micro"
  key_name      = "Charizard"
  tags = {
    Name       = "PB UNIVEST URI - principal"
    CostCenter = "C092000004"
    Project    = "PB UNIVEST URI"
  }

  vpc_id                 = data.aws_vpc.vpc.id
  subnet_id              = data.aws_subnet.subnet-priv.id
  vpc_security_group_ids = [aws_security_group.sg-principal.id]

  volume_tags = {
    Name       = "PB UNIVEST URI - principal"
    CostCenter = "C092000004"
    Project    = "PB UNIVEST URI"
  }
}

resource "aws_lb" "ALB-compass" {
  name               = "ABL-compass"
  load_balancer_type = "application"
  subnets            = data.aws_subnet.subnet-pub[*].id

  security_groups = [aws_security_group.sg-principal.id]

  tags = {
    Name = "ABL-compass"
  }
}

resource "aws_lb_target_group" "TG-compass" {
  name     = "TG-compass"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.vpc.id

  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group_attachment" "my_target_group_attachment" {
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id        = aws_instance.my_instance.id
  port             = 80
}
