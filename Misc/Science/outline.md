---
description: Shadowsocks-based VPN by Jigsaw for secure internet access
---

# Outline

Outline is a free and open-source VPN solution developed by Jigsaw (a subsidiary of Google). It uses the Shadowsocks protocol to create a secure, encrypted connection. Outline is designed to be easy to set up and manage, making it accessible for users who need reliable internet access.

## Install Outline Manager

Outline Manager is the admin tool used to create and manage Outline servers.

```bash
# Download Outline Manager
# macOS
brew install --cask outline-manager

# Linux (AppImage)
wget https://s3.amazonaws.com/outline-releases/manager/linux/stable/Outline-Manager.AppImage
chmod +x Outline-Manager.AppImage
./Outline-Manager.AppImage

# Windows
# Download from https://getoutline.org/get-started/#step-1
```

## Deploy Outline Server

```bash
# One-line install script (runs Docker automatically)
sudo bash -c "$(wget -qO- https://raw.githubusercontent.com/Jigsaw-Code/outline-server/master/src/server_manager/install_scripts/install_server.sh)"

# The script outputs an API URL like:
# {"apiUrl":"https://<SERVER_IP>:<PORT>/<SECRET>","certSha256":"<CERT_HASH>"}
# Paste this into Outline Manager to connect
```

### Docker Compose

```yaml
services:
  outline-server:
    image: quay.io/nickstenning/outline-shadowbox:latest
    container_name: outline-server
    restart: always
    ports:
      - "8088:8088"
      - "8089:8089"
    volumes:
      - ./data/shadowbox:/opt/outline/persisted-state
    environment:
      - SB_DEFAULT_SERVER_NAME=my-outline-server
```

## Install Outline Client

```bash
# macOS
brew install --cask outline

# Linux
wget https://s3.amazonaws.com/outline-releases/client/linux/stable/Outline-Client.AppImage
chmod +x Outline-Client.AppImage
./Outline-Client.AppImage

# iOS / Android
# Download "Outline" from App Store / Google Play
```

## Usage

1. Open **Outline Manager** → Create a new server or connect to an existing one
2. Click **Add new key** to generate an access key (ss:// URL)
3. Share the access key with users
4. Open **Outline Client** → Paste the access key → Connect

> Reference:
>
> 1. [Outline Official Website](https://getoutline.org/)
> 2. [Outline Server Repository](https://github.com/Jigsaw-Code/outline-server)
> 3. [Outline Client Repository](https://github.com/Jigsaw-Code/outline-client)
> 4. [Outline Manager Repository](https://github.com/Jigsaw-Code/outline-apps)
