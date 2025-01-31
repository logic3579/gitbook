---
description: k3s
---

# Overview

## Introduction

### Install

#### Requirements

```bash
# resources
cpu
memory
disk

# Kernel module
lsmod |grep -E "nf_conntrack|br_netfilter"

# firewalld diables

# hostname
hostnamectl hostname masterX
hostnamectl hostname workerX

```

#### Master

```bash
# specified version env
# INSTALL_K3S_VERSION=xxx

# install master with etcd and disable traefik
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --cluster-init --disable=traefik" sh -
K3S_URL=https://master1:443
K3S_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)

# join others master
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable=traefik" K3S_URL=$K3S_URL K3S_TOKEN=$K3S_TOKEN sh -

# check
kubectl get nodes
```

#### Worker
```bash
# install worker and join cluster
K3S_URL=https://master1:443
K3S_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
curl -sfL https://get.k3s.io | K3S_URL=$K3S_URL K3S_TOKEN=$K3S_TOKEN sh -

# check
kubectl get nodes
```

#### Manager
```bash
# set kubectl client config
mkdir ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
chmod 0600 ~/.kube/config

# kubectl client
KUBECTL_VERSION=v1.x.x
curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/bin/kubectl

# helm client
HELM_VERSION=v3.x.x
wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz
tar xf helm-${HELM_VERSION}-linux-amd64.tar.gz && rm -f helm-${HELM_VERSION}-linux-amd64.tar.gz
chmod +x linux-amd64/helm
mv linux-amd64/helm /usr/bin/helm && rm -rf ./linux-amd64

# auto-completion
apt install bash-completion
cat >> ~/.bashrc << "EOF"
complete -o default -F __start_kubectl k
source <(kubectl completion bash)
source <(helm completion bash)
EOF

# worker label
kubectl label nodes nodeX node-role.kubernetes.io/worker=true

# master taint
#kubectl taint nodes masterX node-role.kubernetes.io/master=:NoSchedule
kubectl taint nodes masterX node-role.kubernetes.io/master=:PreferNoSchedule
```

### Others

#### components


#### nfs-driver
```bash
```




> Reference:
> 1. [Official Website](https://k3s.io/)
> 2. [Repository](https://github.com/k3s-io/k3s)
