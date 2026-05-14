---
description: Network diagnostic and testing tools for reachability, interface, sockets, capture, HTTP, and DNS
tags:
  - devops/command
  - networking
---

# Network Tools

## Reachability

### ping

```bash
# default
ping example.com
ping -c 4 example.com                    # send 4 then exit
ping -i 0.2 -c 100 -q example.com        # 0.2s interval, quiet summary
ping -s 1472 -M do example.com           # path MTU probe (1472 + 28 = 1500)
ping6 example.com                        # IPv6
```

### traceroute && mtr

```bash
# install
apt install traceroute mtr-tiny

# classic UDP traceroute / ICMP / TCP
traceroute example.com
traceroute -I example.com                # use ICMP (closer to ping)
traceroute -T -p 443 example.com         # TCP to a specific port

# mtr = ping + traceroute (best for jitter/loss diagnosis)
mtr example.com
mtr -rwc 100 example.com                 # report mode, wide, 100 cycles
mtr -T -P 443 example.com                # TCP probe
```

### arp && arping

```bash
# install (Debian/Ubuntu)
apt install net-tools arping

# select arp table
arp -ne
# -e   display (all) hosts in default (Linux) style
# -n   don't resolve names

# arping
arping 192.168.1.100
# -c count   -i interface   -s MAC   -S IP

# observe with tcpdump
tcpdump -ttttnvvvS -i ens160 arp
```

### hping3 && tcping

```bash
# hping3
apt install hping3
# (or docker.io/utkudarilmaz/hping3)

# imitate syn flood
hping3 -S -p 8877 --flood 127.0.0.1

# multicast
hping3 -1 224.0.0.8 -a 10.0.0.1 -c 10 -i u1000000

# tcping (TCP-port ping)
docker pull pouriyajamshidi/tcping            # DockerHub
docker pull ghcr.io/pouriyajamshidi/tcping    # GitHub container registry
```

## Interface & NIC

### ip

```bash
# apt install iproute2

# inspect
ip route ls
ip addr ls
ip link ls

# add ip to tun0
ip addr add 172.31.0.1/24 dev tun0
ip link set tun0 up
```

### Namespace

```bash
# list / add
ip netns list
ip netns add net-test1                       # appears under /var/run/netns/

# exec in netns
ip netns exec net-test1 ip addr
# ip netns exec ns1 /bin/bash --rcfile <(echo "PS1=\"namespace net-test1> \"")
ip netns exec net-test1 ip link set lo up
```

### veth Pair Example

```bash
# host
ip link add br0 type bridge
ip link set dev br0 up
ip netns add net0
ip netns add net1
ip link add veth-a0 type veth peer name veth-net0
ip link set dev veth-net0 master br0
ip link set dev veth-net0 up
ip link add veth-b0 type veth peer name veth-net1
ip link set dev veth-net1 master br0
ip link set dev veth-net1 up

# net0
ip link set dev veth-a0 netns net0
ip netns exec net0 ip link set dev veth-a0 name eth0
ip netns exec net0 ip addr add 10.0.1.2/24 dev eth0
ip netns exec net0 ip link set dev eth0 up

# net1
ip link set dev veth-b0 netns net1
ip netns exec net1 ip link set dev veth-b0 name eth0
ip netns exec net1 ip addr add 10.0.1.3/24 dev eth0
ip netns exec net1 ip link set dev eth0 up

# verify
ip netns exec net0 ping -c 3 10.0.1.3
```

### ethtool

```bash
# install
apt install ethtool

# link, speed, duplex
ethtool eth0

# driver, firmware
ethtool -i eth0

# ring buffer (rx/tx) sizes — common throughput tuning point
ethtool -g eth0
ethtool -G eth0 rx 4096 tx 4096

# offload (TSO/GSO/GRO/LRO)
ethtool -k eth0
ethtool -K eth0 gro off

# NIC statistics (drops, errors, csum)
ethtool -S eth0 | grep -E 'drop|error|discard'
```

## Sockets & Connections

### netstat && ss

