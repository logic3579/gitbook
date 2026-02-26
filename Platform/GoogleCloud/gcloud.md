---
description: gcloud
---

# gcloud

## Common

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
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:SA@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/editor"

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

## Cloud Storage

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

# Object operations
gcloud storage cp LOCAL_FILE gs://BUCKET_NAME/
gcloud storage cp gs://BUCKET_NAME/FILE ./
gcloud storage cp -r gs://BUCKET_SRC/ gs://BUCKET_DST/
gcloud storage ls gs://BUCKET_NAME/
gcloud storage rm gs://BUCKET_NAME/FILE
```

## Compute Engine

```bash
# Zones and regions
gcloud compute zones list
gcloud compute regions list

# Virtual Machines
gcloud compute instances create INSTANCE_NAME \
    --zone=asia-southeast1-a \
    --machine-type=e2-medium \
    --image-family=debian-12 \
    --image-project=debian-cloud
gcloud compute instances list
gcloud compute instances list --format="value(name,zone)"
gcloud compute instances list --filter="zone ~ ^asia AND -machineType:e2-standard-2"
gcloud compute instances describe INSTANCE_NAME --zone=ZONE
gcloud compute instances update INSTANCE_NAME --zone=ZONE --deletion-protection
gcloud compute instances stop INSTANCE_NAME --zone=ZONE
gcloud compute instances start INSTANCE_NAME --zone=ZONE
gcloud compute instances delete INSTANCE_NAME --zone=ZONE
gcloud compute ssh USER@INSTANCE_NAME --zone=ZONE

# Disks
gcloud compute disks list
gcloud compute disks create DISK_NAME --size=50GB --zone=ZONE --type=pd-ssd
gcloud compute disks resize DISK_NAME \
    --size=100GB \
    --zone=asia-southeast1-a
gcloud compute instances attach-disk INSTANCE_NAME \
    --disk=DISK_NAME --zone=ZONE

# Snapshots
gcloud compute disks snapshot DISK_NAME --zone=ZONE --snapshot-names=SNAPSHOT_NAME
gcloud compute snapshots list
gcloud compute snapshots describe SNAPSHOT_NAME
gcloud compute snapshots delete SNAPSHOT_NAME

# IAP tunnel
# ssh via IAP
gcloud compute ssh USER@INSTANCE_NAME --tunnel-through-iap --zone=ZONE
# TCP forwarding (e.g. MySQL)
gcloud compute start-iap-tunnel INSTANCE_NAME 3306 \
    --local-host-port=localhost:3306 --zone=ZONE
mysql -h 127.0.0.1 -P 3306 -u root -p
```

## IAM

```bash
# Roles
gcloud iam list-grantable-roles //cloudresourcemanager.googleapis.com/projects/PROJECT_ID
gcloud iam roles list --project=PROJECT_ID
gcloud iam roles create ROLE_ID --project=PROJECT_ID \
    --title="Custom Role" \
    --permissions="compute.instances.list,compute.instances.get"

# Service accounts
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

# Workload Identity Federation
gcloud iam workload-identity-pools list --location=global
gcloud iam workload-identity-pools providers list \
    --workload-identity-pool=POOL_ID --location=global
```

## Artifact Registry

```bash
# Configure Docker authentication for Artifact Registry
gcloud auth configure-docker asia-southeast1-docker.pkg.dev

# Repositories
gcloud artifacts repositories create REPO_NAME \
    --repository-format=docker \
    --location=asia-southeast1
gcloud artifacts repositories list --location=asia-southeast1

# Images
gcloud artifacts docker images list asia-southeast1-docker.pkg.dev/PROJECT_ID/REPO_NAME
gcloud artifacts docker tags list asia-southeast1-docker.pkg.dev/PROJECT_ID/REPO_NAME/IMAGE
```

## Kubernetes Engine

```bash
# Clusters
gcloud container clusters create CLUSTER_NAME \
    --zone=asia-southeast1-a \
    --num-nodes=3 \
    --machine-type=e2-standard-4
gcloud container clusters list
gcloud container clusters describe CLUSTER_NAME --zone=ZONE
gcloud container clusters get-credentials CLUSTER_NAME --zone=ZONE
gcloud container clusters resize CLUSTER_NAME --num-nodes=5 --zone=ZONE
gcloud container clusters update CLUSTER_NAME --zone=ZONE \
    --enable-autoscaling --min-nodes=1 --max-nodes=10
gcloud container clusters delete CLUSTER_NAME --zone=ZONE

# Node pools
gcloud container node-pools list --cluster=CLUSTER_NAME --zone=ZONE
gcloud container node-pools describe POOL_NAME --cluster=CLUSTER_NAME --zone=ZONE
gcloud container node-pools create POOL_NAME \
    --cluster=CLUSTER_NAME \
    --zone=ZONE \
    --machine-type=e2-standard-4 \
    --num-nodes=3 \
    --enable-autoscaling --min-nodes=1 --max-nodes=10
gcloud container node-pools update POOL_NAME \
    --cluster=CLUSTER_NAME --zone=ZONE \
    --enable-autoscaling --min-nodes=2 --max-nodes=20
gcloud container node-pools delete POOL_NAME --cluster=CLUSTER_NAME --zone=ZONE

# Container images (legacy, prefer Artifact Registry)
gcloud container images list-tags gcr.io/PROJECT_ID/IMAGE
```

## Network Services

```bash
# Cloud DNS
gcloud dns managed-zones list
gcloud dns managed-zones describe ZONE_NAME
gcloud dns record-sets list --zone=ZONE_NAME
gcloud dns record-sets create 'www.example.com' \
    --type=A \
    --ttl=300 \
    --zone=ZONE_NAME \
    --rrdatas="1.1.1.1"
gcloud dns record-sets update 'www.example.com' \
    --type=A \
    --ttl=300 \
    --zone=ZONE_NAME \
    --rrdatas="2.2.2.2"
gcloud dns record-sets delete 'www.example.com' --type=A --zone=ZONE_NAME

# Load Balancing
gcloud compute forwarding-rules list
gcloud compute backend-services list
gcloud compute url-maps list
gcloud compute target-http-proxies list
gcloud compute ssl-certificates list
```

## VPC Network

```bash
# VPC networks
gcloud compute networks list
gcloud compute networks subnets list --network=NETWORK_NAME
gcloud compute networks subnets list --regions=asia-southeast1

# External IP addresses
gcloud compute addresses list
gcloud compute addresses create ADDRESS_NAME \
    --region=asia-southeast1
gcloud compute addresses create ADDRESS_NAME \
    --global                                         # for global load balancer
gcloud compute addresses describe ADDRESS_NAME --region=asia-southeast1
gcloud compute addresses delete ADDRESS_NAME --region=asia-southeast1

# Firewall rules
gcloud compute firewall-rules list
gcloud compute firewall-rules list --filter="network:default"
gcloud compute firewall-rules create allow-ssh \
    --network=default \
    --allow=tcp:22 \
    --source-ranges="0.0.0.0/0" \
    --target-tags=allow-ssh
gcloud compute firewall-rules describe allow-ssh
gcloud compute firewall-rules delete allow-ssh

# Routes
gcloud compute routes list
```

> Reference:
>
> 1. [Official Website](https://cloud.google.com/sdk/docs/cheatsheet)
