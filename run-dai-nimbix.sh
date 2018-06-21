#!/bin/bash

set -e
set -x

export DRIVERLESS_AI_AUTHENTICATION_METHOD="local"
export DRIVERLESS_AI_LOCAL_HTPASSWD_FILE="/etc/JARVICE/htpasswd"
echo "Starting Driverless AI"

tail -f /opt/h2oai/dai/log/dai.out
