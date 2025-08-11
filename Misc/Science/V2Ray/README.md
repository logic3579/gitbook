# V2ray

## Install

```bash
# windows
wget https://github.com/v2fly/v2ray-core/releases/download/v5.29.3/v2ray-windows-64.zip

# macos
brew install v2ray
```

## Start

```bash
# Binary
v2ray test -c config.json
v2ray run -c config.json

# docker
docker run \
    --name v2ray \
    -v /etc/v2ray/config.json:/etc/v2ray/config.json \
    -p 12306:12306 \
    -d --privileged \
    v2fly/v2fly-core run -c /etc/v2ray/config.json [-format jsonv5]
```

> Reference:
>
> 1. [v2fly-guide](https://guide.v2fly.org/)
> 2. [v2fly-rules](https://github.com/Loyalsoldier/v2ray-rules-dat)
