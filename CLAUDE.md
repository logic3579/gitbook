# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **GitBook-based technical knowledge base** covering cloud-native technologies, DevOps practices, and platform engineering. It is published as a GitBook site.

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

The documentation is organized into seven top-level sections:

| Section | Purpose |
|---------|---------|
| `CNCF/` | Cloud-native tools organized by CNCF landscape categories |
| `DevOps/` | Programming languages, command manuals, network concepts, service configurations, Linux system topics |
| `Platform/` | Cloud provider guides (AWS, GCP, Alibaba Cloud) and Kubernetes distribution installers |
| `Standards/` | Engineering standards: naming conventions, Git Flow, GitHub/GitLab/Docker standards, JiraCDflow |
| `Misc/` | Kubernetes deep-dives, VPN/tunnel technologies (Science), hosting, interviews |
| `Environment/` | Development environment setup (references external repository [logic3579/environment](https://github.com/logic3579/environment)) |

### CNCF Section Structure

`CNCF/` mirrors the CNCF landscape taxonomy with subcategories:
- `AppDefinitionDevelopment/` — Helm, CI/CD (Argo, GitLab, Jenkins), Databases (MySQL, PostgreSQL, MongoDB, Redis, TiKV), Messaging (Kafka, RabbitMQ, RocketMQ, EMQX)
- `CNAI/` — Data Architecture (ClickHouse, Flink), Data Science (PyTorch, TensorFlow)
- `ObservabilityAnalysis/` — Chaos Engineering (Chaos Mesh), Continuous Optimization (OpenCost), Observability (Prometheus, Grafana, Elasticsearch, Fluentd, Logstash, Loki, Jaeger, OpenTelemetry)
- `OrchestrationManagement/` — API Gateway (Higress, Tyk), Coordination & Service Discovery (CoreDNS, Etcd, Nacos, ZooKeeper), RPC (gRPC), Scheduling & Orchestration (Kubernetes), Service Mesh (Istio), Service Proxy (Envoy, HAProxy, Nginx)
- `Provisioning/` — Automation & Configuration (Ansible, Apollo, OpenStack, Salt Project, Terraform), Container Registry (Harbor), Key Management (Vault), Security & Compliance (Cert Manager, Keycloak)
- `Runtime/` — Cloud Native Network (Cilium, CNI), Cloud Native Storage (CSI, MinIO, Rook, Velero), Container Runtime (Docker, Containerd, CRI-O, Lima)
- `Serverless/` — (Section placeholder)

### DevOps Section Structure

- Programming Languages: Bash, Golang, Java, Node.js, Python, Ruby
- `CommandManual/` — CLI references: Automation, BuildTools, ContainerRuntime, Database, IOTools, MemoryTools, NetworkTools, OpenSSL, Package, StreamingMessaging, SystemTools, Systemd, TextSwordsman, VersionControl, VideoTools
- `Network/` — CDN, Computer Network, HTTP, NFS, TCP
- `ServiceConf/` — Service configuration guides: Elasticsearch, Grafana, Jenkins, Kafka, MongoDB, MySQL, Nginx, Observability, PostgreSQL, Redis, Saltstack
- `System/` — Boot, iptables, KVM, Linux From Scratch, Nix
- Kernel — Linux kernel topics

### Standards Section Structure

- `naming-conventions.md` — Naming standards for projects, cloud resources, Kubernetes, and docs
- `gitflow.md` — Git branching strategy and workflow
- `JiraCDflow/` — Jira-based release automation workflow
- `github-standards.md` — GitHub project management and release standards
- `gitlab-standards.md` — GitLab project management and release standards
- `docker-standards.md` — Docker image build and release standards

### External Repository References

Some documents point to external repositories instead of containing inline content:
- `Environment/README.md` → [logic3579/environment](https://github.com/logic3579/environment)
- `CNCF/Provisioning/AutomationConfiguration/ansible.md` → [logic3579/automation](https://github.com/logic3579/automation)
- `CNCF/Provisioning/AutomationConfiguration/saltproject.md` → [logic3579/automation](https://github.com/logic3579/automation)
- `CNCF/Provisioning/AutomationConfiguration/terraform.md` → [logic3579/terraform](https://github.com/logic3579/terraform)

## Conventions for Adding Content

1. Create the markdown file in the appropriate category directory under `CNCF/`, `DevOps/`, `Platform/`, `Standards/`, or `Misc/`.
2. Add the entry to `SUMMARY.md` in the correct section with proper indentation to maintain the navigation hierarchy.
3. Each category directory typically has a `README.md` that serves as the section overview page.
4. Embedded YAML configurations and code examples are used extensively throughout the docs — maintain that style.
5. For tools with dedicated external repositories, use the reference format (frontmatter + brief description + repository link + official references) instead of inline content. See `ansible.md` as a template.
6. Image attachments are stored in `attachements/` subdirectories alongside the referencing documents.

### Markdown Conventions

- **Frontmatter**: Every document should have `description` field. Top-level and second-level directory `README.md` files should include an `icon` field (using [FontAwesome](https://fontawesome.com/icons) icon names). Regular content documents (non-README) do not need `icon`.
- **H1 title**: Must match the official tool/project name (e.g., `# ClickHouse`, `# Elasticsearch`, not `# Overview`)
- **Reference format**: Use the standardized blockquote format at the end of each document:
  ```markdown
  > Reference:
  >
  > 1. [Official Website](https://example.com/)
  > 2. [Repository](https://github.com/org/repo)
  ```
- **Links**: Use standard Markdown links, not Obsidian WikiLink format (`[[...]]`)
