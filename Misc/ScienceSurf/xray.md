---
description: XTLS-powered proxy platform with VLESS, REALITY, XTLS Vision, and more
tags:
  - misc/vpn
---

# Xray

Xray is the network proxy platform from Project X, built around the XTLS protocol family. It supports VLESS, VMess, Trojan, Shadowsocks (including Shadowsocks 2022), SOCKS, and HTTP inbounds/outbounds, plus XTLS Vision and REALITY for unobservable TLS.

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
          {
            "email": "sekai@example.com",
            "password": "L8tiRwi8JCsPssfgSMlhARg=="
          },
          {
            "email": "ayaka@example.com",
            "password": "QwErTyUiOpAsDfGhJkLzXcVb=="
          },
          {
            "email": "miyuki@example.com",
            "password": "ZxCvBnMqWeRtYuIoPaSdFgHj=="
          }
        ],
        "network": "tcp,udp"
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom", "tag": "direct" }]
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
    { "protocol": "freedom", "tag": "direct" },
    { "protocol": "blackhole", "tag": "blocked" }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "domain": ["geosite:cn"],
        "outboundTag": "direct"
      },
      {
        "type": "field",
        "ip": ["geoip:cn"],
        "outboundTag": "direct"
      }
    ]
  }
}
```

### Generating Keys (VLESS + REALITY)

Before writing the VLESS + REALITY config below, generate one UUID per user, an x25519 key pair (private key stays on the server, public key goes to the client), and one or more 0–8 byte hex `shortId`s shared between both sides.

```bash
# UUID — one per user (deterministic form maps any string to a UUIDv5)
xray uuid
# 1a85919c-6ee8-431d-aff4-436a45dc8d2e
xray uuid -i "sekai@example.com"
# 8a7d20b3-9f3a-5a4e-bb2d-3c4f5a6b7c8d

# REALITY x25519 key pair — generate once, keep the private key on the server
xray x25519
# Private key: 0J7lL5pXn1u3W2vQ8dRfYsTiB6cHmKqA9oEgVxZjN4M
# Public key:  rR7lL5pXn1u3W2vQ8dRfYsTiB6cHmKqA9oEgVxZjN4M

# shortId — any hex string of 0–16 chars (i.e. 0–8 bytes); empty "" is also valid
openssl rand -hex 8
# 0123456789abcdef
```

### Server (VLESS + Vision + REALITY, Multi-User)

VLESS with `xtls-rprx-vision` flow over REALITY — no certificate required; the server forwards (and steals) the TLS handshake of `dest` (e.g. `www.cloudflare.com:443`) so to a probe the connection is indistinguishable from a real TLS session to that site.

```json
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
      "tag": "vless-in",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "email": "sekai@example.com",
            "id": "1a85919c-6ee8-431d-aff4-436a45dc8d2e",
            "flow": "xtls-rprx-vision"
          },
          {
            "email": "ayaka@example.com",
            "id": "2b96a2ad-7ff9-542e-bff5-547b56ed9e3f",
            "flow": "xtls-rprx-vision"
          },
          {
            "email": "miyuki@example.com",
            "id": "3ca7b3be-800a-653f-c006-658c67fea040",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.cloudflare.com:443",
          "xver": 0,
          "serverNames": ["www.cloudflare.com"],
          "privateKey": "0J7lL5pXn1u3W2vQ8dRfYsTiB6cHmKqA9oEgVxZjN4M",
          "shortIds": ["0123456789abcdef"]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"]
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom", "tag": "direct" }]
}
```

### Client (VLESS + Vision + REALITY)

`fingerprint` must impersonate a real browser; `publicKey` / `shortId` / `serverName` must match the server.

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
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "server.com",
            "port": 443,
            "users": [
              {
                "id": "1a85919c-6ee8-431d-aff4-436a45dc8d2e",
                "flow": "xtls-rprx-vision",
                "encryption": "none"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "fingerprint": "chrome",
          "serverName": "www.cloudflare.com",
          "publicKey": "rR7lL5pXn1u3W2vQ8dRfYsTiB6cHmKqA9oEgVxZjN4M",
          "shortId": "0123456789abcdef",
          "spiderX": "/"
        }
      }
    },
    { "protocol": "freedom", "tag": "direct" },
    { "protocol": "blackhole", "tag": "blocked" }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      { "type": "field", "ip": ["geoip:private"], "outboundTag": "direct" },
      { "type": "field", "domain": ["geosite:cn"], "outboundTag": "direct" },
      { "type": "field", "ip": ["geoip:cn"], "outboundTag": "direct" }
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
