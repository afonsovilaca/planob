#!/bin/bash
sudo bash -c 'cat << EOF > /var/lib/zookeeper/myid
3
EOF'

sudo sed -i 's/localhost:2181/172.31.0.49:2181,172.31.0.87:2181,172.31.0.107:2181/g' /etc/kafka/server.properties
sudo sed -i 's/broker.id=0/broker.id.generation.enable=true/g' /etc/kafka/server.properties
sudo sed -i 's/num.partions=1/num.partions=10/g' /etc/kafka/server.properties
sudo sed -i 's/offsets.topic.replication.factor=1/offsets.topic.replication.factor=3/g' /etc/kafka/server.properties
sudo systemctl start confluent-zookeeper
sudo systemctl start confluent-kafka
sudo systemctl start confluent-schema-registry
sudo systemctl start confluent-kafka-connect
sudo systemctl start confluent-kafka-rest
sudo systemctl start confluent-ksql