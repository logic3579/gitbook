# Kafka

/opt/kafka/server.conf

```bash
##### producer
# 发送消息收到多少确认信号数量才算写入成功（0:无需等待写入成功，1:只需leader写入成功，-1/all:所有ISR副本）
acks=1
# 发送消息重试次数与间隔
retries=0
retry.backoff.ms=1000
# 请求最大等待时间
request.timeout.ms=30000
# 内存耗尽时停止接收消息抛出错误
block.on.buffer.full=true
# 默认的批量处理消息字节数上限
batch.size=16384
# producer 可以缓存数据的内存大小
buffer.memory=33554432

##### consumer
# fetch 的消息 offset 会同步到 zookeeper，false 为先消费再手动提交
auto.commit.enable=true
auto.commit.interval.ms=5000
# 没有初始 offset 或不存在时，默认为最新获取
auto.offset.reset=latest
# 空连接超时时长
connections.max.idle.ms=540000

##### kafka server
# leader 自动选举平衡
auto.leader.rebalance.enable=true
# 默认线程数
background.threads=10
# broker id，每个节点必须不同
broker.id=0
# topic 压缩类型，默认使用生产者指定的压缩方式
compression.type=producer
# 默认创建 topic 副本数
default.replication.factor=3
# 组协调器在执行第一次重新平衡之前等待更多消费者加入新组的时间量
group.initial.rebalance.delay.ms=3000
# 控制器触发分区重新平衡检查的频率
leader.imbalance.check.interval.seconds=300
# 每个 broker 允许的leader不平衡比率
leader.imbalance.per.broker.percentage=10
# 节点服务监听端口
listeners=PLAINTEXT://1.1.1.1:9092
# 保存日志数据的目录
#log.dir=xxx
log.dirs=/opt/kafka/logs
# 日志刷新到磁盘前在分区（内存）中保存的消息数或时间
#log.flush.interval.messages=
#log.flush.interval.ms=
#log.flush.scheduler.interval.ms=
# 日志删除前保存的消息数或时间
log.retention.hours=168
log.retention.check.interval.ms=300000
# 单个日志段的大小
log.segment.bytes=1073741824
# 按topic计算，允许最大记录的批处理大小
message.max.bytes=1048588
# 生成新快照之前所需的最新快照和高水位线之间日志中的最大字节数
#metadata.log.max.record.bytes.between.snapshots=
# producer acks 设置 -1/all 时，必须成功写入的副本数数量
min.insync.replicas=2
# 默认创建 topic 分区数
num.partitions=3
# 用于处理请求的线程数（包括磁盘IO）
num.io.threads=8
# 用于处理网络请求的线程数
num.network.threads=3
# 每个数据目录的线程数，用于启动时日志恢复，停止时刷新日志
num.recovery.threads.per.data.dir=1
# 每个 broker 节点复制副本的线程数
num.replica.fetchers=1
# commit 前的 ack 确认
offsets.commit.required.acks=-1
# offset 加载到缓存时从 offset 读取的缓存大小
#offsets.load.buffer.size=5242880
# consumer 提交 offset 过期丢弃时间
#offsets.retention.minutes=
# offset commit topic 的分区数量与副本数量（部署后不应修改）
offsets.topic.num.partitions=50
offsets.topic.replication.factor=3
# offset 段大小
offsets.topic.segment.bytes=104857600
# 阻塞网络线程前，数据平面允许等待排队的请求数
queued.max.requests=500
# 副本复制线程请求等待时间
replica.fetch.wait.max.ms=500
# follower 没有发出 fetch 请求或没有消耗 leader end log offset，leader 从 isr 移除该follower
replica.lag.time.max.ms=30000
# 副本复制线程 socket 超时时间
replica.socket.timeout.ms=30000
# socket 请求 buffer/请求字节（设置-1使用操作系统配置）
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
# 事务最大超时时间
transaction.max.timeout.ms=900000
# 事务 topic 的副本数配置
transaction.state.log.replication.factor=3
# 事务 topic 的 min.insync.replicas 配置
transaction.state.log.min.isr=2
# zookeeper 连接配置
zookeeper.connect=1.1.1.1:2181,2.2.2.2:2181,3.3.3.3:2181
# 客户端阻塞前发送给 zookeeper unack 请求数量
zookeeper.max.in.flight.requests=10
# zookeeper 会话超时时间
zookeeper.session.timeout.ms=18000
# 空连接超时时间
connections.max.idle.ms=600000
# 延迟初始消费组重新平衡时间，生产环境建议为3s
group.initial.rebalance.delay.ms=3000
# socket 连接队列，取决于操作系统 somaxconn、tcp_max_syn_backlog
#socket.listen.backlog.size
```
