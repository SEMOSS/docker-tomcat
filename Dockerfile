FROM debian:9.6

LABEL maintainer="semoss@semoss.org"

ENV TOMCAT_HOME=/opt/apache-tomcat-9.0.26
ENV PATH=$PATH:/opt/apache-maven-3.5.4/bin:$TOMCAT_HOME/bin

# Install the following:
# Java
# Tomcat
# Wget
# Maven
# Git
# Nano
RUN apt-get update \
	&& cd ~/ \
	&& apt-get -y install openjdk-8-jdk \
	&& java -version \
	&& apt-get -y install wget \
	&& apt-get -y install procps \
	&& apt-get -y install libopenblas-base \
	&& wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.26/bin/apache-tomcat-9.0.26.tar.gz \
	&& tar -zxvf apache-tomcat-*.tar.gz \
	&& mkdir $TOMCAT_HOME \
	&& mv apache-tomcat-9.0.26/* $TOMCAT_HOME/ \
	&& rm -r apache-tomcat-9.0.26 \
	&& rm apache-tomcat-9.0.26.tar.gz \
	&& rm $TOMCAT_HOME/conf/server.xml \
	&& rm $TOMCAT_HOME/conf/web.xml \
	&& apt-get -y install git \
	&& git config --global http.sslverify false \
	&& git clone https://github.com/SEMOSS/docker-tomcat \
	&& cp docker-tomcat/web.xml $TOMCAT_HOME/conf/web.xml \
	&& cp docker-tomcat/server.xml $TOMCAT_HOME/conf/server.xml \
	&& rm -r docker-tomcat \
	&& echo 'CATALINA_PID="$CATALINA_BASE/bin/catalina.pid"' > $TOMCAT_HOME/bin/setenv.sh \
	&& wget https://archive.apache.org/dist/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz \
	&& tar -zxvf apache-maven-*.tar.gz \
	&& mkdir /opt/apache-maven-3.5.4 \
	&& mv apache-maven-3.5.4/* /opt/apache-maven-3.5.4/ \
	&& rm -r apache-maven-3.5.4 \
	&& rm apache-maven-3.5.4-bin.tar.gz \
	&& apt-get -y install nano \
	&& echo '#!/bin/sh' > $TOMCAT_HOME/bin/start.sh \
	&& echo 'catalina.sh start' >> $TOMCAT_HOME/bin/start.sh \
	&& echo 'tail -f /opt/apache-tomcat-9.0.26/logs/catalina.out' >> $TOMCAT_HOME/bin/start.sh \
	&& echo '#!/bin/sh' > $TOMCAT_HOME/bin/stop.sh \
	&& echo 'shutdown.sh -force' >> $TOMCAT_HOME/bin/stop.sh \
	&& chmod 777 $TOMCAT_HOME/bin/*.sh \
	&& chmod 777 /opt/apache-maven-3.5.4/bin/*.cmd \
	&& apt-get clean all

WORKDIR $TOMCAT_HOME/webapps

CMD ["start.sh"]
