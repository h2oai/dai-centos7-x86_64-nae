#!/bin/bash

sudo nvidia-smi -pm 1
/opt/h2oai/dai/run-h2oai.sh
tail -f /opt/h2oai/dai/log/h2oai.out 
