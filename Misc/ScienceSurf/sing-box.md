---
description: Universal proxy platform supporting VMess, VLESS, Trojan, Hysteria2, TUIC, Shadowsocks, and more
tags:
  - misc/vpn
---

# sing-box

sing-box is the universal proxy platform from SagerNet. It unifies modern proxy protocols (VMess, VLESS, Trojan, Shadowsocks, Hysteria2, TUIC, ShadowTLS, AnyTLS, Naive) with TUN inbound, rule-based routing, rule-sets (geosite/geoip), and a clean JSON configuration model.

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

### Server (VMess + WebSocket + TLS)

```json
{
  "log": {
    "level": "info",
    "output": "/var/log/sing-box.log",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vmess",
      "tag": "vmess-in",
      "listen": "::",
      "listen_port": 443,
      "users": [
        {
          "name": "default",
          "uuid": "1a85919c-6ee8-431d-aff4-436a45dc8d2e"
        }
      ],
      "transport": {
        "type": "ws",
        "path": "/ws"
      },
      "tls": {
        "enabled": true,
        "server_name": "server.com",
        "certificate_path": "/opt/sing-box/server.crt",
        "key_path": "/opt/sing-box/server.key"
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
```

### Client (TUN + VMess + Rule Sets)

```json
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      { "tag": "google", "address": "tls://8.8.8.8", "detour": "proxy" },
      { "tag": "local",  "address": "https://223.5.5.5/dns-query", "detour": "direct" }
    ],
    "rules": [
      { "rule_set": "geosite-cn", "server": "local" },
      { "clash_mode": "direct",   "server": "local" },
      { "clash_mode": "global",   "server": "google" }
    ],
    "strategy": "ipv4_only"
  },
  "inbounds": [
    {
      "type": "mixed",
      "tag": "mixed-in",
      "listen": "127.0.0.1",
      "listen_port": 1080
    },
    {
      "type": "tun",
      "tag": "tun-in",
      "address": ["172.18.0.1/30", "fdfe:dcba:9876::1/126"],
      "auto_route": true,
      "strict_route": true,
      "stack": "system",
      "sniff": true
    }
  ],
  "outbounds": [
    {
      "type": "vmess",
      "tag": "proxy",
      "server": "server.com",
      "server_port": 443,
      "uuid": "1a85919c-6ee8-431d-aff4-436a45dc8d2e",
      "security": "auto",
      "transport": {
        "type": "ws",
        "path": "/ws"
      },
      "tls": {
        "enabled": true,
        "server_name": "server.com"
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
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/cn.srs",
        "download_detour": "proxy"
      },
      {
        "type": "remote",
        "tag": "geosite-ads",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ads-all.srs",
        "download_detour": "proxy"
      }
    ],
    "rules": [
      { "action": "sniff" },
      { "protocol": "dns", "action": "hijack-dns" },
      { "rule_set": "geosite-ads", "outbound": "blocked" },
      { "rule_set": ["geosite-cn", "geoip-cn"], "outbound": "direct" },
      { "ip_is_private": true, "outbound": "direct" }
    ],
    "auto_detect_interface": true,
    "final": "proxy"
  }
}
```

### Server (Hysteria2)

```json
{
  "inbounds": [
    {
      "type": "hysteria2",
      "tag": "hy2-in",
      "listen": "::",
      "listen_port": 443,
      "users": [
        { "name": "default", "password": "your-password" }
      ],
      "masquerade": "https://www.bing.com",
      "tls": {
        "enabled": true,
        "alpn": ["h3"],
        "certificate_path": "/opt/sing-box/server.crt",
        "key_path": "/opt/sing-box/server.key"
      }
    }
  ],
  "outbounds": [
    { "type": "direct", "tag": "direct" }
  ]
}
```

### Server (Shadowsocks 2022)

```json
{
  "inbounds": [
    {
      "type": "shadowsocks",
      "tag": "ss-in",
      "listen": "::",
      "listen_port": 8388,
      "method": "2022-blake3-aes-128-gcm",
      "password": "8JCsPssfgS8tiRwiMlhARg=="
    }
  ],
  "outbounds": [
    { "type": "direct", "tag": "direct" }
  ]
}
```

> Reference:
>
> 1. [Official Website](https://sing-box.sagernet.org/)
> 2. [Configuration Reference](https://sing-box.sagernet.org/configuration/)
> 3. [Repository](https://github.com/SagerNet/sing-box)
