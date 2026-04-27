---
icon: instalod
description: Kubernetes Distribution Installer
tags:
  - kubernetes
---

# Distribution Installer

Kubernetes distribution installers provide simplified deployment and management of Kubernetes clusters. Each tool targets different use cases — from local development environments to production-grade multi-node clusters.

| Tool | Scope | Linux | MacOS |
|------|-------|-------|-------|
| Minikube | Single-node local cluster (VM/Docker) | ✅ | ✅ |
| Kind | Multi-node cluster in Docker, CI-friendly | ✅ | ✅ |
| K3d | K3s wrapped in Docker, fast and lightweight | ✅ | ✅ |
| K3s | Lightweight production-ready distribution | ✅ | via VM (Lima/Multipass) |
| Kubeadm | Official cluster bootstrap tool | ✅ | via VM (Multipass) |
| Rancher | Multi-cluster management platform | ✅ | ✅ (Docker/k8s) |

## Minikube

Minikube is a tool that runs a single-node Kubernetes cluster locally on your machine for development and testing purposes. It supports multiple container runtimes (Docker, containerd, CRI-O) and VM drivers (VirtualBox, HyperKit, Docker, Podman, QEMU). Minikube provides built-in add-ons for common services like Dashboard, Ingress, and Metrics Server.

### Install

```bash
# Linux (x86_64)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# MacOS (Homebrew)
brew install minikube

# MacOS (binary, Apple Silicon)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-arm64
sudo install minikube-darwin-arm64 /usr/local/bin/minikube
```

### Quick Start

```bash
# Start a cluster (auto-detects driver: docker on MacOS, kvm2/docker on Linux)
minikube start --driver=docker --cpus=4 --memory=4g

# Access the Kubernetes dashboard
minikube dashboard

# Deploy an application
kubectl create deployment hello --image=kicbase/echo-server:1.0
kubectl expose deployment hello --type=NodePort --port=8080

# Access the service
minikube service hello

# Stop and delete
minikube stop
minikube delete
```

