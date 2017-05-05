#!/bin/bash

# Change Nginx Redirect
sudo sed -e 's/8888/12345/' -i /etc/nginx/sites-enabled/default
sudo sed -e 's/8888/12345/' -i /etc/nginx/sites-enabled/notebook-site
sudo /usr/sbin/nginx

cd /opt/h2oai  
/usr/bin/python3.6 -m h2o 
