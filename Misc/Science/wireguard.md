---
description: Modern, high-performance VPN tunnel
---

# WireGuard

## Install and generate keys

```bash
# install
apt install wireguard-tools # Ubuntu
brew install wireguard-tools # MacOS
yum install wireguard # Fefora/CentOS

# generate all keys
wg genkey | sudo tee /etc/wireguard/wg0.key | wg pubkey | sudo tee /etc/wireguard/wg0.pub
wg genkey | sudo tee /etc/wireguard/peer1.key | wg pubkey | sudo tee /etc/wireguard/peer1.pub
wg genkey | sudo tee /etc/wireguard/peer2.key | wg pubkey | sudo tee /etc/wireguard/peer2.pub
```

## Peer Server / Relay Server

```bash
# config and setup
sudo mkdir -p /etc/wireguard
sudo cat > /etc/wireguard/wg0.conf << "EOF"
[Interface]
Address = 10.250.0.250/32
ListenPort = 51820
PrivateKey = "wg0_key_content"
# DNS = 1.1.1.1,8.8.8.8
# Table = 12345
# MTU = 1500
# PreUp = /bin/example arg1 arg2 %i
# PreDown = /bin/example arg1 arg2 %i
PostUp = sysctl -w net.ipv4.ip_forward=1
#PostUp = iptables -I INPUT -p udp --dport 51820 -j ACCEPT
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostUp = iptables -A FORWARD -o wg0 -j ACCEPT
#PostUp = iptables -t nat -A POSTROUTING -o ens0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
PostDown = iptables -D FORWARD -o wg0 -j ACCEPT
#PostDown = iptables -t nat -D POSTROUTING -o ens0 -j MASQUERADE

[Peer]
AllowedIPs = 10.250.0.1/32
PublicKey = "peer1_pub_content"

[Peer]
AllowedIPs = 10.250.0.2/32
PublicKey = "peer2_pub_content"
EOF

# Set permission
chmod 600 /etc/wireguard/wg0.conf

# Startup
systemctl enable wg-quick@wg0.service --now
```

## Peer Client

```bash
# Client1(Linux)
sudo mkdir -p /etc/wireguard
sudo cat > /etc/wireguard/peer1.conf << "EOF"
[Interface]
Address = 10.250.0.1/32
#DNS = 1.1.1.1,8.8.8.8
PrivateKey = "peer1_key_content"

[Peer]
AllowedIPs = 10.250.0.0/24
Endpoint = wg0_server_ip:51820
PublicKey = "wg0_pub_content"
PersistentKeepalive = 25
EOF

chmod 600 /etc/wireguard/peer1.conf
systemctl enable wg-quick@peer1.service --now


# Client2(MacOS)
sudo mkdir -p /etc/wireguard
sudo cat > /etc/wireguard/peer2.conf << "EOF"
[Interface]
Address = 10.250.0.2/32
#DNS = 1.1.1.1,8.8.8.8
PrivateKey = "peer2_key_content"

[Peer]
AllowedIPs = 10.250.0.0/24
Endpoint = wg0_server_ip:51820
PublicKey = "wg0_pub_content"
PersistentKeepalive = 25
EOF

chmod 600 /etc/wireguard/peer2.conf
sudo wg-quick up wg0
```

## Management

```bash
# Show link info
ip link show wg0
wg show all
wg show wg0
```

> Reference:
>
> 1. [WireGuard Official Website](https://www.wireguard.com/)
> 2. [WireGuard Quick Start](https://www.wireguard.com/quickstart/)
