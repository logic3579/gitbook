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
net.ipv4.tcp_sack = 1     # SACK method = default is 1, enabled
net.ipv4.tcp_dsack = 1    # D-SACK method = default is 1, enabled
# socket buffer
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_abort_on_overflow = 0    # kernel behavior when accept queue is full = 0 means drop, 1 means reset
net.core.somaxconn = 65535    # accept queue = min(backlog, somaxconn)
net.core.optmem_max = 81920
# TCP conn
net.ipv4.tcp_max_syn_backlog = 262144    # SYN backlog queue = (backlog, tcp_max_syn_backlog, somaxconn)
net.ipv4.tcp_timestamps = 0    # enable timestamps defined in RFC1323, 0 means disabled, 1 means enabled with random offset, 2 means enabled without random offset
net.ipv4.tcp_tw_reuse = 0    # allow kernel to reuse TCP connections in TIME_WAIT state
net.ipv4.tcp_tw_recycle = 0    # removed in kernel version 4.12 and above
net.ipv4.tcp_fin_timeout = 1    # timeout for orphaned connections in FIN_WAIT_2 and TIME_WAIT states
net.ipv4.tcp_max_tw_buckets = 180000   # maximum number of TIME_WAIT state connections
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_syn_retries = 1    # SYN packet retry count in SYN_SENT state
net.ipv4.tcp_synack_retries = 1    # SYN+ACK packet retransmission count in SYN_RECV state
net.ipv4.tcp_syncookies = 1    # establish connections without using SYN backlog queue = 0 means disabled, 1 means enabled only when SYN backlog queue is full, 2 means always enabled
# keepalive conn
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.ip_local_port_range = 10001 65000

# congestion control algorithm
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

# server side
net.ipv4.tcp_fin_timeout = 1 # reduce time_wait duration, set to 1s
net.ipv4.tcp_max_tw_buckets = 180000   # maximum number of TIME_WAIT state connections
# allow kernel to reuse TCP connections in TIME_WAIT state, both must be enabled together
net.ipv4.tcp_timestamps = 1    # must be enabled on both sides
net.ipv4.tcp_tw_reuse = 1

```

### nf\_conntrack: table full, dropping packet

```bash
# conntrack bucket number and used memory
CONNTRACK_MAX = RAMSIZE (in bytes) / 16384 / (ARCH / 32)
size_of_mem_used_by_conntrack (in bytes) = CONNTRACK_MAX * sizeof(struct ip_conntrack) + HASHSIZE * sizeof(struct list_head)
sizeof(struct ip_conntrack) = 352
sizeof(struct list_head) = 2 * size_of_a_pointer (pointer size is 4 bytes on 32-bit systems, 8 bytes on 64-bit)

# Testing method: use a load testing tool to send requests without keep-alive, increase nf_conntrack_tcp_timeout_time_wait, run on a single machine for a period of time to fill up the hash table. Observe changes in response time and server memory usage.

sysctl -p /etc/sysctl.d/90-conntrack.conf
# select used conntrack count
sysctl net.netfilter.nf_conntrack_count

# select conntrack info: apt install conntrack
conntrack -L
ipv4     2 tcp      6 26 TIME_WAIT src=172.28.2.2 dst=172.30.10.16 sport=35998 dport=443 src=172.30.10.16 dst=172.28.2.2 sport=443 dport=35998 [ASSURED] mark=0 use=1
# record format:
# network layer protocol name, network layer protocol number, transport layer protocol name, transport layer protocol number, seconds remaining before record expires, connection state,
# source address, destination address, source port, destination port: first is the request, second is the response
# flags:
# [ASSURED]  traffic seen in both request and response directions
# [UNREPLIED]  no response received, these connections are dropped first when hash table is full
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
# do not track local connections: significant benefit when nginx and the application are on the same machine
iptables -t raw -A PREROUTING -i lo -j NOTRACK
iptables -t raw -A OUTPUT -o lo -j NOTRACK
# do not track connections on other ports
iptables -t raw -A PREROUTING -p tcp -m multiport --dports 80,443 -j NOTRACK
iptables -t raw -A OUTPUT -p tcp -m multiport --sports 80,443 -j NOTRACK


```

> https://testerhome.com/topics/15824

### ARP table

```bash
# arp table cache full
# kernel error message = arp_cache: neighbor table overflow!
net.ipv4.neigh.default.gc_thresh1 = 128    # start periodic garbage collection per gc_interval when exceeding this threshold
net.ipv4.neigh.default.gc_thresh2 = 512    # start garbage collection every 5s when exceeding this threshold
net.ipv4.neigh.default.gc_thresh3 = 1024   # immediately garbage collect the arp table
net.ipv4.neigh.default.gc_interval = 30    # arp table gc cycle interval
net.ipv4.neigh.default.gc_stale_time = 60  # stale state expiration time

# 0 (default) respond to arp requests for any local IP address (including lo interface) received on any interface
# 1 only reply to arp requests when the target IP address is a local address configured on the incoming interface
# 2 only reply to arp requests when the target IP address is a local address configured on the incoming interface, and both the target and sender IP addresses belong to the same subnet on that interface
# 4-7 reserved
# 8 do not reply to any arp requests
net.ipv4.conf.all.arp_ignore = 0
net.ipv4.conf.default.arp_ignore = 0

# 0 (default) send ARP responses using any address configured on any interface
# 1 when sending ARP responses, prefer using an IP address configured on any local interface that is in the same subnet as the target IP. If no such subnet exists, select the source address based on level 2 rules
# 2 when sending ARP responses, use the IP address configured on any local interface that is closest to the target IP as the source IP address.
net.ipv4.conf.all.arp_announce = 0             
net.ipv4.conf.default.arp_announce = 0


```
