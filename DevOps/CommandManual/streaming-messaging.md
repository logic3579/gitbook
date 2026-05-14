---
description: Kafka and RocketMQ CLI references
tags:
  - devops/command
  - messaging
---

# Streaming and Messaging

## Kafka

### Cluster

```bash
# show cluster id
./kafka-cluster.sh cluster-id --bootstrap-server localhost:9092
```

### Configuration

```bash
# describe topic-level configs
./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name myTopic --describe

# alter retention and segment rolling
./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name myTopic --alter --add-config retention.ms=259200000,segment.ms=86400000

# change cleanup policy (delete + compact)
./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name myTopic --alter --add-config cleanup.policy=delete,compact
```

### Topic Management

```bash
# list topics
./kafka-topics.sh --bootstrap-server localhost:9092 --list

# describe a topic (partitions, replicas, ISR)
./kafka-topics.sh --bootstrap-server localhost:9092 --topic myTopic --describe

# create a topic with explicit partition / replication
./kafka-topics.sh --bootstrap-server localhost:9092 --create --topic myTopic --replication-factor 1 --partitions 1 [--config x=y]

# add partitions (cannot reduce)
./kafka-topics.sh --bootstrap-server localhost:9092 --alter --topic myTopic --partitions 3
```

### Topic Offset & Record Deletion

```bash
# look up offset by timestamp (ms)
./kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic myTopic --time 1700000000000

# delete records up to a given offset (per partition)
cat > /tmp/delete.json << "EOF"
{}
EOF
./kafka-delete-records.sh --bootstrap-server localhost:9092 --offset-json-file /tmp/delete.json

# verify after deletion
./kafka-topics.sh --bootstrap-server localhost:9092 --topic myTopic --describe
```

### Producer

```bash
# produce messages interactively
./kafka-console-producer.sh --bootstrap-server localhost:9092 --topic myTopic
first-event
second-event
```

### Consumer

```bash
# consume from a topic (default: latest)
./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic myTopic

# consume as part of a consumer group
./kafka-console-consumer.sh --bootstrap-server localhost:9092 --group myConsumerGroup

# consume from beginning without auto-committing
./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic myTopic --from-beginning --consumer-property enable.auto.commit=false
```

### Consumer Groups

```bash
# list all consumer groups
./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list

# describe group state, lag, members
./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group myConsumerGroup [--members] [--verbose]

# reset offset to latest
./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group myConsumerGroup --reset-offsets --to-latest --execute --topic myTopic

# reset offset to a specific offset
./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group myConsumerGroup --reset-offsets --to-offset offsetInt --execute --topic myTopic

# reset offset to a datetime
./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group myConsumerGroup --reset-offsets --to-datetime 'YYYY-MM-DDTHH:mm:SS.sss' --execute --topic myTopic
```

### Metadata Quorum (KRaft)

```bash
# show KRaft controller quorum status
./kafka-metadata-quorum.sh --bootstrap-server localhost:9092 describe --status
```

## RocketMQ

### Common

```bash
# command shape
# ./mqadmin {command} {args}

# common args
-b brokerName
-c clusterName
-n nameServer
-t topicName
```

### Cluster

```bash
# list brokers in the cluster
./mqadmin clusterList -n 'namersrvName:9876'
```

### Broker

```bash
# show broker runtime status
./mqadmin brokerStatus -b brokerAddr -n 'namersrvName:9876'
```

### Topic Management

```bash
# list topics on the name server
./mqadmin topicList -n 'namersrvName:9876'

# show topic status (queues, offsets, last-update)
./mqadmin topicStatus -t myTopic -n 'namersrvName:9876'

# create or update a topic on a cluster
./mqadmin updateTopic -t myTopic -n 'namersrvName:9876' -c clusterName

# delete a topic
./mqadmin deleteTopic -t myTopic -n 'namersrvName:9876'

# show clusters a topic is routed to
./mqadmin topicClusterList -t myTopic -n 'namersrvName:9876'
```

### Producer

```bash
# send a test message to a topic on a broker
./mqadmin sendMessage -t topicName -b brokerName -p testTopic -n 'namersrvName:9876'
```

### Message Query

```bash
# query a message by its msgId
./mqadmin queryMsgById -i msgId -n 'namersrvName:9876'

# query messages by key
./mqadmin queryMsgByKey -k msgKey -n 'namersrvName:9876'

# query a message by topic/broker/queue/offset
./mqadmin queryMsgByOffset -t topicName -b brokerName -i queueId -o offsetValue -n 'namersrvName:9876'
```

### Consumer

```bash
# consume a message at a specific offset (for inspection)
./mqadmin consumeMessage -t topicName -b brokerName -o offset -i queueId -g consumerGroup

# show consumer group status (subscriptions, progress)
./mqadmin consumerStatus -g consumerGroupName -n 'namersrvName:9876'
```

### Controller (DLedger / Auto-Failover)

```bash
# show controller cluster metadata
./mqadmin getControllerMetaData -a localhost:9878

# show in-sync replica set for a broker
./mqadmin getSyncStateSet -a localhost:9878 -b broker-a

# show current epoch of a broker
./mqadmin getBrokerEpoch -n localhost:9876 -b broker-a
```

> Reference:
>
> 1. [Kafka CLI Documentation](https://kafka.apache.org/documentation/#cli)
> 2. [RocketMQ CLI Documentation](https://rocketmq.apache.org/docs/deploymentOperations/02admintool/)
