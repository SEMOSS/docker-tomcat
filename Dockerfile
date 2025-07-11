# Based on nvidia/cuda:12.2.2-devel-ubuntu22.04
#docker build . -t quay.io/semoss/docker-tomcat:cuda12

ARG BASE_REGISTRY=docker.io
ARG BASE_IMAGE=nvidia/cuda	
ARG BASE_TAG=12.2.2-devel-ubuntu22.04

# JAVA, JDK and TOMCAT default versions
ARG AZUL_ZULU_VERSION=21.42.19
ARG JAVA_HOME=/usr/lib/jvm/zulu21
ARG JDK_VERSION=21.0.7
ARG TOMCAT_VERSION=9.0.107
ARG MAVEN_HOME=/opt/apache-maven-3.8.5

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} AS base

LABEL maintainer="semoss@semoss.org"

# Tomcat and Maven 
ARG TOMCAT_VERSION
ARG MAVEN_HOME
ARG TOMCAT_HOME=/opt/apache-tomcat-${TOMCAT_VERSION}

# JAVA arguments
ARG AZUL_ZULU_VERSION
ARG JAVA_HOME
ARG JDK_VERSION

#JAVA env values for install_java.sh
ENV AZUL_ZULU_VERSION=${AZUL_ZULU_VERSION}
ENV JDK_VERSION=${JDK_VERSION}
ENV PATH=$PATH:/opt/apache-maven-3.8.5/bin:$TOMCAT_HOME/bin:$JAVA_HOME/bin

# Copying install_java.sh file from the same cloned repo instead having to reclone the repository
COPY . /root/

# Install the following:
# Java - zulu https://cdn.azul.com/zulu/bin/zulu8.56.0.21-ca-fx-jdk8.0.302-linux_x64.tar.gz 
# Tomcat
# Wget
# Maven
# Git
# Nano
RUN apt-get update \
	&& apt-get -y install apt-transport-https ca-certificates wget dirmngr gnupg software-properties-common \
	&& apt-get update \
	&& cd ~/ \
	&& apt-get -y install wget procps git libopenblas-base\
	&& mkdir -p $JAVA_HOME \
	&& git config --global http.sslverify false \
	&& chmod +x install_java.sh \
	&& /bin/bash install_java.sh \
	&& java -version \
	&& wget https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz \
	&& tar -zxvf apache-tomcat-9.*.tar.gz \
	&& mkdir $TOMCAT_HOME \
	&& mv apache-tomcat-9.*/* $TOMCAT_HOME/ \
	&& rm -r apache-tomcat-9.*/ \
	&& rm apache-tomcat-9.*.tar.gz \
  	%% rm -rf $TOMCAT_HOME/webapps/* \
	&& rm $TOMCAT_HOME/conf/server.xml \
	&& rm $TOMCAT_HOME/conf/web.xml \
	&& cp web.xml $TOMCAT_HOME/conf/web.xml \
	&& cp server.xml $TOMCAT_HOME/conf/server.xml \
	&& cd .. \
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
	&& apt-get clean all

WORKDIR $TOMCAT_HOME/webapps

CMD ["start.sh"]
