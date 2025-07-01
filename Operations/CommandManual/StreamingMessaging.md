# Streaming and Messaging

## Kafka

```bash
# config
# 动态查看&更新节点配置（官方配置支持 cluster-wide 类型配置才可以更新）
./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type brokers --entity-name 1 --describe
./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type brokers --entity-name 1 --alter --add-config log.cleaner.threads=2
# 使用 --entity-default 参数为调整整个集群的动态配置

# cluster
./kafka-cluster.sh cluster-id --bootstrap-server localhost:9092

# topic
# adding topics by special partition and replication
./kafka-topics.sh --bootstrap-server localhost:9092 --create --topic myTopic --replication-factor 1 --partitions 1 [--config x=y]
# modifying a topic partition with manual
./kafka-topics.sh --bootstrap-server localhost:9092 --alter --topic myTopic --partitions 3
# select topic
./kafka-topics.sh --bootstrap-server localhost:9092 --topic myTopic --descibe
./kafka-topics.sh --bootstrap-server localhost:9092 --list

# production messages
./kafka-console-producer.sh --bootstrap-server localhost:9092 --topic myTopic
first event
second event

# consumer messages
./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic myTopic
./kafka-console-consumer.sh --bootstrap-server localhost:9092 --group myGroup
./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic myTopic --from-beginning

# consumer groups
./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --descibe --group myGroup [--members] [--verbose]
./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list

# offset
./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group myGroup --reset-offsets --to-latest --execute --topic myTopic
./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group myGroup --reset-offsets --to-offset offsetInt --execute --topic myTopic
./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group myGroup --reset-offsets --to-datetime 'YYYY-MM-DDTHH:mm:SS.sss' --execute --topic myTopic

# metadata quorum tool
./kafka-metadata-quorum.sh --bootstrap-server localhost:9092 describe --status
```

## RocketMQ

```bash
# common
# ./mqadmin {command} {args}
# args
-b brokerName
-c clusterName
-n nameServer
-t topicName

# broker
./mqadmin brokerStatus -b brokerAddr -n 'namersrvName:9876'

# topic
./mqadmin topicList -n 'namersrvName:9876'
./mqadmin topicStatus -t myTopic -n 'namersrvName:9876'
./mqadmin updateTopic -t myTopic -n 'namersrvName:9876' -c clusterName
./mqadmin deleteTopic -t myTopic -n 'namersrvName:9876'
./mqadmin topicClusterList -t myTopic -n 'namersrvName:9876'

# cluster
./mqadmin clusterList -n 'namersrvName:9876'

# message
./mqadmin queryMsgById -i msgId -n 'namersrvName:9876'
./mqadmin queryMsgByKey -k msgKey -n 'namersrvName:9876'
./mqadmin queryMsgByOffset -t topicName -b brokerName -i queueId -o offsetValue -n 'namersrvName:9876'
./mqadmin sendMessage -t topicName -b brokerName -p testTopic -n 'namersrvName:9876'
./mqadmin consumeMessage -t topicName -b brokerName -o offset -i queueId -g consumerGroup

# consumer
./mqadmin consumerStatus -g consumerGroupName -n 'namersrvName:9876'

# controller
./mqadmin getControllerMetaData -a localhost:9878
./mqadmin getSyncStateSet -a localhost:9878 -b broker-a
./mqadmin getBrokerEpoch -n localhost:9876 -b broker-a
```
