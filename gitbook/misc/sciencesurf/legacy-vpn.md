---
description: Legacy VPN, tunneling, and proxy solutions — IPsec/L2TP, OpenVPN, SSH Tunnel, ShadowsocksR
tags:
  - misc/vpn
---

# Legacy VPN

Traditional VPN, tunneling, and proxy technologies that predate modern proxy platforms such as sing-box and Xray. These are still widely deployed in enterprise and personal use cases, but their handshake patterns are well-known to DPI systems and they generally lack the obfuscation and multiplexing capabilities of newer protocols.

## IPsec

IPsec/L2TP VPN server deployed via Docker.

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

## OpenVPN

Open-source TLS-based VPN solution.

```bash
sudo apt install git -y && git clone https://github.com/slobys/docker.git && cd docker && chmod +x docker.sh && ./docker.sh

docker run -d \
 --cap-add=NET_ADMIN \
 -p 1194:1194/udp \
 -p 8833:8833 \
 -e ADMIN_USERNAME=admin \
 -e ADMIN_PASSWORD=admin \
 -e OVPN_GATEWAY=true \
 -v $(pwd)/data:/data \
 yyxx/openvpn
```

## SSH Tunnel

Layer 2/3 tunneling over SSH. Requires `PermitTunnel` and `PermitRootLogin` to be enabled on the server's `sshd_config`.

### Layer 2

```bash
# Execute on client
ssh -o Tunnel=ethernet -w 6:6 root@[server_ip]

# Execute on server
ip link add br0 type bridge
ip link set tap6 master br0
ip address add 10.0.0.1/32 dev br0 # Execute the same steps on client, change IP to 10.0.0.2
ip link set tap6 up
ip link set br0 up

# Test if ARP packets can pass through
arping -I br0 10.0.0.1
```

### Layer 3

```bash
ssh -o PermitLocalCommand=yes \
 -o LocalCommand="ip link set tun5 up && ip addr add 10.0.0.2/32 peer 10.0.0.1 dev tun5 " \
 -o TCPKeepAlive=yes \
 -w 5:5 root@[server_ip] \
 'ip link set tun5 up && ip addr add 10.0.0.1/32 peer 10.0.0.2 dev tun5'
```

## ShadowsocksR

ShadowsocksR (SSR) is a fork of the original Shadowsocks project with additional protocol plugins and obfuscation plugins, providing enhanced traffic disguise capabilities.

### Server Install

```bash
# One-line install script
wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/ssr.sh
chmod +x ssr.sh
./ssr.sh
```

### Script Menu

```bash
# Run the management script
./ssr.sh

# Available options:
# 1. Install ShadowsocksR
# 2. Update ShadowsocksR
# 3. Uninstall ShadowsocksR
# 4. Start ShadowsocksR
# 5. Stop ShadowsocksR
# 6. Restart ShadowsocksR
# 7. Set config (port, password, encryption, protocol, obfs)
# 8. View config
# 9. View connection info
```

### Manual Configuration

```bash
# Config file location
cat /etc/shadowsocks-r/config.json
```

```json
{
  "server": "0.0.0.0",
  "server_ipv6": "::",
  "server_port": 12345,
  "local_address": "127.0.0.1",
  "local_port": 1080,
  "password": "your_password",
  "method": "aes-256-cfb",
  "protocol": "auth_sha1_v4",
  "protocol_param": "",
  "obfs": "tls1.2_ticket_auth",
  "obfs_param": "",
  "timeout": 120,
  "udp_timeout": 60,
  "redirect": "",
  "dns_ipv6": false,
  "fast_open": false,
  "workers": 1
}
```

### Service Management

```bash
/etc/init.d/shadowsocks-r start
/etc/init.d/shadowsocks-r stop
/etc/init.d/shadowsocks-r restart
/etc/init.d/shadowsocks-r status
```

### Client

```bash
# macOS — ShadowsocksX-NG-R
# Download from https://github.com/qinyuhang/ShadowsocksX-NG-R/releases

# Windows — ShadowsocksR C#
# Download from https://github.com/shadowsocksrr/shadowsocksr-csharp/releases

# Android — ShadowsocksR Android
# Download from https://github.com/shadowsocksrr/shadowsocksr-android/releases

# iOS — Shadowrocket / Potatso Lite (App Store)
```

| Parameter | Description |
|-----------|-------------|
| Server | Server IP address |
| Server Port | Port configured on server |
| Password | Password configured on server |
| Encryption | Must match server (e.g., `aes-256-cfb`) |
| Protocol | Must match server (e.g., `auth_sha1_v4`) |
| Obfs | Must match server (e.g., `tls1.2_ticket_auth`) |

> Reference:
>
> 1. [docker-ipsec-vpn-server](https://github.com/hwdsl2/docker-ipsec-vpn-server)
> 2. [IPsec Advanced Usage](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/docs/advanced-usage-zh.md)
> 3. [OpenVPN Official Website](https://openvpn.net/)
> 4. [OpenVPN Community](https://openvpn.net/community/)
> 5. [SSH Tunneling](https://www.ssh.com/academy/ssh/tunneling)
> 6. [OpenSSH Manual](https://man.openbsd.org/ssh)
> 7. [ShadowsocksR Install Script](https://github.com/ToyoDAdoubi/doubi)
> 8. [ShadowsocksR C# Client](https://github.com/shadowsocksrr/shadowsocksr-csharp)
> 9. [ShadowsocksR Android Client](https://github.com/shadowsocksrr/shadowsocksr-android)
