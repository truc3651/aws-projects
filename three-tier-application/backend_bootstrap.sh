#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bak
sudo sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf
echo "<html><body><h1>Backend Server</h1><p>This is the backend server running on port 8080.</p></body></html>" | sudo tee /var/www/html/index.html
sudo systemctl restart httpd
sudo systemctl enable httpd
sudo systemctl status httpd

sudo dnf update -y
sudo dnf install mariadb105
mysql -h endpoint -P 3306 -u admin -p
