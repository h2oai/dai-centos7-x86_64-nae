#!/bin/bash

set -e
set -x

echo "Arguement One: $1"
echo "Arguement Two: $2"
echo "Arguement Three: $3"
echo "Arguement Four: $4"

export DRIVERLESS_AI_CONFIG_FILE_PATH=$4
echo "$DRIVERLESS_AI_CONFIG_FILE_PATH"

echo "Starting Driverless AI"
sudo nvidia-smi -pm 1
/opt/h2oai/dai/run-h2oai.sh
tail -f /opt/h2oai/dai/log/h2oai.out
