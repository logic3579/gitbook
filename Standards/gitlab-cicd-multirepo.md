---
icon: arrows-rotate
description: GitLab CI/CD workflow standard for multirepo architecture with multi-platform Docker build, Container Registry publish, and ArgoCD GitOps deployment
tags:
  - standards
  - ci-cd
---

# GitLab CI/CD - Multirepo

GitLab CI/CD workflow standard for multirepo (single-repo-per-service) architecture. Each repository corresponds to an independent service, producing multi-platform Docker images.

Pipeline: code push trigger → multi-platform Docker build → image push to GitLab Container Registry → trigger DevOps project CD → ArgoCD auto-sync.

## Workflow Example

```yaml
# ============================================
# Variables & Stages
# ============================================
variables:
  IMAGE_NAME: app-service

stages:
  - build
  - deploy

# ============================================
# CI: Build and Publish Docker Image
# ============================================
build-and-publish:
  stage: build
  image: docker:27
  services:
    - docker:27-dind
  variables:
    DOCKER_BUILDKIT: "1"
  rules:
    - if: $CI_PIPELINE_SOURCE == "web"
    - if: $CI_COMMIT_BRANCH =~ /^(main|dev)$/
      changes:
        - "**/*"
      exclude:
        - ".gitlab/**"
  before_script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" "$CI_REGISTRY"
    # Install QEMU and Buildx for multi-platform build
    - docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
    - docker buildx create --use --name multi-builder --driver docker-container
    - docker buildx inspect --bootstrap
  script:
    - |
      IMAGE="${CI_REGISTRY_IMAGE}/${IMAGE_NAME}"
      SHORT_SHA=$(echo "$CI_COMMIT_SHA" | cut -c1-7)

      if [[ -n "$CI_COMMIT_TAG" ]]; then
        IMAGE_TAG="${CI_COMMIT_TAG}"
        TAGS="-t ${IMAGE}:${IMAGE_TAG} -t ${IMAGE}:${CI_COMMIT_TAG}-${SHORT_SHA} -t ${IMAGE}:latest"
      else
        IMAGE_TAG="${CI_COMMIT_BRANCH}-${SHORT_SHA}"
        TAGS="-t ${IMAGE}:${IMAGE_TAG}"
        if [[ "$CI_COMMIT_BRANCH" == "main" ]]; then
          TAGS="${TAGS} -t ${IMAGE}:latest"
        fi
      fi

      echo "IMAGE_TAG=${IMAGE_TAG}" >> build.env
      echo "Image tag: ${IMAGE_TAG}"

      docker buildx build \
        --platform linux/amd64,linux/arm64 \
        --push \
        ${TAGS} \
        --label "org.opencontainers.image.source=${CI_PROJECT_URL}" \
        --label "org.opencontainers.image.revision=${CI_COMMIT_SHA}" \
        --label "org.opencontainers.image.title=${IMAGE_NAME}" \
        --file Dockerfile \
        .
  artifacts:
    reports:
      dotenv: build.env

# ============================================
# CD: Trigger ArgoCD GitOps Deployment
# ============================================
# Uses GitLab downstream pipeline trigger to notify the DevOps project,
# which updates Kubernetes manifests in the GitOps repo. ArgoCD watches
# the GitOps repo and auto-syncs changes to the target cluster (pull-based CD).
trigger-cd:
  stage: deploy
  needs:
    - job: build-and-publish
      artifacts: true
  rules:
    - if: $CI_COMMIT_BRANCH == "dev"
      variables:
        ENVIRONMENT: test
    - if: $CI_COMMIT_BRANCH == "main"
      variables:
        ENVIRONMENT: prod
    - if: $CI_COMMIT_TAG
      variables:
        ENVIRONMENT: prod
  trigger:
    project: my-org/devops-tools
    strategy: depend
  variables:
    APP: $IMAGE_NAME
    TAG: $IMAGE_TAG
    VERSION: $CI_COMMIT_REF_NAME
    DEPLOY_ENVIRONMENT: $ENVIRONMENT
    TRIGGERED_BY: $GITLAB_USER_LOGIN
    COMMIT_MESSAGE: $CI_COMMIT_MESSAGE
    SOURCE_PROJECT: $CI_PROJECT_PATH
```

