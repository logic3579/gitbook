---
description: Google Kubernetes Engine
tags:
  - platform/gcp
  - kubernetes
---

# Google Kubernetes Engine

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

# Workload Identity enable.
```

gke-manager instance init

```bash

# Install kubectl client
KUBECTL_VERSION=v1.33.5
curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
sudo chmod +x ./kubectl && sudo mv ./kubectl /usr/bin/kubectl
# Install helm client
HELM_VERSION=v4.0.0
wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz
tar xf helm-${HELM_VERSION}-linux-amd64.tar.gz && rm -f helm-${HELM_VERSION}-linux-amd64.tar.gz
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
metadata:
  name: ip-masq-agent
  namespace: kube-system
data:
  config: |
    nonMasqueradeCIDRs:
      - 192.168.0.0/16
      - 10.0.0.0/16
    masqLinkLocal: false
    resyncInterval: 60s
EOF
kubectl apply -f ip-masq-agent.yaml
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

## CLI

### Clusters

```bash
gcloud container clusters create CLUSTER_NAME \
    --zone=asia-southeast1-a \
    --num-nodes=3 \
    --machine-type=e2-standard-4
gcloud container clusters list
gcloud container clusters describe CLUSTER_NAME --zone=ZONE
gcloud container clusters get-credentials CLUSTER_NAME --zone=ZONE
gcloud container clusters resize CLUSTER_NAME --num-nodes=5 --zone=ZONE
gcloud container clusters update CLUSTER_NAME --zone=ZONE \
    --enable-autoscaling --min-nodes=1 --max-nodes=10
gcloud container clusters delete CLUSTER_NAME --zone=ZONE
```

### Node Pools

```bash
gcloud container node-pools list --cluster=CLUSTER_NAME --zone=ZONE
gcloud container node-pools describe POOL_NAME --cluster=CLUSTER_NAME --zone=ZONE
gcloud container node-pools create POOL_NAME \
    --cluster=CLUSTER_NAME \
    --zone=ZONE \
    --machine-type=e2-standard-4 \
    --num-nodes=3 \
    --enable-autoscaling --min-nodes=1 --max-nodes=10
gcloud container node-pools update POOL_NAME \
    --cluster=CLUSTER_NAME --zone=ZONE \
    --enable-autoscaling --min-nodes=2 --max-nodes=20
gcloud container node-pools delete POOL_NAME --cluster=CLUSTER_NAME --zone=ZONE
```

### Workload Identity

```bash
# Check cluster workload pool
gcloud container clusters describe CLUSTER_NAME \
    --project=PROJECT_ID \
    --region=asia-southeast1 \
    --format="value(workloadIdentityConfig.workloadPool)"
# Enable Workload Identity on the cluster
gcloud container clusters update CLUSTER_NAME \
    --project=PROJECT_ID \
    --region=asia-southeast1 \
    --workload-pool=PROJECT_ID.svc.id.goog

# Inspect node pool workload metadata mode
gcloud container node-pools list \
    --project=PROJECT_ID \
    --region=asia-southeast1 \
    --cluster=CLUSTER_NAME \
    --format="table(name, config.workloadMetadataConfig)"
# Enable GKE metadata server on the node pool
gcloud container node-pools update POOL_NAME \
    --project=PROJECT_ID \
    --zone=asia-southeast1 \
    --cluster=CLUSTER_NAME \
    --workload-metadata=GKE_METADATA
```

### Container Images

```bash
# Legacy gcr.io (prefer Artifact Registry)
gcloud container images list-tags gcr.io/PROJECT_ID/IMAGE
```

> Reference:
>
> 1. [Official Website](https://cloud.google.com/kubernetes-engine)
