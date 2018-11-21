#!/usr/bin/env bash

  # -- Boot strap EC2 web servers

yum update -y
yum install httpd -y

cd /var/www/html
echo "Southern Region - Web Server: Indigo" > index.html

service httpd start
chkconfig httpd on
