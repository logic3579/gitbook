---
description: HAProxy Load Balancer's development branch (mirror of git.haproxy.org)
icon: icon
---

# Overview

## Introduction

...

## Deploy By Binary

### Quick Start

```bash
apt install haproxy
# yum install haproxy

systemctl start haproxy.service
```

### Config and Boot

#### Config

```bash
# options: install and config keepalived
apt install keepalived
cat > /etc/keepalived/keepalived.conf << "EOF"
global_defs {
    router_id LVS_MASTER
    # router_id LVS_BACKUP
    script_user root
    enable_script_security
}

vrrp_script haproxy_check {
    script "/etc/keepalived/haproxy_check.sh"
    interval 2
    weight -20
    fall 2
    rise 2
}

vrrp_instance VI_1 {
    state MASTER
    # state BACKUP
    interface eth0
    virtual_router_id 51
    priority 100
    # priority 90
    advert_int 1
    # unicast_src_ip 10.10.0.2
    # unicast_peer {
    #     10.10.0.3
    # }
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        10.10.0.250
    }
    track_script {
        haproxy_check
    }
}
EOF

cat > /etc/haproxy/haproxy.cfg << "EOF"
global
    log         127.0.0.1 local2
    log         127.0.0.1 local0 info
    log         127.0.0.1 local0 notice
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     5000
    user        haproxy
    group       haproxy
    daemon
    stats socket /var/lib/haproxy/stats
    ssl-default-bind-ciphers PROFILE=SYSTEM
    ssl-default-server-ciphers PROFILE=SYSTEM

defaults
    log global
    mode tcp
    option tcplog
    option dontlognull
    option redispatch
    retries 3
    timeout connect 5000ms
    timeout client 30000ms
    timeout server 30000ms
    maxconn 2000

frontend tcp_front_8888
    bind 0.0.0.0:8888
    mode tcp
    option tcplog
    default_backend tcp_back_8888
backend tcp_back_8888
    mode tcp
    balance roundrobin
    option tcp-check
    server server1 1.1.1.1:8888 check inter 2000 rise 2 fall 3

frontend tcp_front_9999
    bind 0.0.0.0:9999
    mode tcp
    option tcplog
    default_backend tcp_back_9999
backend tcp_back_9999
    mode tcp
    balance roundrobin
    option tcp-check
    server server1 1.1.1.1:9999 check inter 2000 rise 2 fall 3

listen stats
    bind 0.0.0.0:8404
    mode http
    stats enable
    stats uri /stats
    stats realm Haproxy\ Statistics
    stats auth admin:admin123
EOF
```

#### Boot(systemd)

```bash
# log
vim /etc/rsyslog.conf
...
cat > /etc/rsyslog.d/haproxy.conf << "EOF"
local0.*    /var/log/haproxy.log
local2.*    /var/log/haproxy.log
EOF
systemctl restart rsyslog
touch /var/log/haproxy.log && chmod 666 /var/log/haproxy.log

# start
systemctl start haproxy.service
systemctl enable haproxy.service
```

## Deploy By Container

### Run On Docker

```bash
docker run -d --name my-running-haproxy --sysctl net.ipv4.ip_unprivileged_port_start=0 my-haproxy
# -v ./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg
```

### Run On Kubernetes

```bash
# add and update repo
helm repo add haproxytech https://haproxytech.github.io/helm-charts
helm update

# configure and run
vim values.yaml
...

# install
helm install haproxytech/haproxy -f values.yaml -n default
```

> Reference:
>
> 1. [Official Website](https://www.haproxy.com/)
> 2. [Repository](https://github.com/haproxy/haproxy)