```bash
# netstat (legacy, net-tools)
apt install net-tools
# count all tcp state
netstat -tna | awk '/tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}'

# ss (modern, iproute2)
apt install iproute2
ss -na | awk '/tcp/ {++S[$2]} END {for(a in S) print a, S[a]}'

# all tcp connections with process
ss -tnap

# listening sockets only
ss -tlnp
ss -ulnp                                     # UDP

# socket-level details (cwnd, rto, retrans)
ss -tni

# force-kill matching TCP connection
ss -K dst 1.1.1.1 dport = 57156
```

### lsof (Network)

```bash
# all sockets
lsof -i

# specific port / protocol
lsof -i :443
lsof -iTCP -sTCP:LISTEN

# all sockets of a process
lsof -i -a -p <PID>
```

### tcpkill

```bash
apt install dsniff

tcpkill -i <interface> host <destination_ip> and port <destination_port>
# example
tcpkill -i lo host 127.0.0.1 and port 8080
```

## Traffic Generation

### nc && netcat

```bash
apt install netcat-openbsd

# listen + echo each request
nc -l 9999 -k -c 'xargs -n1 echo'

# raw HTTP POST
echo -e "POST /post HTTP/1.1\r\nHost: httpbin.org\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: 7\r\n\r\na=1&b=2\r\n" | nc 172.22.3.29 8877

# scan a TCP port (quick reachability)
nc -zv example.com 443
```

### wscat

```bash
# install
npm install -g wscat

wscat -c ws://api.example.com/ws
wscat -c wss://api.example.com/ws --no-check
```

### iperf3

```bash
# install
apt install iperf3

# server
iperf3 -s

# client (TCP)
iperf3 -c <server>
iperf3 -c <server> -P 8 -t 30                 # 8 parallel streams, 30s

# UDP at target bitrate
iperf3 -c <server> -u -b 1G
```

## Packet Capture

### tcpdump

```bash
# install
apt install tcpdump
```

#### Common Options

```
-i iface          listen on interface
-n                don't resolve names / ports
-S                absolute TCP sequence numbers
-v / -vv / -vvv   verbosity levels
-w file           write raw packets to pcap
-r file           read packets from pcap

# timestamp formats
-t                omit timestamp
-tt               seconds since epoch
-ttt              delta from previous line (μs)
-tttt             date + HH:MM:SS.fraction
-ttttt            delta from first line (μs)
```

#### Capture Rotation

```bash
# rotate every 100M, keep 20 files
tcpdump -i eth0 port 8880 -w cvm.pcap -C 100 -W 20

# rotate every 120s, suffix with timestamp
tcpdump -i eth0 port 31780 -w node-%Y-%m%d-%H%M-%S.pcap -G 120
```

#### Filter Expressions

```bash
# protocol
tcpdump [ip|icmp|tcp|udp|proto 112]
tcpdump 'tcp[tcpflags] & (tcp-syn|tcp-fin) != 0'
tcpdump -i ens4 -nStttv icmp and src 1.1.1.1

# source / destination ip
tcpdump src 1.1.1.1 or dst 1.1.1.1

# port
tcpdump not port 80

# filter only RST packets from a pcap
tcpdump -r test.pcap 'tcp[tcpflags] & (tcp-rst) != 0' -nttt

# kitchen sink
tcpdump -i eth0 -nStttvvv src 1.1.1.1 or dst 1.1.1.1 and port 80
```

### tshark

```bash
# install (wireshark CLI)
apt install tshark

# capture with display filter
tshark -i eth0 -f 'port 443'

# read pcap and extract fields
tshark -r capture.pcap -Y 'http' -T fields -e ip.src -e http.host -e http.request.uri

# follow a TCP stream
tshark -r capture.pcap -q -z follow,tcp,ascii,0
```

## Bandwidth & Traffic

### iftop

```bash
# iftop -h
# -n             no DNS lookups
# -N             no service name lookups
# -i iface       listen on named interface
# -t             text interface, no ncurses
# -o 2s/10s/40s  sort by traffic-average column
# -o source/destination  sort by address
# -s num         (with -t) print one snapshot after num seconds
# -L num         number of lines

# common
iftop -nN -i ens4 -o 10s
iftop -nN -s 5 -t
iftop -nN -L 5 -t
iftop -F 192.168.1.0/24
```

