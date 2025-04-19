---
icon: icon
description: science proxy
---

# Science

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

## Proxy

### SSR

```bash
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ssr.sh
```

> Reference:
>
> 1. [ipsec-vpn-server](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/docs/advanced-usage-zh.md)
> 2. [OpenVPN](https://openvpn.net/)
> 3. [V2ray](https://www.v2fly.org)
> 4. [WireGuard](https://www.wireguard.com/)
