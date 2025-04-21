

# Security Groups
resource "aws_security_group" "jumphost_sg" {
  name        = "Ssm-JumpHost-SG"
  description = "Security group for SSM JumpHost"
  vpc_id      = aws_vpc.main.id
  # Jumphost can access anything
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Roles
resource "aws_iam_role" "jumphost_role" {
  name = "ssm-jumphost-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ssm_attach" {
  name       = "ssm-policy-attachment"
  roles      = [aws_iam_role.jumphost_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "jumphost_instance_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.jumphost_role.name
}

resource "aws_instance" "jumphost" {
  ami                    = "ami-0623d99ec54f5489d" # Amazon Linux 2 (ap-southeast-1)
  instance_type          = "t3.micro"
  iam_instance_profile   = aws_iam_instance_profile.jumphost_instance_profile.name
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.jumphost_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y amazon-ssm-agent
              sudo systemctl enable amazon-ssm-agent
              sudo systemctl start amazon-ssm-agent
              EOF

  tags = {
    Name = "Ssm-JumpHost"
  }
}
