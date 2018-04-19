FROM nvidia/cuda:9.0-cudnn7-runtime-centos7
MAINTAINER H2o.ai <ops@h2o.ai>

# base OS
ADD https://github.com/nimbix/image-common/archive/master.zip /tmp/nimbix.zip
WORKDIR /tmp
RUN yum -y install sudo zip unzip && unzip nimbix.zip && rm -f nimbix.zip
RUN /tmp/image-common-master/setup-nimbix.sh
RUN yum -y install module-init-tools xz vim openssh-server libmlx4 libmlx5 iptables infiniband-diags make gcc gcc-c++ glibc-devel curl libibverbs-devel libibverbs librdmacm librdmacm-devel librdmacm-utils libibmad-devel libibmad byacc flex git cmake screen grep && yum clean all

# Nimbix JARVICE emulation
RUN mkdir -p /usr/lib/JARVICE && cp -a /tmp/image-common-master/tools /usr/lib/JARVICE
RUN cp -a /tmp/image-common-master/etc /etc/JARVICE && chmod 755 /etc/JARVICE && rm -rf /tmp/image-common-master
RUN mkdir -m 0755 /data && chown nimbix:nimbix /data

RUN yum -y install yum-plugin-ovl && yum -y update && yum -y install java

RUN curl https://s3.amazonaws.com/artifacts.h2o.ai/releases/ai/h2o/dai/rel-1.1.0-5/x86_64-centos7/dai-1.1.0-1.x86_64.rpm --output dai-1.1.0-1.x86_64.rpm
RUN rpm -ivh dai-1.1.0-1.x86_64.rpm

RUN chown -R nimbix:nimbix /opt/h2oai

EXPOSE 22
EXPOSE 12345
EXPOSE 54321

COPY run-dai-nimbix.sh /run-dai-nimbix.sh

# Nimbix Integrations
COPY NAE/url.txt /etc/NAE/url.txt
COPY NAE/help.html /etc/NAE/help.html
COPY NAE/AppDef.json /etc/NAE/AppDef.json
COPY NAE/AppDef.png /etc//NAE/default.png
COPY NAE/screenshot.png /etc/NAE/screenshot.png
