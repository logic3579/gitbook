---
description: Aliyun Elastic Compute Service
tags:
  - platform/aliyun
---

# ECS

Aliyun Elastic Compute Service (ECS) provides resizable virtual servers across multiple regions and instance families.

## Instance Families

| Family | Purpose | Example |
|--------|---------|---------|
| **ecs.g7/g8** | General purpose | App servers, web frontends |
| **ecs.c7/c8** | Compute optimized | Batch processing, encoding |
| **ecs.r7/r8** | Memory optimized | Caches, in-memory databases |
| **ecs.hfg7** | High frequency | Low-latency applications |
| **ecs.i4** | Local SSD storage | High I/O databases |
| **ecs.gn7** | GPU compute | ML training/inference |
| **ecs.ebmgn7** | Bare metal GPU | Large-scale training |

Instance naming convention: `ecs.<family><generation>.<size>` (e.g., `ecs.g7.large`, `ecs.c7.xlarge`).

## Billing Methods

- **PayAsYouGo** — Hourly billing, no commitment.
- **Subscription** — Monthly/yearly prepayment with discount.
- **Preemptible** — Spot-like, up to 90% discount, may be reclaimed.
- **Reserved Instance** — Capacity reservation in exchange for a usage discount.
- **Savings Plan** — Commit to a fixed hourly spend for discount.

## CLI

### Instances

```bash
aliyun ecs RunInstances \
  --RegionId cn-hangzhou \
  --ImageId aliyun_3_x64_20G_alibase \
  --InstanceType ecs.g7.large \
  --SecurityGroupId sg-xxx \
  --VSwitchId vsw-xxx \
  --InstanceName test-instance \
  --InstanceChargeType PostPaid
aliyun ecs DescribeInstances --RegionId cn-hangzhou
aliyun ecs DescribeInstanceAttribute --InstanceId i-xxx
aliyun ecs StartInstance --InstanceId i-xxx
aliyun ecs StopInstance --InstanceId i-xxx
aliyun ecs RebootInstance --InstanceId i-xxx
aliyun ecs DeleteInstance --InstanceId i-xxx --Force true
aliyun ecs ModifyInstanceSpec --InstanceId i-xxx --InstanceType ecs.g7.xlarge
```

### Disks

```bash
aliyun ecs CreateDisk \
  --RegionId cn-hangzhou \
  --ZoneId cn-hangzhou-h \
  --DiskCategory cloud_essd \
  --Size 100 \
  --DiskName data-disk
aliyun ecs DescribeDisks --RegionId cn-hangzhou
aliyun ecs AttachDisk --InstanceId i-xxx --DiskId d-xxx
aliyun ecs DetachDisk --InstanceId i-xxx --DiskId d-xxx
aliyun ecs ResizeDisk --DiskId d-xxx --NewSize 200
aliyun ecs DeleteDisk --DiskId d-xxx
```

### Images

```bash
aliyun ecs DescribeImages --RegionId cn-hangzhou --ImageOwnerAlias system
aliyun ecs CreateImage --InstanceId i-xxx --ImageName custom-image
aliyun ecs DeleteImage --ImageId m-xxx --RegionId cn-hangzhou
```

### Snapshots

```bash
aliyun ecs CreateSnapshot --DiskId d-xxx --SnapshotName backup-2026-06
aliyun ecs DescribeSnapshots --RegionId cn-hangzhou --DiskId d-xxx
aliyun ecs DeleteSnapshot --SnapshotId s-xxx
```

### Key Pairs

```bash
aliyun ecs CreateKeyPair --RegionId cn-hangzhou --KeyPairName my-key
aliyun ecs ImportKeyPair \
  --RegionId cn-hangzhou \
  --KeyPairName my-key \
  --PublicKeyBody "$(cat ~/.ssh/id_rsa.pub)"
aliyun ecs DescribeKeyPairs --RegionId cn-hangzhou
aliyun ecs AttachKeyPair --KeyPairName my-key --InstanceIds '["i-xxx"]'
```

> Reference:
>
> 1. [Official Website](https://www.alibabacloud.com/product/ecs)
> 2. [ECS Instance Families](https://www.alibabacloud.com/help/en/ecs/user-guide/overview-of-instance-families)
