#!/bin/bash

# Start Notebook
echo "You can use SSH tunnels to get to the running notebook securely"
echo "Example ssh -L 8888:localhost:8888 nimbix@%PUBLICADDR%"
jupyter notebook --port=8888 --ip=0.0.0.0
