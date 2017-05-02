FROM nvidia/cuda:8.0-cudnn5-devel-ubuntu16.04
MAINTAINER H2o.ai <ops@h2o.ai>

# Nimbix base OS
ENV DEBIAN_FRONTEND noninteractive
ADD https://github.com/nimbix/image-common/archive/master.zip /tmp/nimbix.zip
WORKDIR /tmp
RUN apt-get update && apt-get -y install sudo zip unzip && unzip nimbix.zip && rm -f nimbix.zip
RUN /tmp/image-common-master/setup-nimbix.sh
RUN touch /etc/init.d/systemd-logind
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
  software-properties-common \
  nginx \
  grep

# Clean and generate locales
RUN apt-get clean && \
  locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8

# Add Repos
RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" | sudo tee -a /etc/apt/sources.list && \
  gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 && \
  gpg -a --export E084DAB9 | apt-key add -&& \
  add-apt-repository ppa:fkrull/deadsnakes  && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update -yqq && \
  echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections

# Install H2o dependancies
RUN apt-get install -y \
  python3-pip \
  python3.6 \
  python3.6-dev \
  dirmngr

# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
  apt-get install -y nodejs

# Get R
RUN apt-get install -y r-base r-base-dev && \
  wget https://cran.cnr.berkeley.edu/src/contrib/data.table_1.10.4.tar.gz && \
  wget https://cran.cnr.berkeley.edu/src/contrib/lazyeval_0.2.0.tar.gz && \
  wget https://cran.cnr.berkeley.edu/src/contrib/Rcpp_0.12.10.tar.gz && \
  wget https://cran.cnr.berkeley.edu/src/contrib/tibble_1.3.0.tar.gz && \
  wget https://cran.cnr.berkeley.edu/src/contrib/hms_0.3.tar.gz && \
  wget https://cran.cnr.berkeley.edu/src/contrib/feather_0.3.1.tar.gz && \
  R CMD INSTALL data.table_1.10.4.tar.gz lazyeval_0.2.0.tar.gz Rcpp_0.12.10.tar.gz tibble_1.3.0.tar.gz hms_0.3.tar.gz feather_0.3.1.tar.gz

# Install Oracle Java 8
RUN apt-get install -y oracle-java8-installer && \
  apt-get clean && \
  rm -rf /var/cache/apt/*

# Install Python Dependancies
RUN mkdir /opt/h2oai
WORKDIR /opt/h2oai
ADD requirements.txt /opt/h2oai/requirements.txt
RUN \
  python3.6 -m pip install --upgrade pip && \
  python3.6 -m pip install setuptools && \
  python3.6 -m pip install python-dateutil && \
  python3.6 -m pip install numpy && \
  python3.6 -m pip install cython && \
  python3.6 -m pip install jupyter && \
  python3.6 -m pip install tensorflow-gpu && \
  python3.6 -m pip install -r /opt/h2oai/requirements.txt && \
  python3.6 -m pip install pycuda

WORKDIR /opt

# Add h2o3-xgboost
ADD h2o-3.11.0.99999 /opt/h2o-3
ADD h2o /opt/h2oai/h2o
ADD h2oaiglm /opt/h2oaiglm
COPY scripts/start-h2o.sh /opt/start-h2o.sh
COPY scripts/start-jupyter.sh /opt/start-jupyter.sh
COPY scripts/run-benchmark.sh /opt/run-benchmark.sh
COPY scripts/start-h2oai.sh /opt/start-h2oai.sh


RUN \
  chown -R nimbix:nimbix /opt && \
  chmod +x /opt/start-h2o.sh && \
  chmod +x /opt/start-jupyter.sh && \
  chmod +x /opt/start-h2oai.sh && \
  chmod +x /opt/run-benchmark.sh

RUN \
  python3.6 -m pip install /opt/h2o-3/python/h2o-*-py2.py3-none-any.whl

# configure Jupyter with default password h2oai

EXPOSE 54321
EXPOSE 12345
EXPOSE 443
EXPOSE 8888

# Configure Nginx
COPY configs/default /etc/nginx/sites-enabled/default
COPY configs/notebook-site /etc/nginx/sites-enabled/notebook-site
COPY configs/httpredirect.conf /etc/nginx/conf.d/httpredirect.conf

# Nimbix Integrations
ADD ./NAE/AppDef.json /etc/NAE/AppDef.json
ADD ./NAE/AppDef.png /etc//NAE/default.png
ADD ./NAE/screenshot.png /etc/NAE/screenshot.png
RUN echo "https://%PUBLICAADR%//" > /etc/NAE/url.txt

# Nimbix JARVICE emulation
EXPOSE 22
RUN mkdir -p /usr/lib/JARVICE && cp -a /tmp/image-common-master/tools /usr/lib/JARVICE
RUN cp -a /tmp/image-common-master/etc /etc/JARVICE && chmod 755 /etc/JARVICE && rm -rf /tmp/image-common-master
RUN mkdir -m 0755 /data && chown nimbix:nimbix /data
RUN sed -ie 's/start on.*/start on filesystem/' /etc/init/ssh.conf

# Set user ENV
USER nimbix
ENV CUDA_HOME=/usr/local/cuda-8.0
ENV PATH=$CUDA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# configure Jupyter with default password h2oai
RUN jupyter notebook --generate-config
COPY configs/jupyter_notebook_config.json /home/nimbix/.jupyter/jupyter_notebook_config.json
