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

> Targeting **sing-box 1.12+**. Two breaking changes that affect every client below: (1) empty `direct` / `block` outbounds are deprecated — use route `action: "direct"` / `action: "reject"` instead; (2) a DNS server may not use `detour` to an empty direct outbound — drop the `detour` and let the route rules handle it.

### Server (Shadowsocks, Multi-User)

Server-level `password` is the master key (used by relay/derivation in Shadowsocks 2022); each entry in `users` is an individual subscriber with its own password and tag, which can be matched in routing rules via `user`. No `outbounds` is needed — sing-box 1.12+ direct-routes by default.

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
  ]
}
```

### Client (Shadowsocks)

Each client uses its own user password (not the server master password). Route rules use `action: "direct"` — no empty `direct` / `block` outbounds.

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
      "listen_port": 10800
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
    }
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
      { "action": "sniff" },
      { "protocol": "dns", "action": "hijack-dns" },
      { "ip_is_private": true, "action": "direct" },
      { "rule_set": ["geosite-cn", "geoip-cn"], "action": "direct" }
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

VLESS with XTLS Vision flow over REALITY transport — no real certificate needed; the server steals the TLS handshake of `handshake.server` (e.g. `www.microsoft.com`) so the connection is indistinguishable from a real TLS session to that site. Pick a target that supports TLS 1.3 + H2 + X25519, is geographically close to the server, and is unlikely to be blocked — `www.microsoft.com`, `www.bing.com`, `www.apple.com` are common choices; avoid Cloudflare-fronted sites and anything already censored in your server's region.

```json
{
  "log": {
    "level": "info",
    "output": "/var/log/sing-box.log",
    "timestamp": true
  },
  "dns": {
    "servers": [{ "tag": "local", "type": "local" }],
    "strategy": "prefer_ipv4"
  },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "::",
      "listen_port": 443,
      "users": [
        {
          "name": "sekai",
          "uuid": "1a85919c-6ee8-431d-aff4-436a45dc8d2e",
          "flow": "xtls-rprx-vision"
        },
        {
          "name": "ayaka",
          "uuid": "2b96a2ad-7ff9-542e-bff5-547b56ed9e3f",
          "flow": "xtls-rprx-vision"
        },
        {
          "name": "miyuki",
          "uuid": "3ca7b3be-800a-653f-c006-658c67fea040",
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "www.microsoft.com",
        "reality": {
          "enabled": true,
          "handshake": {
            "server": "www.microsoft.com",
            "server_port": 443
          },
          "private_key": "0J7lL5pXn1u3W2vQ8dRfYsTiB6cHmKqA9oEgVxZjN4M",
          "short_id": ["0123456789abcdef"]
        }
      }
    }
  ],
  "route": {
    "rules": [
      { "action": "sniff" },
      { "ip_is_private": true, "action": "reject" }
    ],
    "default_domain_resolver": "local"
  }
}
```

### Client (VLESS + Vision + REALITY, url-test across multiple servers)

Production-shape client: `proxy` is a manual `selector`, `auto` is a `urltest` that latency-tests each VLESS outbound on a loop. DNS uses the 1.12+ schema (`type` + `server`, no legacy `address: "tls://..."`) and approximates the Xray three-tier pattern — `cloudflare` (DoT via `detour: "proxy"`) handles non-CN domains as `final`, `alidns` (UDP) handles CN domains matched by `geosite-cn`, `system` (`type: "local"`, reads `/etc/resolv.conf`) is the last-resort fallback. sing-box has no `expectIPs` equivalent, so anti-pollution relies on routing the foreign DNS query through the encrypted tunnel rather than filtering responses by IP CIDR. The `alidns` DNS has **no** `detour` (sing-box 1.12+ rejects detour to an empty direct outbound) — the route rules below send it direct via `action: "direct"`. The `experimental.cache_file` persists rule-sets and the urltest's last-pick across restarts.

```json
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "cloudflare",
        "type": "tls",
        "server": "1.1.1.1",
        "detour": "proxy"
      },
      { "tag": "alidns", "type": "udp", "server": "223.5.5.5" },
      { "tag": "system", "type": "local" }
    ],
    "rules": [{ "rule_set": "geosite-cn", "server": "alidns" }],
    "final": "cloudflare",
    "strategy": "ipv4_only"
  },
  "inbounds": [
    {
      "type": "mixed",
      "tag": "mixed-in",
      "listen": "127.0.0.1",
      "listen_port": 10800
    }
  ],
  "outbounds": [
    {
      "type": "selector",
      "tag": "proxy",
      "outbounds": ["auto", "vps-a", "vps-b"],
      "default": "auto"
    },
    {
      "type": "urltest",
      "tag": "auto",
      "outbounds": ["vps-a", "vps-b"],
      "url": "https://www.gstatic.com/generate_204",
      "interval": "1m",
      "tolerance": 50,
      "idle_timeout": "30m",
      "interrupt_exist_connections": false
    },
    {
      "type": "vless",
      "tag": "vps-a",
      "server": "vps-a.example.com",
      "server_port": 443,
      "uuid": "1a85919c-6ee8-431d-aff4-436a45dc8d2e",
      "flow": "xtls-rprx-vision",
      "tls": {
        "enabled": true,
        "server_name": "www.microsoft.com",
        "utls": { "enabled": true, "fingerprint": "chrome" },
        "reality": {
          "enabled": true,
          "public_key": "rR7lL5pXn1u3W2vQ8dRfYsTiB6cHmKqA9oEgVxZjN4M",
          "short_id": "0123456789abcdef"
        }
      }
    },
    {
      "type": "vless",
      "tag": "vps-b",
      "server": "vps-b.example.com",
      "server_port": 443,
      "uuid": "1a85919c-6ee8-431d-aff4-436a45dc8d2e",
      "flow": "xtls-rprx-vision",
      "tls": {
        "enabled": true,
        "server_name": "www.microsoft.com",
        "utls": { "enabled": true, "fingerprint": "chrome" },
        "reality": {
          "enabled": true,
          "public_key": "9aB1c2D3e4F5g6H7i8J9k0L1m2N3o4P5q6R7s8T9uVw",
          "short_id": "fedcba9876543210"
        }
      }
    }
  ],
  "route": {
    "rule_set": [
      {
        "type": "remote",
        "tag": "geosite-category-ads-all",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ads-all.srs",
        "download_detour": "proxy"
      },
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
      { "action": "sniff" },
      { "protocol": "dns", "action": "hijack-dns" },
      {
        "rule_set": "geosite-category-ads-all",
        "action": "reject"
      },
      { "ip_is_private": true, "action": "direct" },
      {
        "ip_cidr": ["223.5.5.5/32", "223.6.6.6/32", "119.29.29.29/32"],
        "action": "direct"
      },
      { "rule_set": ["geosite-cn", "geoip-cn"], "action": "direct" }
    ],
    "final": "proxy",
    "auto_detect_interface": true,
    "default_domain_resolver": "alidns"
  },
  "experimental": {
    "cache_file": {
      "enabled": true,
      "path": "/tmp/sing-box-cache.db"
    }
  }
}
```

> Reference:
>
> 1. [Official Website](https://sing-box.sagernet.org/)
> 2. [Configuration Reference](https://sing-box.sagernet.org/configuration/)
> 3. [Repository](https://github.com/SagerNet/sing-box)
