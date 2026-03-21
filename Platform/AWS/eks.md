---
description: Elastic Kubernetes Service
tags:
  - platform/aws
  - kubernetes
---

# Elastic Kubernetes Service

## Introduction
...

## Install

### cluster init
```console
# node init
1. cluster_name
xx-eks-cluster
2. nodegroup_name
xxx-app-pool
xxx-middleware-pool
3. label settings
4. taint settings

# cluster add-on
ebs-csi

# others
gp3 storageclass

# CICD
ArgoCD
Kubesphere

# observability
Prometheus
Loki
Grafana

# manager
rancher
```

### manager machine
```bash
# awscli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip awscliv2.zip && rm -f /tmp/awscliv2.zip
./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update && rm -rf /tmp/aws

# eksctl
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
sudo mv /tmp/eksctl /usr/local/bin

# kubectl
KUBECTL_VERSION=v1.30.9
HELM_VERSION=v3.15.3
curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
chmod +x ./kubectl && mv ./kubectl /usr/bin/kubectl

# helm
wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz
tar xf helm-v3.16.2-linux-amd64.tar.gz && rm -f helm-v3.16.2-linux-amd64.tar.gz
chmod +x linux-amd64/helm && mv linux-amd64/helm /usr/bin/helm && rm -rf ./linux-amd64

# bash_completion
cat >> ~/.bashrc << "EOF"
source <(kubectl completion bash)
source <(helm completion bash)
EOF
```



> Reference:
> 1. [Official Website](https://docs.aws.amazon.com/)
> 2. [eksctl](https://eksctl.io/)
