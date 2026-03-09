---
description: Multi-protocol proxy tool with flexible routing and traffic obfuscation
---

# V2Ray

V2Ray is a network proxy tool that supports multiple protocols including VMess, VLESS, Shadowsocks, Trojan, and more. It provides flexible routing rules, traffic obfuscation, and transport layer security for building private network tunnels.

## Install

```bash
# windows
wget https://github.com/v2fly/v2ray-core/releases/download/v5.29.3/v2ray-windows-64.zip

# macos
brew install v2ray
```

## Start

```bash
# Binary
v2ray test -c config.json
v2ray run -c config.json

# docker
docker run \
    --name v2ray \
    -v /etc/v2ray/config.json:/etc/v2ray/config.json \
    -p 12306:12306 \
    -d --privileged \
    v2fly/v2fly-core run -c /etc/v2ray/config.json [-format jsonv5]
```

## Configuration

### Server (VMess + TCP)

```json
{
  "log": {
    "access": "/tmp/v2ray-access.log",
    "error": "/tmp/v2ray-error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 12306,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "1a85919c-6ee8-431d-aff4-436a45dc8d2d",
            "alterId": 0
          }
        ]
      },
      "tag": "proxy",
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {}
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
```

### Client (VMess + TCP with Routing)

```json
{
  "log": {
    "access": "/tmp/v2ray-access.log",
    "error": "/tmp/v2ray-error.log",
    "loglevel": "warning"
  },
  "dns": {
    "servers": [
      {
        "address": "119.29.29.29",
        "port": 53,
        "domains": ["geosite:cn"],
        "expectIPs": ["geoip:cn"]
      },
      {
        "address": "8.8.8.8",
        "port": 53,
        "domains": ["geosite:geolocation-!cn", "geosite:speedtest"]
      },
      "1.1.1.1",
      "localhost"
    ]
  },
  "inbounds": [
    {
      "port": 1080,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      },
      "settings": {
        "udp": true
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "1.2.3.4",
            "port": 12306,
            "users": [
              {
                "id": "1a85919c-6ee8-431d-aff4-436a45dc8d2d"
              }
            ]
          }
        ]
      }
    },
    {
      "protocol": "freedom",
      "tag": "direct",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "tag": "adblock",
      "settings": {}
    }
  ],
  "routing": {
    "domainStrategy": "IPOnDemand",
    "rules": [
      {
        "domain": ["tanx.com", "googeadsserving.cn"],
        "type": "field",
        "outboundTag": "adblock"
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": ["geosite:cn", "geoip:cn", "geoip:private"]
      }
    ]
  }
}
```

### Server (VMess + WebSocket + TLS)

```json
{
  "log": {
    "access": "/tmp/access.log",
    "error": "/tmp/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 10000,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "1a85919c-6ee8-431d-aff4-436a45dc8d2e",
            "alterId": 0,
            "security": "auto"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/ws"
        },
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/opt/v2ray/v2ray.crt",
              "keyFile": "/opt/v2ray/v2ray.key"
            }
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {}
    },
    {
      "tag": "blocked",
      "protocol": "blackhole",
      "settings": {}
    }
  ]
}
```

### Client (VMess + WebSocket + TLS)

```json
{
  "inbounds": [
    {
      "port": 1080,
      "protocol": "socks",
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      },
      "settings": {
        "auth": "noauth"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "server.com",
            "port": 443,
            "users": [
              {
                "id": "1a85919c-6ee8-431d-aff4-436a45dc8d2e",
                "alterId": 0
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "wsSettings": {
          "path": "/ws"
        }
      }
    }
  ]
}
```

> Reference:
>
> 1. [v2fly Guide](https://guide.v2fly.org/)
> 2. [v2fly Rules](https://github.com/Loyalsoldier/v2ray-rules-dat)
> 3. [Repository](https://github.com/v2fly/v2ray-core)
