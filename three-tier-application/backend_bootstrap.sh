#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y apache2
sudo cp /etc/apache2/ports.conf /etc/apache2/ports.conf.bak
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.bak
sudo sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf
sudo sed -i 's/:80>/:8080>/' /etc/apache2/sites-available/000-default.conf
echo "<html><body><h1>Backend Server</h1><p>This is the backend server running on port 8080.</p></body></html>" | sudo tee /var/www/html/index.html
sudo systemctl restart apache2
sudo systemctl enable apache2
sudo systemctl status apache2

sudo yum install mysql -y
