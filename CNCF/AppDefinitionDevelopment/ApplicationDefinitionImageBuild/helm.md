---
description: Helm is the package manager for Kubernetes, simplifying application deployment through reusable charts.
tags:
  - cncf/app-definition
  - helm
  - kubernetes
---

# Helm

## Introduction

Helm is the package manager for Kubernetes. It streamlines installing and managing Kubernetes applications by packaging related resources into **charts** — versioned, shareable bundles of pre-configured Kubernetes resource definitions.

### Key Concepts

- **Chart** — A Helm package containing all resource definitions necessary to run an application, tool, or service inside a Kubernetes cluster.
- **Repository** — A place where charts can be collected and shared (e.g., [ArtifactHub](https://artifacthub.io/)).
- **Release** — An instance of a chart running in a Kubernetes cluster. One chart can be installed many times, each creating a new release.
- **Values** — Configuration that can be overridden at install/upgrade time to customize a chart's behavior.

### Architecture

Helm 3 uses a client-only architecture (no Tiller). The Helm client interacts directly with the Kubernetes API server and stores release metadata as Secrets or ConfigMaps in the target namespace.

```text
┌──────────┐     ┌────────────────┐     ┌──────────────┐
│ Helm CLI │────▶│ Kubernetes API │────▶│ etcd (state) │
└──────────┘     └────────────────┘     └──────────────┘
      │
      ▼
┌──────────────┐
│ Chart Repos  │
│ / OCI Registry│
└──────────────┘
```

## Common Operations

```bash
# Add a chart repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Search for charts
helm search repo nginx
helm search hub prometheus

# Install a chart
helm install my-release bitnami/nginx -n my-namespace --create-namespace

# Install with custom values
helm install my-release bitnami/nginx -f custom-values.yaml

# List releases
helm list -A

# Upgrade a release
helm upgrade my-release bitnami/nginx --set replicaCount=3

# Rollback to a previous revision
helm rollback my-release 1

# Uninstall a release
helm uninstall my-release -n my-namespace

# Template rendering (dry-run)
helm template my-release bitnami/nginx -f values.yaml
```

## Chart Development

```bash
# Create a new chart scaffold
helm create my-chart

# Lint a chart for issues
helm lint my-chart/

# Package a chart for distribution
helm package my-chart/

# Push to OCI registry
helm push my-chart-0.1.0.tgz oci://registry.example.com/charts
```

### Chart Structure

```text
my-chart/
├── Chart.yaml          # Chart metadata (name, version, dependencies)
├── values.yaml         # Default configuration values
├── charts/             # Dependency charts
├── templates/          # Kubernetes manifest templates
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── _helpers.tpl    # Template helpers / named templates
│   └── NOTES.txt       # Post-install usage notes
└── .helmignore         # Patterns to ignore when packaging
```

### [CLI Reference](../../../DevOps/CommandManual/container-runtime.md#helm)

> Reference:
>
> 1. [Official Website](https://helm.sh/)
> 2. [Repository](https://github.com/helm/helm)
> 3. [ArtifactHub](https://artifacthub.io/)
