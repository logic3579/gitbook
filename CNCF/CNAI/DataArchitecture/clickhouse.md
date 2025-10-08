---
description: ClickHouse
---

# Clickhouse

## Introduction

## Deploy By Binary

### Run On Systemd

## Deploy By Container

### Run On Kubernetes

```bash
# Add and update repo
helm repo add bitnami https://charts.bitnami.com/bitnami

# Get charts package
helm pull bitnami/clickhouse --untar --version=9.4.3
cd clickhouse

# Configure
vim values.yaml
clusterName: default
auth:
  username: default
  password: ""
resources:
  requests:
    cpu: 2
    memory: 4Gi
  limits:
    cpu: 4
    memory: 8Gi
nodeSelector:
  tier: database
networkPolicy:
  enabled: false
persistence:
  enabled: true
  sieze: 200Gi
keeper:
  enabled: true
  resources:
    requests:
      cpu: 1
      memory: 2Gi
    limits:
      cpu: 1
      memory: 2Gi
  networkPolicy:
    enabled: false
  persistence:
    enabled: true
    size: 8Gi

# Install
helm upgrade --install -n database clickhouse . -f values.yaml
```

> Reference:
>
> 1. [Official Website](https://github.com/ClickHouse/ClickHouse)
> 2. [Repository](https://github.com/ClickHouse/ClickHouse)
