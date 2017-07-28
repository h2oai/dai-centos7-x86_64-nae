#!/bin/bash

#
# Note:  This run script is meant to be run inside the docker container.
#

set -e

# Change Nginx Redirect
sudo sed -e 's/8888/12345/' -i /etc/nginx/sites-enabled/default
sudo sed -e 's/8888/12345/' -i /etc/nginx/sites-enabled/notebook-site
sudo service ssh restart
sudo /usr/sbin/nginx

sudo rm -f /etc/NAE/url.txt
sudo echo "http://%PUBLICADDR%:12345/" > /etc/NAE/url.txt

if [ "x$1" != "x" ]; then
    d=$1
    cd $d
    shift
    export PYTHONPATH=/opt/h2oai
    exec "$@"
fi

set -x

logdir=/log/`date "+%Y%m%d-%H%M%S"`
mkdir -p $logdir

echo "Starting h2o-3 in the background..."
echo "(Logs are written to the mount on $logdir)"
nohup java -Xmx16g -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -jar h2o.jar -port 54321 -ip 127.0.0.1 >> $logdir/h2o.log 2>&1 &

echo "Execing h2oai..."
echo "(Logs are written to the mount on $logdir)"
cd opt/h2oai
exec python3.6 -m h2oai 1>> $logdir/h2oai.log 2>&1
