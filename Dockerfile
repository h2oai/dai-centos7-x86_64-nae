FROM nvidia/cuda:8.0-cudnn5-runtime-ubuntu16.04
MAINTAINER H2o.ai <ops@h2o.ai>

ENV DEBIAN_FRONTEND noninteractive
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/opt/clang/lib:$LD_LIBRARY_PATH

# Nimbix Common
RUN \
  apt-get -y update && \
  apt-get -y install \
  curl \
  apt-utils && \
  curl -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/nimbix/image-common/master/install-nimbix.sh |  bash

# Expose port 22 for local JARVICE emulation in docker
EXPOSE 22

# Notebook Common
ADD https://raw.githubusercontent.com/nimbix/notebook-common/master/install-ubuntu.sh /tmp/install-ubuntu.sh
RUN \
  bash /tmp/install-ubuntu.sh 3 && \
  rm -f /tmp/install-ubuntu.sh

RUN \
  apt-get -y update && \
  apt-get -y install \
  curl \
  apt-utils \
  python-software-properties \
  software-properties-common \
  iputils-ping \
  wget \
  cpio \
  net-tools \
  git \
  dirmngr && \
  # Setup Repos
  add-apt-repository ppa:fkrull/deadsnakes  && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update -yqq && \
  echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \
  curl -sL https://deb.nodesource.com/setup_7.x | bash - && \
  # Install H2o dependencies
  apt-get install -y \
  python3.6 \
  python3.6-dev \
  python3-pip \
  python3-dev \
  python-virtualenv \
  python3-virtualenv \
  nodejs \
  build-essential && \
  # Install Oracle Java 8
  apt-get install -y oracle-java8-installer && \
  apt-get clean && \
  rm -rf /var/cache/apt/* /var/cache/oracle-jdk8-installer


# Install LLVM for pydatatable
RUN \
  mkdir -p /opt && \
  cd /opt && \
  wget --quiet http://releases.llvm.org/4.0.0/clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz && \
  tar xf clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz && \
  rm -f clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz && \
  ln -s clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.04/ clang && \
  cp /opt/clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.04/lib/libomp.so /usr/lib

RUN \
  mkdir h2oai_env && \
  virtualenv --python=/usr/bin/python3.6 h2oai_env && \
  . h2oai_env/bin/activate && \
  pip install --upgrade pip && \
  pip install --upgrade setuptools && \
  pip install --upgrade python-dateutil && \
  pip install --upgrade numpy && \
  pip install --upgrade cython && \
  pip install --upgrade tensorflow-gpu && \
  pip install --upgrade psutil

ENV \
  LLVM4="/opt/clang" \
  CC="/opt/clang/bin/clang" \
  CLANG="/opt/clang/bin/clang" \
  LLVM_CONFIG="/opt/clang/llvm-config"

# Add requirements
COPY h2oai/requirements.txt requirements.txt
RUN \
  . h2oai_env/bin/activate && \
  pip install -r requirements.txt && \
  rm -f requirements.txt 

RUN \
  . h2oai_env/bin/activate && \
  pip install https://s3.amazonaws.com/tomk/alpha/xgboost-fromjon-4/xgboost-0.6-py3-none-any.whl

ENV H2O_MLI_VERSION 0.1.0-SNAPSHOT
ENV H2O_MLI_JAR mli-backend-0.1.0-20170728.203810-30-all.jar

RUN \
  wget --quiet http://172.17.0.53:8081/nexus/repository/snapshots/ai/h2o/mli/mli-backend/${H2O_MLI_VERSION}/${H2O_MLI_JAR} && \
  mv ${H2O_MLI_JAR} h2o.jar

# Add private deps
COPY h2oai/deps deps
RUN \
  . h2oai_env/bin/activate && \
  pip install -r deps/requirements.txt

COPY h2oai/dist dist
RUN \
  . h2oai_env/bin/activate && \
  pip install dist/*

# Add shell wrapper
COPY scripts/run.sh /run.sh
COPY h2oai/LICENSE /LICENSE

# Add bash scripts
COPY scripts/cuda.sh /etc/profile.d/cuda.sh
COPY scripts/start-notebook.sh /opt/start-notebook.sh

# Set executable on scripts
RUN \
  chown -R nimbix:nimbix /opt && \
  chmod +x /opt/start-notebook.sh && \
  chmod +x /run.sh

RUN \
  mkdir /log && \
  chown -R nimbix:nimbix /log && \
  cd /data

EXPOSE 54321
EXPOSE 8888
EXPOSE 12345

# User python install
USER nimbix

# Nimbix Integrations
COPY NAE/AppDef.json /etc/NAE/AppDef.json
COPY NAE/AppDef.png /etc//NAE/default.png
COPY NAE/screenshot.png /etc/NAE/screenshot.png
