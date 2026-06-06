---
description: Cloud Storage
tags:
  - platform/gcp
  - storage
---

# GCS

## Buckets

```bash
# Bucket operations
gcloud storage buckets create gs://BUCKET_NAME --location=asia-southeast1
gcloud storage buckets list
gcloud storage buckets describe gs://BUCKET_NAME
gcloud storage buckets delete gs://BUCKET_NAME

# Bucket settings
gcloud storage buckets describe gs://BUCKET_NAME \
    --format="value(uniformBucketLevelAccess.enabled)"
gcloud storage buckets update gs://BUCKET_NAME --uniform-bucket-level-access

# Bucket IAM
gcloud storage buckets add-iam-policy-binding gs://BUCKET_NAME \
    --member="allUsers" \
    --role="roles/storage.objectViewer"
gcloud storage buckets get-iam-policy gs://BUCKET_NAME
```

## Objects

```bash
gcloud storage cp LOCAL_FILE gs://BUCKET_NAME/
gcloud storage cp gs://BUCKET_NAME/FILE ./
gcloud storage cp -r gs://BUCKET_SRC/ gs://BUCKET_DST/
gcloud storage ls gs://BUCKET_NAME/
gcloud storage rm gs://BUCKET_NAME/FILE
```

> Reference:
>
> 1. [Official Website](https://cloud.google.com/storage/docs)
