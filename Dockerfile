FROM debian:9.6

LABEL maintainer="semoss@semoss.org"

ENV TOMCAT_HOME=/opt/apache-tomcat-8.0.41
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
	&& wget https://archive.apache.org/dist/tomcat/tomcat-8/v8.0.41/bin/apache-tomcat-8.0.41.tar.gz \
	&& tar -zxvf apache-tomcat-*.tar.gz \
	&& mkdir /opt/apache-tomcat-8.0.41 \
	&& mv apache-tomcat-8.0.41/* /opt/apache-tomcat-8.0.41/ \
	&& rm -r apache-tomcat-8.0.41 \
	&& rm apache-tomcat-8.0.41.tar.gz \
	&& echo 'CATALINA_PID="$CATALINA_BASE/bin/catalina.pid"' > /opt/apache-tomcat-8.0.41/bin/setenv.sh \
	&& wget https://apache.claz.org/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz \
	&& tar -zxvf apache-maven-*.tar.gz \
	&& mkdir /opt/apache-maven-3.5.4 \
	&& mv apache-maven-3.5.4/* /opt/apache-maven-3.5.4/ \
	&& rm -r apache-maven-3.5.4 \
	&& rm apache-maven-3.5.4-bin.tar.gz \
	&& apt-get -y install git \
	&& git config --global http.sslverify false \
	&& apt-get -y install nano \
	&& echo '#!/bin/sh' > /opt/apache-tomcat-8.0.41/bin/start.sh \
	&& echo 'catalina.sh start' >> /opt/apache-tomcat-8.0.41/bin/start.sh \
	&& echo 'tail -f /opt/apache-tomcat-8.0.41/logs/catalina.out' >> /opt/apache-tomcat-8.0.41/bin/start.sh \
	&& echo '#!/bin/sh' > /opt/apache-tomcat-8.0.41/bin/stop.sh \
	&& echo 'shutdown.sh -force' >> /opt/apache-tomcat-8.0.41/bin/stop.sh \
	&& chmod 777 /opt/apache-tomcat-8.0.41/bin/*.sh \
	&& chmod 777 /opt/apache-maven-3.5.4/bin/*.cmd \
	&& apt-get clean all

WORKDIR /opt/apache-tomcat-8.0.41/webapps

CMD ["start.sh"]
