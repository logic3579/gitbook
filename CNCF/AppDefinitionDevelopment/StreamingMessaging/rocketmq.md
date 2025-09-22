---
description: RocketMQ
---

# RocketMQ

## Introduction
...


## Deploy By Binary
### Quick Start
```bash
# option1: compile source install
cd /usr/local/src/
wget https://dist.apache.org/repos/dist/release/rocketmq/5.3.0/rocketmq-all-5.3.0-source-release.zip
unzip rocketmq-all-5.3.0-source-release.zip && rm -f rocketmq-all-5.3.0-source-release.zip
cd rocketmq-all-5.3.0-source-release
mvn -Prelease-all -DskipTests -Dspotbugs.skip=true clean install -U
cp -aR distribution/target/rocketmq-5.3.0/rocketmq-5.3.0 /opt/rocketmq-5.3.0

# options2: download bin install
cd /usr/local/src/
wget https://dist.apache.org/repos/dist/release/rocketmq/5.3.0/rocketmq-all-5.3.0-bin-release.zip
unzip rocketmq-all-5.3.0-bin-release.zip && rm -f rocketmq-all-5.3.0-bin-release.zip
cp -aR rocketmq-all-5.3.0-bin-release /opt/rocketmq-5.3.0

# soft link
ln -svf /opt/rocketmq-5.3.0 /opt/rocketmq
cd /opt/rocketmq

# postinstallation
export ROCKETMQ_HOME=/opt/rocketmq
#export JAVA_HOME=/opt/jdk21
export PATH=$PATH:/opt/rocketmq/bin

# local mode
# option1: single replication
./bin/mqnamesrv
./bin/mqbroker -n localhost:9876 --enable-proxy
# option2: synchronization 2m-2s-sync
./bin/mqnamesrv
./bin/mqbroker -n localhost:9876 -c $ROCKETMQ_HOME/conf/2m-2s-sync/broker-a.properties --enable-proxy
./bin/mqbroker -n localhost:9876 -c $ROCKETMQ_HOME/conf/2m-2s-sync/broker-a-s.properties --enable-proxy
./bin/mqbroker -n localhost:9876 -c $ROCKETMQ_HOME/conf/2m-2s-sync/broker-b.properties --enable-proxy
./bin/mqbroker -n localhost:9876 -c $ROCKETMQ_HOME/conf/2m-2s-sync/broker-b-s.properties --enable-proxy
# option3: asynchronous 2m-2s-async
...

# cluster mode
# option1: synchronization 2m-2s-sync
./bin/mqnamesrv
./bin/mqbroker -n 192.168.1.1:9876;192.161.2:9876 -c $ROCKETMQ_HOME/conf/2m-2s-sync/broker-a.properties
./bin/mqbroker -n 192.168.1.1:9876;192.161.2:9876 -c $ROCKETMQ_HOME/conf/2m-2s-sync/broker-a-s.properties
./bin/mqbroker -n 192.168.1.1:9876;192.161.2:9876 -c $ROCKETMQ_HOME/conf/2m-2s-sync/broker-b.properties
./bin/mqbroker -n 192.168.1.1:9876;192.161.2:9876 -c $ROCKETMQ_HOME/conf/2m-2s-sync/broker-b-s.properties
./bin/mqproxy -n 192.168.1.1:9876;192.161.2:9876 -pc $ROCKETMQ_HOME/conf/2m-2s-sync/proxyConfig.json
# option2: asynchronous 2m-2s-async
...

# failover mode
...

# shutdown
./bin/mqshutdown broker
./bin/mqshutdown namesrv
```

### Config and Boot
#### Config
**Local Mode**
```bash
# namesrv config
cat > /opt/rocketmq/conf/2m-2s-sync/nameserver.conf << "EOF"
bindAddress=10.0.0.x
EOF

# master config
cat > /opt/rocketmq/conf/2m-2s-sync/broker-a.properties << "EOF"
brokerClusterName=DefaultCluster
brokerName=broker-a
brokerId=0
namesrvAddr=10.0.0.1:9876;10.0.0.2:9876
bindAddress=10.0.0.1
listenPort=6888
storePathRootDir=/opt/rocketmq/store
deleteWhen=04
diskMaxUsedSpaceRatio=85
fileReservedTime=48
brokerRole=SYNC_MASTER
flushDiskType=ASYNC_FLUSH
EOF
cat > /opt/rocketmq/conf/2m-2s-sync/broker-b.properties << "EOF"
brokerClusterName=DefaultCluster
brokerName=broker-b
brokerId=0
namesrvAddr=10.0.0.1:9876;10.0.0.2:9876
bindAddress=10.0.0.2
listenPort=6888
storePathRootDir=/opt/rocketmq/store
deleteWhen=04
diskMaxUsedSpaceRatio=85
fileReservedTime=48
brokerRole=SYNC_MASTER
flushDiskType=ASYNC_FLUSH
EOF

# slave config
cat > /opt/rocketmq/conf/2m-2s-sync/broker-a-s.properties << "EOF"
brokerClusterName=DefaultCluster
brokerName=broker-a
brokerId=1
namesrvAddr=10.0.0.1:9876;10.0.0.2:9876
bindAddress=10.0.0.1
listenPort=7888
storePathRootDir=/opt/rocketmq/store-s
deleteWhen=04
diskMaxUsedSpaceRatio=85
fileReservedTime=48
brokerRole=SLAVE
flushDiskType=ASYNC_FLUSH
EOF
cat > /opt/rocketmq/conf/2m-2s-sync/broker-b-s.properties << "EOF"
brokerClusterName=DefaultCluster
brokerName=broker-b
brokerId=1
namesrvAddr=10.0.0.1:9876;10.0.0.2:9876
bindAddress=10.0.0.2
listenPort=7888
storePathRootDir=/opt/rocketmq/store-s
deleteWhen=04
diskMaxUsedSpaceRatio=85
fileReservedTime=48
brokerRole=SLAVE
flushDiskType=ASYNC_FLUSH
EOF
```

