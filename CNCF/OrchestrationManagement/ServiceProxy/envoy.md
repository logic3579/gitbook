---
description: Envoy
---

# Envoy

## Introduction
...


## Deploy With Binary
### Quick Start
```bash
# download source
wget https://github.com/envoyproxy/envoy/releases/download/v1.26.2/envoy-x86_64
mkdir -p /opt/envoy/
mv envoy-x86_64 /opt/envoy/envoy

# create config
# https://github.com/envoyproxy/envoy/blob/main/examples/front-proxy/envoy.yaml
cat > /opt/envoy/config.yaml << "EOF"
...
EOF

# run
./envoy -c /opt/envoy/config.yaml
```

## Deploy With Container
### Run in Docker
[[cc-docker|Docker常用命令]]
```bash
# run by docker or docker-compose
# https://hub.docker.com/r/envoyproxy/envoy

# dev
cat > /opt/envoy/envoy.yaml << "EOF"
...
EOF
docker run --rm --name=envoy -d -p 80:10000 -v /opt/envoy/envoy.yaml:/etc/envoy/envoy.yaml envoyproxy/envoy:latest

curl -v 127.0.0.1:80
```

### Run in Kubernetes
[[cc-k8s|deploy by kubernetes manifest]]
```bash
# 
```

[[cc-helm|deploy by helm]]
```bash
#  
```



> Reference:
> 1. [Official Website](https://cloudnative.to/envoy/start/start.html)
> 2. [Repository](https://github.com/envoyproxy/envoy)
