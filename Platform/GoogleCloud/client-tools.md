---
description: client tool: gcloud / gsutil
---

# Client Tools

## gcloud

### Common

```bash
# Authorization and Credentials
gcloud auth login
gcloud auth activate-service-default
gcloud auth list|revoke

# Configuration
gcloud config set|get|list
gcloud config configurations create|list|activate

# Projects
gcloud projects describe
gcloud projects add-iam-policy-binding

# Global flags
--help
--project
--quiet
--verbosity
--version
--format
```

### Cloud storage

```bash
gcloud storage buckets describe gs://YOUR_BUCKET_NAME --format="value(uniformBucketLevelAccess.enabled)"
gcloud storage buckets update gs://YOUR_BUCKET_NAME --uniform-bucket-level-access
gcloud storage buckets add-iam-policy-binding gs://YOUR_BUCKET_NAME \
    --member="allUsers" \
    --role="roles/storage.objectViewer"
gcloud storage buckets get-iam-policy gs://YOUR_BUCKET_NAME
```

### Compute Engine

```bash
# Virutual machines
gcloud compute zones list
gcloud compute instances create
gcloud compute instances describe
gcloud compute instances list
gcloud compute instances list --format="value(name,zone)"
gcloud compute instances list --filter="zone ~ ^asia AND -machineType:e2-standard-2"
gcloud compute instances update $name --zone $zone --deletion-protection
gcloud compute ssh

# Disk
gcloud compute disks snapshot
gcloud compute snapshots describe
gcloud compute snapshots delete
```

### IAM

```bash
# IAM
gcloud iam list-grantable-roles
gcloud iam roles create
gcloud iam service-accounts create
gcloud iam service-accounts add-iam-policy-binding
gcloud iam service-accounts set-iam-policy-binding
gcloud iam service-accounts keys list
```

### Kubernetes Engine

```bash
gcloud auth configure-docker
gcloud container clusters create
gcloud container clusters list
gcloud container clusters get-credentials
gcloud container images list-tags
```

### Network services

```bash
# Load balancing

# Cloud DNS
ZONE_NAME=example.com
gcloud dns record-sets create 'www.example.com' \
    --type=A \
    --ttl=300 \
    --zone="$ZONE_NAME" \
    --rrdatas="1.1.1.1"

# Cloud CDN

# Cloud NAT
```

### VPC Network

```bash
# VPC networks

# IP address
gcloud compute addresses create test-external --region=asia-southeast1

# Firewall
gcloud compute firewall-rules list --filter="network:default"
```

## gsutil

```bash
# iam
gsutil iam ch allUsers:objectViewer gs://YOUR_BUCKET_NAME
gsutil iam ch -d allUsers:objectViewer gs://YOUR_BUCKET_NAME
gsutil iam get gs://YOUR_BUCKET_NAME
```

> Reference:
>
> 1. [Official Website](https://cloud.google.com/sdk/docs/cheatsheet)
