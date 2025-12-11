# Streaming and Messaging

## Kafka

```bash
# config
./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name myTopic --describe
./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name myTopic --alter --add-config retention.ms=259200000,segment.ms=86400000
./kafka-configs.sh --bootstrap-server localhost:9092 --entity-type topics --entity-name myTopic --alter --add-config cleanup.policy=delete,compact

# cluster
./kafka-cluster.sh cluster-id --bootstrap-server localhost:9092

# topic
## query topic
./kafka-topics.sh --bootstrap-server localhost:9092 --list
./kafka-topics.sh --bootstrap-server localhost:9092 --topic myTopic --describe
## adding topics by special partition and replication
./kafka-topics.sh --bootstrap-server localhost:9092 --create --topic myTopic --replication-factor 1 --partitions 1 [--config x=y]
## modifying a topic partition with manual
./kafka-topics.sh --bootstrap-server localhost:9092 --alter --topic myTopic --partitions 3
## reset topic offset
./kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic myTopic --time 1700000000000
cat > /tmp/delete.json << "EOF"
{}
EOF
./kafka-delete-records.sh --bootstrap-server localhost:9092 --offset-json-file /tmp/delete.json
./kafka-topics.sh --bootstrap-server localhost:9092 --topic myTopic --describe

# producer
## produce messages
./kafka-console-producer.sh --bootstrap-server localhost:9092 --topic myTopic
first-event
second-event

# consumer && consumer groups
## query consumer
./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic myTopic
./kafka-console-consumer.sh --bootstrap-server localhost:9092 --group myConsumerGroup
## consume messages
./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic myTopic --from-beginning --consumer-property enable.auto.commit=false
## query consumer groups
./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list
./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group myConsumerGroup [--members] [--verbose]
## reset consumer offset
./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group myConsumerGroup --reset-offsets --to-latest --execute --topic myTopic
./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group myConsumerGroup --reset-offsets --to-offset offsetInt --execute --topic myTopic
./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group myConsumerGroup --reset-offsets --to-datetime 'YYYY-MM-DDTHH:mm:SS.sss' --execute --topic myTopic

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
