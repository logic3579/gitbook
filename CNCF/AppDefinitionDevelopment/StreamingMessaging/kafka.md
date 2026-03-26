---
description: Apache Kafka
tags:
  - cncf/app-definition
  - messaging
---

# Kafka

## Introduction

...

## Deploy By Binary

### Quick Start

#### ZooKeeper Mode

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

### Config and Boot

#### Config

**ZooKeeper Mode**

```bash
cat > config/zookeeper.properties << "EOF"
# initial delay time (in heartbeat time units)
tickTime=2000
initLimit=10
syncLimit=5
# cluster mode requires configuring zk data and log directories (pseudo-cluster on single node uses different directories)
dataDir=/opt/kafka/zk-data
dataLogDir=/opt/kafka/zk-logs
# cluster mode requires configuring service communication and election ports (pseudo-cluster on single node uses different ports)
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

[Kafka Command](/DevOps/CommandManual/streaming-messaging.md#kafka)

## Deploy By Container

### Run On Docker

```bash
docker pull apache/kafka:3.7.1
docker run -p 9092:9092 apache/kafka:3.7.1

# docker-compose
# https://hub.docker.com/r/bitnami/kafka
```

### Run On Kubernetes

#### Install by Helm

```bash
# Add and update repo
helm repo add bitnami https://charts.bitnami.com/bitnami --force-update

# Get charts package
helm pull bitnami/kafka --untar --version=31.5.0
cd kafka

# Configure
vim values.yaml
global:
  storageClass: premium-rwo
controller:
  replicaCount: 3
  resources:
    limits: {}
    requests: {}
  nodeSelector: {}
  persistence: {}
broker:
  replicaCount: 3
  extraConfig: |
    num.partitions=3
    min.insync.replicas=2
    default.replication.factor=3
    offsets.topic.replication.factor=3
    transaction.state.log.min.isr=2
    transaction.state.log.replication.factor=3
  resources:
    limits: {}
    requests: {}
  nodeSelector: {}
  persistence: {}

# Install
helm install -n middleware kafka . --create-namespace
```

## Configuration Reference

**/opt/kafka/server.conf** — Key tuning parameters

```bash
##### producer
# Number of acknowledgments required for a write to be considered successful (0: no wait, 1: only leader, -1/all: all ISR replicas)
acks=1
# Number of retries and interval for sending messages
retries=0
retry.backoff.ms=1000
# Maximum wait time for a request
request.timeout.ms=30000
# Stop accepting messages and throw an error when memory is exhausted
block.on.buffer.full=true
# Default upper limit of batch message size in bytes
batch.size=16384
# Total memory size available for the producer to buffer data
buffer.memory=33554432

##### consumer
# Fetched message offsets are synced to zookeeper; false means consume first then manually commit
auto.commit.enable=true
auto.commit.interval.ms=5000
# When there is no initial offset or it does not exist, defaults to fetching the latest
auto.offset.reset=latest
# Idle connection timeout
connections.max.idle.ms=540000

##### kafka server
# Automatic leader election rebalancing
auto.leader.rebalance.enable=true
# Default number of threads
background.threads=10
# Broker ID, must be unique for each node
broker.id=0
# Topic compression type, defaults to the compression method specified by the producer
compression.type=producer
# Default number of replicas when creating a topic
default.replication.factor=3
# Amount of time the group coordinator waits for more consumers to join a new group before performing the first rebalance
group.initial.rebalance.delay.ms=3000
# Frequency at which the controller triggers partition rebalance checks
leader.imbalance.check.interval.seconds=300
# Allowed leader imbalance ratio per broker
leader.imbalance.per.broker.percentage=10
# Node service listening port
listeners=PLAINTEXT://1.1.1.1:9092
# Directory for storing log data
log.dirs=/opt/kafka/logs
# Retention time or number of messages before log deletion
log.retention.hours=168
log.retention.check.interval.ms=300000
# Size of a single log segment
log.segment.bytes=1073741824
# Maximum record batch size allowed per topic
message.max.bytes=1048588
# When producer acks is set to -1/all, the number of replicas that must successfully write
min.insync.replicas=2
# Default number of partitions when creating a topic
num.partitions=3
# Number of threads for processing requests (including disk I/O)
num.io.threads=8
# Number of threads for processing network requests
num.network.threads=3
# Number of threads per data directory, used for log recovery at startup and log flushing at shutdown
num.recovery.threads.per.data.dir=1
# Number of threads for replicating replicas per broker node
num.replica.fetchers=1
# Acknowledgment required before commit
offsets.commit.required.acks=-1
# Number of partitions and replicas for the offset commit topic (should not be changed after deployment)
offsets.topic.num.partitions=50
offsets.topic.replication.factor=3
# Offset segment size
offsets.topic.segment.bytes=104857600
# Number of queued requests allowed on the data plane before blocking network threads
queued.max.requests=500
# Maximum wait time for replica fetch requests
replica.fetch.wait.max.ms=500
# If a follower has not sent a fetch request or has not consumed up to the leader's end log offset, the leader removes the follower from the ISR
replica.lag.time.max.ms=30000
# Socket timeout for replica fetch threads
replica.socket.timeout.ms=30000
# Socket request buffer/request bytes (set to -1 to use OS configuration)
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
# Maximum transaction timeout
transaction.max.timeout.ms=900000
# Replication factor for the transaction topic
transaction.state.log.replication.factor=3
# min.insync.replicas configuration for the transaction topic
transaction.state.log.min.isr=2
# Zookeeper connection configuration
zookeeper.connect=1.1.1.1:2181,2.2.2.2:2181,3.3.3.3:2181
# Number of unacknowledged requests sent to zookeeper before the client blocks
zookeeper.max.in.flight.requests=10
# Zookeeper session timeout
zookeeper.session.timeout.ms=18000
# Idle connection timeout
connections.max.idle.ms=600000
# Delay time for initial consumer group rebalance, recommended 3s for production
group.initial.rebalance.delay.ms=3000
```

> Reference:
>
> 1. [Official Website](https://kafka.apache.org/documentation/)
> 2. [Repository](https://github.com/apache/kafka)
> 3. [StorageClass Official Documentation](https://kubernetes.io/zh-cn/docs/concepts/storage/storage-classes/)
> 4. [Kafka KRaft Protocol](https://www.infoq.cn/article/j1jm5qehr1jiequby0ot)
> 5.  [NFS Server Deployment](/DevOps/Network/nfs.md#csi-driver-nfs)
