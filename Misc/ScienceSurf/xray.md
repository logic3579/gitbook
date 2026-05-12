---
description: XTLS-powered proxy platform forked from V2Ray with VLESS, REALITY, XTLS Vision, and more
tags:
  - misc/vpn
---

# Xray

Xray is the network proxy platform from Project X, forked from V2Ray and extended with the XTLS protocol family. It supports VMess, VLESS, Trojan, Shadowsocks (including Shadowsocks 2022), SOCKS, and HTTP inbounds/outbounds, plus XTLS Vision and REALITY for unobservable TLS, while remaining backward compatible with V2Ray's JSON configuration model.

## System Optimization (Linux)

Before installing on a Linux server, enable BBR congestion control and raise network/file-descriptor limits — beneficial for any high-traffic proxy node, and required to get full throughput from XTLS Vision / REALITY. Requires kernel ≥ 4.9 for BBR.

```bash
# Persist sysctl tunables
sudo tee /etc/sysctl.d/99-xray.conf > /dev/null <<'EOF'
# BBR + fair queueing
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# TCP buffers (autotuned up to these maxes)
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# UDP buffers
net.core.rmem_default = 26214400
net.core.wmem_default = 26214400

# Connection table + backlog
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 32768
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.ip_local_port_range = 1024 65535
EOF

sudo sysctl --system

# File descriptor limit
sudo tee /etc/security/limits.d/99-xray.conf > /dev/null <<'EOF'
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF

# For the systemd unit specifically (survives without re-login)
sudo mkdir -p /etc/systemd/system/xray.service.d
sudo tee /etc/systemd/system/xray.service.d/override.conf > /dev/null <<'EOF'
[Service]
LimitNOFILE=1048576
EOF
sudo systemctl daemon-reload

# Verify
sysctl net.ipv4.tcp_congestion_control net.core.default_qdisc
# expected: bbr / fq
```

## Install

```bash
# macOS
brew install xray

# Linux (Debian / CentOS / Fedora / openSUSE with systemd, via official Xray-install)
## install / update binary, geoip.dat, geosite.dat
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

## only update geoip.dat / geosite.dat
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install-geodata

## remove xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove

# Go install (latest)
go install -v github.com/xtls/xray-core/main@latest
mv "$(go env GOPATH)/bin/main" "$(go env GOPATH)/bin/xray"
```

Files installed by the script follow FHS:

```
/usr/local/bin/xray
/usr/local/share/xray/geoip.dat
/usr/local/share/xray/geosite.dat
/usr/local/etc/xray/config.json
/var/log/xray/{access,error}.log
/etc/systemd/system/xray.service
/etc/systemd/system/xray@.service
```

## Start

```bash
# Validate configuration
xray test -c config.json

# Run
xray run -c config.json
xray run -confdir /usr/local/etc/xray/   # directory of fragments

# systemd (package install ships a unit file)
sudo systemctl enable --now xray

# Docker
docker run -d --name xray \
    --restart unless-stopped \
    -v /etc/xray:/etc/xray \
    -p 8388:8388 \
    ghcr.io/xtls/xray-core \
    run -c /etc/xray/config.json
```

## Configuration

### Server (Shadowsocks, Multi-User)

Server-level `password` is the master PSK (Shadowsocks 2022 base64 key — 16 bytes for `2022-blake3-aes-128-gcm`, 32 bytes for the 256-gcm / chacha20-poly1305 variants). Each entry in `clients` is an individual subscriber identified by `email`, with its own user PSK.

```json
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
      "tag": "ss-in",
      "port": 8388,
      "protocol": "shadowsocks",
      "settings": {
        "method": "2022-blake3-aes-128-gcm",
        "password": "8JCsPssfgS8tiRwiMlhARg==",
        "clients": [
          { "email": "sekai@example.com",  "password": "L8tiRwi8JCsPssfgSMlhARg==" },
          { "email": "ayaka@example.com",  "password": "QwErTyUiOpAsDfGhJkLzXcVb==" },
          { "email": "miyuki@example.com", "password": "ZxCvBnMqWeRtYuIoPaSdFgHj==" }
        ],
        "network": "tcp,udp"
      }
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "tag": "direct" }
  ]
}
```

### Client (Shadowsocks)

For multi-user mode, the client password is `<server psk>:<user psk>` joined with a colon.

```json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "socks-in",
      "port": 1080,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "settings": {
        "udp": true
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "shadowsocks",
      "settings": {
        "servers": [
          {
            "address": "server.com",
            "port": 8388,
            "method": "2022-blake3-aes-128-gcm",
            "password": "8JCsPssfgS8tiRwiMlhARg==:L8tiRwi8JCsPssfgSMlhARg=="
          }
        ]
      }
    },
    { "protocol": "freedom",   "tag": "direct" },
    { "protocol": "blackhole", "tag": "blocked" }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "direct"
      }
    ]
  }
}
```

> Reference:
>
> 1. [Official Website](https://xtls.github.io/)
> 2. [Repository](https://github.com/XTLS/Xray-core)
> 3. [Xray-install](https://github.com/XTLS/Xray-install)
> 4. [Xray-examples](https://github.com/XTLS/Xray-examples)
