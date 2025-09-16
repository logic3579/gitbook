---
description: Automatically provision and manage TLS certificates in Kubernetes
---

# cert-manager

## Introduction

...

## Deploy With Container

### Run in Docker

```bash
#
```

### Run in Kubernetes

```bash
# Add and update repo
helm repo add jetstack https://charts.jetstack.io
helm update

# Get charts package
helm pull jetstack/cert-manager --untar
cd cert-manager

# Install cert-manager
# option1: from OCI Registry
helm install \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.18.2 \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true
helm install -n cert-manager cert-manager . --set crds.enabled=true --create-namespace
# option2: from Legacy Helm Registry
helm repo add jetstack https://charts.jetstack.io --force-update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.18.2 \
  --set crds.enabled=true

# Install clusterissuer and certificate
# Created secret if GCP GKE cluster
kubectl create -n cert-manager secret generic gcp-dns-key --from-file=./dns01-solver.json
kubectl apply -f clusterissuer-cloudflare.yaml
kubectl apply -f clusterissuer-gcp.yaml
kubectl apply -f -n your_namespace certificate.yaml
```

> Reference:
>
> 1. [Official Website](https://cert-manager.io/)
> 2. [Repository](https://github.com/cert-manager/cert-manager)
