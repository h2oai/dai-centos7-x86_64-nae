FROM nvidia/cuda:8.0-cudnn5-runtime-ubuntu16.04
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
  cpio \
  vim \
  net-tools \
  git \
  dirmngr

# Setup Repos
RUN \
  add-apt-repository ppa:fkrull/deadsnakes  && \
  add-apt-repository -y ppa:webupd8team/java && \
  curl -sL https://deb.nodesource.com/setup_7.x | bash - && \
  apt-get update -yqq && \
  echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections

# Install H2o dependencies
RUN \
  apt-get install --no-install-recommends -y \
  python3.6 \
  python3.6-dev \
  python3-pip \
  nodejs \
  build-essential

RUN \
  /usr/bin/python3.6 -m pip install --upgrade pip && \
  /usr/bin/python3.6 -m pip install --upgrade setuptools && \
  /usr/bin/python3.6 -m pip install --upgrade python-dateutil && \
  /usr/bin/python3.6 -m pip install --upgrade numpy && \
  /usr/bin/python3.6 -m pip install --upgrade cython && \
  /usr/bin/python3.6 -m pip install --upgrade tensorflow-gpu && \
  /usr/bin/python3.6 -m pip install --upgrade psutil && \
  /usr/bin/python3.6 -m pip install --upgrade notebook

# Install Oracle Java 8
RUN \
  apt-get install -y oracle-java8-installer && \
  apt-get clean && \
  rm -rf /var/cache/apt/*

# Install LLVM for pydatatable
RUN \
  wget --quiet http://releases.llvm.org/4.0.0/clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz && \
  tar xf clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz && \
  rm clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz

ENV \
  LLVM4=/clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.04 \
  CC=/clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.04/bin/clang \
  CLANG=/clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.04/bin/clang \
  LLVM_CONFIG=/clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.04/bin/llvm-config

RUN \
  cp /clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.04/lib/libomp.so /usr/lib

# Add requirements
ADD requirements.txt requirements.txt

RUN \
  /usr/bin/python3.6 -m pip install -r requirements.txt

# Add bash scripts
COPY scripts/start-h2o.sh /opt/start-h2o.sh
COPY scripts/run-benchmark.sh /opt/run-benchmark.sh
COPY scripts/start-h2oai.sh /opt/start-h2oai.sh
COPY scripts/cuda.sh /etc/profile.d/cuda.sh
COPY scripts/start-notebook.sh /opt/start-notebook.sh

RUN \
  /usr/bin/python3.6 -m pip install https://s3.amazonaws.com/tomk/alpha/xgboost-fromjon-1/xgboost-0.6-py3-none-any.whl && \
  cp -p /usr/local/xgboost/libxgboost.so /usr/local/lib/python3.6/dist-packages/xgboost/

RUN \
  wget --quiet http://172.17.0.53:8081/nexus/repository/snapshots/ai/h2o/mli/mli-backend/0.1.0-SNAPSHOT/mli-backend-0.1.0-20170627.220812-1-all.jar && \
  mv mli-backend-0.1.0-20170627.220812-1-all.jar h2o.jar

# Add h2o
ADD h2oai /opt/h2oai

# Add deps
ADD h2oai/deps deps
RUN \
  /usr/bin/python3.6 -m pip install -r deps/requirements.txt

ADD datatable-0.1.0-cp36-cp36m-linux_x86_64.whl datatable-0.1.0-cp36-cp36m-linux_x86_64.whl
ADD mli-0.1-py2.py3-none-any.whl mli-0.1-py2.py3-none-any.whl

RUN \
  python3.6 -m pip install mli-0.1-py2.py3-none-any.whl && \
  python3.6 -m pip install datatable-0.1.0-cp36-cp36m-linux_x86_64.whl

RUN \
  cd /opt/h2oai && \
  sed -i "s/python setup.py/python3.6 setup.py/" /opt/h2oai/Makefile && \
  sed -i "s/pip/pip3.6/" /opt/h2oai/Makefile && \
  cp /clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.04/lib/libomp.so /usr/lib && \
  make clean && \
  make
  
# Add shell wrapper
COPY scripts/run.sh /run.sh

COPY nccl.tar /nccl.tar

RUN \
  cd / && \
  tar -xvf nccl.tar

# Set executable on scripts
RUN \
  chown -R nimbix:nimbix /opt && \
  chmod +x /opt/start-h2o.sh && \
  chmod +x /opt/start-h2oai.sh && \
  chmod +x /opt/run-benchmark.sh && \
  chmod +x /opt/start-notebook.sh && \
  chmod +x /run.sh

EXPOSE 54321
EXPOSE 8888
EXPOSE 12345

# User python install
USER nimbix

# Nimbix Integrations
COPY NAE/AppDef.json /etc/NAE/AppDef.json
COPY NAE/AppDef.png /etc//NAE/default.png
COPY NAE/screenshot.png /etc/NAE/screenshot.png
