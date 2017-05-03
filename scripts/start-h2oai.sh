#!/bin/bash

cd /opt/h2oai && /usr/bin/python3.6 -m h2o

sed -e 's/8888/12345/' -i /etc/nginx/site-enabled/default
sed -e 's/8888/12345/' -i /etc/nginx/sites-enabled/notebook-site

# Start Notebook
/usr/local/bin/nimbix_notebook
