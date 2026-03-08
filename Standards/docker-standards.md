---
description: Docker image build and release standards
---

# Docker Standards

## Image Build Standards

### Dockerfile Best Practices

#### Base Image

- Use specific version tags, avoid `latest`
- Prefer minimal base images (`alpine`, `distroless`, `slim`)
- Use official images from trusted registries

#### Multi-Stage Build

```dockerfile
# Stage 1: Build
FROM golang:1.22-alpine AS builder
WORKDIR /build
COPY . .
RUN go build -o app .

# Stage 2: Runtime
FROM alpine:3.20
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=builder --chown=app:app /build/app .
USER app
EXPOSE 8080
ENTRYPOINT ["./app"]
```

#### Security

- Create and use non-root user
- Minimize installed packages, clean up cache in the same `RUN` layer
- Do not embed secrets in images — use runtime injection

```dockerfile
USER root
RUN groupadd -r app && useradd -r -g app app
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*
USER app
```

#### Layer Optimization

- Order instructions from least to most frequently changed
- Combine related `RUN` commands to reduce layers
- Use `.dockerignore` to exclude unnecessary files from build context

### .dockerignore Template

```
# VCS
.git
.gitignore

# Build artifacts
logs/*
tmp/
*.tmp

# IDE and OS files
.cache
.idea/
.vscode/
*.swp
.DS_Store

# Docker
Dockerfile
docker-compose*.yml
Makefile

# Documentation (unless needed in image)
# *.md
# !README.md
```

### Entrypoint Script Pattern

A structured entrypoint pattern for container initialization:

```bash
#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# Load libraries
. /app/scripts/liblog.sh
. /app/scripts/libenv.sh

print_welcome_page

# Run setup if main process is being started
if [[ "$*" = *"/app/scripts/run.sh"* ]]; then
    info "** Starting setup **"
    /app/scripts/setup.sh
    info "** Setup complete **"
fi

exec "$@"
```

### Environment Configuration Pattern

Centralize environment variables in a dedicated script:

```bash
#!/bin/bash
# libenv.sh — Environment configuration

export APP_ROOT_DIR="/app"
export MODULE_NAME="${MODULE_NAME:-my_app}"
export DEBUG_BOOL="${DEBUG_BOOL:-false}"

# Paths
export APP_CONFIG_DIR="${APP_ROOT_DIR}/config"
export APP_DATA_DIR="${APP_ROOT_DIR}/data"
export PATH="${PATH}:${APP_ROOT_DIR}/bin"

# System users (when running with a privileged user)
export APP_DAEMON_USER="app"
export APP_DAEMON_GROUP="app"
```

### Logging Library Pattern

Standardized container logging with color-coded levels:

```bash
#!/bin/bash
# liblog.sh — Logging functions

RESET='\033[0m'
RED='\033[38;5;1m'
GREEN='\033[38;5;2m'
YELLOW='\033[38;5;3m'
MAGENTA='\033[38;5;5m'
CYAN='\033[38;5;6m'
BOLD='\033[1m'

stderr_print() {
    local bool="${STDERR_QUIET:-false}"
    shopt -s nocasematch
    if ! [[ "$bool" = 1 || "$bool" =~ ^(yes|true)$ ]]; then
        printf "%b\\n" "${*}" >&2
    fi
}

log()   { stderr_print "${CYAN}${MODULE:-} ${MAGENTA}$(date "+%T.%2N ")${RESET}${*}"; }
info()  { log "${GREEN}INFO ${RESET} ==> ${*}"; }
warn()  { log "${YELLOW}WARN ${RESET} ==> ${*}"; }
error() { log "${RED}ERROR${RESET} ==> ${*}"; }
debug() { log "${MAGENTA}DEBUG${RESET} ==> ${*}"; }
```

### Process Management Pattern

Handle process execution with privilege de-escalation:

```bash
#!/bin/bash
# run.sh — Process startup

set -o errexit
set -o nounset
set -o pipefail

. /app/scripts/libenv.sh

am_i_root() {
    [[ "$(id -u)" = "0" ]]
}

START_COMMAND=("$APP_ROOT_DIR/bin/start.sh" "$@")
info "** Starting App **"
if am_i_root; then
    exec gosu "$APP_DAEMON_USER" "${START_COMMAND[@]}"
else
    exec "${START_COMMAND[@]}"
fi
```

## Image Naming & Tagging

### Naming Convention

```
<registry>/<owner>/<image-name>:<tag>

# Examples:
ghcr.io/org/api-server:v1.2.0
docker.io/org/api-server:latest
registry.cn-hongkong.aliyuncs.com/org/api-server:v1.2.0
```

### Tagging Strategy

| Tag | Purpose | Example |
|-----|---------|---------|
| `v<semver>` | Release version | `v1.2.0` |
| `<branch>-<sha>` | Development build | `main-a1b2c3d` |
| `latest` | Latest stable release | `latest` |
| `<env>` | Environment-specific | `staging`, `production` |

- Always tag releases with immutable semantic version tags
- Avoid relying on `latest` in production deployments
- Use Git SHA-based tags for traceability in non-release builds

## Multi-Registry Publishing

### CI/CD Pipeline Pattern

Publish to multiple registries (e.g., GHCR, DockerHub, ACR) using a matrix strategy:

```yaml
# GitHub Actions example
jobs:
  docker-push:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        registry: [ghcr, dockerhub, acr]
    steps:
      - uses: actions/checkout@v4

      - uses: docker/setup-buildx-action@v3

      - name: Set registry
        run: |
          case "${{ matrix.registry }}" in
            ghcr)     echo "REGISTRY=ghcr.io" >> $GITHUB_ENV ;;
            dockerhub) echo "REGISTRY=docker.io" >> $GITHUB_ENV ;;
            acr)      echo "REGISTRY=<acr-endpoint>" >> $GITHUB_ENV ;;
          esac

      - uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets[matrix.registry == 'acr' && 'ACR_PWD' || 'GITHUB_TOKEN'] }}

      - uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ env.REGISTRY }}/${{ github.repository }}:${{ github.ref_name }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

```yaml
# GitLab CI example
docker-push:
  image: docker:latest
  services:
    - docker:dind
  variables:
    REGISTRY: $CI_REGISTRY
    IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_TAG
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $REGISTRY
    - docker build -t $IMAGE .
    - docker push $IMAGE
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
```

## Docker Compose Standards

### Development Environment Template

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: builder    # Use build stage for dev
    volumes:
      - .:/app           # Hot reload
    ports:
      - "8080:8080"
    env_file:
      - .env
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: app
      POSTGRES_USER: app
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app"]
      interval: 5s
      retries: 3

volumes:
  db_data:
```

> Reference:
>
> 1. [Dockerfile Best Practices](https://docs.docker.com/build/building/best-practices/)
> 2. [Docker Security](https://docs.docker.com/engine/security/)
> 3. [OCI Image Spec](https://github.com/opencontainers/image-spec)
