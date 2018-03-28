#!/bin/bash

while [ $# -gt 0 ]
do
  echo "$1"
  shift
done

echo "Starting Driverless AI"
sudo nvidia-smi -pm 1
/opt/h2oai/dai/run-h2oai.sh
tail -f /opt/h2oai/dai/log/h2oai.out
