---
icon: wrench
description: Kernel record
---

# Kernel

## sysctl

/etc/sysctl.conf /etc/sysctl.d/\*.conf /proc/sys/...

```bash
# Controls the System Request debugging functionality of the kernel
kernel.sysrq = 0
# Controls whether core dumps will append the PID to the core filename.
# Useful for debugging multi-threaded applications.
kernel.core_uses_pid = 1
# Controls the default maxmimum size of a mesage queue
kernel.msgmnb = 65536
# # Controls the maximum size of a message, in bytes
kernel.msgmax = 65536
# Controls the maximum shared segment size, in bytes
kernel.shmmax = 68719476736
# Controls the maximum number of shared memory segments,in pages
kernel.shmall = 4294967296


# system open files
fs.file-max = 655350
#fs.nr_open = 655350


# Controls source route verification
net.ipv4.conf.default.rp_filter = 1
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.ip_forward = 1
# Do not accept source routing
net.ipv4.conf.default.accept_source_route = 0
# Controls the use of TCP syncookies
net.ipv4.tcp_syncookies = 1
# Disable netfilter on bridges.
net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-iptables = 0
net.bridge.bridge-nf-call-arptables = 0
# TCP kernel paramater
net.ipv4.tcp_mem = 786432 1048576 1572864
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_sack = 1     # SACK 方法 = 默认为1，开启
net.ipv4.tcp_dsack = 1    # D-SACK 方法 = 默认为1，开启
# socket buffer
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_abort_on_overflow = 0    # 全连接队列满时内核行为 = 0为丢弃，1为reset
net.core.somaxconn = 65535    # 全连接队列 = min(backlog, somaxconn)
net.core.optmem_max = 81920
# TCP conn
net.ipv4.tcp_max_syn_backlog = 262144    # 半连接队列 = (backlog, tcp_max_syn_backlog, somaxconn)
net.ipv4.tcp_timestamps = 0    # 启用 RFC1323 中定义的时间戳，0为禁用，1为启用且随机偏移时间戳，2为启用但不使用随机偏移
net.ipv4.tcp_tw_reuse = 0    # 允许内核重用处理 TIME_WAIT 状态的 TCP 连接
net.ipv4.tcp_tw_recycle = 0    # 4.12以上版本内核已移除
net.ipv4.tcp_fin_timeout = 1    # FIN_WAIT_2 TIME_WAIT 孤立连接状态超时时间
net.ipv4.tcp_max_tw_buckets = 180000   # TIME_WAIT 状态最大数量
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_syn_retries = 1    # SYN_SENT 状态 SYN 包重试次数
net.ipv4.tcp_synack_retries = 1    # SYN_RECV 状态 SYN+ACK 包重传次数
net.ipv4.tcp_syncookies = 1    # 不使用半连接队列建立连接 = 0为不开启，1为仅半连接队列满时启用，2为直接启用
# keepalive conn
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.ip_local_port_range = 10001 65000

# 拥塞算法
net.ipv4.tcp_allowed_congestion_control = reno cubic bbr
net.ipv4.tcp_available_congestion_control = reno cubic bbr
net.ipv4.tcp_congestion_control = bbr

# swap
vm.overcommit_memory = 0
vm.swappiness = 10   # default 60, 0 is donot swap memory
#net.ipv4.conf.eth1.rp_filter = 0
#net.ipv4.conf.lo.arp_ignore = 1
#net.ipv4.conf.lo.arp_announce = 2
#net.ipv4.conf.all.arp_ignore = 1
#net.ipv4.conf.all.arp_announce = 2


# effect config
sysctl -p /etc/sysctl.d/xxx.conf
```

## Others

### ulimit：fd dont enough

```bash
# user used fd
lsof -u $(whoami) | wc -l


# system open files
fs.file-max = 65535000


# cat /etc/security/limits.conf
#<domain>      <type>  <item>         <value>
# max number of processes
*        soft    noproc 655350
*        hard    noproc 655350
# max number of open file descriptors
*        soft    nofile 655350
*        hard    nofile 655350

```

### TIME\_WAIT: too mush connection state

```bash
# client 
# HTTP Headers，connection set to keep-alive，http/1.1 default os keep-alive
Connection: keep-alive

# server 端
net.ipv4.tcp_fin_timeout = 1 # 缩减 time_wait 时间，设置为1s
net.ipv4.tcp_max_tw_buckets = 180000   # TIME_WAIT 状态最大数量
# 允许内核重用处理 TIME_WAIT 状态的 TCP 连接，两个必须同时开启
net.ipv4.tcp_timestamps = 1    # 需要双方都启用
net.ipv4.tcp_tw_reuse = 1

```

### nf\_conntrack: table full, dropping packet

