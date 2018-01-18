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
    add-apt-repository ppa:deadsnakes/ppa  && \
    apt-get update -yqq && \
  curl -sL https://deb.nodesource.com/setup_7.x | bash - && \
  apt-get install -y \
    python3.6 \
    python3.6-dev \
    python3-pip \
    python3-dev \
    python-virtualenv \
    python3-virtualenv \
    nodejs \
    libopenblas-dev \
    build-essential

# Install Java 8
ENV JAVA_HOME="/opt/java"

RUN \
  wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie"  http://download.oracle.com/otn-pub/java/jdk/8u162-b12/0da788060d494f5095bf8624735fa2f1/server-jre-8u162-linux-x64.tar.gz && \
  tar -zxvf server-jre* && \
  mv jdk1.8.0_162 /opt/java && \
  rm server-jre* && \ 
  update-alternatives --install /usr/bin/java java ${JAVA_HOME%*/}/bin/java 100 && \
  update-alternatives --install /usr/bin/javac javac ${JAVA_HOME%*/}/bin/java 100   

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
COPY h2oai/config.toml config.toml

ENV H2O_MLI_VERSION=0.1.33
ENV H2O_MLI_JAR=mli-backend-0.1.33-all.jar
ENV PROCSY_VERSION=0.2.0
ENV VIS_SERVER_VERSION=1.4.0

RUN \
  wget --quiet http://172.17.0.53:8081/nexus/repository/releases/ai/h2o/mli/mli-backend/0.1.33/mli-backend-0.1.33-all.jar && \
  mv mli-backend-0.1.33-all.jar h2o.jar && \
  wget http://172.17.0.53:8081/nexus/repository/releases/ai/h2o/vis-data-server-integrated/1.4.0/vis-data-server-integrated-1.4.0-all.jar && \
  mv vis-data-server-integrated-1.4.0-all.jar vis-data-server.jar

# Add private deps
COPY h2oai/deps deps/
COPY h2oai/dist/*.whl dist/

RUN \
  . h2oai_env/bin/activate && \
  pip install --no-cache-dir -r deps/requirements.txt && \
  pip install dist/*.whl && \
  cp deps/procsy .

# Add shell wrapper
COPY scripts/run.sh /run.sh

# Make a default directory where license files can be stored inside the container.
RUN \
  mkdir /license && \
  chmod -R o+w /license

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
  mkdir /h2oai_scorer && \
  chown -R nimbix:nimbix /h2oai_scorer && \
  cd /data

ADD h2oai/h2oai_scorer/ /h2oai_scorer/

EXPOSE 54321
EXPOSE 8888
EXPOSE 12345

# User python install
USER nimbix

# Nimbix Integrations
COPY NAE/AppDef.json /etc/NAE/AppDef.json
COPY NAE/AppDef.png /etc//NAE/default.png
COPY NAE/screenshot.png /etc/NAE/screenshot.png
