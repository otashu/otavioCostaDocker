
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

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum upgrade -y
    chmod 400 /home/ec2-user/chave.pem
    EOF

  provisioner "file" {
    source      = "chave.pem"
    destination = "/home/ec2-user/chave.pem"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("./chave.pem")
      host        = self.public_ip
    }
  }

  vpc_security_group_ids = [aws_security_group.sg-bastion.id]
  subnet_id              = aws_subnet.subnet-pub[0].id

  volume_tags = {
    Name       = "PB UNIVEST URI - bastion"
    CostCenter = "C092000004"
    Project    = "PB UNIVEST URI"
  }
}

# resource "aws_instance" "principal" {
#   ami           = "ami-06a0cd9728546d178"
#   instance_type = "t2.micro"
#   key_name      = "chave"
#   tags = {
#     Name       = "PB UNIVEST URI - principal"
#     CostCenter = "C092000004"
#     Project    = "PB UNIVEST URI"
#   }

#   vpc_security_group_ids = [aws_security_group.sg-principal.id]
#   subnet_id              = aws_subnet.subnet-priv[0].id

#   user_data = templatefile("./user_data.sh", { EFS_ID = aws_efs_file_system.EFS.id })

#   volume_tags = {
#     Name       = "PB UNIVEST URI - principal"
#     CostCenter = "C092000004"
#     Project    = "PB UNIVEST URI"
#   }
# }

resource "aws_autoscaling_group" "asg_principal" {
  name_prefix          = "asg_principal"
  max_size             = 2
  min_size             = 1
  desired_capacity     = 2
  vpc_zone_identifier  = aws_subnet.subnet-priv[*].id
  launch_configuration = aws_launch_configuration.lc_principal.id

  target_group_arns = [aws_lb_target_group.TG-compass.arn]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "PB UNIVEST URI - principal"
    propagate_at_launch = true
  }

  tag {
    key                 = "CostCenter"
    value               = "C092000004"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "PB UNIVEST URI"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "lc_principal" {
  name_prefix     = "my-lc"
  image_id        = "ami-06a0cd9728546d178"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.sg-principal.id]
  key_name        = "chave"

  user_data = templatefile("${path.module}/user_data.sh", {
    EFS_ID  = aws_efs_file_system.EFS.dns_name
    DB_HOST = aws_db_instance.RDS.address
  })

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 50
    delete_on_termination = true
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

resource "aws_lb_listener" "listener-compass" {
  load_balancer_arn = aws_lb.ALB-compass.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TG-compass.arn
  }
}


resource "aws_lb_target_group" "TG-compass" {
  name        = "TG-compass"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    path = "/"
  }
}