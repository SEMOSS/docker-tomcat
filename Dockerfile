# Based on quay.io/semoss/docker-r-python/docker-tomcat:cuda12.5
#docker build . -t quay.io/semoss/docker-tomcat:cuda12.5

ARG BASE_REGISTRY=quay.io
ARG BASE_IMAGE=semoss/docker-r-python
ARG BASE_TAG=cuda12.5

# JAVA, JDK and TOMCAT default versions
ARG AZUL_ZULU_VERSION=21.42.19
ARG JAVA_HOME=/usr/lib/jvm/zulu21
ARG JDK_VERSION=21.0.7
ARG TOMCAT_VERSION=9.0.107
ARG MAVEN_HOME=/opt/apache-maven-3.8.5

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} AS builder

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

ENV TOMCAT_VERSION=${TOMCAT_VERSION}
ENV TOMCAT_HOME=${TOMCAT_HOME}
ENV JAVA_HOME=${JAVA_HOME}
ENV PATH=$PATH:$MAVEN_HOME/bin:$TOMCAT_HOME/bin:$JAVA_HOME/bin
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH

RUN printenv | grep -E '^(JAVA_HOME|TOMCAT_HOME|MAVEN_HOME|LD_LIBRARY_PATH|PATH)=' | awk '{print "export " $0}' >> /opt/set_env.env

COPY . /root/
RUN apt-get update \
	&& apt-get -y install apt-transport-https git ca-certificates dirmngr gnupg software-properties-common \
	&& apt-get update \
	&& cd ~/ \
	&& apt-get -y install wget procps libopenblas-base\
	&& mkdir -p $JAVA_HOME \
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

FROM scratch AS final

ARG TOMCAT_HOME
ARG JAVA_HOME
ARG MAVEN_HOME
#ARG LD_LIBRARY_PATH

ENV TOMCAT_HOME=$TOMCAT_HOME
ENV JAVA_HOME=$JAVA_HOME
ENV PATH=$PATH:$MAVEN_HOME/bin:$TOMCAT_HOME/bin:$JAVA_HOME/bin
#ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH

COPY --from=builder / /
WORKDIR $TOMCAT_HOME/webapps

CMD ["start.sh"]