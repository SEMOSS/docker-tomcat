#docker build . -t quay.io/semoss/docker-tomcat:debian11

ARG BASE_REGISTRY=quay.io
ARG BASE_IMAGE=semoss/docker-r-python
ARG BASE_TAG=debian11

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} as base

LABEL maintainer="semoss@semoss.org"

ENV TOMCAT_HOME=/opt/apache-tomcat-9.0.85
ENV JAVA_HOME=/usr/lib/jvm/zulu8
ENV PATH=$PATH:/opt/apache-maven-3.8.5/bin:$TOMCAT_HOME/bin:$JAVA_HOME/bin
# Needed for JEP
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/python3.9/dist-packages/jep
# Install the following:
# Java - zulu https://cdn.azul.com/zulu/bin/zulu8.56.0.21-ca-fx-jdk8.0.302-linux_x64.tar.gz 
# Tomcat
# Wget
# Maven
# Git
# Nano
RUN apt-get update \
	&& apt-get -y install apt-transport-https ca-certificates git wget dirmngr gnupg software-properties-common \
	&& apt-get update \
	&& cd ~/ \
	&& apt-get -y install wget procps libopenblas-base\
	&& mkdir -p $JAVA_HOME \
	&& git config --global http.sslverify false \
	&& git clone https://github.com/SEMOSS/docker-tomcat \
	&& cd docker-tomcat \
	&& git checkout debian11 \
	&& chmod +x install_java.sh \
	&& /bin/bash install_java.sh \
	&& java -version \
	&& wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.85/bin/apache-tomcat-9.0.85.tar.gz \
	&& tar -zxvf apache-tomcat-9.0.*.tar.gz \
	&& mkdir $TOMCAT_HOME \
	&& mv apache-tomcat-9.0.*/* $TOMCAT_HOME/ \
	&& rm -r apache-tomcat-9.0.*/ \
	&& rm apache-tomcat-9.0.*.tar.gz \
	&& rm $TOMCAT_HOME/conf/server.xml \
	&& rm $TOMCAT_HOME/conf/web.xml \
	&& cp web.xml $TOMCAT_HOME/conf/web.xml \
	&& cp server.xml $TOMCAT_HOME/conf/server.xml \
	&& chmod +x config.sh \
	&& /bin/bash config.sh \
	&& cd .. \
	&& rm -r docker-tomcat \
	&& echo 'CATALINA_PID="$CATALINA_BASE/bin/catalina.pid"' > $TOMCAT_HOME/bin/setenv.sh \
	&& wget https://archive.apache.org/dist/maven/maven-3/3.8.5/binaries/apache-maven-3.8.5-bin.tar.gz\
	&& tar -zxvf apache-maven-*.tar.gz \
	&& mkdir /opt/apache-maven-3.8.5 \
	&& mv apache-maven-3.8.5/* /opt/apache-maven-3.8.5/ \
	&& rm -r apache-maven-3.8.5 \
	&& rm apache-maven-3.8.5-bin.tar.gz \
	&& apt-get -y install nano \
	&& echo '#!/bin/sh' > $TOMCAT_HOME/bin/start.sh \
	&& echo 'catalina.sh start' >> $TOMCAT_HOME/bin/start.sh \
	&& echo "tail -f $TOMCAT_HOME/logs/catalina.out" >> $TOMCAT_HOME/bin/start.sh \
	&& echo '#!/bin/sh' > $TOMCAT_HOME/bin/stop.sh \
	&& echo 'shutdown.sh -force' >> $TOMCAT_HOME/bin/stop.sh \
	&& chmod 777 $TOMCAT_HOME/bin/*.sh \
	&& chmod 777 /opt/apache-maven-3.8.5/bin/*.cmd \
	&& pip3 install jep==3.9.1 \
	&& R CMD javareconf \
	&& apt-get clean all

RUN R -e "install.packages(c('rJava', 'RJDBC'), dependencies=TRUE)" && \
	wget https://www.rforge.net/Rserve/snapshot/Rserve_1.8-11.tar.gz \
	&& R CMD INSTALL Rserve_1.8-11.tar.gz && \
	rm Rserve_1.8-11.tar.gz
WORKDIR $TOMCAT_HOME/webapps

CMD ["start.sh"]
