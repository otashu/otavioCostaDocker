resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
    enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    "Name" = "vpc-terraform"
  }
}

// Public Subnets
resource "aws_subnet" "subnet-pub" {
  count             = 2
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = count.index == 0 ? "us-east-1a" : "us-east-1b"

  tags = {
    "Name" = "subnet-pub-${count.index}"
  }
  map_public_ip_on_launch = true
}

// Private Subnets
resource "aws_subnet" "subnet-priv" {
  count             = 2
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.${count.index + 2}.0/24"
  availability_zone = count.index == 0 ? "us-east-1a" : "us-east-1b"

  tags = {
    "Name" = "subnet-priv-${count.index}"
  }
  map_public_ip_on_launch = false
}

// Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = "gw-pub"
  }
}

// NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.subnet-pub[0].id

  tags = {
    "Name" = "gw-priv"
  }
}

// EIP for NAT Gateway
resource "aws_eip" "nat_eip" {

  vpc = true

  tags = {
    "Name" = "eip-nat"
  }
}

// Route Table for Public Subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "rt-pub"
  }
}

resource "aws_route_table" "priv_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "rt-priv"
  }
}

data "aws_subnets" "subnet_priv_ids" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["subnet-priv"]
  }
}

// RTA for Public Subnets
resource "aws_route_table_association" "rta_pub" {
  count          = 2
  subnet_id      = aws_subnet.subnet-pub[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

// RTA for Private Subnets
resource "aws_route_table_association" "rta_priv" {
  count          = 2
  subnet_id      = aws_subnet.subnet-priv[count.index].id
  route_table_id = aws_route_table.priv_route_table.id
}