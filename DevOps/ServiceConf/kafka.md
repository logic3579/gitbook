# Kafka

/opt/kafka/server.conf

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
#log.dir=xxx
log.dirs=/opt/kafka/logs
# Number of messages or time to keep in partition (memory) before flushing logs to disk
#log.flush.interval.messages=
#log.flush.interval.ms=
#log.flush.scheduler.interval.ms=
# Retention time or number of messages before log deletion
log.retention.hours=168
log.retention.check.interval.ms=300000
# Size of a single log segment
log.segment.bytes=1073741824
# Maximum record batch size allowed per topic
message.max.bytes=1048588
# Maximum bytes in the log between the latest snapshot and the high watermark before generating a new snapshot
#metadata.log.max.record.bytes.between.snapshots=
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
# Buffer size for reading offsets when loading them into cache
#offsets.load.buffer.size=5242880
# Expiration time for consumer committed offsets before being discarded
#offsets.retention.minutes=
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
# Socket connection queue, depends on OS somaxconn and tcp_max_syn_backlog
#socket.listen.backlog.size
```
