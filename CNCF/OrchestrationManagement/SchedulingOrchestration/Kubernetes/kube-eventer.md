---
description: kube-eventer
---

# kube-eventer

## Collecting K8S Cluster Events with kube-eventer

### 1. Background

#### Overview

- What are events: Kubernetes architecture is designed based on a state machine. State transitions generate corresponding events. Transitions between normal states generate Normal-level events, while transitions between normal and abnormal states generate Warning-level events.

- kube-eventer component: An open-source component by Alibaba Cloud, used to collect event messages from K8S clusters and store them in custom middleware or storage. (K8S clusters only retain events for 1 hour by default)

- Official repository: https://github.com/AliyunContainerService/kube-eventer

#### Prerequisites and Software

| Name                             | Function                                          | Notes                         |
| -------------------------------- | ------------------------------------------------- | ----------------------------- |
| K8S Cluster                      | Application cluster                               | Using minikube test cluster   |
| kube-eventer                     | Collect K8S cluster events                        | Third-party cluster component |
| Kafka / Elasticsearch / influxDB | Middleware: store event messages                  | Storage component (Kafka selected) |
| kube-eventer-py                  | Retrieve event messages from queue and send to Telegram alert group | Event consumer |

### 2. Installation and Deployment Steps

#### a) minikube Cluster Deployment

Reference: https://minikube.sigs.k8s.io/docs/start/

#### b) Storage Middleware Deployment

##### Kafka

Deploy Kafka using Helm

```bash
# Add Helm repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Pull Kafka chart and extract
mkdir /opt/helm_chats && cd /opt/helm_chats
helm pull bitnami/kafka && tar xf kafka-18.2.0.tgz && rm -rf kafka-18.2.0.tgz

# Modify key configuration and start Kafka
# Showing key configuration excerpts
cat ./values.yaml
...
...
# Kafka startup configuration file, mounted via ConfigMap
config: |-
  broker.id=0
  listeners=INTERNAL://:9093,CLIENT://:9092
  advertised.listeners=INTERNAL://kafka-0.kafka-headless.default.svc.cluster.local:9093,CLIENT://kafka-0.kafka-headless.default.svc.cluster.local:9092
  listener.security.protocol.map=INTERNAL:PLAINTEXT,CLIENT:PLAINTEXT
  num.network.threads=5
  num.io.threads=10
  socket.send.buffer.bytes=102400
  socket.receive.buffer.bytes=102400
  socket.request.max.bytes=104857600
  log.dirs=/bitnami/kafka/data
  num.partitions=1
  num.recovery.threads.per.data.dir=1
  offsets.topic.replication.factor=1
  transaction.state.log.replication.factor=1
  transaction.state.log.min.isr=1
  log.flush.interval.messages=10000
  log.flush.interval.ms=1000
  log.retention.hours=168   # Queue data retention time, default is 7 days
  log.retention.bytes=1073741824
  log.segment.bytes=1073741824
  log.retention.check.interval.ms=300000
  zookeeper.connect=test-kafka-zookeeper
  zookeeper.connection.timeout.ms=6000
  group.initial.rebalance.delay.ms=0
  allow.everyone.if.no.acl.found=true
  auto.create.topics.enable=true
  default.replication.factor=1
  delete.topic.enable=true   # Whether to automatically delete topic data after timeout
  inter.broker.listener.name=INTERNAL
  log.retention.check.intervals.ms=300000
  max.partition.fetch.bytes=1048576
  max.request.size=1048576
  message.max.bytes=1000012
  sasl.enabled.mechanisms=PLAIN,SCRAM-SHA-256,SCRAM-SHA-512
  sasl.mechanism.inter.broker.protocol=
  super.users=User:admin
...
...
persistence:
  enabled: true
  existingClaim: ""
  storageClass: "standard"   # Persistent storage class
...
...
zookeeper:
  enabled: true
  replicaCount: 1
  auth:
    client:
      enabled: false
      clientUser: ""
      clientPassword: ""
      serverUsers: ""
      serverPasswords: ""
  persistence:
    enabled: true
    storageClass: "standard"   # Persistent storage class, available by default in minikube.


# Deploy and verify
helm install kafka .
# Verify deployment status, check if pods are in Running state
kubectl get pod
NAME                                  READY   STATUS    RESTARTS       AGE
kafka-0                         1/1     Running   0              171m
kafka-zookeeper-0               1/1     Running   6 (168m ago)   10d
```

