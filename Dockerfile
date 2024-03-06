#docker build . -t quay.io/semoss/docker-tomcat:ubi8-rhel

ARG BASE_REGISTRY=quay.io
ARG BASE_IMAGE=semoss/docker-r-python
ARG BASE_TAG=ubi8-rhel-squashed

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} as builder

LABEL maintainer="semoss@semoss.org"

ENV JAVA_HOME=/usr/lib/jvm/zulu8
ENV TOMCAT_HOME=/opt/apache-tomcat-9.0.85
ENV MAVEN_HOME=/opt/apache-maven-3.8.5
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/python3.9/dist-packages/jep
ENV PATH=$PATH:${MAVEN_HOME}/bin:${TOMCAT_HOME}/bin:${JAVA_HOME}/bin

RUN printenv | grep -E '^(JAVA_HOME|TOMCAT_HOME|MAVEN_HOME|LD_LIBRARY_PATH|PATH)=' | awk '{print "export " $0}' >> /opt/set_env.env

RUN yum -y update --exclude=poppler* \
	&& yum -y install curl ca-certificates dirmngr gnupg procps openblas nano \
	&& mkdir -p $JAVA_HOME

COPY . /root/

RUN cd ~/ \
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
	&& echo 'CATALINA_PID="$CATALINA_BASE/bin/catalina.pid"' > $TOMCAT_HOME/bin/setenv.sh \
	&& wget https://archive.apache.org/dist/maven/maven-3/3.8.5/binaries/apache-maven-3.8.5-bin.tar.gz\
	&& tar -zxvf apache-maven-*.tar.gz \
	&& mkdir /opt/apache-maven-3.8.5 \
	&& mv apache-maven-3.8.5/* /opt/apache-maven-3.8.5/ \
	&& rm -r apache-maven-3.8.5 \
	&& rm apache-maven-3.8.5-bin.tar.gz \
	&& echo '#!/bin/sh' > $TOMCAT_HOME/bin/start.sh \
	&& echo 'catalina.sh start' >> $TOMCAT_HOME/bin/start.sh \
	&& echo "tail -f $TOMCAT_HOME/logs/catalina.out" >> $TOMCAT_HOME/bin/start.sh \
	&& echo '#!/bin/sh' > $TOMCAT_HOME/bin/stop.sh \
	&& echo 'shutdown.sh -force' >> $TOMCAT_HOME/bin/stop.sh \
	&& chmod 777 $TOMCAT_HOME/bin/*.sh \
	&& chmod 777 /opt/apache-maven-3.8.5/bin/*.cmd \
	&& pip3 install jep==3.9.1 \
	&& R CMD javareconf

RUN R -e "install.packages(c('rJava', 'RJDBC'), dependencies=TRUE)" && \
	wget https://www.rforge.net/Rserve/snapshot/Rserve_1.8-11.tar.gz \
	&& R CMD INSTALL Rserve_1.8-11.tar.gz && \
	rm Rserve_1.8-11.tar.gz

FROM scratch AS final

ENV JAVA_HOME=/usr/lib/jvm/zulu8
ENV TOMCAT_HOME=/opt/apache-tomcat-9.0.85
ENV MAVEN_HOME=/opt/apache-maven-3.8.5
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/python3.9/dist-packages/jep
ENV PATH=$PATH:${MAVEN_HOME}/bin:${TOMCAT_HOME}/bin:${JAVA_HOME}/bin

COPY --from=builder / /
WORKDIR $TOMCAT_HOME/webapps

CMD ["start.sh"]