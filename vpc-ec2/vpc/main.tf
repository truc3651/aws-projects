resource "aws_vpc" "vpc" {
    cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    "Name" = "demo-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_cidr)
    vpc_id     = aws_vpc.vpc.id
    availability_zone = var.availability_zone[count.index]
  cidr_block = var.public_subnet_cidr[count.index]
  map_public_ip_on_launch = true

  tags = {
    "Name" = "public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
     count = length(var.private_subnet_cidr)
    vpc_id     = aws_vpc.vpc.id
    availability_zone = var.availability_zone[count.index]
  cidr_block = var.private_subnet_cidr[count.index]

  tags = {
    "Name" = "private-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = "gw"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    "Name" = "public_route_table"
  }
}

resource "aws_route_table_association" "public_subnets_association" {
  for_each   = { for k, v in aws_subnet.public_subnet : k => v }
  subnet_id = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "eip" {
  domain   = "vpc"
}

resource "aws_nat_gateway" "nat" {
  depends_on = [aws_internet_gateway.gw]
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    "Name" = "nat"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    "Name" = "private_route_table"
  }
}

resource "aws_route_table_association" "private_subnets_association" {
  for_each = { for k, v in aws_subnet.private_subnet : k => v }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_route_table.id
}