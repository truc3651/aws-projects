#!/bin/bash
sudo yum update -y
sudo yum install -y httpd.x86_64
sudo systemctl start httpd.service
sudo systemctl enable httpd.service
sudo echo "<h1>Hello, world! $(hostname -f)</h1>" > /var/www/html/index.html