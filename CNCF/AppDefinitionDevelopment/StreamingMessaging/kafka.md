---
description: Apache Kafka
---

# Kafka

## Introduction
...

## Deploy With Binary
### Quick Start
#### ZooKeeper Mode
[[zookeeper|zookeeper-deploy]]

```bash
# source download
cd /opt/ && wget https://archive.apache.org/dist/kafka/3.3.1/kafka_2.13-3.3.1.tgz
tar xf kafka_2.13-3.3.1.tgz && rm -rf kafka_2.13-3.3.1.tgz  

# soft link
ln -svf /opt/kafka_2.13-3.3.1/ /opt/kafka
cd /opt/kafka

# option: customize jdk env
export JAVA_HOME=/opt/jdk17
export JRE_HOME=$JAVA_HOME/jre
export CLASSPATH=$JAVA_HOME/lib:$JRE_HOME/lib:$CLASSPATH
export PATH=$JAVA_HOME/bin:$JRE_HOME/bin:$PATH

# start zookeeper and kafka server
./bin/zookeeper-server-start.sh config/zookeeper.properties
./bin/kafka-server-start.sh config/server.properties
```

#### KRaft Mode
```bash
# source download
cd /opt/ && wget https://archive.apache.org/dist/kafka/3.3.1/kafka_2.13-3.3.1.tgz
tar xf kafka_2.13-3.3.1.tgz && rm -rf kafka_2.13-3.3.1.tgz  

# soft link
ln -svf /opt/kafka_2.13-3.3.1/ /opt/kafka
cd /opt/kafka

# option: customize jdk env
export JAVA_HOME=/opt/jdk17
export JRE_HOME=$JAVA_HOME/jre
export CLASSPATH=$JAVA_HOME/lib:$JRE_HOME/lib:$CLASSPATH
export PATH=$JAVA_HOME/bin:$JRE_HOME/bin:$PATH

# generate cluster id and format log dir
./bin/kafka-storage.sh format -t $(bin/kafka-storage.sh random-uuid) -c config/kraft/server.properties
# start kafka
./bin/kafka-server-start.sh config/kraft/server.properties
```

### [[sc-kafka|Config]] and Boot
#### Config
**ZooKeeper Mode**
```bash
cat > config/zookeeper.properties << "EOF"
# 初始延迟时间（心跳时间单位）
tickTime=2000
initLimit=10
syncLimit=5
# 集群时需配置 zk 数据与日志目录（单点伪集群使用不同目录）
dataDir=/opt/kafka/zk-data
dataLogDir=/opt/kafka/zk-logs
# 集群时需配置服务通信与选举用端口（单点伪集群使用不同端口）
server.0=192.168.1.1:2888:3888
server.1=192.168.1.2:2888:3888
server.2=192.168.1.3:2888:3888
clientPort=2181
maxClientCnxns=300
admin.enableServer=false
EOF

cat > config/server.properties << "EOF"
############################# Server Basics #############################
# single mode
broker.id=0
# cluster mode
# broker.id=1
# broker.id=2
# broker.id=3

############################# Socket Server Settings #############################
# single mode
listeners=PLAINTEXT://localhost:9092
# cluster mode
# listeners=PLAINTEXT://192.168.1.1:9092
# listeners=PLAINTEXT://192.168.1.2:9092
# listeners=PLAINTEXT://192.168.1.3:9092

#advertised.listeners=PLAINTEXT://localhost:9092
#listener.security.protocol.map=PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600

############################# Log Basics #############################
log.dirs=/opt/kafka/logs
num.partitions=3
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=3
transaction.state.log.replication.factor=3
transaction.state.log.min.isr=2
default.replication.factor=3
min.insync.replicas=2

############################# Log Flush Policy #############################
#log.flush.interval.messages=10000
#log.flush.interval.ms=1000

############################# Log Retention Policy #############################
log.retention.hours=168
log.retention.check.interval.ms=300000

############################# Zookeeper #############################
# single mode
zookeeper.connect=192.168.1.1:2181
# cluster mode
# zookeeper.connect=192.168.1.1:2181,192.168.1.2:2181,192.168.1.3:2181
zookeeper.connection.timeout.ms=18000

############################# Group Coordinator Settings #############################
group.initial.rebalance.delay.ms=0
# group.initial.rebalance.delay.ms=3  # prod setting
EOF
```

**Kraft Mode**
```bash
cat > config/kraft/server.properties << "EOF"
############################# Server Basics #############################
process.roles=broker,controller

# single mode
node.id=1
controller.quorum.voters=1@localhost:9093
# cluster mode
# node.id=1
# controller.quorum.voters=1@192.168.1.1:9093,2@192.168.1.2:9093,3@192.168.1.3:9093
# node.id=2
# controller.quorum.voters=1@192.168.1.1:9093,2@192.168.1.2:9093,3@192.168.1.3:9093
# node.id=3
# controller.quorum.voters=1@192.168.1.1:9093,2@192.168.1.2:9093,3@192.168.1.3:9093

############################# Socket Server Settings #############################
# single mode
listeners=PLAINTEXT://:9092,CONTROLLER://:9093
# cluster mode
# listeners=PLAINTEXT://192.168.1.1:9092,CONTROLLER://192.168.1.1:9093
# listeners=PLAINTEXT://192.168.1.2:9092,CONTROLLER://192.168.1.2:9093
# listeners=PLAINTEXT://192.168.1.3:9092,CONTROLLER://192.168.1.3:9093

inter.broker.listener.name=PLAINTEXT
#advertised.listeners=PLAINTEXT://localhost:9092
controller.listener.names=CONTROLLER
listener.security.protocol.map=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600

############################# Log Basics #############################
log.dirs=/opt/kafka/logs
num.partitions=3
#num.partitions=8
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=3
transaction.state.log.replication.factor=3
transaction.state.log.min.isr=2
#auto.create.topics.enable=false
default.replication.factor=3
min.insync.replicas=2
queued.max.requests=3000

############################# Log Flush Policy #############################
#log.flush.interval.messages=10000
#log.flush.interval.ms=1000

############################# Log Retention Policy #############################
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
EOF
```

