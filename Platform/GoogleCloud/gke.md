---
description: Google Kubernetes Engine
---

# Google Kubernets Engine

## Introduction

...

## Install

### Cluster init

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

### Manager

kubectl && helm

```bash
# kubectl cli
KUBECTL_VERSION=v1.30.9
curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
chmod +x ./kubectl && mv ./kubectl /usr/bin/kubectl

# helm cli
HELM_VERSION=v3.15.3
wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz
tar xf helm-v3.16.2-linux-amd64.tar.gz && rm -f helm-v3.16.2-linux-amd64.tar.gz
chmod +x linux-amd64/helm && mv linux-amd64/helm /usr/bin/helm && rm -rf ./linux-amd64

# Auto completion
sudo apt install bash-completion -y
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "source <(helm completion bash)" >> ~/.bashrc
source ~/.bashrc
```

gcloud

```bash
# Install gke-gcloud-auth-plugin
# option1
gcloud components install gke-gcloud-auth-plugin
# option2
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/google-cloud-sdk.gpg
echo "deb [signed-by=/usr/share/keyrings/google-cloud-sdk.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt update && sudo apt install google-cloud-sdk-gke-gcloud-auth-plugin

# Init kubeconfig
gcloud container clusters get-credentials your_cluster_name --region your_cluster_region --project your_project
kubectl get nodes
```

> Reference:
>
> 1. [Official Website](https://cloud.google.com/kubernetes-engine)
