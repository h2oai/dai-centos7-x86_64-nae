#!/bin/bash

set -e

# Change Nginx Redirect
sudo sed -e 's/8888/12345/' -i /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-enabled/notebook-site
sudo service nginx restart
sudo service ssh restart

set -x

jobPublic="`sed -n 's/JOB_PUBLICADDR=//p' jobinfo.sh | sed -e "s/.jarvice.com//"`"

logdir=/data/log/$jobPublic/`date "+%Y%m%d-%H%M%S"`
mkdir -p $logdir

echo "Starting h2o-3 in the background..."
echo "(Logs are written to the mount on $logdir)"
nohup java -Xmx16g -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -jar /h2o.jar -port 54321 -ip 127.0.0.1 >> $logdir/h2o.log 2>&1 &

echo "Execing h2oai..."
echo "(Logs are written to the mount on $logdir)"
cd /
. h2oai_env/bin/activate && exec python3.6 -m h2oai 1>> $logdir/h2oai.log 2>&1
