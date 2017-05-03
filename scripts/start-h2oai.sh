#!/bin/bash

cd /opt/h2oai && /usr/bin/python3.6 -m h2o

sudo sed -e 's/8888/12345/' -i /etc/nginx/site-enabled/default
sudo sed -e 's/8888/12345/' -i /etc/nginx/sites-enabled/notebook-site

sudo /etc/init.d/nginx restart

# Start Notebook
/usr/local/bin/nimbix_notebook
