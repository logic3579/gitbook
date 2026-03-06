---
icon: instalod
description: Kubernetes Distribution Installer
---

# Distribution Installer

Kubernetes distribution installers provide simplified deployment and management of Kubernetes clusters. Each tool targets different use cases — from local development environments to production-grade multi-node clusters.

## K3S

K3S is a lightweight, certified Kubernetes distribution built for IoT, edge computing, and resource-constrained environments. It packages the entire Kubernetes control plane into a single binary under 100MB, with built-in SQLite (or etcd), Flannel, CoreDNS, and Traefik. K3S is production-ready and ideal for scenarios where a full Kubernetes deployment would be too heavy.

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

> Reference:
> 1. [Official Website](https://k3s.io/)
> 2. [Repository](https://github.com/k3s-io/k3s)

## KubeSphere

KubeSphere is an open-source container platform built on Kubernetes that provides a full-stack IT automated operations and DevOps workflow. It features a web-based console with a developer-friendly wizard UI for managing multi-tenant clusters, CI/CD pipelines, service mesh, multi-cluster management, observability, and application lifecycle management — all without requiring deep Kubernetes expertise.

> Reference:
>
> 1. [Official Website](https://www.kubesphere.io/)
> 2. [Repository](https://github.com/kubesphere/kubesphere)

## Kubespray

Kubespray is a composition of Ansible playbooks, inventory, and provisioning tools for deploying production-ready Kubernetes clusters. It supports multiple cloud providers (AWS, GCE, Azure, OpenStack), bare-metal, and on-premises environments. Kubespray is highly customizable, allowing fine-grained control over networking plugins (Calico, Cilium, Flannel), container runtimes (containerd, CRI-O), and cluster add-ons.

> Reference:
>
> 1. [Official Website](https://kubespray.io/)
> 2. [Repository](https://github.com/kubernetes-sigs/kubespray)

## Minikube

Minikube is a tool that runs a single-node Kubernetes cluster locally on your machine for development and testing purposes. It supports multiple container runtimes (Docker, containerd, CRI-O) and VM drivers (VirtualBox, HyperKit, Docker, Podman). Minikube provides built-in add-ons for common services like Dashboard, Ingress, and Metrics Server.

### Install

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

### Quick Start

```bash
# Start a cluster
minikube start

# Access the Kubernetes dashboard
minikube dashboard

# Deploy an application
kubectl create deployment hello-minikube --image=kicbase/echo-server:1.0
kubectl expose deployment hello-minikube --type=NodePort --port=8080

# Access the service
minikube service hello-minikube

# Stop and delete
minikube stop
minikube delete
```

> Reference:
> 1. [Official Website](https://minikube.sigs.k8s.io/docs/)
> 2. [Repository](https://github.com/kubernetes/minikube)

## Rancher

Rancher is an open-source multi-cluster management platform that simplifies Kubernetes operations at scale. It provides a unified management plane for provisioning, upgrading, and monitoring clusters across any infrastructure — on-premises, cloud, or edge. Rancher includes built-in user authentication (LDAP, AD, SAML), RBAC, security policies, a built-in app catalog (Helm charts), and centralized logging and monitoring.

### Run On Docker

```bash
docker run -d --name rancher --rm \
-p 80:80 -p 443:443 \
-e HTTP_PROXY=http://1.1.1.1:8888/ \
-e HTTPS_PROXY=http://1.1.1.1:8888/ \
--privileged rancher/rancher

# get password
docker logs rancher |grep Password
```

### Run On Kubernetes

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
>
> 1. [Official Website](https://www.rancher.com/)
> 2. [Repository](https://github.com/rancher/rancher)
