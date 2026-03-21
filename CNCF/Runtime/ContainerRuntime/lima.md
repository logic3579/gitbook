---
description: Linux virtual machines, typically on macOS, for running containerd
tags:
  - cncf/runtime
  - container
---

# Lima

## Introduction

Lima (Linux Machines) is an open-source tool for running Linux virtual machines on macOS (and Linux), with a focus on providing containerd as the container runtime. It serves as a lightweight alternative to Docker Desktop, automatically handling file sharing, port forwarding, and containerd/nerdctl setup. Lima uses QEMU or Apple's Virtualization.framework (vz) as the VM backend.

## Key Features

- **Automatic containerd Setup**: Ships with containerd and nerdctl pre-configured
- **File Sharing**: Bidirectional file sharing between host and guest (reverse-sshfs, virtiofs, 9p)
- **Port Forwarding**: Automatic forwarding of ports from guest to host
- **Multi-Architecture**: Support for x86_64 and aarch64 VMs, including Rosetta for x86 emulation on Apple Silicon
- **Multiple VM Types**: Templates for containerd, Docker, Podman, Kubernetes (k3s, k8s), and more
- **macOS Integration**: Native support for Apple Virtualization.framework (vz) with better performance

## Installation

```bash
# Install via Homebrew
brew install lima

# Verify installation
limactl --version
```

## Usage

### Create and Start a VM

```bash
# Create default VM (containerd + nerdctl)
limactl start

# Create VM from a specific template
limactl start template://k3s
limactl start template://docker

# List running VMs
limactl list

# Shell into a VM
limactl shell default

# Stop and delete a VM
limactl stop default
limactl delete default
```

### Using nerdctl (containerd CLI)

Lima provides `nerdctl` as a Docker-compatible CLI for containerd:

```bash
# Run containers (inside Lima VM or via lima prefix)
lima nerdctl run -d --name nginx -p 8080:80 nginx:latest
lima nerdctl ps
lima nerdctl images
lima nerdctl build -t my-app .
```

## Configuration

Lima VMs are configured via YAML files (`~/.lima/<instance>/lima.yaml`):

```yaml
# VM resource allocation
cpus: 4
memory: "8GiB"
disk: "100GiB"

# Use Apple Virtualization.framework (better performance on macOS)
vmType: vz
rosetta:
  enabled: true  # Enable Rosetta for x86 emulation on Apple Silicon

# Mount directories from host
mounts:
  - location: "~"
    writable: false
  - location: "/tmp/lima"
    writable: true

# Port forwarding rules
portForwards:
  - guestPort: 8080
    hostPort: 8080
  - guestPortRange: [30000, 32767]  # NodePort range for K8s

# containerd configuration
containerd:
  system: false
  user: true
```

### Kubernetes with Lima

Use the k3s template for a lightweight Kubernetes cluster:

```bash
# Start a k3s VM
limactl start template://k3s

# Access the cluster
export KUBECONFIG=$(limactl list k3s --format '{{.Dir}}/copied-from-guest/kubeconfig.yaml')
kubectl get nodes
```

> Reference:
>
> 1. [Official Website](https://lima-vm.io/)
> 2. [Repository](https://github.com/lima-vm/lima)
