resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    "Name" = "vpc-terraform"
  }
}

// Public Subnets
resource "aws_subnet" "subnet-pub" {
  count      = 2
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.${count.index}.0/24"

  tags = {
    "Name" = "subnet-pub-${count.index}"
  }
  map_public_ip_on_launch = true
}

// Private Subnets
resource "aws_subnet" "subnet-priv" {
  count      = 2
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.${count.index + 2}.0/24"

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
  subnet_id     = aws_subnet.subnet-priv[0].id

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

// Route Table for Private Subnets
resource "aws_route_table" "priv_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "rt-priv"
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

// Route for NAT Gateway
resource "aws_route" "nat_route" {
  route_table_id        = aws_route_table.priv_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id        = aws_nat_gateway.nat_gateway.id
}
