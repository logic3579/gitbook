# AGENTS.md - Agent Guidance for GitBook Documentation Repository

## Project Overview

This is a **GitBook-based technical knowledge base** covering cloud-native technologies, DevOps practices, and platform engineering. The repository contains Markdown documentation organized into structured categories, published as a GitBook site.

- **Repository**: https://github.com/logic3579/gitbook/
- **Format**: Markdown documents following CNCF landscape taxonomy
- **Also used as**: Obsidian vault (`.obsidian/` config present) with the [obsidian-skills](https://github.com/kepano/obsidian-skills) plugin installed
- **Local Dev**: GitBook CLI

---

## Key Files

- `SUMMARY.md` — **Must be updated** when adding or removing pages. Controls navigation sidebar.
- `README.md` — Landing page for the GitBook site.
- `.gitbook.yaml` — GitBook configuration (points to `README.md` and `SUMMARY.md`).
- `CLAUDE.md` — Guidance for Claude Code AI assistant.
- `content-tracker.base` — Obsidian Bases dashboard for tracking content completion status and stub files.
- `doc-audit.base` — Obsidian Bases dashboard for documentation quality audit (freshness, word estimates).
- `CNCF/cncf-landscape.canvas` — Obsidian Canvas visualization of the CNCF technology landscape with tool relationships.
- `CNCF/ObservabilityAnalysis/observability-stack.canvas` — Canvas showing metrics/logs/traces pipelines and their relationships.
- `CNCF/OrchestrationManagement/orchestration-ecosystem.canvas` — Canvas showing K8s-centric ecosystem (service discovery, mesh, gateway, RPC).
- `CNCF/Runtime/runtime-stack.canvas` — Canvas showing container runtime, network, and storage layers.
- `DevOps/CommandManual/command-index.base` — Obsidian Bases dashboard for categorized CLI command reference with content gap tracking.

---

## Build & Development Commands

### GitBook Commands

```bash
# Install GitBook CLI
npm install gitbook-cli -g

# Initialize and serve locally
gitbook init
gitbook serve    # Live preview at http://localhost:4000
gitbook build    # Static output to _book/
```

### Preview

There is no test suite. To verify changes:
- Run `gitbook serve` to preview locally
- Open http://localhost:4000 in browser

---

## Content Architecture

The documentation is organized into six top-level sections:

| Section | Purpose |
|---------|---------|
| `CNCF/` | Cloud-native tools organized by CNCF landscape categories |
| `DevOps/` | Programming languages, command manuals, network concepts, Linux system topics |
| `Platform/` | Cloud provider guides (AWS, GCP, Alibaba Cloud) and Kubernetes distribution installers |
| `Standards/` | Engineering standards: naming conventions, Git Flow, GitHub/GitLab/Docker standards, JiraCDflow |
| `Misc/` | VPN/tunnel technologies and hosting (Science), interviews |
| `Environment/` | Development environment setup (references external repository [logic3579/environment](https://github.com/logic3579/environment)) |

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
- `CommandManual/` — CLI references: ai-coding, automation, big-data, build-tools, container-runtime, database, io-tools, memory-tools, network-tools, openssl, package, streaming-messaging, system-tools, systemd, text-swordsman, version-control, video-tools
- `Network/` — CDN, Computer Network, HTTP, TCP
- `System/` — Boot, iptables, KVM, Linux From Scratch, Nix
- Kernel — Linux kernel topics

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

Some documents point to external repositories instead of containing inline content:
- `Environment/README.md` → [logic3579/environment](https://github.com/logic3579/environment)
- `CNCF/Provisioning/AutomationConfiguration/ansible.md` → [logic3579/automation](https://github.com/logic3579/automation)
- `CNCF/Provisioning/AutomationConfiguration/saltproject.md` → [logic3579/automation](https://github.com/logic3579/automation)
- `CNCF/Provisioning/AutomationConfiguration/terraform.md` → [logic3579/terraform](https://github.com/logic3579/terraform)

---

## Naming Conventions

- **Directories**: PascalCase (e.g., `CommandManual/`, `AppDefinitionDevelopment/`). Acronyms stay uppercase (e.g., `CNCF/`, `CNAI/`, `AWS/`).
- **Documents/files**: kebab-case (e.g., `big-data.md`, `container-runtime.md`, `naming-conventions.md`). Single-word names are just lowercase (e.g., `helm.md`, `docker.md`).
- **Exceptions**: `README.md`, `SUMMARY.md`, `CLAUDE.md`, `AGENTS.md` follow their respective conventions. Non-documentation directories (code, config, assets like `iplib/`, `archery/`) are excluded from the PascalCase rule.

---

## Conventions for Adding Content

1. Create the markdown file (kebab-case name) in the appropriate category directory under `CNCF/`, `DevOps/`, `Platform/`, `Standards/`, or `Misc/`.
2. Add the entry to `SUMMARY.md` in the correct section with proper indentation to maintain the navigation hierarchy.
3. Each category directory has a `README.md` that serves as the section overview page, following this format: frontmatter (`icon` + `description`) → H1 title → one-line description → sub-page list with brief descriptions.
4. Embedded YAML configurations and code examples are used extensively throughout the docs — maintain that style.
5. For tools with dedicated external repositories, use the reference format (frontmatter + brief description + repository link + official references) instead of inline content. See `ansible.md` as a template.
6. Images are hosted on Cloudflare R2 (`https://gitbook-r2.yakir.top/`). See **Markdown Conventions → Links & Images** for the upload workflow. Local `attachements/` directories are no longer used.

---

## Markdown Conventions

### Frontmatter

**Required for ALL documents:**
```yaml
---
description: <brief description>
tags:
  - <hierarchical-tag>
  - <sub-category-tag>
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

### Tags

All content files (non-README) should include `tags` in frontmatter for Obsidian navigation. Use hierarchical nested tags with `/` separator:
- CNCF section: `cncf/app-definition`, `cncf/cnai`, `cncf/observability`, `cncf/orchestration`, `cncf/provisioning`, `cncf/runtime`
- DevOps section: `devops/language`, `devops/command`, `devops/network`, `devops/system`
- Platform section: `platform/aws`, `platform/gcp`, `platform/alibaba`
- Standards section: `standards`
- Misc section: `misc/vpn`, `misc/interview`
- Sub-category tags: `database`, `messaging`, `ci-cd`, `monitoring`, `logging`, `tracing`, `kubernetes`, `networking`, `security`, `container`, `storage`, `service-mesh`, `service-proxy`, `api-gateway`, `service-discovery`, `configuration`, `helm`

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
- **Images**: Hosted on Cloudflare R2; reference with absolute URL: `![alt](https://gitbook-r2.yakir.top/<prefix><filename>)`. To add a new image:
  1. Pick the section prefix from the table below.
  2. Use a URL-safe filename (lowercase, hyphens — no spaces).
  3. Upload via rclone: `rclone copyto path/to/image.png logic-r2:gitbook/<prefix><filename>`.
  4. Reference the resulting `https://gitbook-r2.yakir.top/<prefix><filename>` URL in markdown.

  | Section | Prefix |
  |---------|--------|
  | `CNCF/ObservabilityAnalysis/Observability/` | `cncf-observability-` |
  | `CNCF/OrchestrationManagement/SchedulingOrchestration/Kubernetes/` | `cncf-kubernetes-` |
  | `CNCF/Runtime/ContainerRuntime/` | `cncf-runtime-` |
  | `DevOps/Network/` | `devops-network-` |
  | `DevOps/System/` | `devops-system-` |
  | `Platform/AlibabaCloud/` | `platform-alibaba-` |
  | `Standards/` | `standards-` |
- Do NOT use Obsidian WikiLink format `[[...]]`
- Do NOT use non-standard image syntax (e.g., `asset_img`)
- Do NOT store images in local `attachements/` directories — they are not rendered after deployment.

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

## Obsidian Integration

This vault uses the [obsidian-skills](https://github.com/kepano/obsidian-skills) plugin, which provides `obsidian-markdown`, `obsidian-bases`, and `json-canvas` skills.

- **Bases** (`.base` files): Used for dashboard views of vault content (content tracking, quality audit). Root-level bases track the whole vault; section-level bases (e.g., `DevOps/CommandManual/command-index.base`) focus on specific directories.
- **Canvas** (`.canvas` files): Used for visual architecture maps. Top-level canvas (e.g., `CNCF/cncf-landscape.canvas`) shows the full landscape; second-level canvas files (e.g., `CNCF/ObservabilityAnalysis/observability-stack.canvas`) zoom into specific domains with detailed data flows and dependencies.
- **Compatibility**: Content files must use standard Markdown links (not wikilinks) for GitBook compatibility. Obsidian-specific features (tags, bases, canvas) are additive and do not affect GitBook rendering.

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
- Images hosted on Cloudflare R2 at `https://gitbook-r2.yakir.top/`

---

## Pre-commit Checklist

Before every git commit and push, **always update `AGENTS.md`** to reflect any structural changes made in the session (new files, moved directories, updated conventions, etc.). This ensures the project documentation stays in sync with the actual codebase.
- Added DevOps/rust.md for Rust language documentation, following DevOps/nodejs.md format.
