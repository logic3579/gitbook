---
description: Memory Database Redis
---

# Redis

## Introduction
...


## Deploy By Binary
### Quick Start
```bash
# dependencies
apt install pkgconf libsystemd-dev

# download source code
cd /usr/local/src/
#wget https://download.redis.io/redis-stable.tar.gz
#tar -xzvf redis-stable.tar.gz && cd redis-stable
wget https://download.redis.io/releases/redis-7.0.11.tar.gz
tar -xzvf redis-7.0.11.tar.gz && cd redis-7.0.11

# compile and install
make MALLOC=jemalloc USE_SYSTEMD=yes
make test
make PREFIX=/opt/redis-7.0.11/ install

# soft link
ln -svf /opt/redis-7.0.11 /opt/redis
cd /opt/redis

# start redis server
## 1. single mode
cp /usr/local/src/redis-7.0.11/redis.conf /opt/redis/redis.conf
/opt/redis/bin/redis-server /opt/redis/redis.conf
## 2. fake cluster mode
mkdir -p /opt/redis/{7001..7003}
cp /usr/local/src/redis-7.0.11/redis.conf /opt/redis/7001/redis.conf && cp /usr/local/src/redis-7.0.11/redis.conf /opt/redis/7002/redis.conf && cp /usr/local/src/redis-7.0.11/redis.conf /opt/redis/7003/redis.conf
./bin/redis-server /opt/redis/7001/redis.conf --bind 127.0.0.1 --port 7001 --daemonize yes --pidfile ./redis.pid --logfile ./redis.log --dir /opt/redis/7001 --cluster-enabled yes
./bin/redis-server /opt/redis/7002/redis.conf --bind 127.0.0.1 --port 7002 --daemonize yes --pidfile ./redis.pid --logfile ./redis.log --dir /opt/redis/7002 --cluster-enabled yes
./bin/redis-server /opt/redis/7003/redis.conf --bind 127.0.0.1 --port 7003 --daemonize yes --pidfile ./redis.pid --logfile ./redis.log --dir /opt/redis/7003 --cluster-enabled yes
./bin/redis-cli --cluster create 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 --cluster-replicas 0 --cluster-yes
```

### Config and Boot
#### Config
```bash
# single mode && cluster mode
cat > /opt/redis/redis.conf << "EOF"
bind 127.0.0.1 -::1
port 6379
pidfile ./redis.pid
logfile ./redis.log
dir /opt/redis
...
cluster-enabled yes   # only cluster mode config
EOF

# fake cluster mode
# node1: /opt/redis/7001/redis.conf
port 7001
pidfile ./7001/redis.pid
logfile ./7001/redis.log
dir /opt/redis/7001
# node2: /opt/redis/7002/redis.conf
port 7002
pidfile ./7002/redis.pid
logfile ./7002/redis.log
dir /opt/redis/7002
# node3: /opt/redis/7003/redis.conf
port 7003
pidfile ./7003/redis.pid
logfile ./7003/redis.log
dir /opt/redis/7003
EOF
```

#### Boot(systemd)
```bash
cat > /etc/systemd/system/redis.service << "EOF"
[Unit]
Description=Redis data structure server
Documentation=https://redis.io/documentation
Wants=network-online.target
After=network-online.target

[Service]
# single mode && cluster mode
ExecStart=/opt/redis/bin/redis-server /opt/redis/redis.conf --supervised systemd --daemonize no
# fake cluster mode
# ExecStart=/opt/redis/bin/redis-server /opt/redis/7001/redis.conf --supervised systemd --daemonize no
# ExecStart=/opt/redis/bin/redis-server /opt/redis/7002/redis.conf --supervised systemd --daemonize no
# ExecStart=/opt/redis/bin/redis-server /opt/redis/7003/redis.conf --supervised systemd --daemonize no
LimitNOFILE=655350
LimitNPROC=65535
NoNewPrivileges=yes
#PrivateTmp=yes
Restart=on-failure
RestartSec=10s
Type=notify
TimeoutStartSec=infinity
TimeoutStopSec=infinity
UMask=0077
User=redis
Group=redis
WorkingDirectory=/opt/redis

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start redis.service
systemctl enable redis.service
```

### Verify
[Redis Command](/DevOps/CommandManual/Database.md#redis)

### Troubleshooting
```bash
# ../deps/jemalloc/lib/libjemalloc.a: No such file or directory
apt install libjemalloc-dev

# server.h:57:10: fatal error: systemd/sd-daemon.h: No such file or directory
apt install libsystemd-dev
```

## Deploy By Container
### Run On Docker
```bash
# Standlone
docker run --rm --name redis \
  -e REDIS_PASSWORD=redis_password \
  -p 6379:6379 \
  -v /docker-volume/data:/data \
  -d redis

# Cluster
docker run --rm --name redis-cluster \
  -e ALLOW_EMPTY_PASSWORD=yes \
  -d bitnami/redis-cluster
```

### Run On Kubernetes
```bash
# add and update repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm update

# get charts package
# single mode
helm pull bitnami/redis --untar
# cluster mode
helm pull bitnami/redis-cluster --untar

# configure and run
vim values.yaml
global:
  storageClass: "xxx"
  redis:
    password: "xxx"
# single mode config
architecture: standalone
master:
  disableCommands:
    - FLUSHDB
    - FLUSHALL
    - CONFIG
    - SHUTDOWN
    - KEYS
# cluster mode config
cluster:
  nodes: 3
  replicas: 0
vim templates/configmap.yaml
data:
  redis-default.conf: |-
    rename-command FLUSHALL ""
    rename-command FLUSHDB  ""
    rename-command CONFIG   ""
    rename-command SHUTDOWN ""
    rename-command KEYS     ""
...

# install
helm -n middleware install redis .
helm -n middleware install redis-cluster .

# verify
kubectl -n middleware get secret uat-redis-cluster -o jsonpath="{.data.redis-password}" | base64 -d
kubectl -n middleware get service |grep redis
```



> Reference:
> 1. [Official Website](https://redis.io/docs/getting-started/)
> 2. [Repository](https://github.com/redis/redis)
> 3. [Redis Download Releases](https://download.redis.io/releases/)
> 4. [Redis Cluster Solutions](https://segmentfault.com/a/1190000022028642)
