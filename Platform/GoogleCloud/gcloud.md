---
description: gcloud client tool
---

# gcloud

## Common

```bash
# Personalization
gcloud config set|get|list
gcloud config configurations create|list|activate

# Authorization and Credentials
gcloud auth login
gcloud auth activate-service-default
gcloud auth list|revoke

# Projects
gcloud projects describe
gcloud projects add-iam-policy-binding

# IAM
gcloud iam list-grantable-roles
gcloud iam roles create
gcloud iam service-accounts create
gcloud iam service-accounts add-iam-policy-binding
gcloud iam service-accounts set-iam-policy-binding
gcloud iam service-accounts keys list

# Global flags
--help
--project
--quiet
--verbosity
--version
--format
```

## GCE

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

# Storage
gcloud compute disks snapshot
gcloud compute snapshots describe
gcloud compute snapshots delete
```

## GKE

```bash
gcloud auth configure-docker
gcloud container clusters create
gcloud container clusters list
gcloud container clusters get-credentials
gcloud container images list-tags
```

## Network

```bash
# VPC networks

# Firewall
gcloud compute firewall-rules list --filter="network:default"

# IP address
gcloud compute addresses create test-external --region=asia-southeast1

# Cloud NAT

```

> Reference:
>
> 1. [Official Website](https://cloud.google.com/sdk/docs/cheatsheet)
