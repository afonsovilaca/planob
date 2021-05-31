#!/bin/bash
yum -y install wget
wget https://www.dropbox.com/s/9q2cbio0lqq120u/OGG_BigData_Linux_x64_19.1.0.0.1.tar.gz?dl=0 -O /tmp/OGG_BigData_Linux_x64_19.1.0.0.1.tar.gz

# Load variables
GG_VERSION="OGG_BigData_Linux_x64_19.1.0.0.1.tar.gz"
BASE_DIRECTORY="/u01"
GGBD_DIRECTORY="GGBD19"
GG_DB="ORCL"

# Create folders to install GG BD
mkdir -p $BASE_DIRECTORY/$GGBD_DIRECTORY/$GG_DB/ggs
chmod -R 775 $BASE_DIRECTORY/$GGBD_DIRECTORY/$GG_DB
chown -R centos $BASE_DIRECTORY/$GGBD_DIRECTORY

# Load variables
GG_VERSION="OGG_BigData_Linux_x64_19.1.0.0.1.tar.gz"
BASE_DIRECTORY="/u01"
GGBD_DIRECTORY="GGBD19"
GG_DB="ORCL"

# Install GoldenGate BigData
cp /tmp/$GG_VERSION $BASE_DIRECTORY/$GGBD_DIRECTORY/$GG_DB/ggs
cd $BASE_DIRECTORY/$GGBD_DIRECTORY/$GG_DB/ggs
tar -xvzf $BASE_DIRECTORY/$GGBD_DIRECTORY/$GG_DB/ggs/$GG_VERSION
rm -f $BASE_DIRECTORY/$GGBD_DIRECTORY/$GG_DB/ggs/$GG_VERSION

# Create GoldenGate directories
# ver diretoria JAVA_HOME: update-alternatives --config java
echo "export JAVA_HOME=/usr/lib/jvm/jre" >> ~/.bash_profile
echo "export LD_LIBRARY_PATH=\$JAVA_HOME/lib/amd64/server" >> ~/.bash_profile
. ~/.bash_profile

$BASE_DIRECTORY/$GGBD_DIRECTORY/$GG_DB/ggs/ggsci << EOF
create subdirs
EOF

# Create GLOBALS file
echo "ALLOWOUTPUTDIR ./dirdat" >> $BASE_DIRECTORY/$GGBD_DIRECTORY/$GG_DB/ggs/GLOBALS

# Configure Manager. You can see that GG Target will be running on 7860 port;
cat > $BASE_DIRECTORY/$GGBD_DIRECTORY/$GG_DB/ggs/dirprm/mgr.prm << EOF
PORT 7860
AUTOSTART REPLICAT *
EOF

#GoldenGate Producer Configuration
#Create Kafka properties files. Replace DNS Brokers tags for Kafka DNS.
mkdir -p $BASE_DIRECTORY/$GGBD_DIRECTORY/$GG_DB/ggs/dirprm/kafkaprops

cat > $BASE_DIRECTORY/$GGBD_DIRECTORY/$GG_DB/ggs/dirprm/kafkaprops/cloudera_kafka.properties <<EOF
bootstrap.servers= 172.31.0.40:9092, 172.31.0.70:9092, 172.31.0.100:9092
acks=1
compression.type=gzip
reconnect.backoff.ms=1000
value.serializer=org.apache.kafka.common.serialization.ByteArraySerializer
key.serializer=org.apache.kafka.common.serialization.ByteArraySerializer
batch.size=1
linger.ms=10000
value.converter=org.apache.kafka.connect.json.JsonConverter
key.converter=org.apache.kafka.connect.json.JsonConverter
internal.value.converter=org.apache.kafka.connect.json.JsonConverter
internal.key.converter=org.apache.kafka.connect.json.JsonConverter
EOF

cat > $BASE_DIRECTORY/$GGBD_DIRECTORY/$GG_DB/ggs/dirprm/kafkaprops/kafka_topics.props <<EOF
gg.handlerlist = kafkahandler
gg.handler.kafkahandler.type=kafka
gg.handler.kafkahandler.KafkaProducerConfigFile=kafkaprops/cloudera_kafka.properties
gg.handler.kafkahandler.topicMappingTemplate=$${tableName}
gg.handler.kafkahandler.keyMappingTemplate=$${primaryKeys}
gg.handler.kafkahandler.format=json
gg.handler.kafkahandler.BlockingSend =false
gg.handler.kafkahandler.includeTokens=false
gg.handler.kafkahandler.mode=op
goldengate.userexit.writers=javawriter
javawriter.stats.display=TRUE
javawriter.stats.full=TRUE
gg.log=log4j
gg.log.level=INFO
gg.report.time=30sec
gg.classpath=dirprm/:/usr/share/java/kafka/*:
javawriter.bootoptions=-Xmx512m -Xms32m -Djava.class.path=ggjava/ggjava.jar
EOF

# GoldenGate Replicat Configuration
cat > $BASE_DIRECTORY/$GGBD_DIRECTORY/$GG_DB/ggs/dirprm/RPGEMP.prm <<EOF
REPLICAT RPGEMP
TARGETDB LIBFILE libggjava.so SET property=dirprm/kafkaprops/kafka_topics.props
REPORTCOUNT EVERY 1 MINUTES, RATE
--TABLES
MAP EMP.EMPLOYEES, TARGET EMP.EMPLOYEES, KEYCOLS( EMP_NO );
MAP EMP.DEPARTMENTS, TARGET EMP.DEPARTMENTS, KEYCOLS( DEPT_NO );
MAP EMP.DEPT_EMP, TARGET EMP.DEPT_EMP, KEYCOLS( EMP_NO, DEPT_NO );
MAP EMP.DEPT_MANAGER, TARGET EMP.DEPT_MANAGER, KEYCOLS( EMP_NO, DEPT_NO );
MAP EMP.SALARIES, TARGET EMP.SALARIES, KEYCOLS( EMP_NO, FROM_DATE );
MAP EMP.TITLES, TARGET EMP.TITLES, KEYCOLS( EMP_NO, TITLE, FROM_DATE );
EOF

# Zookeeper config
export ZK=172.31.0.40:2181,172.31.0.70:2181,172.31.0.100:2181
kafka-topics --create --zookeeper $ZK --replication-factor 3 \
--partitions 10 --topic EMPLOYEES
kafka-topics --create --zookeeper $ZK --replication-factor 3 \
--partitions 10 --topic DEPARTMENTS
kafka-topics --create --zookeeper $ZK --replication-factor 3 \
--partitions 10 --topic DEPT_EMP
kafka-topics --create --zookeeper $ZK --replication-factor 3 \
--partitions 10 --topic DEPT_MANAGER
kafka-topics --create --zookeeper $ZK --replication-factor 3 \
--partitions 10 --topic SALARIES
kafka-topics --create --zookeeper $ZK --replication-factor 3 \
--partitions 10 --topic TITLES