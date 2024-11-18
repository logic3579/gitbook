---
description: tunnel proxy
---

# Tunnel Proxy

## Forward Proxy
### Proxychains
```bash
#
```

### Tinyproxy
```bash
# 
```


## VPN Tunnel

### v2ray
```bash
mkdir /etc/v2ray
cat > /etc/v2ray/config.json << "EOF"
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
      "port": 12306,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "1a85919c-6ee8-431d-aff4-436a45dc8d2d",
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

docker run -d --name v2ray -e TZ=Asia/Shanghai -v /etc/v2ray:/etc/v2ray -p 12306:12306 v2ray/official v2ray -config=/etc/v2ray/config.json
```

### ipsec
```bash
cat > vpn.env << "EOF"
VPN_IPSEC_PSK=ipsecpskkey1234567890
VPN_USER=ipsec123
VPN_PASSWORD=ipsec123
#VPN_ADDL_USERS=additional_username_1 additional_username_2
#VPN_ADDL_PASSWORDS=additional_password_1 additional_password_2
EOF

docker run --name ipsecvpn --env-file ./vpn.env --restart=always -p 500:500/udp -p 4500:4500/udp -d --privileged hwdsl2/ipsec-vpn-server
```

### SSR
```bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ssr.sh
```

### OVS

```bash
# 
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
