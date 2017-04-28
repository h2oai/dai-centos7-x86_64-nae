#!/bin/bash

# This will start H2o backgrounded, and automatically consume 90% available memory

# If you want S3 support create a core-site.xml file and place it in $HOME/.ec2/

# Assumes the h2o.jar you want is in /opt

set -e

# Use 90% of RAM for H2O.
memTotalKb=`cat /proc/meminfo | grep MemTotal | sed 's/MemTotal:[ \t]*//' | sed 's/ kB//'`
memTotalMb=$[ $memTotalKb / 1024 ]
tmp=$[ $memTotalMb * 90 ]
xmxMb=$[ $tmp / 100 ]

/usr/bin/python3.6 -m h2o