##### elasticsearch

#### c) kube-eventer Deployment

- Deploy using official YAML resource files

```bash
cat > kube-eventer.yaml << "EOF"
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    name: kube-eventer
  name: kube-eventer
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kube-eventer
  template:
    metadata:
      labels:
        app: kube-eventer
      annotations:
        #scheduler.alpha.kubernetes.io/critical-pod: ''
        priorityClassName: ''
    spec:
      dnsPolicy: ClusterFirstWithHostNet
      serviceAccount: kube-eventer
      containers:
        - image: registry.aliyuncs.com/acs/kube-eventer-amd64:v1.2.0-484d9cd-aliyun
          name: kube-eventer
          command:
            - "/kube-eventer"
            - "--source=kubernetes:https://kubernetes.default"
            # kafka
            - --sink=kafka:?brokers=kafka.middleware:9092&eventstopic=my_kube_events
            # elasticsearch
            #- --sink=elasticsearch:http://es.middleware:9200?sniff=false&ver=7&index=my_kube_events
          env:
          # If TZ is assigned, set the TZ value as the time zone
          - name: TZ
            value: "Asia/Shanghai"
          volumeMounts:
            - name: localtime
              mountPath: /etc/localtime
              readOnly: true
            - name: zoneinfo
              mountPath: /usr/share/zoneinfo
              readOnly: true
          resources:
            requests:
              cpu: 100m
              memory: 100Mi
            limits:
              cpu: 500m
              memory: 250Mi
      volumes:
        - name: localtime
          hostPath:
            path: /etc/localtime
        - name: zoneinfo
          hostPath:
            path: /usr/share/zoneinfo
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kube-eventer
rules:
  - apiGroups:
      - ""
    resources:
      - configmaps
      - events
    verbs:
      - get
      - list
      - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-eventer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kube-eventer
subjects:
  - kind: ServiceAccount
    name: kube-eventer
    namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube-eventer
  namespace: kube-system
EOF

# Deploy resources, deployed to kube-system namespace by default
kubectl apply -f kube-eventer.yaml
# Verify deployment status
kubectl get pod -n kube-system
NAME                               READY   STATUS    RESTARTS        AGE
kube-eventer-69455778cd-cvr9w      1/1     Running   0               8d
```

#### d) Retrieve Events from Message Queue and Send to Telegram

- Create Telegram bot and alert group

> References
>
> 1. Bot creation: https://cloud.tencent.com/developer/article/1835051
>
> 2. Telegram Python SDK: https://github.com/python-telegram-bot/python-telegram-bot

- Python script details

