---
description: Google Artifact Registry for container images and packages
tags:
  - platform/gcp
  - container
---

# Artifact Registry

## Authentication

```bash
# Configure Docker authentication for Artifact Registry
gcloud auth configure-docker asia-southeast1-docker.pkg.dev
```

## Repositories

```bash
gcloud artifacts repositories create REPO_NAME \
    --repository-format=docker \
    --location=asia-southeast1
gcloud artifacts repositories list --location=asia-southeast1
```

## Images

```bash
gcloud artifacts docker images list asia-southeast1-docker.pkg.dev/PROJECT_ID/REPO_NAME
gcloud artifacts docker tags list asia-southeast1-docker.pkg.dev/PROJECT_ID/REPO_NAME/IMAGE
```

> Reference:
>
> 1. [Official Website](https://cloud.google.com/artifact-registry/docs)
