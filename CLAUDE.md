# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **GitBook-based technical knowledge base** covering cloud-native technologies, DevOps practices, and platform engineering. It is published as a GitBook site and can be containerized via Docker for deployment.

- Repository: https://github.com/logic3579/gitbook
- Format: Markdown documents organized following the CNCF landscape taxonomy
- Also used as an Obsidian vault (`.obsidian/` config present)

## Key Files

- `SUMMARY.md` — Table of contents and navigation structure for GitBook. **Must be updated** when adding or removing pages.
- `README.md` — Landing page for the GitBook site.
- `.gitbook.yaml` — GitBook configuration (points to `README.md` and `SUMMARY.md`).

## Local Development

```bash
# Install GitBook CLI
npm install gitbook-cli -g

# Initialize and serve locally
gitbook init
gitbook serve    # Live preview at http://localhost:4000
gitbook build    # Static output to _book/
```

## Content Architecture

The documentation is organized into six top-level sections:

| Section | Purpose |
|---------|---------|
| `CNCF/` | Cloud-native tools organized by CNCF landscape categories (AppDefinition, CNAI, Observability, Orchestration, Provisioning, Runtime, Serverless) |
| `DevOps/` | Programming language references, command manuals, network concepts, service configurations, Linux system topics |
| `Platform/` | Cloud provider guides (AWS, GCP, Alibaba Cloud) and Kubernetes distribution installers (K3S, Kubespray, Minikube, Rancher) |
| `Misc/` | Kubernetes deep-dives, VPN/tunnel technologies, git flow, interviews |
| `Environment/` | Development environment setup |
| `APP-META/` | Docker packaging and CI/CD configuration for this repository |

### CNCF Section Structure

`CNCF/` mirrors the CNCF landscape taxonomy with subcategories:
- `AppDefinitionDevelopment/` — Helm, CI/CD (Argo, GitLab, Jenkins), Databases (MySQL, PostgreSQL, MongoDB, Redis, TiKV), Messaging (Kafka, RabbitMQ, RocketMQ, EMQX)
- `CNAI/` — ML/AI tooling (MLflow, ClickHouse, Flink, PyTorch, TensorFlow)
- `ObservabilityAnalysis/` — Prometheus, Grafana, ELK stack, Loki, Jaeger, OpenTelemetry, Chaos Mesh, OpenCost
- `OrchestrationManagement/` — Kubernetes, Istio, Envoy, Nginx, HAProxy, gRPC, etcd, CoreDNS
- `Provisioning/` — Terraform, Ansible, Salt, Harbor, Vault, Keycloak, Cert Manager
- `Runtime/` — Docker, Containerd, CRI-O, Cilium, CNI, CSI, MinIO, Rook, Velero

## CI/CD

- **GitHub Actions** workflow at `.github/workflows/docker-publish.yml`
- Manually triggered (`workflow_dispatch`) with environment (staging/production) and version inputs
- Publishes Docker images to three registries: Alibaba Cloud ACR, DockerHub, and GitHub Container Registry (GHCR)
- Docker build context: `APP-META/Docker/`

## Conventions for Adding Content

1. Create the markdown file in the appropriate category directory under `CNCF/`, `DevOps/`, `Platform/`, or `Misc/`.
2. Add the entry to `SUMMARY.md` in the correct section with proper indentation to maintain the navigation hierarchy.
3. Each category directory typically has a `README.md` that serves as the section overview page.
4. Embedded YAML configurations and code examples are used extensively throughout the docs — maintain that style.
