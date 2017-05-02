#!/bin/bash

# Start Notebook
echo "You can use SSH tunnels to get to the running notebook securely"
echo "Example ssh -L 8888:localhost:8888 nimbix@%PUBLICADDR%"
sudo /sbin/init
sudo /usr/sbin/nginx
cd /data
exec jupyter notebook --ip=0.0.0.0 --no-browser
