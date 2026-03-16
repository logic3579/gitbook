# AGENTS.md - Agent Guidance for GitBook Documentation Repository

## Project Overview

This is a **GitBook-based technical knowledge base** covering cloud-native technologies, DevOps practices, and platform engineering. The repository contains Markdown documentation organized into structured categories, published as a GitBook site.

- **Repository**: https://github.com/logic3579/gitbook/
- **Format**: Markdown documents following CNCF landscape taxonomy
- **Also used as**: Obsidian vault (`.obsidian/` config present)
- **Local Dev**: GitBook CLI

---

## Key Files

- `SUMMARY.md` — **Must be updated** when adding or removing pages. Controls navigation sidebar.
- `README.md` — Landing page for the GitBook site.
- `.gitbook.yaml` — GitBook configuration (points to `README.md` and `SUMMARY.md`).
- `CLAUDE.md` — Guidance for Claude Code AI assistant.

---

## Build & Development Commands

### GitBook Commands

```bash
# Install GitBook CLI (requires Node.js)
npm install gitbook-cli -g

# Initialize (run once after clone)
gitbook init

# Serve locally (live preview at http://localhost:4000)
gitbook serve

# Build static output to _book/
gitbook build
```

### Preview

There is no test suite. To verify changes:
- Run `gitbook serve` to preview locally
- Open http://localhost:4000 in browser

---

## Content Organization

### Main Sections

| Section | Purpose |
|---------|---------|
| `CNCF/` | Cloud-native tools organized by CNCF landscape categories |
| `DevOps/` | Programming languages, command manuals, network concepts, service configurations, Linux system topics |
| `Platform/` | Cloud provider guides (AWS, GCP, Alibaba Cloud) and Kubernetes distribution installers |
| `Standards/` | Engineering standards: naming conventions, Git Flow, GitHub/GitLab/Docker standards, JiraCDflow |
| `Misc/` | VPN/tunnel technologies and hosting (Science), interviews |
| `Environment/` | Development environment setup (references external repository) |

### CNCF Section Structure

`CNCF/` mirrors the CNCF landscape taxonomy with subcategories:
- `AppDefinitionDevelopment/` — Helm, CI/CD (Argo, GitLab, Jenkins), Databases (MySQL, PostgreSQL, MongoDB, Redis, TiKV), Messaging (Kafka, RabbitMQ, RocketMQ, EMQX)
- `CNAI/` — Data Architecture (ClickHouse, Flink), Data Science (PyTorch, TensorFlow)
- `ObservabilityAnalysis/` — Chaos Engineering (Chaos Mesh), Continuous Optimization (OpenCost, Kubecost), Observability (Prometheus, Grafana, Elasticsearch, Fluentd, Logstash, Loki, Jaeger, OpenTelemetry)
- `OrchestrationManagement/` — API Gateway (Higress, Tyk), Coordination & Service Discovery (CoreDNS, Etcd, Nacos, ZooKeeper), RPC (gRPC), Scheduling & Orchestration (Kubernetes: Network, RBAC, Kubeadm Deploy, Kube Eventer), Service Mesh (Istio), Service Proxy (Envoy, HAProxy, Nginx)
- `Provisioning/` — Automation & Configuration (Ansible, Apollo, OpenStack, Salt Project, Terraform), Container Registry (Harbor), Key Management (Vault), Security & Compliance (Cert Manager, Keycloak)
- `Runtime/` — Cloud Native Network (Cilium, CNI), Cloud Native Storage (CSI, MinIO, Rook, Velero), Container Runtime (Docker, Containerd, CRI-O, Lima)
- `Serverless/` — (Section placeholder)

### DevOps Section Structure

- Programming Languages: Bash, Golang, Java, Node.js, Python, Ruby
- `CommandManual/` — CLI references: automation, big-data, build-tools, container-runtime, database, io-tools, memory-tools, network-tools, openssl, package, streaming-messaging, system-tools, systemd, text-swordsman, version-control, video-tools
- `Network/` — CDN, Computer Network, HTTP, TCP
- `ServiceConf/` — Service configuration guides: Elasticsearch, Grafana, Jenkins, Kafka, MongoDB, MySQL, Nginx, Observability, PostgreSQL, Redis, Saltstack
- `System/` — Boot, iptables, KVM, Linux From Scratch, Nix

### Platform Section Structure

- `AlibabaCloud/` — RAM, VPC
- `AWS/` — CloudFront, EC2, EKS
- `GoogleCloud/` — gcloud, GCE, GKE
- `distribution-installer.md` — Kubernetes distribution installation guides

### Standards Section Structure

- `naming-conventions.md` — Naming standards for projects, cloud resources, Kubernetes, and docs
- `gitflow.md` — Git branching strategy and workflow
- `JiraCDflow/` — Jira-based release automation workflow
- `github-standards.md` — GitHub project management and release standards
- `gitlab-standards.md` — GitLab project management and release standards
- `docker-standards.md` — Docker image build and release standards

