# WireGuard

Install and generate keys

```bash
# install
apt install wireguard-tools # Ubuntu
brew install wireguard-tools # MacOS
yum install wireguard # Fefora/CentOS

# generate all keys
wg genkey | sudo tee /etc/wireguard/wg0.key | wg pubkey | sudo tee /etc/wireguard/wg0.pub
wg genkey | sudo tee /etc/wireguard/client0.key | wg pubkey | sudo tee /etc/wireguard/client.pub
wg genkey | sudo tee /etc/wireguard/client1.key | wg pubkey | sudo tee /etc/wireguard/client1.pub
```

Peer Server / Relay Server

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
PostUp = sysctl -w net.ipv6.ip_forward=1
#PostUp = iptables -I INPUT -p udp --dport 51820 -j ACCEPT
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostUp = iptables -A FORWARD -o wg0 -j ACCEPT
#PostUp = iptables -t nat -A POSTROUTING -o ens0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
PostDown = iptables -D FORWARD -o wg0 -j ACCEPT
#PostDown = iptables -t nat -D POSTROUTING -o ens0 -j MASQUERADE

[Peer]
AllowedIPs = 10.250.0.1/32
PublicKey = "client0_pub_content"

[Peer]
AllowedIPs = 10.250.0.2/32
PublicKey = "client1_pub_content"
EOF

# set permission
chmod 600 /etc/wireguard/wg0.conf

# startup
systemctl enable wg-quick@wg0.service --now
```

Peer Client

```bash
# config and setup
sudo mkdir -p /etc/wireguard
sudo cat > /etc/wireguard/client0.conf << "EOF"
[Interface]
#Address = 10.250.0.1/32
Address = 10.250.0.2/32
#DNS = 1.1.1.1,8.8.8.8
PrivateKey = "wg0_key_content"

[Peer]
AllowedIPs = 10.250.0.0/24
Endpoint = server_public_ip:51820
#PublicKey = "client0_pub_content"
PublicKey = "client1_pub_content"
PersistentKeepalive = 25
EOF

# set permission
chmod 600 /etc/wireguard/wg0.conf

# startup
## Linux
systemctl enable wg-quick@wg0.service --now
## MacOS
sudo wg-quick up wg0
```

Management command

```bash
ip link show wg0
wg show all
wg show wg0
```
