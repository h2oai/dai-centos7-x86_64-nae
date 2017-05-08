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
  dpkg -i https://developer.nvidia.com/compute/cuda/8.0/Prod2/local_installers/cuda-repo-ubuntu1604-8-0-local-ga2_8.0.61-1_amd64-deb
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

# Add h2o3-xgboost
# You must manually add the target h2o to the folder this script is run in
cp -R h2o-3.11.0.99999 /opt/h2o3-xgboost
cp ./scripts/start-xgboost.sh /opt/start-xgboost.sh
chmod +x /opt/start-xgboost.sh && \

python3.6 -m pip install /opt/h2o3-xgboost/python/h2o-*-py2.py3-none-any.whl

# Add H2oAI
# You must manually add the target h2o to the folder this script is run in
cp -R h2o /opt/h2oai/h2o

# Add benchmark and start script
# You must manually add the target h2o to the folder this script is run in
cp -R h2oaiglm /opt/h2oaiglm
cp scripts/run-benchmark.sh /opt/run-benchmark.sh
cp ./scripts/start-h2oai.sh /opt/start-h2oai.sh

chmod +x /opt/start-h2oai.sh && \
chmod +x /opt/run-benchmark.sh 