### Misc Section Structure

- `Science/` — VPN/tunnel technologies (V2Ray, IPsec, OpenVPN, SSH Tunnel, WireGuard, Outline, ShadowsocksR), hosting
- `interview.md` — Interview preparation

### External Repository References

For tools with dedicated external repositories, use reference format instead of inline content:
- `Environment/README.md` → [logic3579/environment](https://github.com/logic3579/environment)
- `CNCF/Provisioning/AutomationConfiguration/ansible.md` → [logic3579/automation](https://github.com/logic3579/automation)
- `CNCF/Provisioning/AutomationConfiguration/saltproject.md` → [logic3579/automation](https://github.com/logic3579/automation)
- `CNCF/Provisioning/AutomationConfiguration/terraform.md` → [logic3579/terraform](https://github.com/logic3579/terraform)

---

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Directories | PascalCase | `CNCF/`, `DevOps/`, `CommandManual/` |
| Acronyms | Uppercase | `CNCF/`, `CNAI/`, `AWS/` |
| Documents | kebab-case | `docker.md`, `kubernetes-network.md`, `big-data.md` |
| Single-word docs | lowercase | `helm.md`, `docker.md` |
| Exceptions | Fixed names | `README.md`, `SUMMARY.md`, `CLAUDE.md`, `AGENTS.md` |

**Note**: Non-documentation directories (code, config, assets like `attachements/`, `iplib/`, `archery/`) are excluded from the PascalCase rule.

---

## Markdown Conventions

### Frontmatter

**Required for ALL documents:**
```yaml
---
description: <brief description>
---
```

**Required for section README files (directories):**
```yaml
---
icon: <fontawesome-icon-name>
description: <section description>
---
```

**Icon Examples**: `bullseye-arrow`, `robot`, `circle-dot`, `hand-wave`, `magnifying-glass-chart`

### H1 Title

Must match the official tool/project name exactly:
- ✅ `# Docker`, `# Kubernetes`, `# Prometheus`, `# ClickHouse`
- ❌ `# Overview`, `# Introduction to Docker`

### Section README Format

```markdown
---
icon: <icon>
description: <description>
---

# SectionName

<one-line description>

- [Page1](path/page1.md) — <brief desc>
- [Page2](path/page2.md) — <brief desc>
```

### Reference Blocks

Place at document end using blockquote format:
```markdown
> Reference:
>
> 1. [Official Website](https://example.com/)
> 2. [Repository](https://github.com/org/repo)
```

### Links & Images

- **Links**: Use standard Markdown `[text](url)`
- **Images**: Use standard Markdown `![alt](attachements/image.png)`
- Do NOT use Obsidian WikiLink format `[[...]]`
- Do NOT use non-standard image syntax (e.g., `asset_img`)

### Code Blocks

- Use fenced code blocks with language identifier
- Include comments for clarity in technical content
- Keep code examples accurate and tested

---

## Navigation

### SUMMARY.md Structure

The `SUMMARY.md` file controls the GitBook navigation sidebar:
```markdown
# Table of contents

- [Introduction](./README.md)

## Section Name

- [Overview](./Section/README.md)
  - [Page1](./Section/page1.md)
  - [Page2](./Section/page2.md)
```

**Must update SUMMARY.md** when adding or removing pages. Maintain proper indentation hierarchy.

---

## What NOT To Do

- Do NOT use Obsidian WikiLinks (`[[...]]`)
- Do NOT use non-standard image syntax (e.g., `asset_img`)
- Do NOT use generic H1 titles like "Overview" or "Introduction"
- Do NOT skip frontmatter `description` field
- Do NOT forget to update SUMMARY.md when modifying pages
- Do NOT use PascalCase or camelCase for document filenames

---

## Common Tasks

### Adding a New Tool/Page

1. Create markdown file in appropriate directory (kebab-case)
2. Add frontmatter with `description`
3. Add H1 matching official name
4. Add content following existing patterns
5. Add reference block at end
6. Update SUMMARY.md with new entry

### Adding External Repository Reference

For tools with dedicated external repositories:
1. Create markdown file with frontmatter + brief description
2. Add repository link and official references
3. See `ansible.md` or `terraform.md` as template
4. Update SUMMARY.md

### Modifying Navigation

Edit `SUMMARY.md` — maintain indentation hierarchy. GitBook generates sidebar from this file.

---

## Editor Configuration

No specific linter or formatter configured. Recommended:
- Use a Markdown linter (e.g., markdownlint) for consistent formatting
- Configure editor to use 2-space indentation
- Enable Markdown preview in editor

---

## Notes

- This is a documentation-only repository (no code, no tests)
- Content is in English with some Chinese technical terms
- Images stored in `attachements/` subdirectories alongside referencing docs
