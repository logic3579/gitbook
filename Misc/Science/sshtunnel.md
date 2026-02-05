# SSH Tunnel

## Layer2

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

## Layer3

```bash
ssh -o PermitLocalCommand=yes \
 -o LocalCommand="ip link set tun5 up && ip addr add 10.0.0.2/32 peer 10.0.0.1 dev tun5 " \
 -o TCPKeepAlive=yes \
 -w 5:5 root@[server_ip] \
 'ip link set tun5 up && ip addr add 10.0.0.1/32 peer 10.0.0.2 dev tun5' (Server-side SSH needs Tunnel and RootLogin enabled)
```