```bash
# conntrack bucket number and used memory
CONNTRACK_MAX = RAMSIZE (in bytes) / 16384 / (ARCH / 32)
size_of_mem_used_by_conntrack (in bytes) = CONNTRACK_MAX * sizeof(struct ip_conntrack) + HASHSIZE * sizeof(struct list_head)
sizeof(struct ip_conntrack) = 352
sizeof(struct list_head) = 2 * size_of_a_pointer（32 位系统的指针大小是 4 字节，64 位是 8 字节）

# 测试方法：压测工具不用 keep-alive 发请求，调大 nf_conntrack_tcp_timeout_time_wait，单机跑一段时间就能填满哈希表。观察响应时间的变化和服务器内存的使用情况。

sysctl -p /etc/sysctl.d/90-conntrack.conf
# select used conntrack count
sysctl net.netfilter.nf_conntrack_count

# select conntrack info: apt install conntrack
conntrack -L
ipv4     2 tcp      6 26 TIME_WAIT src=172.28.2.2 dst=172.30.10.16 sport=35998 dport=443 src=172.30.10.16 dst=172.28.2.2 sport=443 dport=35998 [ASSURED] mark=0 use=1
# 记录格式：
# 网络层协议名、网络层协议编号、传输层协议名、传输层协议编号、记录失效前剩余秒数、连接状态、
# 源地址、目标地址、源端口、目标端口： 第一次请求，第二次响应
# flag：
# [ASSURED]  请求和响应都有流量
# [UNREPLIED]  没收到响应，哈希表满的时候这些连接先扔掉
# network protocol
conntrack -L -o extended | awk '{sum[$1]++} END {for(i in sum) print i, sum[i]}'
# transport protocol
conntrack -L -o extended | awk '{sum[$3]++} END {for(i in sum) print i, sum[i]}'
# tcp state 
conntrack -L -o extended | awk '/^.*tcp.*$/ {sum[$6]++} END {for(i in sum) print i, sum[i]}'
# top 10 ip
conntrack -L -o extended | awk -F'[ =]+' '{print $8}' |sort |uniq -c |sort -rn |head


# kernel parameters
# nf_contrack bucket 
net.netfilter.nf_conntrack_buckets = 65536
echo 262144 | sudo tee /sys/module/nf_conntrack/parameters/hashsize
# conntrack number: buckets * 4
net.nf_conntrack_max=262144
net.netfilter.nf_conntrack_max = 262144

# tcp state timeout parameters
sysctl -a | grep nf_conntrack | grep timeout
net.netfilter.nf_conntrack_icmp_timeout = 10
net.netfilter.nf_conntrack_tcp_timeout_syn_sent = 5
net.netfilter.nf_conntrack_tcp_timeout_syn_recv = 5
net.netfilter.nf_conntrack_tcp_timeout_established = 7200
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 30
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 120
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 30
net.netfilter.nf_conntrack_tcp_timeout_last_ack = 30


# unconntrack
iptables -I INPUT 1 -m state --state UNTRACKED -j ACCEPT
# 不跟踪本地连接：nginx 与应用都在本机时收益明显
iptables -t raw -A PREROUTING -i lo -j NOTRACK
iptables -t raw -A OUTPUT -o lo -j NOTRACK
# 不跟踪其他端口连接
iptables -t raw -A PREROUTING -p tcp -m multiport --dports 80,443 -j NOTRACK
iptables -t raw -A OUTPUT -p tcp -m multiport --sports 80,443 -j NOTRACK


```

> https://testerhome.com/topics/15824

### ARP table

```bash
# arp table cache full
# kernel error message = arp_cache: neighbor table overflow!
net.ipv4.neigh.default.gc_thresh1 = 128    # 超过此阈值时按 gc_interval 定期启动回收
net.ipv4.neigh.default.gc_thresh2 = 512    # 超过此阈值每5s启动回收
net.ipv4.neigh.default.gc_thresh3 = 1024   # 立即回收 arp 表
net.ipv4.neigh.default.gc_interval = 30    # arp 表 gc 启动周期
net.ipv4.neigh.default.gc_stale_time = 60  # stale 状态过期时间

# 0 （默认）响应任意接口上接收到的对本机IP地址（包括 lo 网卡）的 arp 请求
# 1 仅当目标 IP 地址是传入接口上配置的本地地址时回复 arp 请求
# 2 仅当目标 IP 地址是传入接口上配置的本地地址，并且两者与发送者的 IP 地址属于该接口上的同一子网时回复 arp 请求
# 4-7 reserved
# 8 不回复任何 arp 请求
net.ipv4.conf.all.arp_ignore = 0
net.ipv4.conf.default.arp_ignore = 0

# 0 （默认）使用任意接口配置的任意地址发送 ARP 响应
# 1 发送 ARP 响应时，尽量使用本机所有接口上配置的 IP 地址中与目标 IP 在同一子网的地址作为源 IP 地址。如果没有这样的子网，根据级别2规则选择源地址
# 2 发送 ARP 响应时，使用本机所有接口上配置的 IP 地址中最接近目标 IP 的地址作为源 IP 地址。
net.ipv4.conf.all.arp_announce = 0             
net.ipv4.conf.default.arp_announce = 0


```
