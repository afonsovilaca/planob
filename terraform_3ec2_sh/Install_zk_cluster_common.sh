#!/bin/bash

# Install Java
yum -y update
sudo yum -y install java-1.8.0-openjdk
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.292.b10-1.el7_9.x86_64/jre/bin/java

# Install zk
sudo yum -y install curl which

# https://docs.confluent.io/4.1.1/installation/installing_cp/rhel-centos.html
sudo bash -c 'cat << EOF > /etc/yum.repos.d/confluent.repo
[Confluent.dist]
name=Confluent repository (dist)
baseurl=https://packages.confluent.io/rpm/4.1/7
gpgcheck=1
gpgkey=https://packages.confluent.io/rpm/4.1/archive.key
enabled=1

[Confluent]
name=Confluent repository
baseurl=https://packages.confluent.io/rpm/4.1
gpgcheck=1
gpgkey=https://packages.confluent.io/rpm/4.1/archive.key
enabled=1
EOF'

sudo yum -y clean all &&  sudo yum -y install confluent-platform-oss-2.11

# Delete old zookeeper properties
sudo rm -f /etc/kafka/zookeeper.properties

sudo bash -c 'cat << EOF > /etc/kafka/zookeeper.properties
tickTime=2000
dataDir=/var/lib/zookeeper/
clientPort=2181
initLimit=5
syncLimit=2
server.1=172.31.0.49:2888:3888
server.2=172.31.0.87:2888:3888
server.3=172.31.0.107:2888:3888
autopurge.snapRetainCount=3
autopurge.purgeInterval=24
EOF'
