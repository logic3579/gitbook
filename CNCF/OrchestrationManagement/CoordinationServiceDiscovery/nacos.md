---
description: Nacos
tags:
  - cncf/orchestration
  - service-discovery
  - configuration
---

# Nacos

## Introduction

Nacos is an open-source platform from Alibaba for dynamic service discovery, configuration management, and service governance. It supports both DNS-based and RPC-based service discovery, hot-reloadable configuration with audit history, and integrates natively with Spring Cloud, Dubbo, gRPC, and Kubernetes — frequently used as an alternative to Eureka, Consul, or ZooKeeper in microservice deployments.

## How to Install

### Starting via Binary

#### Quick Start

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

### Starting via Docker

```bash
# https://hub.docker.com/r/nacos/nacos-server
```

### Starting via Kubernetes

#### Deploy by Kubernetes Manifest

```bash
#
```

#### Deploy by Helm

```bash
# https://artifacthub.io/packages/helm/ygqygq2/nacos
```

> Reference:
>
> 1. [Official Website](https://nacos.io/zh-cn/docs/quick-start.html)
> 2. [Repository](https://github.com/alibaba/nacos)
