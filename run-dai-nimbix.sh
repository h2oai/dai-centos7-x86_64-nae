#!/bin/bash

set -e
set -x

export DRIVERLESS_AI_CONFIG_FILE_PATH="/opt/h2oai/dai"
echo "$DRIVERLESS_AI_CONFIG_FILE_PATH"

if [ -z "$4" ]
then
  echo "No Configuration File Provided"
else
  echo "Making Configuration File Available for DAI"
  CONFIG_FILE="$4"
  cp $CONFIG_FILE "$DRIVERLESS_AI_CONFIG_FILE_PATH/config.toml"
fi

echo "Starting Driverless AI"
sudo nvidia-smi -pm 1
/opt/h2oai/dai/run-h2oai.sh
tail -f /opt/h2oai/dai/log/h2oai.out
