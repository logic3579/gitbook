---
description: Aliyun Container Service for Kubernetes
tags:
  - platform/aliyun
  - kubernetes
---

# ACK

Aliyun Container Service for Kubernetes (ACK) is the managed Kubernetes service. Clusters are managed via the `aliyun cs` CLI; `kubectl` access requires fetching kubeconfig from ACK.

## Cluster Types

| Type | Use Case |
|------|----------|
| **ACK Managed Pro** | Production, SLA-backed managed control plane (recommended) |
| **ACK Managed Basic** | Cost-sensitive, smaller scale |
| **ACK Dedicated** | Self-managed control plane on ECS |
| **ACK Serverless (ASK)** | Pod-only billing, no node management |
| **ACK Edge** | Edge computing scenarios |

## Install

### Cluster Init

Create via console (most common) or `aliyun cs CreateCluster` with a JSON body. Key inputs:

```console
# Cluster basics
Name: prod-ack
Region: cn-hangzhou
Kubernetes Version: 1.30.x
Cluster Type: ACK Managed Pro

# Networking
Network Plugin: Terway (recommended) | Flannel
VPC: vpc-xxx
vSwitches: vsw-aaa, vsw-bbb (multi-AZ)
Service CIDR: 172.21.0.0/20
Pod CIDR (Flannel only): 172.20.0.0/16

# Control plane
API Server: SLB internal | public
Audit Logs: enabled
RRSA: enabled

# Add-ons
csi-plugin, csi-provisioner          # CSI for cloud disk / NAS / OSS
metrics-server
nginx-ingress-controller
ack-node-problem-detector
logtail-ds                           # SLS log collection
```

### Manager Machine

```bash
# aliyun CLI
curl -L -o aliyun-cli.tgz https://aliyuncli.alicdn.com/aliyun-cli-linux-latest-amd64.tgz
tar -xzf aliyun-cli.tgz && sudo mv aliyun /usr/local/bin/
aliyun configure                              # set AK/SK + region

# kubectl + helm
KUBECTL_VERSION=v1.30.5
curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
sudo install -m 0755 kubectl /usr/local/bin/kubectl

HELM_VERSION=v3.16.2
wget https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz
tar xf helm-${HELM_VERSION}-linux-amd64.tar.gz
sudo install -m 0755 linux-amd64/helm /usr/local/bin/helm

# Fetch kubeconfig
mkdir -p ~/.kube
aliyun cs DescribeClusterUserKubeconfig --ClusterId CLUSTER_ID --PrivateIpAddress false \
  --output cols=config | tail -n +2 > ~/.kube/config
chmod 600 ~/.kube/config
kubectl get nodes

# bash completion
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "source <(helm completion bash)" >> ~/.bashrc
```

## CLI

### Clusters

```bash
aliyun cs DescribeClusters --RegionId cn-hangzhou
aliyun cs DescribeClusterDetail --ClusterId CLUSTER_ID
aliyun cs DescribeClusterUserKubeconfig --ClusterId CLUSTER_ID --PrivateIpAddress false
aliyun cs UpgradeCluster --ClusterId CLUSTER_ID \
  --body '{"next_version":"1.30.5-aliyun.1"}'
aliyun cs DeleteCluster --ClusterId CLUSTER_ID

# Create via JSON body
aliyun cs CreateCluster --body "$(cat cluster.json)"
```

### Node Pools

```bash
aliyun cs DescribeClusterNodePools --ClusterId CLUSTER_ID
aliyun cs DescribeClusterNodePoolDetail --ClusterId CLUSTER_ID --NodepoolId NP_ID

aliyun cs CreateClusterNodePool --ClusterId CLUSTER_ID \
  --body "$(cat nodepool.json)"
aliyun cs ScaleClusterNodePool --ClusterId CLUSTER_ID --NodepoolId NP_ID \
  --body '{"count":5}'
aliyun cs ModifyClusterNodePool --ClusterId CLUSTER_ID --NodepoolId NP_ID \
  --body '{"auto_scaling":{"enable":true,"min_instances":1,"max_instances":10}}'
aliyun cs DeleteClusterNodepool --ClusterId CLUSTER_ID --NodepoolId NP_ID
```

Example `nodepool.json`:

```json
{
  "nodepool_info": { "name": "app-pool" },
  "scaling_group": {
    "instance_types": ["ecs.g7.xlarge"],
    "vswitch_ids": ["vsw-xxx"],
    "system_disk_category": "cloud_essd",
    "system_disk_size": 100,
    "login_password": "..."
  },
  "kubernetes_config": {
    "labels": [{ "key": "tier", "value": "app" }],
    "taints": [],
    "runtime": "containerd"
  },
  "count": 3
}
```

### RRSA (RAM Roles for Service Accounts)

ACK's equivalent of EKS IRSA / GKE Workload Identity — bind a K8s ServiceAccount to a RAM role via OIDC.

```bash
# Enable RRSA on the cluster
aliyun cs UpdateClusterRRSAConfig --ClusterId CLUSTER_ID \
  --body '{"enable_rrsa":true}'

# Inspect cluster OIDC issuer (used in RAM role trust policy)
aliyun cs DescribeClusterDetail --ClusterId CLUSTER_ID \
  --output cols=meta_data
```

Bind the role via ServiceAccount annotation:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-sa
  namespace: default
  annotations:
    pod-identity.alibabacloud.com/role-arn: acs:ram::ACCOUNT_ID:role/ROLE_NAME
```

> RAM role creation with web identity trust policy is covered in [ram.md](ram.md).

### Add-ons

```bash
aliyun cs DescribeClusterAddonsVersion --ClusterId CLUSTER_ID
aliyun cs DescribeClusterAddonInstance --ClusterId CLUSTER_ID --AddonName csi-plugin

aliyun cs InstallClusterAddons --ClusterId CLUSTER_ID \
  --body '{"addons":[{"name":"nginx-ingress-controller"}]}'
aliyun cs UpgradeClusterAddons --ClusterId CLUSTER_ID \
  --body '{"addons":[{"component_name":"csi-plugin","next_version":"v1.30.0"}]}'
aliyun cs UnInstallClusterAddons --ClusterId CLUSTER_ID \
  --body '{"addons":[{"name":"nginx-ingress-controller"}]}'
```

### Cluster Tasks

```bash
# Track long-running operations (cluster create, upgrade, scale)
aliyun cs DescribeTaskInfo --task_id TASK_ID
aliyun cs DescribeClusterTasks --ClusterId CLUSTER_ID
```

> Reference:
>
> 1. [Official Website](https://www.aliyun.com/product/kubernetes)
> 2. [ACK Documentation](https://help.aliyun.com/product/85222.html)
> 3. [RRSA Overview](https://help.aliyun.com/document_detail/356611.html)
