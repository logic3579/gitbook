---
description: Nacos
---

# Nacos

## Introduction
...


## Deploy With Binary
### Quick Start
```bash
# download source
wget https://github.com/alibaba/nacos/releases/download/2.2.3/nacos-server-2.2.3.zip
unzip nacos-server-2.2.3.zip && cd nacos


# create data and config dir
mkdir -p /opt/zookeeper-3.7.1/data
mkdir -p /opt/zookeeper-3.7.1/logs
cat > /opt/nacos/conf/application.properties << "EOF"
...
EOF


# run
# standalone
sh startup.sh -m standalone
# cluster
sh startup.sh 
```

## Deploy With Container
### Run in Docker
[[cc-docker|Docker常用命令]]
```bash
# run by docker or docker-compose
# https://hub.docker.com/r/nacos/nacos-server
```

### Run in Kubernetes
[[cc-k8s|deploy by kubernetes manifest]]
```bash
# 
```

[[cc-helm|deploy by helm]]
```bash
# https://artifacthub.io/packages/helm/ygqygq2/nacos
```


> Reference:
> 1. [Official Website](https://nacos.io/zh-cn/docs/quick-start.html)
> 2. [Repository](https://github.com/alibaba/nacos)
