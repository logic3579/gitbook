---
description: EC2
tags:
  - platform/aws
---

# EC2

## Introduction

Amazon Elastic Compute Cloud (EC2) is a core AWS service that provides resizable virtual servers (instances) in the cloud. EC2 offers a wide range of instance types optimized for different workloads, along with flexible pricing models, storage options, and networking configurations. It forms the foundation of most AWS infrastructure deployments.

## Instance Types

EC2 instance types are grouped by family based on the target workload:

| Family | Purpose | Example |
|--------|---------|---------|
| **t3/t4g** | General purpose, burstable | Web servers, dev environments |
| **m6i/m7g** | General purpose, balanced | Application servers, databases |
| **c6i/c7g** | Compute optimized | Batch processing, ML inference |
| **r6i/r7g** | Memory optimized | In-memory caches, large databases |
| **i4i** | Storage optimized | High I/O databases |
| **p4d/p5** | GPU accelerated | ML training, HPC |
| **g5** | Graphics intensive | Video encoding, game streaming |

Instance naming convention: `<family><generation><attributes>.<size>` (e.g., `m6i.xlarge`, `c7g.2xlarge`)

## Pricing Models

- **On-Demand**: Pay by the second with no commitment
- **Reserved Instances**: 1 or 3-year commitment for up to 72% discount
- **Savings Plans**: Flexible pricing with commitment to usage amount ($/hr)
- **Spot Instances**: Up to 90% discount for interruptible workloads
- **Dedicated Hosts**: Physical server dedicated to your account for compliance requirements

## Key Concepts

### AMI (Amazon Machine Image)

AMIs are templates for launching instances:

```bash
# List available Amazon Linux AMIs
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --output text

# Launch an instance
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.medium \
  --key-name my-keypair \
  --security-group-ids sg-0123456789abcdef0 \
  --subnet-id subnet-0123456789abcdef0 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=my-server}]'
```

### Security Groups

```bash
# Create a security group
aws ec2 create-security-group \
  --group-name my-sg \
  --description "My security group" \
  --vpc-id vpc-0123456789abcdef0

# Allow SSH and HTTP
aws ec2 authorize-security-group-ingress \
  --group-id sg-0123456789abcdef0 \
  --protocol tcp --port 22 --cidr 10.0.0.0/8

aws ec2 authorize-security-group-ingress \
  --group-id sg-0123456789abcdef0 \
  --protocol tcp --port 80 --cidr 0.0.0.0/0
```

### User Data (Instance Initialization)

```bash
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.micro \
  --user-data file://init-script.sh
```

Example `init-script.sh`:

```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl enable --now httpd
echo "Hello from $(hostname)" > /var/www/html/index.html
```

### Instance Lifecycle

```bash
# List instances
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=my-server" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress]' \
  --output table

# Stop / Start / Terminate
aws ec2 stop-instances --instance-ids i-0123456789abcdef0
aws ec2 start-instances --instance-ids i-0123456789abcdef0
aws ec2 terminate-instances --instance-ids i-0123456789abcdef0
```

## EBS Volumes

```bash
# Create a volume
aws ec2 create-volume \
  --volume-type gp3 \
  --size 100 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=data-vol}]'

# Attach to an instance
aws ec2 attach-volume \
  --volume-id vol-0123456789abcdef0 \
  --instance-id i-0123456789abcdef0 \
  --device /dev/xvdf
```

> Reference:
>
> 1. [Official Website](https://aws.amazon.com/ec2/)
> 2. [CentOS AWS AMIs](https://centos.org/download/aws-images/)
