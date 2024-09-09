data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}

resource "aws_instance" "web_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]

  subnet_id              = var.subnet_id
  user_data_replace_on_change = true
  user_data = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install nginx -y

    echo "server {
        listen 80 default_server;
        listen [::]:80 default_server;
        root /var/www/html;
        index index.html;
        server_name _;
        location / {
            try_files \$uri \$uri/ =404;
        }
    }" | sudo tee /etc/nginx/sites-available/default
    
    echo "<html><body><div>Hello, world!</div></body></html>" > sudo tee /var/www/html/index.html

    sudo ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

    sudo nginx -t

    sudo systemctl enable nginx
    sudo systemctl start nginx
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("${path.module}/../id_rsa.pub")  # Make sure this path is correct
}