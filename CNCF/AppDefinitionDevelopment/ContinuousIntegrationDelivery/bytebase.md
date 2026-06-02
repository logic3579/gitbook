---
description: Bytebase
tags:
  - cncf/app-definition
  - ci-cd
  - database
---

# Bytebase

## Introduction

Bytebase is an open-source database DevOps and CI/CD platform for developers, DBAs, and platform teams. It provides a unified GUI workspace for schema change, query, security, and governance across MySQL, PostgreSQL, TiDB, Oracle, SQL Server, Snowflake, ClickHouse, MongoDB, Redis, OceanBase, Spanner, and other engines. Core capabilities include schema migration with review workflow, GitOps-style version control (database-as-code), SQL Editor with data masking, drift detection, batch change across tenants, and a rich audit log — making it the database counterpart to GitLab/GitHub for application code.

## How to Install

### Starting via Docker

```bash
# pull and run with persistent volume
mkdir -p /opt/bytebase/data

docker run --init \
  --name bytebase \
  --restart always \
  --publish 5678:8080 \
  --health-cmd "curl --fail http://localhost:8080/healthz || exit 1" \
  --health-interval 5m \
  --health-timeout 60s \
  --volume /opt/bytebase/data:/var/opt/bytebase \
  -d bytebase/bytebase:3.5.0 \
  --data /var/opt/bytebase \
  --port 8080

# visit http://<host>:5678 to finish the workspace setup
```

### Starting via Kubernetes

```bash
# add and update repo
helm repo add bytebase https://helm.bytebase.com
helm repo update

# get charts package
helm pull bytebase/bytebase --untar
cd bytebase

# configure and run
vim values.yaml
# key fields:
#   bytebase.option.port: 8080
#   bytebase.option.external-url: https://bytebase.example.com
#   bytebase.option.pg: postgresql://<user>:<password>@<host>:5432/bytebase   # external metadata DB (recommended for prod)
#   bytebase.persistence.existingClaim: bytebase-data                          # PVC if using embedded PG
#   ingress.enabled: true
helm -n cicd install bytebase .
```

### Config and Boot

#### External Metadata Database (Production)

Bytebase stores its own metadata in PostgreSQL. By default an embedded Postgres is used; for production point it at an external instance to enable backup, HA, and observability:

```bash
# create dedicated DB and user on existing PostgreSQL
psql -U postgres << "EOF"
CREATE USER bytebase WITH ENCRYPTED PASSWORD 'change-me';
CREATE DATABASE bytebase OWNER bytebase;
EOF

# pass via --pg flag (or BB_PG env var)
docker run --init --name bytebase --restart always \
  --publish 5678:8080 \
  --volume /opt/bytebase/data:/var/opt/bytebase \
  -d bytebase/bytebase:3.5.0 \
  --data /var/opt/bytebase \
  --port 8080 \
  --pg "postgresql://bytebase:change-me@pg.internal:5432/bytebase"
```

#### External URL & Reverse Proxy

When fronting Bytebase with Nginx/Traefik, set `--external-url` so generated links (issue, OAuth callback, webhook) point at the public hostname:

```bash
--external-url https://bytebase.example.com
```

### Verify

```bash
# health endpoint
curl -fsS http://localhost:5678/healthz
# {"status":"OK"}

# version via API
curl -fsS http://localhost:5678/v1/actuator/info | jq .
```

## Core Concepts

| Concept | Description |
|---------|-------------|
| Workspace | Top-level tenant containing all projects, instances, and users |
| Instance | A connected database server (MySQL/PostgreSQL/…) |
| Database | A logical database living on an instance |
| Project | Logical group binding databases, issues, and members for one app/team |
| Issue | The unit of work: schema change, data change, request grant, rollout, etc. |
| Changelist | Ordered set of changes promoted across environments (dev → staging → prod) |
| Environment | Pipeline stage with its own approval, SQL review, and rollout policy |
| SQL Review | Policy engine that lints DDL/DML against 100+ rules before merge |

## Common Operations

### GitOps Workflow (Database-as-Code)

1. Connect a Git repo (GitHub, GitLab, Bitbucket, Azure DevOps) to a project.
2. Place migration files under the configured path, e.g.:

   ```
   bytebase/
   └── prod/
       ├── 202606020001_add_users_email_idx.sql
       └── 202606020002_backfill_users_status.sql
   ```

3. Push to the watched branch — Bytebase opens an issue, runs SQL Review, and rolls out per environment policy.

### CLI (`bb`)

```bash
# install
brew install bytebase/tap/bb           # macOS
# or grab the binary: https://github.com/bytebase/bytebase/releases

# dump schema from a live instance
bb dump --dsn 'mysql://user:pass@tcp(127.0.0.1:3306)/app' --schema-only > schema.sql

# migrate (apply a versioned change script)
bb migrate --dsn 'postgresql://user:pass@127.0.0.1:5432/app' --file 202606020001_add_users_email_idx.sql
```

### CI Integration (GitHub Actions)

```yaml
# .github/workflows/db-review.yaml
name: SQL Review
on:
  pull_request:
    paths: ['migrations/**.sql']
jobs:
  sql-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: bytebase/sql-review-action@v1
        with:
          url: ${{ secrets.BYTEBASE_URL }}
          token: ${{ secrets.BYTEBASE_TOKEN }}
          project: projects/sample
          file-pattern: 'migrations/*.sql'
```

## Troubleshooting

```bash
# metadata Postgres connection refused on container start
docker logs bytebase | grep -i "failed to connect"
# → check --pg DSN, network reachability, and that the user owns the DB

# stuck migration / lock contention
# UI: Issue → "Cancel rollout" then re-run; verify no other DDL holding metadata lock on target DB

# upgrade in place (always back up metadata DB first)
docker stop bytebase && docker rm bytebase
docker run ... bytebase/bytebase:<new-version> ...
# Bytebase auto-runs its own schema migration on first start
```

> Reference:
>
> 1. [Official Website](https://www.bytebase.com/)
> 2. [Repository](https://github.com/bytebase/bytebase)
> 3. [Documentation](https://docs.bytebase.com/)
> 4. [SQL Review Rules](https://docs.bytebase.com/sql-review/review-rules/)
> 5. [Helm Chart](https://github.com/bytebase/bytebase-helm)