> Reference:
>
> 1. [Official Website](https://minikube.sigs.k8s.io/docs/)
> 2. [Repository](https://github.com/kubernetes/minikube)

## Kind

Kind (Kubernetes IN Docker) runs Kubernetes clusters using Docker containers as nodes. It boots fast, supports multi-node topologies in a single config file, and is the canonical tool for testing Kubernetes itself and CI workflows.

### Install

```bash
# Linux
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind

# MacOS (Homebrew)
brew install kind

# MacOS (binary, Apple Silicon)
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-darwin-arm64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind
```

### Quick Start

```bash
# Single-node cluster
kind create cluster --name dev

# Multi-node cluster from config
cat > kind-multinode.yaml << EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker
- role: worker
networking:
  podSubnet: 10.244.0.0/16
  serviceSubnet: 10.96.0.0/16
EOF
kind create cluster --name multi --config kind-multinode.yaml

# Load a local image into the cluster (skip registry push)
kind load docker-image my-app:dev --name multi

# Manage clusters
kind get clusters
kind delete cluster --name multi
```

> Reference:
>
> 1. [Official Website](https://kind.sigs.k8s.io/)
> 2. [Repository](https://github.com/kubernetes-sigs/kind)

## K3d

K3d wraps K3s in Docker containers, providing K3s's lightweight footprint with Kind's container-based ergonomics. Cluster startup is typically faster than Kind, and K3d ships with a built-in image registry helper and load balancer.

### Install

```bash
# Linux / MacOS (install script)
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# MacOS (Homebrew)
brew install k3d
```

### Quick Start

```bash
# Single-server cluster with port mapping
k3d cluster create dev \
  --servers 1 --agents 2 \
  -p "8080:80@loadbalancer" \
  -p "8443:443@loadbalancer"

# Cluster with built-in registry (push images without pushing to a remote registry)
k3d registry create myregistry.localhost --port 5000
k3d cluster create dev --registry-use k3d-myregistry.localhost:5000

# Multi-server (HA) cluster
k3d cluster create ha --servers 3 --agents 2

# Manage clusters
k3d cluster list
k3d kubeconfig merge dev --kubeconfig-switch-context
k3d cluster delete dev
```

> Reference:
>
> 1. [Official Website](https://k3d.io/)
> 2. [Repository](https://github.com/k3d-io/k3d)

## K3s

K3s is a lightweight, certified Kubernetes distribution built for IoT, edge computing, and resource-constrained environments. It packages the entire Kubernetes control plane into a single binary under 100MB, with built-in SQLite (or etcd), Flannel, CoreDNS, and Traefik. K3s is production-ready and ideal for scenarios where a full Kubernetes deployment would be too heavy.

> K3s runs natively on Linux only. On MacOS, run K3s inside a Lima/Multipass VM, or use **K3d** above for a Docker-based equivalent.

### Requirements

```bash
# Resources: CPU / memory / disk per node

# Kernel modules
lsmod | grep -E "nf_conntrack|br_netfilter"

# Disable firewalld

# Hostname planning
hostnamectl hostname masterX
hostnamectl hostname workerX
```

### Master

```bash
# Specify version (optional)
# INSTALL_K3S_VERSION=vX.Y.Z

# First master with embedded etcd, disable Traefik
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --cluster-init --disable=traefik" sh -
K3S_URL=https://master1:443
K3S_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)

# Additional masters (HA)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable=traefik" K3S_URL=$K3S_URL K3S_TOKEN=$K3S_TOKEN sh -

kubectl get nodes
```

### Worker

```bash
K3S_URL=https://master1:443
K3S_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
curl -sfL https://get.k3s.io | K3S_URL=$K3S_URL K3S_TOKEN=$K3S_TOKEN sh -

kubectl get nodes
```

### Manager Workstation

```bash
# Copy kubeconfig
mkdir ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
chmod 0600 ~/.kube/config

# kubectl client
KUBECTL_VERSION=v1.x.x
curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
chmod +x ./kubectl && sudo mv ./kubectl /usr/bin/kubectl

# Helm client
HELM_VERSION=v3.x.x
wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz
tar xf helm-${HELM_VERSION}-linux-amd64.tar.gz && rm -f helm-${HELM_VERSION}-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/bin/helm && rm -rf ./linux-amd64

# Auto-completion
sudo apt install bash-completion
cat >> ~/.bashrc << "EOF"
complete -o default -F __start_kubectl k
source <(kubectl completion bash)
source <(helm completion bash)
EOF

# Worker label / master taint
kubectl label nodes nodeX node-role.kubernetes.io/worker=true
kubectl taint nodes masterX node-role.kubernetes.io/master=:PreferNoSchedule
```

> Reference:
>
> 1. [Official Website](https://k3s.io/)
> 2. [Repository](https://github.com/k3s-io/k3s)

## Kubeadm

Kubeadm is the official Kubernetes cluster bootstrapping tool. It performs the actions necessary to get a minimum viable cluster up and running and is designed to be the foundation for higher-level deployment tooling.

> Kubeadm requires a Linux host. On MacOS, use **Multipass** (or Lima) to provision Linux VMs and run all node-side commands inside those VMs.

### Environment Preparation

#### 1. Provision VMs (MacOS via Multipass, Linux via your hypervisor)

```bash
# MacOS (or any host running Multipass): generate key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/k8s_rsa -C k8s

# Master node
multipass launch -c 2 -m 2G -d 20G -n master --cloud-init - << EOF
ssh_authorized_keys:
- $(cat ~/.ssh/k8s_rsa.pub)
EOF

# Worker nodes
multipass launch -c 1 -m 2G -d 20G -n node1 --cloud-init - << EOF
ssh_authorized_keys:
- $(cat ~/.ssh/k8s_rsa.pub)
EOF
multipass launch -c 1 -m 2G -d 20G -n node2 --cloud-init - << EOF
ssh_authorized_keys:
- $(cat ~/.ssh/k8s_rsa.pub)
EOF
```

> `--cloud-init` injects the local public key into the VM, enabling passwordless SSH.

#### 2. Host and Network Planning

| Host IP      | Hostname | Spec  | Role        |
|--------------|----------|-------|-------------|
| 192.168.64.4 | master1  | 2C/2G | master      |
| 192.168.64.5 | node1    | 1C/1G | worker      |
| 192.168.64.6 | node2    | 1C/1G | worker      |

| Subnet        | CIDR Range      |
|---------------|-----------------|
| nodeSubnet    | 192.168.64.0/24 |
| podSubnet     | 172.16.0.0/16   |
| serviceSubnet | 10.10.0.0/16    |

#### 3. Software Versions (example)

| Software            | Version            |
|---------------------|--------------------|
| OS                  | Ubuntu 20.04.4 LTS |
| Kernel              | 5.4.0-109-generic  |
| containerd          | 1.5.10-1           |
| kubernetes          | v1.23.2            |
| etcd                | v3.5.1             |
| CNI Plugin (Calico) | v3.18              |

### Cluster Configuration (Execute on All Nodes)

#### 1. Node Initialization

- Hostname and host resolution

```bash
hostnamectl --static set-hostname master    # on master
hostnamectl --static set-hostname node1     # on node1
hostnamectl --static set-hostname node2     # on node2

sudo tee -a /etc/hosts << EOF
192.168.64.4 master
192.168.64.5 node1
192.168.64.6 node2
EOF
```

- Disable firewall and swap

```bash
sudo ufw disable && sudo systemctl disable ufw

swapoff -a
sed -ri 's/.*swap.*/#&/' /etc/fstab
```

> Swap must be disabled or kubelet won't start, blocking cluster bring-up. Swap also degrades kubelet performance.

- Synchronize time and timezone

```bash
sudo cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
sudo timedatectl set-timezone Asia/Shanghai
sudo timedatectl set-local-rtc 0
sudo timedatectl set-ntp yes

sudo apt-get install chrony -y
sudo chronyc tracking
sudo hwclock -w
sudo systemctl restart rsyslog.service cron.service
```

- Kernel modules and sysctl

```bash
# ipvs
sudo apt-get install ipset ipvsadm -y

# Persistent module loading
sudo tee /etc/modules-load.d/k8s.conf << EOF
br_netfilter
overlay
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
EOF

# Load now
for m in br_netfilter overlay ip_vs ip_vs_rr ip_vs_wrr ip_vs_sh nf_conntrack; do
  sudo modprobe $m
done
lsmod | egrep "ip_vs|nf_conntrack"

# Required sysctl parameters
sudo tee /etc/sysctl.d/99-kubernetes-cri.conf << EOF
net.bridge.bridge-nf-call-ipv6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
```

#### 2. Container Runtime (containerd)

```bash
# Remove old packages
sudo apt-get remove docker docker-engine docker.io containerd runc

# Prerequisites
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release -y

# Docker GPG key and repo
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
 $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/container.list

# Install containerd
sudo apt-get update
apt-cache madison containerd.io
sudo apt install containerd.io=1.5.10-1 -y

# Configure containerd
containerd config default | sudo tee /etc/containerd/config.toml
# Replace pause image source (mirror)
sudo sed -i "s#k8s.gcr.io/pause#registry.cn-hangzhou.aliyuncs.com/google_containers/pause#g" /etc/containerd/config.toml

# Registry mirrors
sudo tee ~/tmp.txt << EOF
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
          endpoint = ["https://taa4w07u.mirror.aliyuncs.com"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."gcr.io"]
          endpoint = ["https://gcr.mirrors.ustc.edu.cn"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."k8s.gcr.io"]
          endpoint = ["https://gcr.mirrors.ustc.edu.cn/google-containers/", "https://registry.aliyuncs.com/google-containers/"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."quay.io"]
          endpoint = ["https://quay.mirrors.ustc.edu.cn"]
EOF
sudo sed -i '/registry.mirrors\]/r ./tmp.txt' /etc/containerd/config.toml

# Use systemd cgroup driver
sudo sed -i 's# SystemdCgroup = false# SystemdCgroup = true#g' /etc/containerd/config.toml

# Start
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
sudo ctr version
```

### Build Cluster

#### 1. Install kubeadm / kubelet / kubectl (All Nodes)

```bash
# Use Aliyun mirror
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -
sudo tee /etc/apt/sources.list.d/kubernetes.list << EOF
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

sudo apt-get update
apt-cache madison kubeadm | head
sudo apt install kubeadm=1.23.2-00 kubelet=1.23.2-00 kubectl=1.23.2-00 -y
sudo apt-mark hold kubelet kubeadm kubectl

# crictl runtime endpoint
sudo crictl config runtime-endpoint /run/containerd/containerd.sock
sudo tee /etc/crictl.yaml << EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now kubelet
systemctl status kubelet
```

#### 2. Initialize Master Node

```bash
# Generate template
kubeadm config print init-defaults > kubeadm.yaml

# Customize
cat > kubeadm.yaml << EOF
apiVersion: kubeadm.k8s.io/v1beta3
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 192.168.64.4
  bindPort: 6443
nodeRegistration:
  criSocket: /run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
  name: master
  taints:
  - effect: "NoSchedule"
    key: "node-role.kubernetes.io/master"
---
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta3
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns: {}
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers
kind: ClusterConfiguration
kubernetesVersion: 1.23.0
networking:
  dnsDomain: cluster.local
  podSubnet: 172.16.0.0/16
  serviceSubnet: 10.10.0.0/16
scheduler: {}
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF

# Pre-pull images
kubeadm config images list --config kubeadm.yaml
kubeadm config images pull --config kubeadm.yaml

# Init
sudo kubeadm init --config=kubeadm.yaml
```

#### 3. Join Workers

```bash
# Run the join command emitted by `kubeadm init` on each worker
sudo kubeadm join 192.168.64.4:6443 --token abcdef.0123456789abcdef \
  --discovery-token-ca-cert-hash sha256:<HASH>

# Re-print the join command
# kubeadm token create --print-join-command

# Configure kubectl on master
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

#### 4. Install CNI (Calico)

```bash
wget https://docs.projectcalico.org/v3.18/manifests/calico.yaml

# Set CIDR to match podSubnet
vim calico.yaml
- name: CALICO_IPV4POOL_CIDR
  value: "172.16.0.0/16"

kubectl apply -f calico.yaml
watch kubectl get pod -n kube-system
```

```bash
# Node roles
kubectl label nodes master node-role.kubernetes.io/control-plane=
kubectl label nodes node1 node-role.kubernetes.io/worker=
kubectl label nodes node2 node-role.kubernetes.io/worker=
kubectl get nodes

# kubectl auto-completion
sudo apt install -y bash-completion
source /usr/share/bash-completion/bash_completion
echo "source <(kubectl completion bash)" >> ~/.bashrc

# nerdctl (docker-compatible CLI for containerd)
wget https://github.com/containerd/nerdctl/releases/download/v0.20.0/nerdctl-0.20.0-linux-amd64.tar.gz
sudo tar Cxfz /usr/local/bin/ nerdctl-0.20.0-linux-amd64.tar.gz
sudo nerdctl -n k8s.io images
sudo nerdctl -n k8s.io ps
```

```bash
# Reset (Flannel-style only — not for Calico)
kubeadm reset
ifconfig cni0 down && ip link delete cni0
ifconfig flannel.1 down && ip link delete flannel.1
rm -rf /var/lib/cni/
```

#### 5. Verify

```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --target-port=80 --type=NodePort

# Cluster IP / NodePort / Pod IP
curl 10.10.225.108:80 -I
curl 192.168.64.5:31052 -I
curl 172.16.166.132:80 -I
```

### Kubernetes Dashboard

```bash
# Deploy
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.6.0/aio/deploy/recommended.yaml

# Expose via NodePort
kubectl get pod,service -n kubernetes-dashboard
kubectl edit service kubernetes-dashboard -n kubernetes-dashboard
# ports:
# - nodePort: 30333
#   port: 443
#   protocol: TCP
#   targetPort: 8443
# type: NodePort

# Token
kubectl describe secret -n kubernetes-dashboard \
  $(kubectl get secret -n kubernetes-dashboard | grep kubernetes-dashboard-token | awk '{print $1}')
# Visit https://<master-ip>:30333 (Firefox recommended)
```

For a TUI alternative, see [K9S](https://k9scli.io/).

> Reference:
>
> 1. [Kubeadm Documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
> 2. [Multipass](https://multipass.run/)
> 3. [Calico Quickstart](https://projectcalico.docs.tigera.io/getting-started/kubernetes/quickstart)

## Rancher

Rancher is an open-source multi-cluster management platform that simplifies Kubernetes operations at scale. It provides a unified management plane for provisioning, upgrading, and monitoring clusters across any infrastructure — on-premises, cloud, or edge. Rancher includes built-in user authentication (LDAP, AD, SAML), RBAC, security policies, a built-in app catalog (Helm charts), and centralized logging and monitoring.

### Run On Docker (Linux / MacOS)

```bash
# Works the same on Linux and MacOS (with Docker Desktop / OrbStack)
docker run -d --name rancher --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  --privileged rancher/rancher:latest

# Get bootstrap password
docker logs rancher 2>&1 | grep "Bootstrap Password:"
```

### Run On Kubernetes (Helm)

```bash
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update

helm pull rancher-stable/rancher --untar
cd rancher
vim values.yaml

helm -n cattle-system install rancher . --create-namespace
kubectl -n cattle-system get pod
```

> Reference:
>
> 1. [Official Website](https://www.rancher.com/)
> 2. [Repository](https://github.com/rancher/rancher)
