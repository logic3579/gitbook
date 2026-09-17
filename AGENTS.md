# AGENTS.md

Guidance for coding agents working in this repository.

## Project Overview

This is a **GitBook-based technical knowledge base** covering cloud-native technologies, DevOps practices, and platform engineering.

- Repository: https://github.com/logic3579/gitbook
- Format: Markdown, organized by the CNCF landscape taxonomy
- Published by GitBook Git sync (`.gitbook.yaml` points at `README.md` and `SUMMARY.md`)
- Also used as an Obsidian vault (`.obsidian/`). Agent skills: [obsidian-skills](https://github.com/kepano/obsidian-skills) (`obsidian-markdown`, `obsidian-bases`, `json-canvas`)

Do not use the legacy `gitbook-cli` (`gitbook serve` / `gitbook build`). There is no Node toolchain in this repo. Edit Markdown and let GitBook sync from Git. Local authoring is in the editor or Obsidian.

## Source of Truth

| Concern | File |
|---------|------|
| Site navigation | `SUMMARY.md` — **must** be updated when adding, removing, or moving pages |
| Landing page | `README.md` |
| GitBook site config | `.gitbook.yaml` |
| Agent conventions | `AGENTS.md` (this file) |

Do **not** copy the page catalog into this file. `SUMMARY.md` is the inventory; this file only describes architecture and writing rules.

## Key Supporting Files

- `content-tracker.base` — Obsidian Bases view of content completeness / stubs
- `doc-audit.base` — Obsidian Bases view of freshness and size
- `DevOps/CommandManual/command-index.base` — CLI command reference index
- `CNCF/cncf-landscape.canvas` — CNCF landscape map
- `CNCF/ObservabilityAnalysis/observability-stack.canvas` — metrics / logs / traces
- `CNCF/OrchestrationManagement/orchestration-ecosystem.canvas` — K8s-centric ecosystem
- `CNCF/Runtime/runtime-stack.canvas` — runtime / network / storage

## Content Architecture

Six top-level sections:

| Section | Purpose |
|---------|---------|
| `CNCF/` | Cloud-native tools by CNCF landscape category |
| `DevOps/` | Languages, CLI manuals, network, Linux system, kernel |
| `Platform/` | AWS, GCP, Aliyun, and Kubernetes distribution installers |
| `Standards/` | Naming, Git Flow, GitHub/GitLab/Docker, CI/CD, JiraCDflow |
| `Misc/` | ScienceSurf (VPN/proxy/hosting) and interviews |
| `Environment/` | Points at [logic3579/environment](https://github.com/logic3579/environment) |

`CNCF/` category directories (leaf pages live under these; do not enumerate them here):

- `AppDefinitionDevelopment/` — Helm, CI/CD, databases, streaming & messaging
- `CNAI/` — data architecture and data science
- `ObservabilityAnalysis/` — chaos, cost optimization, observability
- `OrchestrationManagement/` — gateway, discovery, RPC, Kubernetes, mesh, proxy
- `Provisioning/` — automation, registry, key management, security
- `Runtime/` — CNI, CSI, container runtimes
- `Serverless/` — thin section (landing page only)

Some pages are stubs that link out instead of duplicating another repo:

- `Environment/README.md` → [logic3579/environment](https://github.com/logic3579/environment)
- `CNCF/Provisioning/AutomationConfiguration/ansible.md` and `saltproject.md` → [logic3579/automation](https://github.com/logic3579/automation)
- `CNCF/Provisioning/AutomationConfiguration/terraform.md` → [logic3579/terraform](https://github.com/logic3579/terraform)

## Naming Conventions

- **Directories**: PascalCase (`CommandManual/`, `AppDefinitionDevelopment/`). Acronyms stay uppercase (`CNCF/`, `CNAI/`, `AWS/`).
- **Documents**: kebab-case (`naming-conventions.md`). Single-word names are lowercase (`helm.md`, `docker.md`).
- **Exceptions**: `README.md`, `SUMMARY.md`, `AGENTS.md`. Non-documentation trees (code/config such as `Standards/JiraCDflow/archery/`) are excluded from PascalCase.

## Adding or Changing Content

1. Put a kebab-case Markdown file in the matching category under `CNCF/`, `DevOps/`, `Platform/`, `Standards/`, or `Misc/`.
2. Add or remove the entry in `SUMMARY.md` with the existing indent hierarchy.
3. Update the parent section `README.md` so its sub-page list stays accurate.
4. Category `README.md` format: frontmatter (`icon` + `description`) → H1 → one-line description → linked sub-page list with brief descriptions.
5. Keep the existing style: embedded YAML and command examples.
6. External-repo tools: frontmatter + short description + repo link + official references. Use `ansible.md` as the template.
7. Host images on Cloudflare R2 (see Images below). Do not commit local `attachements/` directories.

## Markdown Conventions

- **Frontmatter**: every document needs `description`. `icon` ([FontAwesome](https://fontawesome.com/icons) name) is required on every GitBook sidebar top-level item from `SUMMARY.md`: root `README.md`, section landing `README.md` files, and single-file top-level pages (e.g. `DevOps/golang.md`, `Standards/gitflow.md`, `Misc/interview.md`, `Platform/distribution-installer.md`). Nested READMEs inside a collapsed group, and regular pages under a collapsed group, do not need `icon`.
- **Tags**: all content files (non-README) need frontmatter `tags` for Obsidian. Use nested tags with `/`:
  - Section: `cncf/app-definition`, `cncf/cnai`, `cncf/observability`, `cncf/orchestration`, `cncf/provisioning`, `cncf/runtime`, `devops/language`, `devops/command`, `devops/network`, `devops/system`, `devops/kernel`, `platform/aws`, `platform/gcp`, `platform/aliyun`, `standards`, `misc/vpn`, `misc/interview`
  - Topic (add as needed): `database`, `messaging`, `ci-cd`, `monitoring`, `logging`, `tracing`, `kubernetes`, `networking`, `security`, `container`, `storage`, `service-mesh`, `service-proxy`, `api-gateway`, `service-discovery`, `configuration`, `helm`
- **H1**: official tool/project name (`# ClickHouse`), not `# Overview`.
- **References** at the end of each document:

  ```markdown
  > Reference:
  >
  > 1. [Official Website](https://example.com/)
  > 2. [Repository](https://github.com/org/repo)
  ```

- **Links**: standard Markdown links only. Do not use Obsidian wikilinks (`[[...]]`).
- **Images**: host on Cloudflare R2 at `https://gitbook-r2.yakir.top/<prefix><filename>`. Use a normal Markdown image: `![alt](https://gitbook-r2.yakir.top/devops-network-tcp-handshake.png)`.
  1. Pick a prefix from the table (or add one in the same `{area}-{topic}-` pattern and record it here).
  2. Filename: lowercase, hyphens, no spaces or `%20`.
  3. Upload: `rclone copyto path/to/image.png logic-r2:gitbook/<prefix><filename>`
  4. Reference the resulting URL in Markdown.

  | Section | Prefix |
  |---------|--------|
  | `CNCF/ObservabilityAnalysis/Observability/` | `cncf-observability-` |
  | `CNCF/OrchestrationManagement/SchedulingOrchestration/Kubernetes/` | `cncf-kubernetes-` |
  | `CNCF/Runtime/ContainerRuntime/` | `cncf-runtime-` |
  | `DevOps/Network/` | `devops-network-` |
  | `DevOps/System/` | `devops-system-` |
  | `Platform/Aliyun/` | `platform-aliyun-` |
  | `Standards/` | `standards-` |

## Obsidian

Bases (`.base`) are dashboards over the vault; canvases (`.canvas`) are architecture maps. Both are additive and do not affect GitBook rendering. Content files must stay GitBook-compatible (standard Markdown links, no wikilinks).

## When Structure Changes

If the session adds, removes, or moves pages, or changes writing rules: update `SUMMARY.md`, the affected section `README.md`, and this `AGENTS.md` when the architecture or conventions themselves changed. Do not maintain a duplicate page list here.
