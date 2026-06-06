---
description: Google Compute Engine
tags:
  - platform/gcp
---

# Compute Engine

## CLI

### Zones and Regions

```bash
gcloud compute zones list
gcloud compute regions list
```

### Virtual Machines

```bash
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
```

### Disks

```bash
gcloud compute disks list
gcloud compute disks create DISK_NAME --size=50GB --zone=ZONE --type=pd-ssd
gcloud compute disks resize DISK_NAME \
    --size=100GB \
    --zone=asia-southeast1-a
gcloud compute instances attach-disk INSTANCE_NAME \
    --disk=DISK_NAME --zone=ZONE
```

### Snapshots

```bash
gcloud compute disks snapshot DISK_NAME --zone=ZONE --snapshot-names=SNAPSHOT_NAME
gcloud compute snapshots list
gcloud compute snapshots describe SNAPSHOT_NAME
gcloud compute snapshots delete SNAPSHOT_NAME
```

### IAP Tunnel

```bash
# ssh via IAP
gcloud compute ssh USER@INSTANCE_NAME --tunnel-through-iap --zone=ZONE
# TCP forwarding (e.g. MySQL)
gcloud compute start-iap-tunnel INSTANCE_NAME 3306 \
    --local-host-port=localhost:3306 --zone=ZONE
mysql -h 127.0.0.1 -P 3306 -u root -p
```

## Add a Storage Disk

```bash
# 1. add new disk to VM instances
#operate in console

# 2. init lvm volume
# create pv volume
pvcreate /dev/sdb
# create vg volume
vgcreate vg_name /dev/sdb
# create lvs volume
lvcreate -l +100%free -n lv_name vg_name
# format lvs
mkfs.ext4 /dev/vg_name/lv_name
# mount
uuid=$(blkid /dev/mapper/vg_name-lv_name |awk '{print $2}' |awk -F'[="]+' '{print $2}')
echo "UUID=$uuid /mnt/dir ext4 defaults 0 0" >> /etc/fstab
mount -a
```

## Expand Disk Capacity

```bash
# option1: expand the original disk
# get original disk name and pvresize
fdisk /dev/sdb # if /dev/sdb partition
pvs -a -o +devices
pvresize /dev/sdb
# get lv name and extend
lvdisplay
lvextend -l +100%free /dev/vg_name/lv_name
resize2fs /dev/vg_name/lv_name

# option2: add new disk or new disk partition to expand
# create pv
pvcreate /dev/sdc
# get vg name and add new pv to vg group
vgs
vgextend vg_name /dev/sdc
# get lv name and extend
lvdisplay
lvextend -l +100%free /dev/vg_name/lv_name
# reidentify filesystem size
resize2fs /dev/vg_name/lv_name
#xfs_growfs /dev/vg_name/lv_name

# option3: expand Disks
lsblk
growpart /dev/sda 1
resize2fs /dev/sda1
#xfs_growfs /dev/sda1
df -h
```

> Reference:
>
> 1. [Official Website](https://cloud.google.com/compute/docs)
