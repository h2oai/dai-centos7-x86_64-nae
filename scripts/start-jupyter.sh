#!/bin/bash

# Start Notebook
echo "You can use SSH tunnels to get to the running notebook securely"
echo "Example ssh -L 8888:localhost:8888 nimbix@203.0.113.0"
jupyter notebook
