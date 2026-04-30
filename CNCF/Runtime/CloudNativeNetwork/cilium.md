---
description: Cilium is an eBPF-based networking, observability, and security solution for Kubernetes and cloud-native environments.
tags:
  - cncf/runtime
  - networking
  - kubernetes
---

# Cilium

## Introduction

Cilium is an open-source project that provides eBPF-powered networking, security, and observability for cloud-native environments. It is a CNCF graduated project and serves as the default CNI for many Kubernetes distributions.

### Key Features

- **eBPF-Based Data Plane** — Uses extended Berkeley Packet Filter (eBPF) in the Linux kernel for high-performance packet processing without iptables.
- **Network Policy** — Supports both Kubernetes NetworkPolicy and extended CiliumNetworkPolicy with L3/L4/L7 enforcement.
- **Service Mesh** — Provides sidecar-less service mesh capabilities using eBPF (mTLS, traffic management, L7 load balancing).
- **Hubble** — Built-in observability platform for monitoring network flows, DNS queries, and HTTP requests.
- **Cluster Mesh** — Connects multiple Kubernetes clusters with pod-to-pod connectivity and shared services.
- **BGP Support** — Native BGP peering for advertising pod CIDRs and LoadBalancer IPs.

### Architecture

```text
┌─────────────────────────────────────────┐
│           Kubernetes Cluster            │
│                                         │
│  ┌──────────┐   ┌──────────────────┐   │
│  │  Cilium   │   │  Hubble          │   │
│  │  Operator │   │  (Observability) │   │
│  └──────────┘   └──────────────────┘   │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  Cilium Agent (per node)         │  │
│  │  ┌───────────┐  ┌────────────┐  │  │
│  │  │ eBPF      │  │ IPAM       │  │  │
│  │  │ Programs  │  │ (allocator)│  │  │
│  │  └───────────┘  └────────────┘  │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## How to Install

### Starting via Kubernetes

Install via Helm:

```bash
# Add Cilium Helm repository
helm repo add cilium https://helm.cilium.io/
helm repo update

# Install Cilium (replace existing CNI)
helm install cilium cilium/cilium \
  --namespace kube-system \
  --set operator.replicas=2 \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true

# Verify installation
cilium status --wait
```

Install via Cilium CLI:

```bash
# Install Cilium CLI
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
curl -L --fail --remote-name-all \
  https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-amd64.tar.gz
sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin

# Install Cilium
cilium install

# Enable Hubble observability
cilium hubble enable --ui

# Validate connectivity
cilium connectivity test
```

### Network Policy Example

```yaml
# Allow HTTP GET to /api from frontend pods only
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: api-access
spec:
  endpointSelector:
    matchLabels:
      app: backend
  ingress:
    - fromEndpoints:
        - matchLabels:
            app: frontend
      toPorts:
        - ports:
            - port: "8080"
              protocol: TCP
          rules:
            http:
              - method: "GET"
                path: "/api/.*"
```

> Reference:
>
> 1. [Official Website](https://cilium.io/)
> 2. [Repository](https://github.com/cilium/cilium)
> 3. [Hubble](https://github.com/cilium/hubble)
