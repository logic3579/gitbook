---
description: Container runtime interface OCI
tags:
  - cncf/runtime
  - container
---

# CRI-O

## Introduction

CRI-O is a lightweight container runtime specifically designed for Kubernetes. It implements the Kubernetes Container Runtime Interface (CRI) using OCI-compatible runtimes, providing a minimal and stable alternative to Docker and containerd for running containers in Kubernetes clusters. CRI-O follows the Kubernetes release cycle, with each CRI-O minor version matching the corresponding Kubernetes minor version.

## Key Features

- **CRI-Native**: Built exclusively to implement the Kubernetes CRI specification
- **OCI-Compatible**: Supports any OCI-compliant runtime (runc, crun, Kata Containers)
- **Minimal Footprint**: No daemon bloat -- only implements what Kubernetes needs
- **Version Alignment**: CRI-O 1.x.y is compatible with Kubernetes 1.x.y
- **Image Management**: Pulls images from any OCI-compliant or Docker registry
- **Conmon**: Lightweight container monitor that tracks container lifecycle

## Architecture

CRI-O sits between the kubelet and the OCI runtime:

```
kubelet → CRI (gRPC) → CRI-O → OCI Runtime (runc/crun)
                           ↓
                        conmon (container monitor)
```

Components:
- **CRI-O daemon**: Receives CRI calls from kubelet
- **conmon**: Per-container process that monitors the container and handles logging
- **OCI runtime**: Actual container executor (default: runc)
- **CNI plugins**: Network configuration for pods
- **containers/image**: Image pull and management library

## Installation

### RHEL/CentOS/Fedora

```bash
# Set Kubernetes version
KUBERNETES_VERSION=v1.30
CRIO_VERSION=v1.30

# Add repositories
curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/rpm/repodata/repomd.xml.key | \
  gpg --dearmor -o /etc/pki/rpm-gpg/RPM-GPG-KEY-cri-o

# Install CRI-O
dnf install -y cri-o
systemctl enable --now crio
```

### Verify Installation

```bash
# Check CRI-O status
systemctl status crio

# Verify with crictl
crictl info
crictl version
```

## Configuration

CRI-O configuration is located at `/etc/crio/crio.conf`:

```toml
[crio]
  log_dir = "/var/log/crio/pods"
  log_level = "info"

[crio.api]
  listen = "/var/run/crio/crio.sock"
  grpc_max_send_msg_size = 83886080
  grpc_max_recv_msg_size = 83886080

[crio.runtime]
  default_runtime = "runc"
  conmon = "/usr/bin/conmon"
  cgroup_manager = "systemd"

  [crio.runtime.runtimes.runc]
    runtime_path = "/usr/bin/runc"
    runtime_type = "oci"

[crio.image]
  pause_image = "registry.k8s.io/pause:3.9"

[crio.network]
  network_dir = "/etc/cni/net.d/"
  plugin_dir = "/opt/cni/bin/"
```

### Kubeadm Integration

Configure kubeadm to use CRI-O as the container runtime:

```yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
nodeRegistration:
  criSocket: unix:///var/run/crio/crio.sock
```

> Reference:
>
> 1. [Official Website](https://cri-o.io/)
> 2. [Repository](https://github.com/cri-o/cri-o)
