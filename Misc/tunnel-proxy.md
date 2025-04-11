---
description: tunnel proxy
---

# Tunnel Proxy

## Forward Proxy

### Tinyproxy
```bash
# config
vim /etc/tinyproxy/tinyproxy.conf
...
Allow 10.0.0.1
...
# start server
systemctl start tinyproy && systemctl enable tinyproxy
```

## VPN Tunnel

### ipsec
```bash
mkdir /opt/ipsec
cat > /opt/ipsec/vpn.env << "EOF"
VPN_IPSEC_PSK=ipsecpskkey1234567890
VPN_USER=ipsec123
VPN_PASSWORD=ipsec123
#VPN_ADDL_USERS=additional_username_1 additional_username_2
#VPN_ADDL_PASSWORDS=additional_password_1 additional_password_2
VPN_ENABLE_MODP1024=yes
EOF
# run server
docker run \
    --name ipsec-vpn-server \
    --env-file /opt/ipsec/vpn.env \
    --restart=always \
    -v ikev2-vpn-data:/etc/ipsec.d \
    -v /lib/modules:/lib/modules:ro \
    -p 500:500/udp \
    -p 4500:4500/udp \
    -d --privileged \
    hwdsl2/ipsec-vpn-server
```

### OpenVPN
```bash
```

### SSR
```bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ssr.sh
```

### V2ray
```bash
mkdir /opt/v2ray
# server config
cat > /opt/v2ray/server.json << "EOF"
{
  "log": {
    "access": "/tmp/v2ray-access.log",
    "error": "/tmp/v2ray-error.log",
    "loglevel": "warning"
  },
  "dns": {},
  "stats": {},
  "inbounds": [
    {
      "port": 12306,  # server listen port
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "1a85919c-6ee8-431d-aff4-436a45dc8d2d", # generate random clients uuid
            "alterId": 32
          }
        ]
      },
      "tag": "in-0",
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
    },
    {
      "tag": "blocked",
      "protocol": "blackhole",
      "settings": {}
    }
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "blocked"
      }
    ]
  },
  "policy": {},
  "reverse": {},
  "transport": {}
}
EOF
# client config
cat > /opt/v2ray/client.json << "EOF"
{
  "inbounds": [{
    "port": 1080,  // SOCKS proy port, configure the proxy in your browser
    "listen": "127.0.0.1",
    "protocol": "socks",
    "settings": {
      "udp": true
    }
  }],
  "outbounds": [{
    "protocol": "vmess",
    "settings": {
      "vnext": [{
        "address": "server", // your server public IP
        "port": 12306,  // your server listen port
        "users": [{ "id": "1a85919c-6ee8-431d-aff4-436a45dc8d2d" }] # your server random clients uuid
      }]
    }
  },{
    "protocol": "freedom",
    "tag": "direct",
    "settings": {}
  }],
  "routing": {
    "domainStrategy": "IPOnDemand",
    "rules": [{
      "type": "field",
      "ip": ["geoip:private"],
      "outboundTag": "direct"
    }]
  }
}
# run server
docker run \
    --name v2ray \
    -v /opt/v2ray/server.json:/etc/v2ray/config.json \
    -p 12306:12306 \
    -d --privileged \
    v2fly/v2fly-core run -c /etc/v2ray/config.json [-format jsonv5]
```

### WireGuard
```bash

```

## SSH Tunnel

### Layer2
```bash
# 客户端执行
ssh -o Tunnel=ethernet -w 6:6 root@[server_ip] 

# 服务端执行
ip link add br0 type bridge
ip link set tap6 master br0
ip address add 10.0.0.1/32 dev br0 # 客户端执行相同步骤，ip改为10.0.0.2
ip link set tap6 up
ip link set br0 up

# 测试arp包能否通过
arping -I br0 10.0.0.1
```

### Layer3
```bash
ssh -o PermitLocalCommand=yes \
 -o LocalCommand="ip link set tun5 up && ip addr add 10.0.0.2/32 peer 10.0.0.1 dev tun5 " \
 -o TCPKeepAlive=yes \
 -w 5:5 root@[server_ip] \
 'ip link set tun5 up && ip addr add 10.0.0.1/32 peer 10.0.0.2 dev tun5' （Server端ssh需打开Tunnel和Rootlogin 配置）
```

> Reference:
> 1. [V2ray](https://github.com/v2fly/v2ray-core)
> 2. [OpenVPN](https://openvpn.net/)
> 3. [ipsec-vpn-server](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/docs/advanced-usage-zh.md#%E4%BB%8E%E6%BA%90%E4%BB%A3%E7%A0%81%E6%9E%84%E5%BB%BA)

