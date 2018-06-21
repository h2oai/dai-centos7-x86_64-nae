#!/bin/bash

export DRIVERLESS_AI_AUTHENTICATION_METHOD="local"
export DRIVERLESS_AI_LOCAL_HTPASSWD_FILE="/etc/JARVICE/htpasswd"
echo "Starting Driverless AI"

sudo nvidia-smi -pm 1
sudo systemctl restart dai
sudo tail -f /opt/h2oai/dai/log/dai.out
