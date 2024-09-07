provider "aws" {
  profile = "default"
  region = "ap-southeast-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  owners = ["099720109477"] # Canonical Ubuntu AWS account id
}

resource "aws_instance" "hello" {
  count = 5
  ami           = data.aws_ami.ubuntu
  instance_type = var.instance_type
}

output "ec2" {
  value = {
    public_ip = [for v in aws_instance.hello : v.public_ip]
  }
}

