---
description: Google Kubernetes Engine
---

# Google Kubernets Engine

## Introduction

...

## Install

### Cluster init

```console
# Cluster basics
Name: your_cluster_name
Regional: your_region

# NODE POOLS
name: app-pool
Labels: tier=app
Taint: app_dedicated=true

# Networking
Enable authorized networks: true
Access using the control plane's external IP address: false
Authorized networks: Add an authorized network(internal)
Cluster networking: select your VPC and gke subnet.
Enable Private nodes: true
Cluster default Pod address range: 172.16.0.0/16
Service address range: 192.168.0.0/16

# Cluster add-on
pd-csi-driver
```

### GCP settings and Manager machine init

GCP settings

```console
# Create Cloud NAT public instance for internet access.
1. Creted a public NAT public instance on console.
2. Associate the NAT instance with the GKE cluster.

# Create IAM service-account for gke-manager and cert-manager.
1. Created service-account(gke-manager and dns01-resolver) on GCP IAM console.
2. Assign Kubernetes Engine Admin role to gke-manager and DNS Administrator to dns01-resolver.
3. Generate a service-account json key for each service-account.

# Create a static internal/external IP address for istio external gateway.
1. Reserve external IP and named istio-ingress-external.
2. Modify values-external.yaml loadBalancerIP and deployment.
```

gke-manager init

```bash

# Install kubectl client
KUBECTL_VERSION=v1.30.9
curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
sudo chmod +x ./kubectl && sudo mv ./kubectl /usr/bin/kubectl
# Install helm client
HELM_VERSION=v3.19.0
wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz
tar xf helm-v3.16.2-linux-amd64.tar.gz && rm -f helm-v3.16.2-linux-amd64.tar.gz
sudo chmod +x linux-amd64/helm && sudo mv linux-amd64/helm /usr/bin/helm && rm -rf ./linux-amd64
# Auto completion
sudo apt install bash-completion -y
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "source <(helm completion bash)" >> ~/.bashrc
source ~/.bashrc

# Install gke-gcloud-auth-plugin
# option1
gcloud components install gke-gcloud-auth-plugin
# option2
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/google-cloud-sdk.gpg
echo "deb [signed-by=/usr/share/keyrings/google-cloud-sdk.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt update && sudo apt install google-cloud-sdk-gke-gcloud-auth-plugin -y

# Activate service-account on manager machine
gcloud auth activate-service-account --key-file=./your-service-account-key.json
# Init gke cluster connect permission
gcloud container clusters get-credentials your_cluster_name --region your_cluster_region --project your_project
kubectl get nodes

# Configuring and deploying the ip-masq-agent
cat > ip-masq-agent.yaml << "EOF"
apiVersion: v1
kind: ConfigMap
data:
  config: |
    nonMasqueradeCIDRs:
      - 192.168.0.0/16
      - 10.0.0.0/16
    masqLinkLocal: false
    resyncInterval: 60s
EOF
kubectl apply -n kube-system -f ip-masq-agent.yaml
```

### Cluster component

```console
# Certificate
cert-manager

# CICD
Jenkins
ArgoCD

# Observability
node-exporter
Prometheus
Promtail
Loki
Grafana

# Manager
rancher
```

> Reference:
>
> 1. [Official Website](https://cloud.google.com/kubernetes-engine)
