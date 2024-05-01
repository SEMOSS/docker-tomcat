#docker build . -t quay.io/semoss/docker-tomcat:debian11-1

ARG BASE_REGISTRY=quay.io
ARG BASE_IMAGE=semoss/docker-r-python
ARG BASE_TAG=debian11

ARG TOMCAT_HOME=/opt/apache-tomcat-9.0.88
ARG JAVA_HOME=/usr/lib/jvm/zulu8
ARG MAVEN_HOME=/opt/apache-maven-3.8.5
ARG LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/python3.9/dist-packages/jep

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} as builder

ARG JAVA_HOME
ARG TOMCAT_HOME
ARG MAVEN_HOME
ARG LD_LIBRARY_PATH
LABEL maintainer="semoss@semoss.org"

ENV TOMCAT_HOME=$TOMCAT_HOME
ENV JAVA_HOME=$JAVA_HOME
ENV PATH=$PATH:$MAVEN_HOME/bin:$TOMCAT_HOME/bin:$JAVA_HOME/bin
# Needed for JEP
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH

RUN printenv | grep -E '^(JAVA_HOME|TOMCAT_HOME|MAVEN_HOME|LD_LIBRARY_PATH|PATH)=' | awk '{print "export " $0}' >> /opt/set_env.env

COPY . /root/
RUN echo "print JAVA_HOME ${JAVA_HOME}"
RUN apt-get update \
	&& apt-get -y install apt-transport-https ca-certificates git wget dirmngr gnupg software-properties-common \
	&& apt-get update \
	&& cd ~/ \
	&& apt-get -y install wget procps libopenblas-base\
	&& echo "Creating directory for ${JAVA_HOME}.." \
	&& mkdir -p $JAVA_HOME \
	&& chmod +x install_java.sh \
	&& /bin/bash install_java.sh \
	&& java -version \
	&& wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.88/bin/apache-tomcat-9.0.88.tar.gz \
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

FROM scratch AS final

ARG JAVA_HOME
ARG TOMCAT_HOME
ARG MAVEN_HOME
ARG LD_LIBRARY_PATH
LABEL maintainer="semoss@semoss.org"

ENV TOMCAT_HOME=$TOMCAT_HOME
ENV JAVA_HOME=$JAVA_HOME
ENV PATH=$PATH:$MAVEN_HOME/bin:$TOMCAT_HOME/bin:$JAVA_HOME/bin
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH
COPY --from=builder / /
WORKDIR $TOMCAT_HOME/webapps

CMD ["start.sh"]
