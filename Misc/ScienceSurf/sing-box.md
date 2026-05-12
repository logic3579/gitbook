---
description: Universal proxy platform supporting VMess, VLESS, Trojan, Hysteria2, TUIC, Shadowsocks, and more
tags:
  - misc/vpn
---

# sing-box

sing-box is the universal proxy platform from SagerNet. It unifies modern proxy protocols (VMess, VLESS, Trojan, Shadowsocks, Hysteria2, TUIC, ShadowTLS, AnyTLS, Naive) with TUN inbound, rule-based routing, rule-sets (geosite/geoip), and a clean JSON configuration model.

## System Optimization (Linux)

Before installing on a Linux server, enable BBR congestion control and raise network/file-descriptor limits — relevant for any proxy node, and especially important for QUIC-based protocols (Hysteria2 / TUIC) which rely on large UDP buffers. Requires kernel ≥ 4.9 for BBR.

```bash
# Persist sysctl tunables
sudo tee /etc/sysctl.d/99-singbox.conf > /dev/null <<'EOF'
# BBR + fair queueing
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# TCP buffers (autotuned up to these maxes)
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# UDP buffers (required for Hysteria2 / TUIC throughput)
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
sudo tee /etc/security/limits.d/99-singbox.conf > /dev/null <<'EOF'
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF

# For the systemd unit specifically (survives without re-login)
sudo mkdir -p /etc/systemd/system/sing-box.service.d
sudo tee /etc/systemd/system/sing-box.service.d/override.conf > /dev/null <<'EOF'
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
brew install sing-box

# Debian / Ubuntu
sudo curl -fsSL https://sing-box.app/gpg.key -o /etc/apt/keyrings/sagernet.asc
sudo chmod a+r /etc/apt/keyrings/sagernet.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/sagernet.asc] https://deb.sagernet.org/ * *" \
  | sudo tee /etc/apt/sources.list.d/sagernet.list > /dev/null
sudo apt-get update && sudo apt-get install sing-box

# RHEL / Fedora
sudo dnf config-manager --add-repo https://sing-box.app/sing-box.repo
sudo dnf install sing-box

# Go install (latest)
go install -v github.com/sagernet/sing-box/cmd/sing-box@latest
```

## Start

```bash
# Validate configuration
sing-box check -c config.json

# Format / merge configurations
sing-box format -c config.json -w
sing-box merge merged.json -C /etc/sing-box/conf.d/

# Run
sing-box run -c config.json
sing-box run -C /etc/sing-box/conf.d/   # directory of fragments

# systemd (package install ships a unit file)
sudo systemctl enable --now sing-box

# Docker
docker run -d --name sing-box \
    --restart unless-stopped \
    --network host \
    --cap-add NET_ADMIN \
    -v /etc/sing-box:/etc/sing-box \
    ghcr.io/sagernet/sing-box \
    run -c /etc/sing-box/config.json
```

## Configuration

### Server (Shadowsocks, Multi-User)

Server-level `password` is the master key (used by relay/derivation in Shadowsocks 2022); each entry in `users` is an individual subscriber with its own password and tag, which can be matched in routing rules via `user`.

```json
{
  "log": {
    "level": "info",
    "output": "/var/log/sing-box.log",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "shadowsocks",
      "tag": "ss-in",
      "listen": "::",
      "listen_port": 8080,
      "network": "tcp",
      "method": "2022-blake3-aes-128-gcm",
      "password": "8JCsPssfgS8tiRwiMlhARg==",
      "users": [
        { "name": "sekai", "password": "L8tiRwi8JCsPssfgSMlhARg==" },
        { "name": "ayaka", "password": "QwErTyUiOpAsDfGhJkLzXcVb==" },
        { "name": "miyuki", "password": "ZxCvBnMqWeRtYuIoPaSdFgHj==" }
      ],
      "multiplex": {
        "enabled": true
      }
    }
  ],
  "outbounds": [{ "type": "direct", "tag": "direct" }]
}
```

### Client (Shadowsocks)

Each client uses its own user password (not the server master password).

```json
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "mixed",
      "tag": "mixed-in",
      "listen": "127.0.0.1",
      "listen_port": 1080
    }
  ],
  "outbounds": [
    {
      "type": "shadowsocks",
      "tag": "proxy",
      "server": "server.com",
      "server_port": 8080,
      "method": "2022-blake3-aes-128-gcm",
      "password": "8JCsPssfgS8tiRwiMlhARg==:L8tiRwi8JCsPssfgSMlhARg==",
      "multiplex": {
        "enabled": true,
        "protocol": "smux",
        "max_streams": 32
      }
    },
    { "type": "direct", "tag": "direct" },
    { "type": "block", "tag": "blocked" }
  ],
  "route": {
    "rule_set": [
      {
        "type": "remote",
        "tag": "geosite-cn",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-cn.srs",
        "download_detour": "proxy"
      },
      {
        "type": "remote",
        "tag": "geoip-cn",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-cn.srs",
        "download_detour": "proxy"
      }
    ],
    "rules": [
      { "ip_is_private": true, "outbound": "direct" },
      { "rule_set": ["geosite-cn", "geoip-cn"], "outbound": "direct" }
    ],
    "final": "proxy",
    "auto_detect_interface": true,
    "default_domain_resolver": "local"
  }
}
```

