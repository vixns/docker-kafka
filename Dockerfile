FROM vixns/java8
MAINTAINER Stéphane Cottin <stephane.cottin@vixns.com>

ENV SCALA_VERSION 2.10
ENV KAFKA_VERSION 0.8.2.1

RUN curl -s -o /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz http://mir2.ovh.net/ftp.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz
RUN tar xfz /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt && rm /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz

ADD kafka.sh /usr/local/bin/kafka.sh

ENV KAFKA_HOME /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}

# Expose ports.
EXPOSE 9092

ENTRYPOINT ["/usr/local/bin/kafka.sh"]