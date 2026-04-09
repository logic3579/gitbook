---
description: GitHub Actions CI/CD workflow standard for monorepo architecture with path-based triggering, Docker build, GHCR publish, and cross-repo CD trigger
tags:
  - standards
  - ci-cd
---

# GitHub Actions CI/CD - Monorepo

GitHub Actions CI/CD workflow standard for monorepo architecture. Uses `paths` filtering for per-module triggering, suitable for projects managed by Turborepo / Nx.

Pipeline: path change trigger → application build → Docker image push to GHCR → cross-repo CD trigger.

## Workflow Example

```yaml
name: app-service

on:
  push:
    branches:
      - main
      - dev
    paths:
      - "apps/my-app/**"
      - "packages/**"
      - "package.json"
      - "yarn.lock"
      - "turbo.json"
  workflow_dispatch:

env:
  MODULE_PATH: apps/my-app
  IMAGE_NAME: app-service

permissions:
  contents: write
  packages: write
  id-token: write

concurrency:
  group: ci-${{ github.ref }}-${{ github.workflow }}
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

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "22"
          cache: "yarn"

      - name: Install dependencies
        run: yarn install --frozen-lockfile

      - name: Build application
        run: yarn build

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.repository_owner }}
          password: ${{ secrets.GITHUB_TOKEN }}

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
          context: ${{ env.MODULE_PATH }}
          file: ${{ env.MODULE_PATH }}/Dockerfile
          push: true
          tags: ${{ steps.tags.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  # ============================================
  # CD: Trigger Deployment in DevOps Repo
  # ============================================
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

## Monorepo-Specific Design

### Path-Based Triggering

In a monorepo, multiple applications share one repository. Each application has its own workflow file and uses `paths` to precisely control the trigger scope:

```yaml
paths:
  - "apps/my-app/**" # Current application code changes
  - "packages/**" # Shared package changes (may affect all apps)
  - "package.json" # Dependency changes
  - "yarn.lock" # Lock file changes
  - "turbo.json" # Build configuration changes
```

### MODULE_PATH Build Context

The `MODULE_PATH` environment variable specifies the sub-application path. Both the Docker build context and Dockerfile are scoped to the sub-application directory:

```yaml
env:
  MODULE_PATH: apps/my-app

# During Docker build:
context: ${{ env.MODULE_PATH }}
file: ${{ env.MODULE_PATH }}/Dockerfile
```

### Concurrency Group

Multiple workflows may run concurrently in a monorepo. The concurrency group must include `github.workflow` to prevent different application workflows from cancelling each other:

```yaml
concurrency:
  group: ci-${{ github.ref }}-${{ github.workflow }}
  cancel-in-progress: true
```

### Language Environment Setup

Monorepo workflows typically install dependencies and build artifacts in CI (e.g., `yarn build`), then COPY the build output into the Docker image. This differs from the multirepo pattern where the entire build happens inside the Dockerfile.

> Reference:
>
> 1. [GitHub Actions Documentation](https://docs.github.com/en/actions)
> 2. [docker/build-push-action](https://github.com/docker/build-push-action)
> 3. [peter-evans/repository-dispatch](https://github.com/peter-evans/repository-dispatch)
> 4. [Turborepo - CI/CD](https://turbo.build/repo/docs/guides/ci)