**Failover Mode**
```bash
# namesrv and controller config
cat > /opt/rocketmq/conf/controller/cluster-3n-namesrv-plugin/namesrv-n0.conf << "EOF"
# namesrv config
bindAddress = 10.0.0.1
listenPort = 9876
enableControllerInNamesrv = true
# controller config
controllerDLegerGroup = group1
controllerDLegerPeers = n0-10.0.0.1:9877;n1-10.0.0.2:9877;n2-10.0.0.2:9877
controllerDLegerSelfId = n0
controllerStorePath = /opt/rocketmq/DledgerController
enableElectUncleanMaster = false
notifyBrokerRoleChanged = true
EOF
cat > /opt/rocketmq/conf/controller/cluster-3n-namesrv-plugin/namesrv-n1.conf << "EOF"
# namesrv config
bindAddress = 10.0.0.2
listenPort = 9876
enableControllerInNamesrv = true
# controller config
controllerDLegerGroup = group1
controllerDLegerPeers = n0-10.0.0.1:9877;n1-10.0.0.2:9877;n2-10.0.0.2:9877
controllerDLegerSelfId = n1
controllerStorePath = /opt/rocketmq/DledgerController
enableElectUncleanMaster = false
notifyBrokerRoleChanged = true
EOF
cat > /opt/rocketmq/conf/controller/cluster-3n-namesrv-plugin/namesrv-n2.conf << "EOF"
# namesrv config
bindAddress = 10.0.0.3
listenPort = 9876
enableControllerInNamesrv = true
# controller config
controllerDLegerGroup = group1
controllerDLegerPeers = n0-10.0.0.1:9877;n1-10.0.0.2:9877;n2-10.0.0.2:9877
controllerDLegerSelfId = n2
controllerStorePath = /opt/rocketmq/DledgerController
enableElectUncleanMaster = false
notifyBrokerRoleChanged = true
EOF

# broker config
cat > /opt/rocketmq/conf/controller/cluster-3n-namesrv-plugin/broker-n0.conf << "EOF"
enableControllerMode = true
controllerAddr = 10.0.0.1:9877;10.0.0.2:9877;10.0.0.3:9877
namesrvAddr = 10.0.0.1:9876;10.0.0.2:9876;10.0.0.3:9876
storePathEpochFile = /opt/rocketmq/store/node00
storePathCommitLog = /opt/rocketmq/store/node00/commitlog
allAckInSyncStateSet = true
listenPort = 30900
EOF
cat > /opt/rocketmq/conf/controller/cluster-3n-namesrv-plugin/broker-n1.conf << "EOF"
enableControllerMode = true
controllerAddr = 10.0.0.1:9877;10.0.0.2:9877;10.0.0.3:9877
namesrvAddr = 10.0.0.1:9876;10.0.0.2:9876;10.0.0.3:9876
storePathEpochFile = /opt/rocketmq/store/node01
storePathCommitLog = /opt/rocketmq/store/node01/commitlog
allAckInSyncStateSet = true
listenPort = 30901
EOF
```

