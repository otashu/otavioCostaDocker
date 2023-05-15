//Cria a vpc
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true //permite que as instancias reconheçam dns (necessário para que o efs possa ser montado via dns)
  enable_dns_hostnames = true //cria dns para as instancias, usando seus ips

  tags = {
    "Name" = "vpc-compass"
  }
}

//Cria as subnets publicas
resource "aws_subnet" "subnet-pub" {
  count             = 2
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = count.index == 0 ? "us-east-1a" : "us-east-1b" //Define onde elas são disponiveis 

  tags = {
    "Name" = "subnet-pub-${count.index}" //Ex: subnet-pub-0
  }
  map_public_ip_on_launch = true //define se elas terão um ip público (como elas são públicas, precisam de um)
}

//Cria as subnets publicas
resource "aws_subnet" "subnet-priv" {
  count             = 2
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.${count.index + 2}.0/24"                 //'+ 2' é necessário para que as subnets privadas não tenha os mesmos cidr_blocks que as publicas.
  availability_zone = count.index == 0 ? "us-east-1a" : "us-east-1b" //Define onde elas são disponiveis 

  tags = {
    "Name" = "subnet-priv-${count.index}" //Ex: subnet-pub-0
  }
  map_public_ip_on_launch = false //define se elas terão um ip público (como elas são privadas, não podem ter um)
}

//Cria o Internet-Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = "gw-pub"
  }
}

//Cria o Nat-Gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id          //precisa de um ip elástico
  subnet_id     = aws_subnet.subnet-pub[0].id //a subnet precisa ser publica

  tags = {
    "Name" = "gw-priv"
  }
}

//Cria o Ip elastico para o Nat-Gateway
resource "aws_eip" "nat_eip" {

  vpc = true //associado à uma vpc, não à uma instancia especifica

  tags = {
    "Name" = "eip-nat"
  }
}

//Route Table das subnets publicas
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id //Define qual a vpc

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id //Define qual o Internet-Gateway
  }

  tags = {
    Name = "rt-pub"
  }
}

//Route Table das subnets privadas
resource "aws_route_table" "priv_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id //Define qual o Nat-Gateway
  }

  tags = {
    Name = "rt-priv"
  }
}

//Cria uma Route-Table-Association para as subnets publicas
resource "aws_route_table_association" "rta_pub" {
  count          = 2
  subnet_id      = aws_subnet.subnet-pub[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

//Cria uma Route-Table-Association para as subnets privadas
resource "aws_route_table_association" "rta_priv" {
  count          = 2
  subnet_id      = aws_subnet.subnet-priv[count.index].id
  route_table_id = aws_route_table.priv_route_table.id
}