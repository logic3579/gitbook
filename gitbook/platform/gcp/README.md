---
icon: google
description: GCP
---

# GCP

GCP platform services and infrastructure.

- [Artifact Registry](artifact-registry.md) — Container images and packages
- [GCE](gce.md) — Compute Engine
- [GCS](gcs.md) — Cloud Storage
- [GKE](gke.md) — Kubernetes Engine
- [IAM](iam.md) — Identity, service accounts, Workload Identity Federation
- [Network](network.md) — VPC, Cloud DNS, Cloud Load Balancing

## gcloud CLI Basics

```bash
# Authentication
gcloud auth login                            # interactive browser login
gcloud auth application-default login        # set Application Default Credentials (ADC)
gcloud auth activate-service-account --key-file=KEY.json
gcloud auth list                             # list authenticated accounts
gcloud auth revoke                           # revoke credentials

# Configuration
gcloud config set project PROJECT_ID
gcloud config set compute/region asia-southeast1
gcloud config set compute/zone asia-southeast1-a
gcloud config get project
gcloud config list                           # list all properties

# Configuration profiles
gcloud config configurations create staging
gcloud config configurations list
gcloud config configurations activate staging

# Projects
gcloud projects describe PROJECT_ID
gcloud projects list

# Components
gcloud components list
gcloud components install kubectl
gcloud components update

# Info and version
gcloud info
gcloud version

# Global flags
--project=PROJECT_ID                         # override active project
--format="json|yaml|table|value|csv"         # output format
--filter="EXPRESSION"                        # filter results
--quiet                                      # disable interactive prompts
--verbosity=debug                            # set log verbosity
--help                                       # show help
```

> Reference:
>
> 1. [Official Website](https://cloud.google.com/)
> 2. [gcloud CLI Cheatsheet](https://cloud.google.com/sdk/docs/cheatsheet)
