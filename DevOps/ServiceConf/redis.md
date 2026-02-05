# Redis

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

