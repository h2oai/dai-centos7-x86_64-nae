FROM nvidia/cuda:8.0-cudnn5-devel-ubuntu16.04
MAINTAINER H2o.ai <ops@h2o.ai>

ENV DEBIAN_FRONTEND noninteractive

# Nimbix Common
RUN \
  apt-get -y update && \
  apt-get -y install \
  curl \
  apt-utils

RUN \
    curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/nimbix/image-common/master/install-nimbix.sh |  bash

# Expose port 22 for local JARVICE emulation in docker
EXPOSE 22

# Notebook Common
ADD https://raw.githubusercontent.com/nimbix/notebook-common/master/install-ubuntu.sh /tmp/install-ubuntu.sh
RUN \
  bash /tmp/install-ubuntu.sh 3 && \
  rm -f /tmp/install-ubuntu.sh

# General Packaging
RUN \
  apt-get -y install \
  python-software-properties \
  software-properties-common \
  iputils-ping \
  cpio 

# Setup Repos
RUN \
  echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" | sudo tee -a /etc/apt/sources.list && \
  gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 && \
  gpg -a --export E084DAB9 | apt-key add -&& \
  add-apt-repository ppa:fkrull/deadsnakes  && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update -yqq && \
  echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections

# Install H2o dependencies
RUN \
  apt-get install -y \
  libopenblas-dev \
  libatlas-base-dev \
  python3.6 \
  python3.6-dev \
  python3-pip \
  python3-dev \
  nodejs \
  libgtk2.0-0 \
  dirmngr 

# Install Python Dependencies
COPY requirements.txt /opt/h2oai/requirements.txt
COPY integrated-all.jar /opt/integrated-all.jar
COPY xgboost-0.6-py36-none-any.whl /opt/xgboost-0.6-py36-none-any.whl
COPY credit_card.csv /opt/credit_card.csv

RUN \
  /usr/bin/pip3 install --upgrade pip && \
  /usr/bin/pip3 install --upgrade numpy && \
  /usr/bin/pip3 install --upgrade cython && \
  /usr/bin/pip3 install --upgrade pandas && \
  /usr/bin/pip3 install --upgrade tensorflow-gpu && \
  /usr/bin/pip3 install --upgrade keras && \
  /usr/bin/pip3 install --upgrade graphviz && \
  /usr/bin/pip3 install -r /opt/h2oai/requirements.txt && \
  /usr/bin/pip3 install --upgrade psutil && \
  /usr/bin/python3.6 -m pip install --upgrade pip && \
  /usr/bin/python3.6 -m pip install --upgrade setuptools && \
  /usr/bin/python3.6 -m pip install --upgrade python-dateutil && \
  /usr/bin/python3.6 -m pip install --upgrade numpy && \
  /usr/bin/python3.6 -m pip install --upgrade cython && \
  /usr/bin/python3.6 -m pip install --upgrade tensorflow-gpu && \
  /usr/bin/python3.6 -m pip install --upgrade keras && \
  /usr/bin/python3.6 -m pip install --upgrade graphviz && \
  /usr/bin/python3.6 -m pip install -r /opt/h2oai/requirements.txt && \
  /usr/bin/python3.6 -m pip install --upgrade pandas && \
  /usr/bin/python3.6 -m pip install --upgrade psutil && \
  /usr/bin/python3.6 -m pip install --upgrade pycuda && \
  /usr/bin/python3.6 -m pip install --upgrade notebook && \
  /usr/bin/python3.6 -m pip install /opt/xgboost-0.6-py36-none-any.whl

# Install Oracle Java 8
RUN \
  apt-get install -y oracle-java8-installer && \
  apt-get clean && \
  rm -rf /var/cache/apt/*

RUN \
  cd /opt && \
  git clone http://github.com/fbcotter/py3nvml && \
  cd py3nvml && \
  /usr/bin/python3.6 ./setup.py install

# Install H2o
RUN \
  cd /opt && \
  wget https://s3.amazonaws.com/h2o-deepwater/public/nightly/deepwater-h2o-230/h2o.jar && \
  wget https://s3.amazonaws.com/h2o-beta-release/goai/h2oaiglm-0.0.2-py2.py3-none-any.whl && \
  wget http://s3.amazonaws.com/h2o-deepwater/public/nightly/deepwater-h2o-230/h2o-3.11.0.230-py2.py3-none-any.whl && \
  wget https://s3.amazonaws.com/h2o-deepwater/public/nightly/latest/mxnet-0.7.0-py2.7.egg && \
  /usr/bin/python3.6 -m pip install --upgrade /opt/h2oaiglm-0.0.2-py2.py3-none-any.whl && \
  /usr/bin/python3.6 -m pip install --upgrade /opt/h2o-3.11.0.230-py2.py3-none-any.whl && \  
  /usr/bin/pip3 install --upgrade /opt/h2oaiglm-0.0.2-py2.py3-none-any.whl && \
  /usr/bin/pip3 install --upgrade /opt/h2o-3.11.0.230-py2.py3-none-any.whl && \
  git clone http://github.com/h2oai/perf
  
ADD h2oai /opt/h2oai

RUN \
  cd /opt && \
  wget https://s3.amazonaws.com/h2o-public-test-data/bigdata/laptop/higgs_head_2M.csv && \
  wget https://s3.amazonaws.com/h2o-public-test-data/bigdata/laptop/ipums_feather.gz

# Add bash scripts
COPY scripts/start-h2o.sh /opt/start-h2o.sh
COPY scripts/run-benchmark.sh /opt/run-benchmark.sh
COPY scripts/start-h2oai.sh /opt/start-h2oai.sh
COPY scripts/cuda.sh /etc/profile.d/cuda.sh
COPY scripts/start-notebook.sh /opt/start-notebook.sh

# Set executable on scripts
RUN \
  chown -R nimbix:nimbix /opt && \
  chmod +x /opt/start-h2o.sh && \
  chmod +x /opt/start-h2oai.sh && \
  chmod +x /opt/run-benchmark.sh && \
  chmod +x /opt/start-notebook.sh

EXPOSE 54321
EXPOSE 8888
EXPOSE 12345

# User python install
USER nimbix

RUN \
#  /usr/bin/python3.6 -m pip install --user /opt/h2oaiglm-0.0.2-py2.py3-none-any.whl && \
#  /usr/bin/pip3 install --upgrade --user /opt/h2oaiglm-0.0.2-py2.py3-none-any.whl && \
#  /usr/bin/python3.6 -m pip install --user /opt/h2o-3.11.0.230-py2.py3-none-any.whl && \
#  /usr/bin/pip3 install --upgrade --user /opt/h2o-3.11.0.230-py2.py3-none-any.whl && \
#  /usr/bin/python3.6 -m pip install --upgrade /opt/xgboost-0.6-py36-none-any.whl && \
  rm -f /opt/*.whl

# Nimbix Integrations
COPY NAE/AppDef.json /etc/NAE/AppDef.json
COPY NAE/AppDef.png /etc//NAE/default.png
COPY NAE/screenshot.png /etc/NAE/screenshot.png