#### Boot(systemd)
**ZooKeeper Mode**
```bash
# 1. generate zookeeper id
echo 0 > /opt/kafka/zk-data/myid
echo 1 > /opt/kafka/zk-data/myid
echo 2 > /opt/kafka/zk-data/myid
# 2. kafka systemd service
cat > /etc/systemd/system/kafka.service << EOF
[Unit]
Description=Apache Kafka server
Documentation=https://kafka.apache.org
After=network.target
Wants=network-online.target
 
[Service]
Environment=KAFKA_HOME=/opt/kafka
Environment=KAFKA_HEAP_OPTS="-Xms2G -Xmx2G"
ExecStartPre=/opt/kafka/bin/kafka-storage.sh format -t $KAFKA_CLUSTER_ID -c /opt/kafka/config/kraft/server.properties --ignore-formatted
ExecStart=/opt/kafka/bin/kafka-server-start.sh -daemon /opt/kafka/config/kraft/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh 
KillSignal=SIGTERM
KillMode=mixed
LimitNOFILE=655350
LimitNPROC=655350
NoNewPrivileges=yes
#PrivateTmp=yes
Restart=on-failure
RestartSec=10s
SendSIGKILL=no
SuccessExitStatus=143
Type=forking
TimeoutStartSec=60
TimeoutStopSec=30
UMask=0077
User=kafka
Group=kafka
WorkingDirectory=/opt/kafka

[Install]
WantedBy=multi-user.target
EOF
```

**Kraft Mode**
```bash
# 1. generate only once cluster id
KAFKA_CLUSTER_ID=$(/opt/kafka/bin/kafka-storage.sh random-uuid)
KAFKA_CLUSTER_ID=$KAFKA_CLUSTER_ID
# 2. kafka systemd service
cat > /etc/systemd/system/kafka.service << EOF
[Unit]
Description=Apache Kafka server
Documentation=https://kafka.apache.org
After=network.target
Wants=network-online.target
 
[Service]
Environment=KAFKA_HOME=/opt/kafka
Environment=KAFKA_HEAP_OPTS="-Xms2G -Xmx2G"
Environment=KAFKA_CLUSTER_ID=7hakKVZCQ0aRnOKAmdPmEw
ExecStartPre=/opt/kafka/bin/kafka-storage.sh format -t $KAFKA_CLUSTER_ID -c /opt/kafka/config/kraft/server.properties --ignore-formatted
ExecStart=/opt/kafka/bin/kafka-server-start.sh -daemon /opt/kafka/config/kraft/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
LimitNOFILE=655350
LimitNPROC=65535
NoNewPrivileges=yes
KillSignal=SIGTERM
KillMode=mixed
Restart=on-failure
RestartSec=10s
SendSIGKILL=no
SuccessExitStatus=143
Type=forking
TimeoutStartSec=60
TimeoutStopSec=5
UMask=0077
User=kafka
Group=kafka
WorkingDirectory=/opt/kafka

[Install]
WantedBy=multi-user.target
EOF


chown kafka:kafka /opt/kafka -R
systemctl daemon-reload
systemctl start kafka.service
systemctl enable kafka.service
```

### Verify
[[StreamingMessaging#Kafka|Kafka Command]]

## Deploy With Container
### Run in Docker
```bash
docker pull apache/kafka:3.7.1
docker run -p 9092:9092 apache/kafka:3.7.1

# docker-compose
# https://hub.docker.com/r/bitnami/kafka
```

### Run in Kubernetes
#### Helm Charts
```bash
# add and update repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm update

# get charts package
helm pull bitnami/kafka --untar --version=29.3.5
cd kafka

# configure and run
vim values.yaml
global:
  storageClass: nfs-client
heapOpts: -Xmx1 -Xms1024m
extraConfigYaml:
  default.replication.factor: 3
  offsets.topic.replication.factor: 3
  transaction.state.log.replication.factor: 3
  transaction.state.log.min.isr: 2
  num.partitions: 3

# install
helm -n middleware install kafka .
```

#### Persistent storage
kafka 需要使用持久化存储配置，k8s 本身不支持 nfs 做 storageclass ，需要安装第三方 nfs 驱动实现

[[nfs-server|1.nfs-server部署]]

2.安装 nfs 第三方驱动插件
[[nfs-server#nfs-subdir-external-provisioner|deploy provisioner]]



>Reference:
>1. [Official Website](https://kafka.apache.org/documentation/)
>2. [Repository](https://github.com/apache/kafka)
>3. [storageclass 存储类官方说明](https://kubernetes.io/zh-cn/docs/concepts/storage/storage-classes/)
>4. [nfs-server 驱动部署方式](https://blog.51cto.com/smbands/4903841)
>5. [nfs 驱动 helm 安装](https://artifacthub.io/packages/helm/nfs-subdir-external-provisioner/nfs-subdir-external-provisioner)
>6. [kafka kraft 协议介绍](https://www.infoq.cn/article/j1jm5qehr1jiequby0ot)
