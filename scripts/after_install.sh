#!/bin/bash

sudo cp -f /var/www/html/index.html /var/www/html/index.html

sudo chmod 644 /var/www/html/index.html

sudo systemctl restart apache2