## Multirepo-Specific Design

### Trigger Strategy

In a multirepo setup, the entire repository represents a single service. Use `changes` with `exclude` to skip non-build files:

```yaml
rules:
  - if: $CI_COMMIT_BRANCH =~ /^(main|dev)$/
    changes:
      - "**/*"
    exclude:
      - ".gitlab/**"
```

### Root-Level Build Context

The build context is the repository root directory:

```yaml
docker buildx build \
  --file Dockerfile \
  .
```

### Multi-Platform Build

Multirepo services typically require multi-platform deployment (e.g., amd64 + arm64), achieved via QEMU emulation with Buildx:

```yaml
before_script:
  - docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
  - docker buildx create --use --name multi-builder --driver docker-container

script:
  - docker buildx build --platform linux/amd64,linux/arm64 --push ...
```

### Downstream Pipeline Trigger

GitLab uses `trigger` keyword to invoke a downstream pipeline in the DevOps project, passing deployment parameters as variables. The DevOps project receives these variables, updates Kubernetes manifests in the GitOps repo, and ArgoCD auto-syncs the changes to the cluster (pull-based CD):

```yaml
trigger:
  project: my-org/devops-tools
  strategy: depend     # Wait for downstream pipeline to complete
variables:
  APP: $IMAGE_NAME
  TAG: $IMAGE_TAG
  DEPLOY_ENVIRONMENT: $ENVIRONMENT
```

## GitHub Actions vs GitLab CI/CD Comparison

| Dimension | GitHub Actions | GitLab CI/CD |
|-----------|---------------|--------------|
| Config file | `.github/workflows/*.yml` | `.gitlab-ci.yml` |
| Container build | `docker/build-push-action` | `docker:dind` service + `docker buildx` |
| Registry | GHCR (`ghcr.io`) | GitLab Container Registry (`$CI_REGISTRY`) |
| Cross-repo CD | `peter-evans/repository-dispatch` | `trigger` downstream pipeline |
| Concurrency | `concurrency.group` + `cancel-in-progress` | `resource_group` or `interruptible` |
| Job outputs | `outputs` + `$GITHUB_OUTPUT` | `artifacts:reports:dotenv` |
| Env detection | `github.ref` / `github.event_name` | `$CI_COMMIT_BRANCH` / `$CI_COMMIT_TAG` |
| Manual trigger | `workflow_dispatch` | `$CI_PIPELINE_SOURCE == "web"` |
| Job summary | `$GITHUB_STEP_SUMMARY` | Pipeline UI (no equivalent) |

## Shared Design

The following patterns are consistent with the GitHub Actions multirepo standard:

### Image Tag Strategy

| Scenario | Tag Format | Example |
|----------|------------|---------|
| Push to dev | `{branch}-{short_sha}` | `dev-a1b2c3d` |
| Push to main | `{branch}-{short_sha}` + `latest` | `main-a1b2c3d`, `latest` |
| Tag event | `{version}` + `{version}-{short_sha}` + `latest` | `v1.2.0`, `v1.2.0-a1b2c3d`, `latest` |

### Environment Mapping

| Branch / Event | Deploy Environment |
|----------------|--------------------|
| `dev` | test |
| `main` / tag | prod |

### Required CI/CD Variables

| Variable | Purpose |
|----------|---------|
| `CI_REGISTRY_*` | Automatically provided, used for GitLab Container Registry login and image push |
| Downstream project access | The trigger user must have at least Maintainer role on the DevOps project, or configure a project-level CI/CD trigger token |

> Reference:
>
> 1. [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
> 2. [GitLab Container Registry](https://docs.gitlab.com/ee/user/packages/container_registry/)
> 3. [Multi-project Pipelines](https://docs.gitlab.com/ee/ci/pipelines/downstream_pipelines.html)
> 4. [Argo CD - Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)
