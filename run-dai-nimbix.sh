#!/bin/bash

set -e
set -x

CONFIG_LOC="$1"

export DRIVERLESS_AI_CONFIG_FILE_PATH=$CONFIG_LOC

printenv

echo "Starting Driverless AI"
sudo nvidia-smi -pm 1
/opt/h2oai/dai/run-h2oai.sh
tail -f /opt/h2oai/dai/log/h2oai.out
