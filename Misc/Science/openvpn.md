# OpenVPN

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
