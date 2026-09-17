---
description: Elastic Kubernetes Service
tags:
  - platform/aws
  - kubernetes
---

# Elastic Kubernetes Service

Amazon EKS is a managed Kubernetes service. EKS clusters are typically managed via `eksctl` for cluster/node-group lifecycle and `awscli` for inspection and addon operations.

## Install

### Cluster Init

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

### Manager Machine

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

## CLI

### Clusters

```bash
# eksctl
eksctl create cluster \
  --name=CLUSTER_NAME \
  --region=us-east-1 \
  --version=1.30 \
  --nodegroup-name=ng-1 \
  --node-type=t3.medium \
  --nodes=3 \
  --nodes-min=1 \
  --nodes-max=5
eksctl get cluster --region=us-east-1
eksctl upgrade cluster --name=CLUSTER_NAME --version=1.31 --approve
eksctl delete cluster --name=CLUSTER_NAME --region=us-east-1

# awscli
aws eks list-clusters --region us-east-1
aws eks describe-cluster --name CLUSTER_NAME --region us-east-1
aws eks update-kubeconfig --name CLUSTER_NAME --region us-east-1
```

### Node Groups

```bash
# eksctl
eksctl create nodegroup \
  --cluster=CLUSTER_NAME \
  --name=ng-2 \
  --node-type=t3.large \
  --nodes=3 --nodes-min=1 --nodes-max=10 \
  --node-labels="tier=app"
eksctl get nodegroup --cluster=CLUSTER_NAME
eksctl scale nodegroup --cluster=CLUSTER_NAME --name=ng-2 --nodes=5
eksctl delete nodegroup --cluster=CLUSTER_NAME --name=ng-2

# awscli
aws eks list-nodegroups --cluster-name CLUSTER_NAME --region us-east-1
aws eks describe-nodegroup --cluster-name CLUSTER_NAME --nodegroup-name ng-1 --region us-east-1
aws eks update-nodegroup-config --cluster-name CLUSTER_NAME --nodegroup-name ng-1 \
  --scaling-config minSize=2,maxSize=10,desiredSize=4 --region us-east-1
```

### IRSA (IAM Roles for Service Accounts)

```bash
# Associate OIDC provider once per cluster
eksctl utils associate-iam-oidc-provider \
  --cluster=CLUSTER_NAME --region=us-east-1 --approve

# Create an IAM service account bound to an IAM policy
eksctl create iamserviceaccount \
  --cluster=CLUSTER_NAME \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve
```

### Add-ons

```bash
aws eks list-addons --cluster-name CLUSTER_NAME --region us-east-1
aws eks describe-addon-versions --addon-name vpc-cni --region us-east-1
aws eks create-addon --cluster-name CLUSTER_NAME --addon-name vpc-cni --region us-east-1
aws eks update-addon --cluster-name CLUSTER_NAME --addon-name vpc-cni \
  --addon-version v1.18.0-eksbuild.1 --resolve-conflicts OVERWRITE --region us-east-1
aws eks delete-addon --cluster-name CLUSTER_NAME --addon-name vpc-cni --region us-east-1
```

> Reference:
>
> 1. [Official Website](https://docs.aws.amazon.com/eks/)
> 2. [eksctl](https://eksctl.io/)