iftop keyboard reference (interactive):

```
Host:                                  General:
 n  toggle DNS                          P  pause
 s  toggle source host                  h  toggle help
 d  toggle destination host             b  bar graph
 t  cycle line mode                     B  cycle bar average
                                        T  cumulative line totals
Port:                                   j/k  scroll
 N  toggle service resolution           f  edit filter
 S  toggle source port                  l  screen filter
 D  toggle destination port             L  lin/log scales
 p  toggle port display                 !  shell command
                                        q  quit
Sort:
 1/2/3  sort by 1st/2nd/3rd column
 < / >  sort by source / dest name
 o      freeze order
```

### sar (Network)

```bash
# install
apt install sysstat

# per-device traffic
sar -n DEV 1 10

# socket statistics
sar -n SOCK 1 10

# TCP / UDP / ICMP / IP
sar -n TCP 1 10
sar -n UDP 1 10
sar -n ICMP 1 10
sar -n IP 1 10
```

## HTTP

### ab && wrk

```bash
# install ab
apt install apache2-utils

# ab
ab -n 1000 -c 100 http://www.baidu.com

# wrk (https://github.com/wg/wrk)
# -t threads  -c connections  -d duration
wrk -t 100 -c 10000 -d 30 --latency http://www.google.com/
```

### curl

```bash
# UserAgent
curl -A 'chrome' https://example.com

# Cookie
curl -b 'foo=bar' https://example.com
curl -c cookie.txt https://example.com

# HTTP POST data
curl -d 'username=abc' -X POST https://example.com/login
curl -d '@data.txt' -X POST https://example.com/login
curl -d '{"username":"abc"}' -H 'Content-Type: application/json' -X POST https://example.com/login
curl --data-binary 'msg=hello wordld' https://example.com/login      # transfer binary data
curl --data-raw 'msg=hello wordld' https://example.com/login         # transfer original data
curl --data-urlencode 'msg=hello wordld' https://example.com/login   # URL Encode data

# HTTP Referer
curl -e 'https://google.com?q=example' https://example.com
curl -H'Referer: https://google.com?q=example' https://example.com

# HTTP GET data
curl -G -d 'q=query' -d 'count-10' https://example.com/search

# HTTP Header
curl -H'Accept-Language: en-US' -H 'Content-Type: application/json' https://example.com

# HTTP HEAD request
curl -I https://example.com

# Skip SSL check
curl -k https://example.com

# Follow redirect
curl -L https://example.com

# Limit rate
curl --limit-rate 200k https://example.com

# Save to file
curl -o example.html https://example.com
curl -O https://example.com/foo/bar.html

# Silence
curl -s https://example.com
curl -S https://example.com    # only error msg

# Server user and password
curl -u 'user:pwd' https://example.com/login
curl -H'Authorization: Basic cHdkCg==' https://example.com/login
curl https://user:pwd@example.com/login

# Verbose info
curl -v https://example.com
curl --trace https://example.com

# HTTP proxy
curl -x [protocol://]host[:port] https://example.com
curl -x socks5://user:pwd@myproxy.com:8080 https://example.com

# HTTP method
curl -X [GET|POST|PUT|DELETE|OPTIONS] https://example.com
```

#### curl Examples

```bash
# 304 response
curl https://cdn.example.com/ -H'if-modified-since: Mon, 1 Jan 2024 00:00:00 GMT' -i
curl https://cdn.example.com/ -H'if-none-match: "xxx123-xxx456"' -i

# check tls max version
curl https://google.com -kv --tlsv1 --tls-max 1.0
curl https://google.com -kv --tlsv1.3 --tls-max 1.3

# resolve IP override (bypass local DNS)
curl https://google.com --resolve google.com:443:1.1.1.1 -v

# inspect tls certificate
openssl s_client -servername your.domain.com -connect 127.0.0.1:443

# mock websocket upgrade
curl http://127.0.0.1:9999 \
  -H'Upgrade: websocket' -H'Connection: Upgrade' \
  -H'Sec-WebSocket-Key: eeZn6lg/rOu8QbKwltqHDA==' -H'Sec-WebSocket-Version: 13'

# timing breakdown
curl -L -w "time_namelookup: %{time_namelookup}\ntime_connect: %{time_connect}\ntime_appconnect: %{time_appconnect}\ntime_pretransfer: %{time_pretransfer}\ntime_redirect: %{time_redirect}\ntime_starttransfer: %{time_starttransfer}\ntime_total: %{time_total}\n" \
  https://example.com/
```

