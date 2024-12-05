---
description: k3s
---

# Overview

## Introduction

### Install

```
# Kernel module
lsmod |grep -E "nf_conntrack|br_netfilter"

# Master
curl -sfL https://get.k3s.io | sh -
cat /var/lib/rancher/k3s/server/node-token  # join token
# Disable traefik
kubectl -n kube-system delete helmcharts.helm.cattle.io traefik
kubectl -n kube-system delete helmcharts.helm.cattle.io traefik-crd
kubectl -n kube-system delete pod --field-selector=status.phase==Succeeded 
# Modify /etc/systemd/system/k3s.service
ExecStart=/usr/local/bin/k3s \
    server \
    --disable traefik \
    --disable traefik-crd \
##restart k3s server
rm /var/lib/rancher/k3s/server/manifests/traefik.yaml
systemctl daemon-reload
systemctl restart k3s

# Worker
curl -sfL https://get.k3s.io | K3S_URL=https://k3s_server_ip:6443 K3S_TOKEN=k3s_server_token sh -

# Get kubectl and helm client
apt install bash-completion
curl -LO https://dl.k8s.io/release/v1.27.3/bin/linux/amd64/kubectl
wget https://get.helm.sh/helm-v3.11.0-linux-amd64.tar.gz
cat >> ~/.bashrc << "EOF"
complete -o default -F __start_kubectl k
source <(kubectl completion bash)
source <(helm completion bash)
EOF

# kubectl client config
mkdir ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
kubectl get pod -A
helm list
```



> Reference:
> 1. [Official Website](https://k3s.io/)
> 2. [Repository](https://github.com/k3s-io/k3s)
