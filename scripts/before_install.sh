#!/bin/bash

sudo apt update -y
sudo apt install -y apache2
sudo rm -f /var/www/html/index.html  
sudo systemctl start apache2
sudo systemctl enable apache2
