---
description: GitHub Actions CI/CD workflow standard for multirepo architecture with multi-platform Docker build, GHCR publish, and ArgoCD GitOps deployment
tags:
  - standards
  - ci-cd
---

# GitHub Actions CI/CD - Multirepo

GitHub Actions CI/CD workflow standard for multirepo (single-repo-per-service) architecture. Each repository corresponds to an independent service, producing multi-platform Docker images.

Pipeline: code push trigger → multi-platform Docker build → image push to GHCR → update GitOps manifest → ArgoCD auto-sync.

## Workflow Example

```yaml
name: app-service

on:
  push:
    branches:
      - main
      - dev
    paths-ignore:
      - ".github/**"
  workflow_dispatch:

env:
  IMAGE_NAME: app-service

permissions:
  contents: write
  packages: write
  id-token: write

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  # ============================================
  # CI: Build and Publish Docker Image
  # ============================================
  build-and-publish:
    runs-on: ubuntu-latest
    outputs:
      image_tag: ${{ steps.tags.outputs.image_tag }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.repository_owner }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Setup QEMU
        uses: docker/setup-qemu-action@v3

      - name: Setup Docker Buildx
        uses: docker/setup-buildx-action@v3
        with:
          install: true
          driver: docker-container

      - name: Compute image tags
        id: tags
        run: |
          IMAGE="ghcr.io/${{ github.repository_owner }}/${{ env.IMAGE_NAME }}"
          SHORT_SHA=$(echo "${{ github.sha }}" | cut -c1-7)

          if [[ "${{ github.event_name }}" == "release" ]]; then
            IMAGE_TAG="${{ github.ref_name }}"
            TAGS="${IMAGE}:${IMAGE_TAG},${IMAGE}:${{ github.ref_name }}-${SHORT_SHA},${IMAGE}:latest"
          else
            IMAGE_TAG="${{ github.ref_name }}-${SHORT_SHA}"
            TAGS="${IMAGE}:${IMAGE_TAG}"
            if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
              TAGS="${TAGS},${IMAGE}:latest"
            fi
          fi

          echo "image_tag=${IMAGE_TAG}" >> "$GITHUB_OUTPUT"
          echo "tags=${TAGS}" >> "$GITHUB_OUTPUT"
          echo "Image tag: ${IMAGE_TAG}"

      - name: Docker metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository_owner }}/${{ env.IMAGE_NAME }}
          labels: |
            org.opencontainers.image.source=${{ github.repository }}
            org.opencontainers.image.revision=${{ github.sha }}
            org.opencontainers.image.title=${{ env.IMAGE_NAME }}

      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          file: Dockerfile
          push: true
          platforms: linux/amd64,linux/arm64
          tags: ${{ steps.tags.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  # ============================================
  # CD: Trigger ArgoCD GitOps Deployment
  # ============================================
  # Uses repository-dispatch to notify the DevOps repo, which updates
  # Kubernetes manifests in the GitOps repo. ArgoCD watches the GitOps
  # repo and auto-syncs changes to the target cluster (pull-based CD).
  trigger-cd:
    needs: build-and-publish
    runs-on: ubuntu-latest
    if: github.event_name == 'push' || github.event_name == 'release'

    steps:
      - name: Determine environment
        id: env
        run: |
          if [[ "${{ github.ref }}" == "refs/heads/dev" ]]; then
            echo "environment=test" >> $GITHUB_OUTPUT
            echo "Deploying to TEST environment"
          elif [[ "${{ github.ref }}" == "refs/heads/main" || "${{ github.event_name }}" == "release" ]]; then
            echo "environment=prod" >> $GITHUB_OUTPUT
            echo "Deploying to PROD environment"
          else
            echo "::warning::Unknown branch, skipping CD trigger"
            echo "environment=" >> $GITHUB_OUTPUT
          fi

      - name: Trigger CD in DevOps repo
        if: steps.env.outputs.environment != ''
        uses: peter-evans/repository-dispatch@v3
        with:
          token: ${{ secrets.DEVOPS_REPO_PAT }}
          repository: my-org/devops-tools
          event-type: deploy-app
          client-payload: |
            {
              "app": "${{ env.IMAGE_NAME }}",
              "tag": "${{ needs.build-and-publish.outputs.image_tag }}",
              "version": "${{ github.ref_name }}",
              "environment": "${{ steps.env.outputs.environment }}",
              "triggered_by": "${{ github.actor }}",
              "commit_message": ${{ toJSON(github.event.head_commit.message) }},
              "source_repo": "${{ github.repository }}"
            }

      - name: CD Trigger Summary
        if: steps.env.outputs.environment != ''
        run: |
          echo "## CD Pipeline Triggered" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Field | Value |" >> $GITHUB_STEP_SUMMARY
          echo "|-------|-------|" >> $GITHUB_STEP_SUMMARY
          echo "| Application | \`${{ env.IMAGE_NAME }}\` |" >> $GITHUB_STEP_SUMMARY
          echo "| Image Tag | \`${{ needs.build-and-publish.outputs.image_tag }}\` |" >> $GITHUB_STEP_SUMMARY
          echo "| Environment | ${{ steps.env.outputs.environment }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Target Repo | my-org/devops-tools |" >> $GITHUB_STEP_SUMMARY
```

