#!/bin/bash
RUN apt-get -y install \
  locales \
  module-init-tools \
  xz-utils \
  vim \
  openssh-server \
  libpam-systemd \
  libmlx4-1 \
  libmlx5-1 \
  iptables \
  infiniband-diags \
  build-essential \
  curl \
  libibverbs-dev \
  libibverbs1 \
  librdmacm1 \
  librdmacm-dev \
  rdmacm-utils \
  libibmad-dev \
  libibmad5 \
  byacc \
  flex \
  git \
  cmake \
  screen \
  wget \
  apt-utils \
  python-software-properties \
  software-properties-common

# Clean and generate locales
apt-get clean && \
  locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8

# Add Repos
echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" | sudo tee -a /etc/apt/sources.list && \
  gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 && \
  gpg -a --export E084DAB9 | apt-key add -&& \
  add-apt-repository ppa:fkrull/deadsnakes  && \
  add-apt-repository -y ppa:webupd8team/java && \
  add-apt-repository ppa:graphics-drivers/ppa && \
  dpkg -i cuda-repo-ubuntu1604_8.0.61-1_amd64.deb && \
  apt-get update -yqq && \
  echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections

# Install Nvidia
apt-get install -y \
  nvidia-381 \
  cuda 

# Install H2o dependancies
apt-get install -y \
  python3-dev \
  python3-pip \
  python3.6 \
  python3.6-dev \
  dirmngr

# Install Node.js
curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
  apt-get install -y nodejs

# Get R
apt-get install -y r-base r-base-dev && \
  wget https://cran.cnr.berkeley.edu/src/contrib/data.table_1.10.4.tar.gz && \
  wget https://cran.cnr.berkeley.edu/src/contrib/lazyeval_0.2.0.tar.gz && \
  wget https://cran.cnr.berkeley.edu/src/contrib/Rcpp_0.12.10.tar.gz && \
  wget https://cran.cnr.berkeley.edu/src/contrib/tibble_1.3.0.tar.gz && \
  wget https://cran.cnr.berkeley.edu/src/contrib/hms_0.3.tar.gz && \
  wget https://cran.cnr.berkeley.edu/src/contrib/feather_0.3.1.tar.gz && \
  R CMD INSTALL data.table_1.10.4.tar.gz lazyeval_0.2.0.tar.gz Rcpp_0.12.10.tar.gz tibble_1.3.0.tar.gz hms_0.3.tar.gz feather_0.3.1.tar.gz

# Install Oracle Java 8
apt-get install -y oracle-java8-installer && \
  apt-get clean && \
  rm -rf /var/cache/apt/*

# Install Python Dependancies
mkdir /opt/h2oai
cp requirements.txt /opt/h2oai/requirements.txt
python3.6 -m pip install --upgrade pip && \
  python3.6 -m pip install numpy && \
  python3.6 -m pip install cython && \
  python3.6 -m pip install jupyter && \
  python3.6 -m pip install -r /opt/h2oai/requirements.txt

# Get H2oaiglm
wget https://s3.amazonaws.com/h2o-beta-release/goai/h2oaiglm-0.0.2-py2.py3-none-any.whl
wget https://s3.amazonaws.com/h2o-deepwater/public/nightly/latest/deepwater-h2o.tgz
wget https://s3.amazonaws.com/h2o-deepwater/public/nightly/latest/h2o_latest.tar.gz
tar -xvf deepwater-h2o.tgz
tar -xvf h2o_latest.tar.gz

wget https://s3.amazonaws.com/h2o-deepwater/public/nightly/latest/mxnet-0.7.0-py2.7.egg
wget https://s3.amazonaws.com/h2o-deepwater/public/nightly/latest/tensorflow-1.1.0rc0-cp27-cp27mu-linux_x86_64.whl

apt-get install python-wheel-common
wheel convert `find . -name "mxnet*.egg"`
pip2 install `find . -name "mxnet*.whl"` && \
pip2 install `find . -name "tensorflow*.whl"` && \
pip2 install `find . -name "h2o*.whl"` && \

python3.6 -m pip install h2oaiglm-*-py2.py3-none-any.whl
pip install `find . -name "tensorflow-*.whl"`