## DNS

### dig

```bash
# normal query
dig www.google.com
dig -t ns www.google.com
dig -t cname www.google.com

# query from root (full delegation trace)
dig +trace www.google.com

# only IP / only answer section
dig +short www.google.com
dig +noall +answer www.google.com

# query a specific resolver
dig www.google.com @8.8.8.8

# reverse lookup
dig -x 8.8.8.8

# get local resolver public IP (akamai's whoami)
dig +short TXT whoami.ds.akahelp.net
# "ns"  "123.126.xx.xx"     egress IP used by local resolver
# "ecs" "120.52.xx.xx/32/24" EDNS client subnet sent in query
# "ip"  "123.126.xx.xx"     authoritative-side view of client

# query with explicit EDNS client subnet
dig www.google.com +subnet=1.1.1.0/24
```

### nslookup && host

```bash
# nslookup (interactive friendly)
nslookup example.com
nslookup -type=mx example.com 8.8.8.8

# host (simple one-liner)
host example.com
host -t aaaa example.com
host -a example.com                       # all records
```

## Kernel Tracing

### watch /proc/softirqs

```bash
# monitor soft interrupt rate per CPU
watch -d cat /proc/softirqs
watch -d 'grep -E "^(NET_RX|NET_TX)" /proc/softirqs'

# hardware interrupts
watch -d cat /proc/interrupts
```

### /proc/net

```bash
# TCP state counters
cat /proc/net/sockstat
cat /proc/net/netstat

# per-protocol counters (drops, retransmits, etc.)
nstat -a
```

### systemtap (Network Probes)

```bash
# install
apt install systemtap

# hello world
tee helloworld.stp << "EOF"
probe begin
{
  print ("hello world\n")
  exit ()
}
EOF
stap helloworld.stp

# observe outgoing connect() syscalls to specific ports
tee tcp.stp << "EOF"
#!/usr/bin/env stap
probe syscall.connect {
  if (uaddr_ip_port == "443") {
    printf("ip: %s port: %s cmd: %s pid: %d ppid: %d\n",
           uaddr_ip, uaddr_ip_port, execname(), pid(), ppid())
  }
  if (uaddr_ip_port == "1521") {
    printf("Time:%s remote_ip:%s remote_port:%s local_cmd:%s pid:%d local_pcmd:%s ppid:%d euid:%d egid:%d env_PWD:%s\n",
           tz_ctime(gettimeofday_s()), uaddr_ip, uaddr_ip_port,
           execname(), pid(), pexecname(), ppid(), euid(), egid(), env_var("PWD"))
  }
}
EOF
stap -v tcp.stp

# observe signals sent to a target PID (e.g. find who killed the container)
tee sg.stp << "EOF"
global target_pid = 7942
probe signal.send {
  if (sig_pid == target_pid) {
    printf("%s(%d) send %s to %s(%d)\n", execname(), pid(), sig_name, pid_name, sig_pid)
    printf("parent of sender: %s(%d)\n", pexecname(), ppid())
    printf("task_ancestry:%s\n", task_ancestry(pid2task(pid()), 1))
  }
}
EOF
stap -v sg.stp
```

> Reference:
>
> 1. [curl Manual](https://curl.se/docs/manpage.html)
> 2. [tcpdump Manual](https://www.tcpdump.org/manpages/tcpdump.1.html)
> 3. [iproute2](https://wiki.linuxfoundation.org/networking/iproute2)
> 4. [ethtool](https://www.kernel.org/pub/software/network/ethtool/)
> 5. [iperf3](https://iperf.fr/)
> 6. [mtr](https://github.com/traviscross/mtr)
> 7. [systemtap](https://sourceware.org/systemtap/documentation.html)
