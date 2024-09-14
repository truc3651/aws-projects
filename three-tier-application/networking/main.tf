resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    instance_tenancy = "default"
     enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
        Name = "three_tier_vpc"
    }
}

// igw
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

// subnets
resource "aws_subnet" "public_subnets" {
    count = length(var.public_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidrs[count.index]
    availability_zone = var.azs[count.index]
    map_public_ip_on_launch = true

    tags = {
      Name = "public_subnet"
    }
}

resource "aws_subnet" "private_subnets" {
    count = length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidrs[count.index]
    availability_zone = var.azs[count.index]

    tags = {
      Name = "private_subnet"
    }
}

resource "aws_subnet" "database_subnets" {
    count = length(var.database_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.database_subnet_cidrs[count.index]
    availability_zone = var.azs[count.index]

    tags = {
      Name = "database_subnet"
    }
}

// alb sg
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_sg_allows_internet_access" {
  security_group_id = aws_security_group.alb_sg.id
  from_port   = 80
  to_port     = 80
  ip_protocol     = "tcp"
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_sg_allows_everywhere" {
  security_group_id = aws_security_group.alb_sg.id
  ip_protocol     = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

// web_sg
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow ALB access web instances"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "web_sg_allows_alb" {
  security_group_id = aws_security_group.web_sg.id
  from_port   = 80
  to_port     = 80
  ip_protocol     = "tcp"
  referenced_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "web_sg_allows_ssh" {
  security_group_id = aws_security_group.web_sg.id
  from_port   = 22
  to_port     = 22
  ip_protocol     = "tcp"
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "web_sg_access_everywhere" {
  security_group_id = aws_security_group.web_sg.id
  ip_protocol     = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

// backend_sg
resource "aws_security_group" "backend_sg" {
  name        = "backend_sg"
  description = "Allow web server access app backend"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "backend_sg_allows_imcp" {
  security_group_id = aws_security_group.backend_sg.id
  from_port   = -1
  to_port     = -1
  ip_protocol     = "icmp"
  referenced_security_group_id = aws_security_group.web_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "backend_sg_allows_ssh" {
  security_group_id = aws_security_group.backend_sg.id
  from_port   = 22
  to_port     = 22
  ip_protocol     = "tcp"
  referenced_security_group_id = aws_security_group.web_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "backend_sg_allows_web" {
  security_group_id = aws_security_group.backend_sg.id
  from_port   = 8080
  to_port     = 8080
  ip_protocol     = "tcp"
  referenced_security_group_id = aws_security_group.web_sg.id
}

resource "aws_vpc_security_group_egress_rule" "web_sg_allows_backend" {
  security_group_id = aws_security_group.web_sg.id
  from_port   = 8080
  to_port     = 8080
  ip_protocol     = "tcp"
  referenced_security_group_id = aws_security_group.backend_sg.id
}

resource "aws_vpc_security_group_egress_rule" "backend_sg_allows_everywhere" {
  security_group_id = aws_security_group.backend_sg.id
  ip_protocol     = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

// database_sg
resource "aws_security_group" "database_sg" {
  name        = "database_sg"
  description = "Allow web servers access to RDS"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "database_sg_allows_backend" {
  security_group_id = aws_security_group.database_sg.id
  from_port   = 5432
  to_port     = 5432
  ip_protocol     = "tcp"
  referenced_security_group_id = aws_security_group.backend_sg.id
}

resource "aws_vpc_security_group_egress_rule" "database_sg_access_everywhere" {
  security_group_id = aws_security_group.database_sg.id
  ip_protocol     = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

// route table
// // public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_rt_association" {
  for_each   = { for k, v in aws_subnet.public_subnets : k => v }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}

// // private route table
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id         = aws_nat_gateway.nat_gw.id
  }
}

resource "aws_route_table_association" "private_rt_association" {
  for_each   = { for k, v in aws_subnet.private_subnets : k => v }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt.id
}