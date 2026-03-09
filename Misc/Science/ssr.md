---
description: ShadowsocksR proxy with obfuscation and protocol plugins
---

# ShadowsocksR

ShadowsocksR (SSR) is a fork of the original Shadowsocks project with additional features including protocol plugins and obfuscation plugins, providing enhanced traffic disguise capabilities.

## Server Install

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

## Client

```bash
# macOS — ShadowsocksX-NG-R
# Download from https://github.com/qinyuhang/ShadowsocksX-NG-R/releases

# Windows — ShadowsocksR C#
# Download from https://github.com/shadowsocksrr/shadowsocksr-csharp/releases

# Android — ShadowsocksR Android
# Download from https://github.com/shadowsocksrr/shadowsocksr-android/releases

# iOS — Shadowrocket / Potatso Lite (App Store)
```

### Client Configuration

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
> 1. [ShadowsocksR Install Script](https://github.com/ToyoDAdoubi/doubi)
> 2. [ShadowsocksR C# Client](https://github.com/shadowsocksrr/shadowsocksr-csharp)
> 3. [ShadowsocksR Android Client](https://github.com/shadowsocksrr/shadowsocksr-android)
