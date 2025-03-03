---
description: Google Kubernetes Engine
---

# Google Kubernets Engine

## Introduction
...

## Install

### cluster init
```console
# node init
1. cluster_name
xx-gke-cluster
2. nodegroup_name
xxx-app-pool
xxx-middleware-pool
3. label settings
4. taint settings
5. pod, service CIDR settings

# cluster add-on
pd-csi-driver


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
# gcloud
gcloud components install gke-gcloud-auth-plugin
gcloud container clusters get-credentials xxx-gke-cluster --region asia-east2 --project your_project

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
> 1. [Official Website](https://cloud.google.com/kubernetes-engine)
