FROM nvidia/cuda:8.0-cudnn5-devel-ubuntu16.04
MAINTAINER H2o.ai <ops@h2o.ai>

ENV DEBIAN_FRONTEND noninteractive

# Nimbix Integrations
COPY NAE/AppDef.json /etc/NAE/AppDef.json
COPY NAE/AppDef.png /etc//NAE/default.png
COPY NAE/screenshot.png /etc/NAE/screenshot.png

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
  curl -sL https://deb.nodesource.com/setup_7.x | bash - && \
  add-apt-repository ppa:fkrull/deadsnakes  && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update -yqq && \
  echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections

# Install H2o dependancies
RUN \
  apt-get install -y \
  python3.6 \
  python3.6-dev \
  python3-pip \
  python3-dev \
  nodejs \
  libgtk2.0-0 \
  dirmngr 

# Get R
RUN \
  apt-get install -y r-base r-base-dev && \
  wget https://cran.cnr.berkeley.edu/src/contrib/data.table_1.10.4.tar.gz && \
  wget https://cran.cnr.berkeley.edu/src/contrib/lazyeval_0.2.0.tar.gz && \
  wget https://cran.cnr.berkeley.edu/src/contrib/Rcpp_0.12.10.tar.gz && \
  wget https://cran.cnr.berkeley.edu/src/contrib/tibble_1.3.0.tar.gz && \
  wget https://cran.cnr.berkeley.edu/src/contrib/hms_0.3.tar.gz && \
  wget https://cran.cnr.berkeley.edu/src/contrib/feather_0.3.1.tar.gz && \
  R CMD INSTALL data.table_1.10.4.tar.gz lazyeval_0.2.0.tar.gz Rcpp_0.12.10.tar.gz tibble_1.3.0.tar.gz hms_0.3.tar.gz feather_0.3.1.tar.gz

# Install Oracle Java 8
RUN \
  apt-get install -y oracle-java8-installer && \
  apt-get clean && \
  rm -rf /var/cache/apt/*

# Install Python Dependancies
ADD requirements.txt /opt/h2oai/requirements.txt

RUN \
  /usr/bin/pip3 install --upgrade pip && \
  /usr/bin/pip3 install numpy && \
  /usr/bin/pip3 install cython && \
  /usr/bin/pip3 install pandas && \
  /usr/bin/pip3 install -r /opt/h2oai/requirements.txt && \
  /usr/bin/pip3 install psutil && \
  python3.6 -m pip install --upgrade pip && \
  python3.6 -m pip install setuptools && \
  python3.6 -m pip install python-dateutil && \
  python3.6 -m pip install numpy && \
  python3.6 -m pip install cython && \
  python3.6 -m pip install tensorflow-gpu && \
  python3.6 -m pip install -r /opt/h2oai/requirements.txt && \
  python3.6 -m pip install pandas && \
  python3.6 -m pip install psutil && \
  python3.6 -m pip install pycuda

RUN \
  cd /opt && \
  git clone http://github.com/fbcotter/py3nvml && \
  cd py3nvml && \
  /usr/bin/python3.6 ./setup.py install

# Add h2o3-xgboost
ADD h2o-3.11.0.99999 /opt/h2o-3
ADD h2o /opt/h2oai/h2o
ADD h2oaiglm /opt/h2oaiglm
ADD h2oai-prototypes /opt/h2oai-prototypes


# Add bash scripts
COPY scripts/start-h2o.sh /opt/start-h2o.sh
COPY scripts/run-benchmark.sh /opt/run-benchmark.sh
COPY scripts/start-h2oai.sh /opt/start-h2oai.sh
COPY scripts/cuda.sh /etc/profile.d/cuda.sh

# Set executable on scripts
RUN \
  chown -R nimbix:nimbix /opt && \
  chmod +x /opt/start-h2o.sh && \
  chmod +x /opt/start-h2oai.sh && \
  chmod +x /opt/run-benchmark.sh

RUN \
  python3.6 -m pip install /opt/h2o-3/python/h2o-*-py2.py3-none-any.whl

