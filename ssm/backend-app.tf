# Security Groups
resource "aws_security_group" "backend_sg" {
  name        = "Backend-App-SG"
  description = "Security group for backend application"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP from within VPC
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "backend" {
  ami                    = "ami-0623d99ec54f5489d" # Amazon Linux 2 (ap-southeast-1)
  instance_type          = "t3.micro"
  iam_instance_profile   = aws_iam_instance_profile.jumphost_instance_profile.name
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  user_data_replace_on_change = true
  user_data                   = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y amazon-ssm-agent
              sudo systemctl enable amazon-ssm-agent
              sudo systemctl start amazon-ssm-agent

              sudo curl -sL https://rpm.nodesource.com/setup_16.x | sudo bash -
              sudo yum install -y nodejs

              mkdir -p ~/app
              cat > ~/app/app.js << 'APPJS'
              const http = require('http');

              const server = http.createServer((req, res) => {
                if (req.url === '/') {
                  res.writeHead(200, { 'Content-Type': 'application/json' });
                  res.end(JSON.stringify({
                    message: 'Hello from the Docker container!',
                    hostname: require('os').hostname(),
                    timestamp: new Date().toISOString()
                  }));
                } else if (req.url === '/health') {
                  res.writeHead(200, { 'Content-Type': 'application/json' });
                  res.end(JSON.stringify({ status: 'healthy' }));
                } else {
                  res.writeHead(404, { 'Content-Type': 'application/json' });
                  res.end(JSON.stringify({ error: 'Not found' }));
                }
              });

              const PORT = 3000;
              server.listen(PORT, '0.0.0.0', () => {
                console.log('Server running on port', PORT);
              });
              APPJS

              node app.js
              EOF

  tags = {
    Name = "Backend-App"
  }
}
