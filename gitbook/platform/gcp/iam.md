---
description: GCP IAM, service accounts, and Workload Identity Federation
tags:
  - platform/gcp
  - security
---

# IAM

## Roles

```bash
gcloud iam list-grantable-roles //cloudresourcemanager.googleapis.com/projects/PROJECT_ID
gcloud iam roles list --project=PROJECT_ID
gcloud iam roles create ROLE_ID --project=PROJECT_ID \
    --title="Custom Role" \
    --permissions="compute.instances.list,compute.instances.get"
```

## Service Accounts

```bash
gcloud iam service-accounts create SA_NAME \
    --display-name="My Service Account"
gcloud iam service-accounts list
gcloud iam service-accounts describe SA@PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts keys list \
    --iam-account=SA@PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts keys create KEY.json \
    --iam-account=SA@PROJECT_ID.iam.gserviceaccount.com

# Service account IAM binding
gcloud iam service-accounts add-iam-policy-binding SA@PROJECT_ID.iam.gserviceaccount.com \
    --member="user:USER@example.com" \
    --role="roles/iam.serviceAccountUser"
```

## Project IAM

```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:SA@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/editor"
```

## Workload Identity Federation

```bash
gcloud iam workload-identity-pools list --location=global
gcloud iam workload-identity-pools providers list \
    --workload-identity-pool=POOL_ID --location=global
```

> Reference:
>
> 1. [Official Website](https://cloud.google.com/iam/docs)
