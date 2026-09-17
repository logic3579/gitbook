---
description: Chaos Mesh
tags:
  - cncf/observability
  - kubernetes
---

# Chaos Mesh

## Introduction

Chaos Mesh is a CNCF incubating project that provides a cloud-native chaos engineering platform for Kubernetes. It enables engineers to simulate various fault scenarios (network failures, pod crashes, I/O delays, kernel faults) in a controlled manner to verify system resilience. Chaos Mesh uses CRDs to define chaos experiments, making it easy to integrate into GitOps workflows and CI/CD pipelines.

## Key Features

- **Kubernetes-Native**: All experiments are defined as CRDs and managed by Kubernetes controllers
- **Rich Fault Types**: Pod, network, I/O, stress, time, kernel, DNS, HTTP, and JVM faults
- **Dashboard UI**: Web-based interface for creating and monitoring experiments
- **Workflow Engine**: Orchestrate multi-step chaos experiments with serial, parallel, and conditional execution
- **RBAC Integration**: Fine-grained access control through Kubernetes RBAC
- **Namespace Scoping**: Restrict chaos experiments to specific namespaces for safety

## Installation

```bash
# Add Chaos Mesh Helm repo
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm repo update

# Install Chaos Mesh
helm install chaos-mesh chaos-mesh/chaos-mesh \
  -n chaos-mesh --create-namespace \
  --set chaosDaemon.runtime=containerd \
  --set chaosDaemon.socketPath=/run/containerd/containerd.sock
```

## Experiment Types

### PodChaos

Simulate pod failures such as pod kill, pod failure, or container kill:

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-kill-example
  namespace: chaos-mesh
spec:
  action: pod-kill
  mode: one
  selector:
    namespaces:
      - default
    labelSelectors:
      app: my-app
  scheduler:
    cron: "@every 5m"
```

### NetworkChaos

Inject network faults like delay, loss, duplication, or partition:

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: network-delay-example
spec:
  action: delay
  mode: all
  selector:
    namespaces:
      - default
    labelSelectors:
      app: my-app
  delay:
    latency: "200ms"
    correlation: "50"
    jitter: "50ms"
  duration: "60s"
```

### StressChaos

Apply CPU or memory stress to containers:

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: StressChaos
metadata:
  name: cpu-stress-example
spec:
  mode: one
  selector:
    labelSelectors:
      app: my-app
  stressors:
    cpu:
      workers: 2
      load: 80
  duration: "30s"
```

## Workflow

Chaos Mesh supports orchestrating multiple experiments in a workflow:

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: Workflow
metadata:
  name: serial-chaos-workflow
spec:
  entry: serial-steps
  templates:
    - name: serial-steps
      templateType: Serial
      children:
        - network-delay
        - pod-kill
    - name: network-delay
      templateType: NetworkChaos
      deadline: 60s
      networkChaos:
        action: delay
        mode: one
        selector:
          labelSelectors:
            app: my-app
        delay:
          latency: "100ms"
    - name: pod-kill
      templateType: PodChaos
      deadline: 30s
      podChaos:
        action: pod-kill
        mode: one
        selector:
          labelSelectors:
            app: my-app
```

> Reference:
>
> 1. [Official Website](https://chaos-mesh.org/)
> 2. [Repository](https://github.com/chaos-mesh/chaos-mesh)
