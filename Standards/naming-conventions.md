---
description: Naming conventions for projects, cloud resources, Kubernetes, and documentation
---

# Naming Conventions

## General Principles

- Use **lowercase** with **hyphens** as separators (`kebab-case`)
- Be **descriptive** but **concise** — avoid abbreviations that are not universally understood
- Follow a consistent **hierarchical pattern**: from broad scope to specific detail
- Avoid special characters, underscores (except where required by platform), and trailing numbers without context

## Project & Repository Naming

```
<team/org>-<service/component>

# Examples:
platform-api
platform-web
infra-terraform-modules
shared-ci-templates
data-etl-pipeline
```

| Rule | Example |
|------|---------|
| Lowercase with hyphens | `my-project` |
| Prefix with team/domain for internal projects | `platform-api-gateway` |
| Suffix with type for non-application repos | `infra-helm-charts`, `shared-docker-images` |
| Monorepo uses generic name | `platform-monorepo` |

## Cloud Resource Naming

### Standard Pattern

```
<project/business>-<application>-<environment>-<region>-<resource-type>[-<instance>]

# Examples:
myproject-myapp-prod-ase1-vm
myproject-myapp-prod-euw1-db
algorithm-dev-use1-vm
```

### Detailed Pattern (for complex environments)

```
<scope/owner>-<environment>-<region>-<component>-<role>[-<index>]

# Examples:
platform-prod-euw1-mysql-master
platform-prod-euw1-mysql-slave-01
platform-staging-ase1-redis-sentinel-01
data-prod-use1-kafka-broker-03
```

### Environment Abbreviations

| Environment | Abbreviation |
|-------------|-------------|
| Development | `dev` |
| Testing | `test` |
| Staging | `staging` / `stg` |
| Production | `prod` |
| Disaster Recovery | `dr` |

### Region Abbreviations

Follow cloud provider conventions or use short codes:

| Region | Abbreviation |
|--------|-------------|
| Asia Southeast 1 (Singapore) | `ase1` |
| Asia East 1 (Hong Kong) | `ae1` |
| US East 1 (N. Virginia) | `use1` |
| EU West 1 (Ireland) | `euw1` |

### Resource Type Suffixes

| Resource | Suffix | Example |
|----------|--------|---------|
| Virtual Machine | `vm` | `platform-prod-ase1-vm` |
| Database (generic) | `db` | `platform-prod-euw1-db` |
| MySQL | `mysql` | `platform-prod-euw1-mysql-master` |
| PostgreSQL | `pgsql` | `platform-prod-euw1-pgsql-primary` |
| Redis | `redis` | `platform-prod-ase1-redis-sentinel-01` |
| Load Balancer | `lb` | `platform-prod-ase1-lb` |
| Object Storage | `oss` / `s3` | `data-prod-use1-s3` |
| Message Queue | `mq` | `data-prod-ase1-mq-broker-01` |
| VPC | `vpc` | `platform-prod-ase1-vpc` |
| Subnet | `subnet` | `platform-prod-ase1-subnet-private` |
| Security Group | `sg` | `platform-prod-ase1-sg-web` |

## Kubernetes Resource Naming

### Namespace

```
<team/project>-<environment>

# Examples:
platform-prod
data-staging
middleware-prod
monitoring-prod
```

### Workloads (Deployment / StatefulSet / DaemonSet)

```
<application>[-<component>]

# Examples:
api-server
web-frontend
order-service-consumer
kafka-broker
redis-sentinel
```

### Service

Match the workload name. Use suffix for non-default types:

```
<application>[-<component>][-<type>]

# Examples:
api-server                  # ClusterIP (default)
api-server-nodeport         # NodePort
web-frontend-headless       # Headless
```

### ConfigMap & Secret

```
<application>-<purpose>

# Examples:
api-server-config
api-server-env
nginx-vhost-config
api-server-tls
database-credentials
```

### PersistentVolumeClaim

```
<application>-<purpose>-<index>

# Examples:
mysql-data-0
kafka-data-broker-0
redis-data-0
```

### Ingress

```
<application>[-<route>]

# Examples:
api-server
web-frontend
api-server-internal
```

### Labels & Annotations

Follow the [Kubernetes recommended labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/):

```yaml
labels:
  app.kubernetes.io/name: api-server
  app.kubernetes.io/instance: api-server-prod
  app.kubernetes.io/version: "1.2.0"
  app.kubernetes.io/component: backend
  app.kubernetes.io/part-of: platform
  app.kubernetes.io/managed-by: helm
```

## Docker Image Naming

See [Docker Standards](docker-standards.md#image-naming--tagging) for detailed image naming and tagging conventions.

```
<registry>/<owner>/<image-name>:<tag>

# Examples:
ghcr.io/org/api-server:v1.2.0
docker.io/org/api-server:main-a1b2c3d
```

## Branch Naming

See [GitHub Standards](github-standards.md#branch-strategy) and [GitLab Standards](gitlab-standards.md#branch-strategy) for detailed branching conventions.

```
<type>/<issue-id>-<short-description>

# Examples:
feature/123-add-oauth-login
bugfix/456-fix-timeout
hotfix/789-patch-xss
release/v1.2.0
```

## Documentation File Naming

| Rule | Example |
|------|---------|
| Use `kebab-case` for file names | `naming-conventions.md` |
| Section overview uses `README.md` | `Standards/README.md` |
| Tool-specific docs use tool name (lowercase) | `docker.md`, `kafka.md`, `nginx.md` |
| Multi-word names use hyphens | `cert-manager.md`, `computer-network.md` |
| Avoid prefixes/suffixes like `doc-`, `-guide` | `kafka.md` not `kafka-guide.md` |

## CI/CD Resource Naming

### GitHub Actions

```yaml
# Workflow file: .github/workflows/<purpose>.yml
# Examples:
.github/workflows/ci.yml
.github/workflows/release.yml
.github/workflows/docker-publish.yml

# Job names:
jobs:
  build:
  test:
  deploy-staging:
  deploy-production:
```

### GitLab CI

```yaml
# Job names follow: <action>[-<target>][-<environment>]
# Examples:
build:
test-unit:
test-integration:
deploy-staging:
deploy-production:
```

> Reference:
>
> 1. [Kubernetes Recommended Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/)
> 2. [AWS Naming Conventions](https://docs.aws.amazon.com/whitepapers/latest/tagging-best-practices/naming-conventions.html)
> 3. [Google Cloud Naming Convention](https://cloud.google.com/architecture/best-practices-vpc-design#naming)
