---
description: Kubespray
---

# Kubespray

## Introduction
...


## Deploy With Binary

### Quick Start
```bash
# download source
```


## Deploy With Container

### Run in Docker
```bash
# run by docker or docker-compose
# https://hub.docker.com/_/zookeeper
```

### Run in Kubernetes
[[cc-k8s|deploy by kubernetes manifest]]
```bash
# 
```

[[cc-helm|deploy by helm]]
```bash
# Add and update repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Get charts package
helm pull bitnami/zookeeper --untar 
cd zookeeper

# Configure and run
vim values.yaml
global:
  storageClass: "nfs-client"
replicaCount: 3

helm -n middleware install zookeeper . --create-namespace 

# verify
kubectl -n middleware exec -it zookeeper-0 -- zkServer.sh status  
```



> Reference:
> 1. [Official Website](https://kubespray.io/#/)
> 2. [Repository](https://github.com/kubernetes-sigs/kubespray)
