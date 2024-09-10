resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    instance_tenancy = "default"

    tags = {
        Name = "three_tier_vpc"
    }
}

resource "aws_subnet" "public_subnets" {
    count = length(var.public_subnet_cidr)
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidr[count.index]

    tags = {
      Name = "public_subnet"
    }
}

resource "aws_subnet" "private_subnets" {
    count = length(var.private_subnet_cidr)
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidr[count.index]

    tags = {
      Name = "private_subnet"
    }
}

resource "aws_subnet" "database_subnets" {
    count = length(var.database_subnet_cidr)
    vpc_id = aws_vpc.main.id
    cidr_block = var.database_subnet_cidr[count.index]

    tags = {
      Name = "database_subnet"
    }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow all internet access to ALB"
  vpc_id      = aws_vpc.main.id

  ingress = {
    from_port         = 80
    to_port           = 80
    ip_protocol       = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow ALB access web instances"
  vpc_id      = aws_vpc.main.id

  ingress = {
    from_port         = 80
    to_port           = 80
    ip_protocol       = "tcp"
    cidr_blocks = [aws_security_group.alb_sg.id]
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow web instances access to RDS"
  vpc_id      = aws_vpc.main.id

  ingress = {
    from_port         = 80
    to_port           = 80
    ip_protocol       = "tcp"
    cidr_blocks = [aws_security_group.web_sg.id]
  }
}
