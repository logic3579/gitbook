# ipsec

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
