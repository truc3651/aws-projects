data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64-gp2"]  # This is the pattern for Amazon Linux 2023 AMI
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["137112412989"]  # Amazon's AWS account ID for Amazon Linux AMIs
}

resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]

  subnet_id              = var.subnet_id
  user_data_replace_on_change = true
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y httpd.x86_64
    sudo systemctl start httpd.service
    sudo systemctl enable httpd.service
    sudo echo "<h1>Hello, world! $(hostname -f)</h1>" > /var/www/html/index.html
    EOF
}


resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // to install nginx
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/aws_projects")
}