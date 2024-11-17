---
description: Rancher
---

# Rancher

## Introduction
...


## Deploy With Binary
### Quick Start
```bash
```

## Deploy With Container
### Run in Docker
```bash
# run by docker or docker-compose
docker run -d --name rancher --rm \
-p 80:80 -p 443:443 \
-e HTTP_PROXY=http://1.1.1.1:8888/ \
-e HTTPS_PROXY=http://1.1.1.1:8888/ \
--privileged rancher/rancher

# get password
docker logs rancher |grep Password
```

### Run in Kubernetes
[[cc-k8s|deploy by kubernetes manifest]]
```bash
# 
```

[[cc-helm|deploy by helm]]
```bash
# Add and update repo
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update

# Get charts package
helm pull rancher-stable/rancher --untar
cd rancher

# Configure and run
vim values.yaml
...

helm -n cattle-system install rancher . --create-namespace 

# verify
kubectl -n cattle-system get pod 
```



> Reference:
> 1. [Official Website](https://github.com/rancher/rke)
> 2. [Repository](https://github.com/rancher/rke)
