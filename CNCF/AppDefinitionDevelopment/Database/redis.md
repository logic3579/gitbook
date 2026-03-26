---
description: Memory Database Redis
tags:
  - cncf/app-definition
  - database
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
[Redis Command](/DevOps/CommandManual/database.md#redis)

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



## Configuration Reference

**/opt/redis/redis.conf**

```bash
################################## MODULES #####################################
# loadmodule /path/to/my_module.so

################################## NETWORK #####################################
bind 127.0.0.1 -::1
protected-mode yes
port 6379
# Half-open connection queue size, takes the minimum of this and the OS configuration
tcp-backlog 511
timeout 0
tcp-keepalive 300

################################# TLS/SSL #####################################

################################# GENERAL #####################################
daemonize yes
pidfile ./redis.pid
loglevel notice
logfile ./redis.log
databases 16
always-show-logo no
set-proc-title yes
proc-title-template "{title} {listen-addr} {server-mode}"

################################ SNAPSHOTTING  ################################
# save <seconds> <changes> [<seconds> <changes> ...]
# save ""
save 3600 1 300 100 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
rdb-del-sync-files no
dir /opt/redis

################################# REPLICATION #################################
# replicaof <masterip> <masterport>
# masterauth <master-password>
replica-serve-stale-data yes
replica-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-diskless-sync-max-replicas 0
repl-diskless-load disabled
repl-disable-tcp-nodelay no
replica-priority 100

############################### KEYS TRACKING #################################

################################## SECURITY ###################################
acllog-max-len 128
# aclfile /etc/redis/users.acl
# Password setting, compatible with Redis 6 and above
requirepass foobared
# Command renaming (DEPRECATED)
rename-command FLUSHALL ""
rename-command FLUSHDB  ""
rename-command CONFIG   ""
rename-command SHUTDOWN ""
rename-command KEYS     ""

################################### CLIENTS ####################################
# maxclients 10000

############################## MEMORY MANAGEMENT ################################
# maxmemory <bytes>
# maxmemory-policy noeviction

############################# LAZY FREEING ####################################
lazyfree-lazy-eviction no
lazyfree-lazy-expire no
lazyfree-lazy-server-del no
replica-lazy-flush no
lazyfree-lazy-user-del no
lazyfree-lazy-user-flush no

################################ THREADED I/O #################################
# io-threads 4

############################ KERNEL OOM CONTROL ##############################
oom-score-adj no
oom-score-adj-values 0 200 800

#################### KERNEL transparent hugepage CONTROL ######################
disable-thp yes

############################## APPEND ONLY MODE ###############################
appendonly yes
appendfilename "appendonly.aof"
appenddirname "appendonlydir"
# appendfsync always/everysec/no
appendfsync everysec
# Whether to sync during AOF rewrite
no-appendfsync-on-rewrite no
# Rewrite trigger mechanism
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
# Behavior on AOF load error: log and continue / abort
aof-load-truncated yes
aof-use-rdb-preamble yes
aof-timestamp-enabled no

################################ SHUTDOWN #####################################
# shutdown-timeout 10

################ NON-DETERMINISTIC LONG BLOCKING COMMANDS #####################
# lua-time-limit 5000
# busy-reply-threshold 5000

################################ REDIS CLUSTER  ###############################
cluster-enabled yes
# cluster-config-file nodes-6379.conf
cluster-node-timeout 15000
# cluster-port 0

########################## CLUSTER DOCKER/NAT support  ########################
# cluster-announce-ip 10.1.1.5
# cluster-announce-tls-port 6379
# cluster-announce-port 0
# cluster-announce-bus-port 6380

################################## SLOW LOG ###################################
slowlog-log-slower-than 10000
slowlog-max-len 128

################################ LATENCY MONITOR ##############################
latency-monitor-threshold 0

################################ LATENCY TRACKING ##############################
# latency-tracking yes
# latency-tracking-info-percentiles 50 99 99.9

############################# EVENT NOTIFICATION ##############################
notify-keyspace-events ""

############################### ADVANCED CONFIG ###############################
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
stream-node-max-bytes 4096
stream-node-max-entries 100
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
dynamic-hz yes
# Whether AOF file rewrite incremental fsync strategy is enabled
aof-rewrite-incremental-fsync yes
# Whether RDB incremental fsync on auto-trigger is enabled
rdb-save-incremental-fsync yes

########################### ACTIVE DEFRAGMENTATION #######################
jemalloc-bg-thread yes
```

> Reference:
>
> 1. [Official Website](https://redis.io/docs/getting-started/)
> 2. [Repository](https://github.com/redis/redis)
> 3. [Redis Download Releases](https://download.redis.io/releases/)
> 4. [Redis Cluster Solutions](https://segmentfault.com/a/1190000022028642)
