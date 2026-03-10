---
description: Kubernetes
---

# Kubernetes

Kubernetes (K8s) is an open-source container orchestration platform originally designed by Google and now maintained by CNCF. It automates deployment, scaling, and management of containerized applications.

## Architecture

```
                         ┌─────────────────────────────────────────┐
                         │            Control Plane                │
                         │                                        │
  kubectl / API ────────►│  ┌──────────┐  ┌───────────────────┐   │
                         │  │ kube-api  │  │       etcd        │   │
                         │  │  server   │──│  (cluster state)  │   │
                         │  └────┬─────┘  └───────────────────┘   │
                         │       │                                 │
                         │  ┌────┴──────────┐  ┌───────────────┐  │
                         │  │   scheduler   │  │  controller   │  │
                         │  │               │  │   manager     │  │
                         │  └───────────────┘  └───────────────┘  │
                         └──────────────┬──────────────────────────┘
                                        │
                    ┌───────────────────┬┴──────────────────┐
                    ▼                   ▼                    ▼
            ┌──────────────┐   ┌──────────────┐    ┌──────────────┐
            │   Worker 1   │   │   Worker 2   │    │   Worker N   │
            │              │   │              │    │              │
            │  kubelet     │   │  kubelet     │    │  kubelet     │
            │  kube-proxy  │   │  kube-proxy  │    │  kube-proxy  │
            │  container   │   │  container   │    │  container   │
            │   runtime    │   │   runtime    │    │   runtime    │
            │              │   │              │    │              │
            │ ┌──┐ ┌──┐   │   │ ┌──┐ ┌──┐   │    │ ┌──┐ ┌──┐   │
            │ │P1│ │P2│   │   │ │P3│ │P4│   │    │ │P5│ │P6│   │
            │ └──┘ └──┘   │   │ └──┘ └──┘   │    │ └──┘ └──┘   │
            └──────────────┘   └──────────────┘    └──────────────┘
```

## Components

### Control Plane

| Component | Description |
|-----------|-------------|
| kube-apiserver | REST API entry point for all cluster operations, handles authentication, authorization, and admission control |
| etcd | Distributed key-value store for all cluster state and configuration data |
| kube-scheduler | Watches for newly created Pods with no assigned node, selects a node based on resource requirements, affinity, taints/tolerations |
| kube-controller-manager | Runs controller loops: Node, ReplicaSet, Deployment, Job, ServiceAccount, etc. |
| cloud-controller-manager | Integrates with cloud provider APIs for nodes, routes, load balancers, and volumes |

### Worker Node

| Component | Description |
|-----------|-------------|
| kubelet | Agent on each node, ensures containers are running in Pods as declared by the API server |
| kube-proxy | Maintains network rules (iptables/IPVS) for Service abstraction, handles ClusterIP/NodePort/LoadBalancer routing |
| Container Runtime | Runs containers via CRI interface (containerd, CRI-O) |

## Core Resources

| Resource | Description |
|----------|-------------|
| Pod | Smallest deployable unit, one or more containers sharing network/storage |
| Deployment | Manages ReplicaSets for stateless workloads, supports rolling updates and rollbacks |
| StatefulSet | Manages stateful workloads with stable network IDs and persistent storage |
| DaemonSet | Ensures a Pod runs on all (or selected) nodes |
| Job / CronJob | Runs tasks to completion / on a schedule |
| Service | Stable network endpoint for a set of Pods (ClusterIP, NodePort, LoadBalancer, ExternalName) |
| Ingress | HTTP/HTTPS routing rules, TLS termination, virtual hosting |
| ConfigMap / Secret | Inject configuration and sensitive data into Pods |
| PersistentVolume (PV) / PersistentVolumeClaim (PVC) | Storage abstraction and provisioning |
| Namespace | Logical isolation for resources within a cluster |
| ServiceAccount / RBAC | Identity and access control for Pods and users |
| HPA / VPA | Horizontal and Vertical Pod Autoscalers |
| NetworkPolicy | Pod-level firewall rules (requires CNI plugin support) |

## Deployment Methods

### kubeadm

The official cluster bootstrapping tool.

```bash
# Initialize control plane
kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --apiserver-advertise-address=<MASTER_IP> \
  --kubernetes-version=v1.31.0

# Set up kubeconfig
mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config

# Install CNI plugin (e.g., Calico)
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml

# Join worker nodes
kubeadm join <MASTER_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

### Managed Kubernetes

Cloud-managed control planes with provider integrations:

| Provider | Service | CLI |
|----------|---------|-----|
| AWS | EKS | `eksctl create cluster` |
| Google Cloud | GKE | `gcloud container clusters create` |
| Azure | AKS | `az aks create` |
| Alibaba Cloud | ACK | `aliyun cs CreateCluster` |

### Lightweight / Local

| Tool | Use Case |
|------|----------|
| k3s | Lightweight production-ready distribution (single binary, ~70MB) |
| kind | Kubernetes-in-Docker for CI/CD and local testing |
| minikube | Local single-node cluster for development |
| k0s | Zero-friction Kubernetes distribution |

### Infrastructure as Code

```bash
# Terraform + EKS example
terraform apply -target=module.eks

# Kubespray (Ansible-based)
ansible-playbook -i inventory/mycluster/hosts.yaml cluster.yml
```

## kubectl Quick Reference

```bash
# Cluster info
kubectl cluster-info
kubectl get nodes -o wide
kubectl top nodes

# Workload management
kubectl create deployment nginx --image=nginx:1.27 --replicas=3
kubectl expose deployment nginx --port=80 --type=ClusterIP
kubectl scale deployment nginx --replicas=5
kubectl rollout status deployment/nginx
kubectl rollout undo deployment/nginx

# Debugging
kubectl get pods -A -o wide
kubectl describe pod <pod-name>
kubectl logs <pod-name> -f --previous
kubectl exec -it <pod-name> -- /bin/sh
kubectl events --for pod/<pod-name>

# Resource management
kubectl apply -f manifest.yaml
kubectl diff -f manifest.yaml
kubectl delete -f manifest.yaml
kubectl get all -n <namespace>

# Config and context
kubectl config get-contexts
kubectl config use-context <context-name>
kubectl config set-context --current --namespace=<ns>
```

## Deep Dives

- [Kubernetes Network](k8s-network.md) — Container networking, Service implementation (iptables/IPVS), and flannel CNI
- [Kubernetes RBAC](k8s-rbac.md) — RBAC authorization with Role, ClusterRole, and ServiceAccount
- [Kubeadm Deploy](kubeadm-deploy.md) — Deploy Kubernetes cluster with kubeadm and containerd on Ubuntu
- [Kube Eventer](kube-eventer.md) — Collect cluster events with kube-eventer and send to Kafka/Telegram

> Reference:
>
> 1. [Official Website](https://kubernetes.io/)
> 2. [Repository](https://github.com/kubernetes/kubernetes)
> 3. [Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
> 4. [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
> 5. [kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