```python
# telegrambot.py file
import asyncio
import telegram
import json
import traceback

TOKEN = "xxxxx"
chat_id = "-xxxxx"
bot = telegram.Bot(token=TOKEN)


class FilterMsg(object):
    def __init__(self, text):
        self.event_value = json.loads(text['EventValue'])

        self.data = dict()
        self.data['kind'] = self.event_value['involvedObject']['kind']
        self.data['namespace'] = self.event_value['involvedObject']['namespace']
        self.data['reason'] = self.event_value['reason']
        self.data['message'] = self.event_value['message']
        self.data['first_timestamp'] = self.event_value['firstTimestamp']
        self.data['last_timestamp'] = self.event_value['lastTimestamp']
        self.data['count'] = self.event_value['count']
        self.data['type'] = self.event_value['type']
        self.data['event_time'] = self.event_value['eventTime']
        self.data['pod_hostname'] = text['EventTags']['hostname']
        self.data['pod_name'] = text['EventTags']['pod_name']

    def convert(self):
        msg_markdown = f"""
        *K8S Cluster Event*
    `Kind: {self.data['kind']}`
    `Namescodeace: {self.data['namespace']}`
    `Reason: {self.data['reason']}`
    `Timestamp: {self.data['first_timestamp']} to {self.data['last_timestamp']}`
    `Count: {self.data['count']}`
    `EventType: {self.data['type']}`
    `EventTime: {self.data['event_time']}`
    `PodHostname: {self.data['pod_hostname']}`
    `PodName: {self.data['pod_name']}`
    `Message: {self.data['message']}`
"""
        return msg_markdown

async def send_message(text):
    try:
        # Core: get message from Kafka,and filter message
        convert_text = json.loads(text.decode('utf8').replace('\\n', ''))
        msg_instance = FilterMsg(convert_text)
        msg = msg_instance.convert()
        send_result = bot.send_message(chat_id=chat_id, text=msg, parse_mode='MarkdownV2')
        return send_result
    except KeyError as e:
        msg = "Unknow message.."
        send_result = bot.send_message(chat_id=chat_id, text=msg)
        return send_result
    except Exception as e:
        print(e.__str__())
        #traceback.print_exc()
        print('send message to telegram failed,please check.')

if __name__ == '__main__':
    text = b''
    text = json.loads(text.decode('utf8').replace('\\n', ''))
    send_result = asyncio.run(send_message(text))
    print(send_result)

# get_events.py file
from kafka import KafkaConsumer, TopicPartition
from telegrambot import send_message
import asyncio

class KConsumer(object):
    """kafka consumer instance"""
    def __init__(self, topic, group_id, bootstrap_servers, auto_offset_reset, enable_auto_commit=False):
        """
        :param topic:
        :param group_id:
        :param bootstrap_servers:
        """
        self.consumer = KafkaConsumer(
            topic,
            bootstrap_servers=bootstrap_servers,
            group_id=group_id,
            auto_offset_reset=auto_offset_reset,
            enable_auto_commit=enable_auto_commit,
            consumer_timeout_ms=10000
        )
        self.tp = TopicPartition(topic, 0)

    def start_consumer(self):
        while True:
            try:
                # Manually pull messages with 30s interval, then manually commit the current offset
                msg_list_dict = self.consumer.poll(timeout_ms=30000)
                for tp, msg_list in msg_list_dict.items():
                    for msg in msg_list:
                        ### core operate,send message to telegram
                        send_result = asyncio.run(send_message(msg.value))
                        print(send_result)
                #print(f"current offset is {self.consumer.position(tp)}")
                self.consumer.commit()
            except Exception as e:
                print('ERROR: get cluster events failed,please check.')

    def close_consumer(self):
        try:
            self.consumer.unsubscribe()
            self.consumer.close()
        except:
            print("consumer stop failed,please check.")

if __name__ == '__main__':
    # env, middleware configuration
    topic = 'test_topic'
    bootstrap_servers = 'kafka-headless:9092'
    group_id = 'test.group'
    auto_offset_reset = 'earliest'
    enable_auto_commit = False

    # start
    consumer = KConsumer(topic, group_id=group_id, bootstrap_servers=bootstrap_servers, auto_offset_reset=auto_offset_reset, enable_auto_commit=enable_auto_commit)
    consumer.start_consumer()
    # stop
    #consumer.close_consumer()
```

- Dockerfile Configuration

```dockerfile
FROM python:3.8

# Set an environment variable
ENV APP /app

# Create the directory
RUN mkdir $APP
WORKDIR $APP

# Expose the port uWSGI will listen on
#EXPOSE 5000

# Copy the requirements file in order to install
# Python dependencies
#COPY requirements.txt .
COPY . .
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

# Finally, we run uWSGI with the ini file
#CMD ["sleep", "infinity"]
CMD ["python", "get_events.py"]
```

- Build Image and Verify Startup

```bash
# Steps to compile source code and build image
cd /app/kube-eventer-py/ && mkdir APP-META
rm -f APP-META/*.py && cp *.py APP-META/

cd APP-META && build -t kube-eventer-telegrambot:latest .

# Start image (docker or kubectl)
cat > kube-eventer-telegrambot.yaml << "EOF"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kube-eventer
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kube-eventer
  template:
    metadata:
      labels:
        app: kube-eventer
    spec:
      containers:
        - image: kube-eventer-telegrambot:latest
          name: kube-eventer
          env:
          - name: TZ
            value: "Asia/Shanghai"
      volumes:
        - name: localtime
          hostPath:
            path: /etc/localtime
        - name: zoneinfo
          hostPath:
            path: /usr/share/zoneinfo
EOF
# Verify startup result
kubectl apply -f kube-eventer-telegrambot.yaml
kubectl get pod
NAME                                  READY   STATUS    RESTARTS        AGE
kube-eventer-589bf867bc-tgs5l   1/1     Running   0               27
```

- Event Message Reception Verification
