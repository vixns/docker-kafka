#!/bin/bash

if [ -z "$KAFKA_ZOOKEEPER_CONNECT" ]
then
  # ask consul
  export KAFKA_ZOOKEEPER_CONNECT=$(curl -s -XGET http://consul.service.consul:8500/v1/health/service/zookeeper\?passing | jq -r '[.[] | "\(.Service .Address):\(.Service .Port)" ] | join(",")')
fi

if [ -z "$KAFKA_ADVERTISED_HOST_NAME" ]
then
  export KAFKA_ADVERTISED_HOST_NAME=$(/bin/ip -4 a show dev eth0 scope global | grep inet | awk '{split($2,a,"/"); print a[1]}')
fi

if [ -z "$KAFKA_BROKER_ID"]
then
  if [ "$KAFKA_BROKER_ID_AS_HOST" = "true" ]
  	then
      export KAFKA_BROKER_ID=$(dig +short a ${HOST} | tr -d '.')
  else
      export KAFKA_BROKER_ID=$(echo ${KAFKA_ADVERTISED_HOST_NAME} | tr -d '.')
  fi
fi

cat $KAFKA_HOME/config/server.properties > $KAFKA_HOME/config/server-dyn.properties

for VAR in `env`
do
	if [[ $VAR =~ ^KAFKA_ && ! $VAR =~ ^KAFKA_HOME ]]; then
		kafka_name=`echo "$VAR" | sed -r "s/KAFKA_(.*)=.*/\1/g" | tr '[:upper:]' '[:lower:]' | tr _ .`
		env_var=`echo "$VAR" | sed -r "s/(.*)=.*/\1/g"`
		if egrep -q "(^|^#)$kafka_name" $KAFKA_HOME/config/server-dyn.properties; then
			sed -r -i "s@(^|^#)($kafka_name)=(.*)@\2=${!env_var}@g" $KAFKA_HOME/config/server-dyn.properties #note that no config values may contain an '@' char
		else
			echo "$kafka_name=${!env_var}" >> $KAFKA_HOME/config/server-dyn.properties
		fi
	fi
done

export KAFKA_LOG4J_OPTS="-Dlog4j.configuration=file:$KAFKA_HOME/config/log4j.properties"
export KAFKA_HEAP_OPTS="-Xmx1G -Xms1G"

exec $KAFKA_HOME/bin/kafka-run-class.sh -name kafkaServer -loggc kafka.Kafka $KAFKA_HOME/config/server-dyn.properties