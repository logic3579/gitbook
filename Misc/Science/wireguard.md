# WireGuard

```bash
# install
apt install wireguard-tools # Ubuntu
brew install wireguard-tools # MacOS
yum install wireguard # Fefora/CentOS

# server
## generate config and setup
mkdir -p /etc/wireguard
wg genkey | sudo tee /etc/wireguard/wg0.key | wg pubkey | sudo tee /etc/wireguard/wg0.pub
cat > /etc/wireguard/wg0.conf << "EOF"
[Interface]
Address = 172.31.0.1/32
ListenPort = 51820
PrivateKey = "wg0.key content"
# DNS = 1.1.1.1,8.8.8.8
# Table = 12345
# MTU = 1500
# PreUp = /bin/example arg1 arg2 %i
# PreDown = /bin/example arg1 arg2 %i
# PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ens0 -j MASQUERADE
# PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ens0 -j MASQUERADE
[Peer]
AllowedIPs = 172.31.0.2/32
PublicKey = "client0.pub content"
EOF
## set permission
chmod 600 /etc/wireguard/ -R
## ip forwarding
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.ipv6.ip_forward = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.proxy_arp = 1" >> /etc/sysctl.conf
sysctl -p
## firewall
iptables -I INPUT -p udp --dport 51820 -j ACCEPT
iptables -I FORWARD -i wg0 -j ACCEPT
iptables -t nat -A POSTROUTING -s 172.31.0.0/24 -o eth0 -j MASQUERADE
## start/stop server: wg-quick [up/down] wg0
systemctl start wg-quick@wg0.service
systemctl enable wg-quick@wg0.service

# client
## generate config and setup
mkdir -p /etc/wireguard
wg genkey | sudo tee /etc/wireguard/client0.key | wg pubkey | sudo tee /etc/wireguard/client0.pub
cat > /etc/wireguard/client0.conf << "EOF"
[Interface]
Address = 172.31.0.2/32
DNS = 1.1.1.1,8.8.8.8
PrivateKey = "client0.key content"
[Peer]
AllowedIPs = 0.0.0.0/0
Endpoint = server_public_ip:51820
# PresharedKey = "" # options
PublicKey = "wg0.pub content"
PersistentKeepalive = 10
EOF
## start/stop client: wg-quick [up/down] client0
systemctl start wg-quick@client0.service
systemctl enable wg-quick@client0.service

# show info
ip link show wg0
wg show all
wg show wg0

```
