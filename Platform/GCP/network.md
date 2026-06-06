---
description: GCP VPC, Cloud DNS, and Cloud Load Balancing
tags:
  - platform/gcp
  - networking
---

# Network

## VPC Networks and Subnets

```bash
gcloud compute networks list
gcloud compute networks subnets list --network=NETWORK_NAME
gcloud compute networks subnets list --regions=asia-southeast1
```

## External IP Addresses

```bash
gcloud compute addresses list
gcloud compute addresses create ADDRESS_NAME \
    --region=asia-southeast1
gcloud compute addresses create ADDRESS_NAME \
    --global                                         # for global load balancer
gcloud compute addresses describe ADDRESS_NAME --region=asia-southeast1
gcloud compute addresses delete ADDRESS_NAME --region=asia-southeast1
```

## Firewall Rules

```bash
gcloud compute firewall-rules list
gcloud compute firewall-rules list --filter="network:default"
gcloud compute firewall-rules create allow-ssh \
    --network=default \
    --allow=tcp:22 \
    --source-ranges="0.0.0.0/0" \
    --target-tags=allow-ssh
gcloud compute firewall-rules describe allow-ssh
gcloud compute firewall-rules delete allow-ssh
```

## Routes

```bash
gcloud compute routes list
```

## Cloud DNS

```bash
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
```

## Cloud Load Balancing

```bash
gcloud compute forwarding-rules list
gcloud compute backend-services list
gcloud compute url-maps list
gcloud compute target-http-proxies list
gcloud compute ssl-certificates list
```

> Reference:
>
> 1. [VPC](https://cloud.google.com/vpc/docs)
> 2. [Cloud DNS](https://cloud.google.com/dns/docs)
> 3. [Cloud Load Balancing](https://cloud.google.com/load-balancing/docs)