#### Boot(systemd)
**Local Mode**
```bash
# namesrv
cat > /etc/systemd/system/rocketmq-namesrv.service << "EOF"
[Unit]
Description=Rocketmq
Documentation=https://rocketmq.apache.org/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/opt/rocketmq/bin/mqnamesrv
LimitNOFILE=655350
LimitNPROC=65535
NoNewPrivileges=yes
#PrivateTmp=yes
Restart=on-failure
RestartSec=10s
SuccessExitStatus=143
Type=simple
TimeoutStartSec=60
TimeoutStopSec=30
UMask=0077
User=rocketmq
Group=rocketmq
WorkingDirectory=/opt/rocketmq

[Install]
WantedBy=multi-user.target
EOF


# master
cat > /etc/systemd/system/rocketmq-master.service << "EOF"
[Unit]
Description=Rocketmq
Documentation=https://rocketmq.apache.org/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/opt/rocketmq/bin/mqbroker -c /opt/rocketmq/conf/2m-2s-sync/broker-m.properties
LimitNOFILE=655350
LimitNPROC=65535
NoNewPrivileges=yes
#PrivateTmp=yes
Restart=on-failure
RestartSec=10s
Type=simple
TimeoutStartSec=60
TimeoutStopSec=30
UMask=0077
User=rocketmq
Group=rocketmq
WorkingDirectory=/opt/rocketmq

[Install]
WantedBy=multi-user.target
EOF

# slave
cat > /etc/systemd/system/rocketmq-slave.service << "EOF"
[Unit]
Description=Rocketmq
Documentation=https://rocketmq.apache.org/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/opt/rocketmq/bin/mqbroker -c /opt/rocketmq/conf/2m-2s-sync/broker-s.properties
LimitNOFILE=655350
LimitNPROC=65535
NoNewPrivileges=yes
#PrivateTmp=yes
Restart=on-failure
RestartSec=10s
Type=simple
TimeoutStartSec=60
TimeoutStopSec=30
UMask=0077
User=rocketmq
Group=rocketmq
WorkingDirectory=/opt/rocketmq

[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload
systemctl start rocketmq-namesrv.service
systemctl start rocketmq-master.service
systemctl start rocketmq-slave.service
systemctl enable rocketmq-master.service
systemctl enable rocketmq-slave.service
systemctl enable rocketmq-namesrv.service
```

**Failover Mode**
```bash
# namesrv and controller
cat > /etc/systemd/system/rocketmq-namesrv.service << "EOF"
[Unit]
Description=Rocketmq
Documentation=https://rocketmq.apache.org/docs/
Wants=network-online.target
After=network-online.target

[Service]
# node1
ExecStart=/opt/rocketmq/bin/mqnamesrv -c /opt/rocketmq/conf/controller/cluster-3n-namesrv-plugin/namesrv-n0.conf
# node2
ExecStart=/opt/rocketmq/bin/mqnamesrv -c /opt/rocketmq/conf/controller/cluster-3n-namesrv-plugin/namesrv-n1.conf
# node3
ExecStart=/opt/rocketmq/bin/mqnamesrv -c /opt/rocketmq/conf/controller/cluster-3n-namesrv-plugin/namesrv-n2.conf
LimitNOFILE=655350
LimitNPROC=65535
NoNewPrivileges=yes
#PrivateTmp=yes
Restart=on-failure
RestartSec=10s
SuccessExitStatus=143
Type=simple
TimeoutStartSec=60
TimeoutStopSec=30
UMask=0077
User=rocketmq
Group=rocketmq
WorkingDirectory=/opt/rocketmq

[Install]
WantedBy=multi-user.target
EOF


# broker
cat > /etc/systemd/system/rocketmq-broker.service << "EOF"
[Unit]
Description=Rocketmq
Documentation=https://rocketmq.apache.org/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/opt/rocketmq/bin/mqbroker -c /opt/rocketmq/conf/controller/cluster-3n-namesrv-plugin/broker-n0.conf
LimitNOFILE=655350
LimitNPROC=65535
NoNewPrivileges=yes
#PrivateTmp=yes
Restart=on-failure
RestartSec=10s
Type=simple
TimeoutStartSec=60
TimeoutStopSec=30
UMask=0077
User=rocketmq
Group=rocketmq
WorkingDirectory=/opt/rocketmq

[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload
systemctl start rocketmq-namesrv.service
systemctl start rocketmq-broker.service
systemctl enable rocketmq-master.service
systemctl enable rocketmq-broker.service
```

### Verify
```bash
# set nameserver address
export NAMESRV_ADDR=localhost:9876

# produce 
./tools.sh org.apache.rocketmq.example.quickstart.Producer ; sleep 3
# consume
./tools.sh org.apache.rocketmq.example.quickstart.Consumer
```

### Troubleshooting
```bash
# problem 1
# 
```


## Deploy By Container
### Run On Docker
```bash
# pull image
docker pull apache/rocketmq:5.3.0

# start nameserver
docker run -it --net=host apache/rocketmq ./mqnamesrv

# start broker
docker run -it --net=host --mount source=/tmp/store,target=/home/rocketmq/store apache/rocketmq ./mqbroker -n localhost:9876
```

### Run On Kubernetes
```bash
# rocketmq operator
# https://artifacthub.io/packages/olm/community-operators/rocketmq-operator
```



> Reference:
> 1. [Official Website](https://rocketmq.apache.org/)
> 2. [Repository](https://github.com/apache/rocketmq)
