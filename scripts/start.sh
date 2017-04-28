#!/bin/bash

# This will start H2o backgrounded, and automatically consume 90% available memory

# If you want S3 support create a core-site.xml file and place it in $HOME/.ec2/

# Assumes the h2o.jar you want is in /opt

set -e

# Use 90% of RAM for H2O.
cd /opt/h2oai && /usr/bin/python3.6 -m h2o