### Generating Keys (VLESS + REALITY)

Before writing the VLESS + REALITY config below, generate one UUID per user, an x25519 key pair (private key stays on the server, public key goes to the client), and one or more 0–8 byte hex `short_id`s shared between both sides.

```bash
# UUID — one per user
sing-box generate uuid
# 1a85919c-6ee8-431d-aff4-436a45dc8d2e

# REALITY x25519 key pair — generate once, keep the private key on the server
sing-box generate reality-keypair
# PrivateKey: 0J7lL5pXn1u3W2vQ8dRfYsTiB6cHmKqA9oEgVxZjN4M
# PublicKey:  rR7lL5pXn1u3W2vQ8dRfYsTiB6cHmKqA9oEgVxZjN4M

# short_id — any hex string of 0–16 chars (i.e. 0–8 bytes); empty "" is also valid
sing-box generate rand --hex 8
# 0123456789abcdef
```

### Server (VLESS + Vision + REALITY, Multi-User)

VLESS with XTLS Vision flow over REALITY transport — no real certificate needed; the server steals the TLS handshake of `handshake.server` (e.g. `www.cloudflare.com`) so the connection is indistinguishable from a real TLS session to that site.

```json
{
  "log": {
    "level": "info",
    "output": "/var/log/sing-box.log",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "::",
      "listen_port": 443,
      "users": [
        { "name": "sekai",  "uuid": "1a85919c-6ee8-431d-aff4-436a45dc8d2e", "flow": "xtls-rprx-vision" },
        { "name": "ayaka",  "uuid": "2b96a2ad-7ff9-542e-bff5-547b56ed9e3f", "flow": "xtls-rprx-vision" },
        { "name": "miyuki", "uuid": "3ca7b3be-800a-653f-c006-658c67fea040", "flow": "xtls-rprx-vision" }
      ],
      "tls": {
        "enabled": true,
        "server_name": "www.cloudflare.com",
        "reality": {
          "enabled": true,
          "handshake": {
            "server": "www.cloudflare.com",
            "server_port": 443
          },
          "private_key": "0J7lL5pXn1u3W2vQ8dRfYsTiB6cHmKqA9oEgVxZjN4M",
          "short_id": ["0123456789abcdef"]
        }
      }
    }
  ],
  "outbounds": [{ "type": "direct", "tag": "direct" }]
}
```

### Client (VLESS + Vision + REALITY)

uTLS fingerprint must match a real browser; the public key/short ID pair must match the server.

```json
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "mixed",
      "tag": "mixed-in",
      "listen": "127.0.0.1",
      "listen_port": 1080
    }
  ],
  "outbounds": [
    {
      "type": "vless",
      "tag": "proxy",
      "server": "server.com",
      "server_port": 443,
      "uuid": "1a85919c-6ee8-431d-aff4-436a45dc8d2e",
      "flow": "xtls-rprx-vision",
      "tls": {
        "enabled": true,
        "server_name": "www.cloudflare.com",
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        },
        "reality": {
          "enabled": true,
          "public_key": "rR7lL5pXn1u3W2vQ8dRfYsTiB6cHmKqA9oEgVxZjN4M",
          "short_id": "0123456789abcdef"
        }
      }
    },
    { "type": "direct", "tag": "direct" },
    { "type": "block",  "tag": "blocked" }
  ],
  "route": {
    "rule_set": [
      {
        "type": "remote",
        "tag": "geosite-cn",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-cn.srs",
        "download_detour": "proxy"
      },
      {
        "type": "remote",
        "tag": "geoip-cn",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-cn.srs",
        "download_detour": "proxy"
      }
    ],
    "rules": [
      { "ip_is_private": true, "outbound": "direct" },
      { "rule_set": ["geosite-cn", "geoip-cn"], "outbound": "direct" }
    ],
    "final": "proxy",
    "auto_detect_interface": true,
    "default_domain_resolver": "local"
  }
}
```

> Reference:
>
> 1. [Official Website](https://sing-box.sagernet.org/)
> 2. [Configuration Reference](https://sing-box.sagernet.org/configuration/)
> 3. [Repository](https://github.com/SagerNet/sing-box)
