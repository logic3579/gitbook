---
description: MongoDB
tags:
  - cncf/app-definition
  - database
---

# MongoDB

## Introduction

MongoDB is an open-source, document-oriented NoSQL database that stores data as flexible, JSON-like BSON documents. It supports rich queries, secondary indexes, aggregation pipelines, and horizontal scaling through sharding and replica sets, making it a popular choice for content management, IoT, and real-time analytics workloads.

## How to Install

### Starting via Binary
#### Quick Start
```bash
# dependencies
apt install python3-pip
apt install python-dev-is-python3 libssl-dev
apt install build-essential

# download source
git clone -b r6.0.1 https://github.com/mongodb/mongo.git
cd mongo

# compile 
python3 -m pip install -r etc/pip/compile-requirements.txt
python3 buildscripts/scons.py DESTDIR=/opt/mongo install-all

# postinstallation
# groupadd mongodb
# useradd -r -g mongodb -s /bin/false mongodb
mkdir /opt/mongodb/data /opt/mongodb/logs
# chown mongodb:mongodb /opt/mongodb -R

# startup 
/opt/mongodb/bin/mongod --dbpath /opt/mongodb --logpath /opt/mongodb/logs/mongod.log --fork #--config /opt/mongodb/mongod.conf --bind_ip 0.0.0.0

```

#### Config and Boot
##### Config

**/etc/mongod.conf**

```yaml
# mongod.conf
storage:
  dbPath: /opt/mongodb/data
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /opt/mongodb/logs/mongod.log

net:
  port: 27017
  bindIp: 127.0.0.1

processManagement:
  timeZoneInfo: /usr/share/zoneinfo
  fork: true
  pidFilePath: /opt/mongodb/logs/mongod.pid

# security:
#   authorization: enabled

# replication:
#   replSetName: rs0
```

##### Boot(systemd)

```bash
# boot
cat > /etc/systemd/system/mongod.service << "EOF"
[Unit]
Description=MongoDB Database Server
Documentation=https://docs.mongodb.org/manual
After=network-online.target
Wants=network-online.target

[Service]
User=mongodb
Group=mongodb
EnvironmentFile=-/etc/default/mongod
Environment="MONGODB_CONFIG_OVERRIDE_NOFORK=1"
ExecStart=/usr/bin/mongod --config /etc/mongod.conf
RuntimeDirectory=mongodb
# file size
LimitFSIZE=infinity
# cpu time
LimitCPU=infinity
# virtual memory size
LimitAS=infinity
# open files
LimitNOFILE=64000
# processes/threads
LimitNPROC=64000
# locked memory
LimitMEMLOCK=infinity
# total threads (user+kernel)
TasksMax=infinity
TasksAccounting=false

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start mongod.service
systemctl enable mongod.service
```

#### Verify
```bash
# syntax check

```

#### Troubleshooting
```bash
# problem 1
# Cannot find system library 'lzma' required for use with libunwind
apt install liblzma-dev

# problem 2
# Checking for curl_global_init(0) in C library curl... no
# Could not find <curl/curl.h> and curl lib
apt install libcurl4-openssl-dev

```


### Starting via Docker
```bash
# WARNING: MongoDB 5.0+ requires a CPU with AVX support, and your current system does not appear to have that!
cat /proc/cpuinfo |grep flags |grep avx
docker pull mongo:4.4.23

# pull image
docker pull mongodb/mongodb-community-server

# run
docker run --name mongo -d mongodb/mongodb-community-server:latest

# test
docker exec -it mongo mongosh
```

### Starting via Kubernetes
```bash
# add and update repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm update

# get charts package
helm pull bitnami/mongodb --untar
cd mongodb

# configure and run
vim values.yaml
...
helm -n middleware install mongodb .

```


> Reference:
>
> 1. [Official Website](https://www.mongodb.com/docs/manual/administration/install-on-linux/)
> 2. [Repository](https://github.com/mongodb/mongo)
> 3. [APT Installation Method](https://www.postgresql.org/download/linux/ubuntu/)