## Multirepo-Specific Design

### Trigger Strategy

In a multirepo setup, the entire repository represents a single service. Instead of `paths` filtering, use `paths-ignore` to exclude files that should not trigger a build:

```yaml
paths-ignore:
  - ".github/**" # Workflow file changes do not trigger builds
```

### Root-Level Build Context

The build context is the repository root directory, no `MODULE_PATH` needed:

```yaml
context: .
file: Dockerfile
```

### Multi-Platform Build

Multirepo services typically require multi-platform deployment (e.g., amd64 + arm64), achieved via QEMU emulation for cross-compilation:

```yaml
- name: Setup QEMU
  uses: docker/setup-qemu-action@v3

- name: Build and push
  uses: docker/build-push-action@v6
  with:
    platforms: linux/amd64,linux/arm64
```

## Monorepo vs Multirepo Comparison

| Dimension     | Monorepo                                       | Multirepo                                |
| ------------- | ---------------------------------------------- | ---------------------------------------- |
| Trigger       | `paths` matching sub-app paths                 | `paths-ignore` excluding non-build files |
| Build context | `apps/my-app/` (subdirectory)                  | `.` (root directory)                     |
| Language env  | CI setup + build, artifacts COPY into image    | Entire build inside Dockerfile           |
| Multi-arch    | Typically single-arch (frontend static assets) | Multi-arch (QEMU + Buildx)               |
| Concurrency   | `ci-${{ github.ref }}-${{ github.workflow }}`  | `ci-${{ github.ref }}`                   |

## Shared Design

The following patterns are consistent across both architectures:

### Image Tag Strategy

| Scenario      | Tag Format                                       | Example                              |
| ------------- | ------------------------------------------------ | ------------------------------------ |
| Push to dev   | `{branch}-{short_sha}`                           | `dev-a1b2c3d`                        |
| Push to main  | `{branch}-{short_sha}` + `latest`                | `main-a1b2c3d`, `latest`             |
| Release event | `{version}` + `{version}-{short_sha}` + `latest` | `v1.2.0`, `v1.2.0-a1b2c3d`, `latest` |

### Environment Mapping

| Branch           | Deploy Environment |
| ---------------- | ------------------ |
| `dev`            | test               |
| `main` / release | prod               |

### Cross-Repo CD Trigger

Uses `peter-evans/repository-dispatch` to send a `deploy-app` event to a dedicated DevOps repository. The DevOps repo receives the event, updates Kubernetes manifests in the GitOps repo, and ArgoCD auto-syncs the changes to the cluster (pull-based CD).

### Required Secrets

| Secret            | Purpose                                                                     |
| ----------------- | --------------------------------------------------------------------------- |
| `GITHUB_TOKEN`    | Automatically provided, used for GHCR login and image push                  |
| `DEVOPS_REPO_PAT` | Manually configured, used for cross-repo CD trigger (requires `repo` scope) |

> Reference:
>
> 1. [GitHub Actions Documentation](https://docs.github.com/en/actions)
> 2. [docker/build-push-action](https://github.com/docker/build-push-action)
> 3. [docker/setup-qemu-action](https://github.com/docker/setup-qemu-action)
> 4. [peter-evans/repository-dispatch](https://github.com/peter-evans/repository-dispatch)
> 5. [Argo CD - Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)
> 6. [GitHub Packages - GHCR](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
