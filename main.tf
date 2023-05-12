provider "aws" {
  access_key = "AKIA6NQ6LDRTMJWKYGHA"
  secret_key = "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"
  region     = "us-east-1"
}

resource "aws_security_group" "sg-terraform" {
  name        = "sgterraform"
  description = "sgterraform"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
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




resource "aws_instance" "terraform" {
  ami           = "ami-0c94855ba95c71c99"
  instance_type = "t2.micro"
  key_name      = "Charizard"
  tags = {
    Name       = "PB UNIVEST URI"
    CostCenter = "C092000004"
    Project    = "PB UNIVEST URI"
  }

  vpc_security_group_ids = [aws_security_group.sg-terraform.id]

  volume_tags = {
    Name       = "PB UNIVEST URI"
    CostCenter = "C092000004"
    Project    = "PB UNIVEST URI"
  }
}
