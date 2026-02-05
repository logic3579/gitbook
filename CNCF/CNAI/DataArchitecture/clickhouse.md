---
description: ClickHouse
---

# Clickhouse

## Introduction

...

## Deploy By Binary

### Run On Systemd

## Deploy By Container

### Run On Kubernetes

```bash
# Add and update repo
helm repo add bitnami https://charts.bitnami.com/bitnami

# Get charts package
helm pull bitnami/clickhouse --untar --version=9.4.3
cd clickhouse

# Configure
vim values.yaml
clusterName: default
auth:
  username: default
  password: ""
resources:
  requests:
    cpu: 2
    memory: 4Gi
  limits:
    cpu: 4
    memory: 8Gi
nodeSelector:
  tier: database
networkPolicy:
  enabled: false
persistence:
  enabled: true
  sieze: 200Gi
keeper:
  enabled: true
  resources:
    requests:
      cpu: 1
      memory: 2Gi
    limits:
      cpu: 1
      memory: 2Gi
  networkPolicy:
    enabled: false
  persistence:
    enabled: true
    size: 8Gi

# Install
helm upgrade --install -n database clickhouse . -f values.yaml
```

## Backup and Restore

### clickhouse-backup

Install and config

```bash
# install
wget https://github.com/Altinity/clickhouse-backup/releases/download/v2.6.41/clickhouse-backup-linux-amd64.tar.gz
tar xf clickhouse-backup-linux-amd64.tar.gz && rm -f clickhouse-backup-linux-amd64.tar.gz
mv /home/ubuntu/build/linux/amd64/clickhouse-backup /usr/bin/

# config
mkdir /etc/clickhouse-backup
# if use gcs: create gcs.json to /etc/clickhouse-backup/gcs.json
vim /etc/clickhouse-backup/config.yml
```

Command

```bash
# backup all tables
clickhouse-backup create backup_$(date +%Y%m%d_%H%M%S)
# backup specific tables
clickhouse-backup create --tables="mydb.mytable" backup_mytable_$(date +%Y%m%d)
# backup schema only
clickhouse-backup create --schema backup_schema_$(date +%Y%m%d)
# backup RBAC objects
clickhouse-backup create --rbac backup_with_rbac
# backup specific partitions
clickhouse-backup create --partitions="202401,202402" backup_partitions

# upload specific backup
clickhouse-backup upload backup_20250101_120000
# upload incremental backup (based on a previous backup)
clickhouse-backup upload --diff-from-remote=backup_20250101 backup_20250102
# resumable upload (supports resuming interrupted transfers)
clickhouse-backup upload --resumable backup_20250101_120000

# create backup and upload directly to remote
clickhouse-backup create_remote backup_$(date +%Y%m%d_%H%M%S)
# create incremental backup
clickhouse-backup create_remote --diff-from-remote=backup_20250101 backup_$(date +%Y%m%d_%H%M%S)

# list all backups
clickhouse-backup list
# list local backups only
clickhouse-backup list local
# list remote backups only
clickhouse-backup list remote

# delete local backup
clickhouse-backup delete local backup_name
# delete remote backup
clickhouse-backup delete remote backup_name
# clean up corrupted local backups
clickhouse-backup clean_local_broken
# clean up corrupted remote backups
clickhouse-backup clean_remote_broken

# download specific backup
clickhouse-backup download backup_20250101_120000
# download schema only
clickhouse-backup download --schema backup_20250101_120000
# resumable download
clickhouse-backup download --resumable backup_20250101_120000

# restore all data
clickhouse-backup restore backup_20250101_120000
# restore schema only
clickhouse-backup restore --schema backup_20250101_120000
# restore data only
clickhouse-backup restore --data backup_20250101_120000
# drop existing tables before restore
clickhouse-backup restore --rm backup_20250101_120000
# restore to a different database
clickhouse-backup restore --restore-database-mapping=old_db:new_db backup_20250101_120000
# restore RBAC objects
clickhouse-backup restore --rbac backup_20250101_120000

# restore directly from remote
clickhouse-backup restore_remote backup_20250101_120000
# restore specific tables
clickhouse-backup restore_remote --tables="mydb.mytable" backup_20250101_120000
```

### Official backup in Kubernetes

Deploy

```bash
# check clickhouse version
kubectl run ch-test --rm -it --restart=Never \
  --namespace=database \
  --image=clickhouse/clickhouse-client:latest \
  -- --host=clickhouse-shard0-0.clickhouse-headless \
     --query="SELECT version()"
kubectl run ch-test --rm -it --restart=Never \
  --namespace=database \
  --image=clickhouse/clickhouse-client:latest \
  -- --host=clickhouse-shard1-0.clickhouse-headless \
     --query="SELECT version()"

# get clickhouse service
kubectl get svc -n database
kubectl get svc -n database | grep headless

# deploy backup cronjob: backup to GCS
kubectl apply -f clickhouse-backup-gcs.yml

# verify
kubectl get cronjobs -n database
kubectl get secret,configmap -n database | grep backup
```

Manually trigger and verify

```bash
# manually trigger full backup
kubectl create job manual-full-$(date +%s) --from=cronjob/clickhouse-backup-full -n database

# manually trigger incremental backup
kubectl create job manual-incr-$(date +%s) --from=cronjob/clickhouse-backup-incremental -n database

# check backup results and records
kubectl exec -it -n database clickhouse-shard0-0 -- clickhouse-client -h localhost -u readonly --password xxx --query="SELECT name FROM system.backups WHERE status = 'BACKUP_CREATED' AND name LIKE '%/shard0/full-%'"
kubectl exec -it -n database clickhouse-shard1-0 -- clickhouse-client -h localhost -u readonly --password xxx --query="SELECT name FROM system.backups WHERE status = 'BACKUP_CREATED' AND name LIKE '%/shard1/full-%'"
```

Command

```bash
# check cronjob and job
kubectl get cronjobs -n database --sort-by=.metadata.creationTimestamp
kubectl get jobs -n database --sort-by=.metadata.creationTimestamp

# suspend/resume cronjob
kubectl patch cronjob clickhouse-backup-full -n database -p '{"spec":{"suspend":true}}'
kubectl patch cronjob clickhouse-backup-full -n database -p '{"spec":{"suspend":false}}'
kubectl patch cronjob clickhouse-backup-incremental -n database -p '{"spec":{"suspend":true}}'
kubectl patch cronjob clickhouse-backup-incremental -n database -p '{"spec":{"suspend":false}}'

# restore
## all
RESTORE ALL FROM S3(
  'https://storage.googleapis.com/your-bucket/clickhouse-backups/shard0/full-shard0-20250101-180002',
  'gcs_hmac_access_key',
  'gcs_hmac_secret_key'
);
RESTORE ALL FROM S3(
  'https://storage.googleapis.com/your-bucket/clickhouse-backups/shard1/full-shard1-20250101-180002',
  'gcs_hmac_access_key',
  'gcs_hmac_secret_key'
);
## restore specific database
RESTORE DATABASE mydb FROM S3(...);
## restore specific table
RESTORE TABLE mydb.mytable FROM S3(...);
## restore specific table to new table
RESTORE TABLE mydb.mytable AS mydb.mytable_new FROM S3(...);
```

Restore

```bash
# full restore
## shard0
kubectl exec -it -n database clickhouse-shard0-0 -- clickhouse-client -h localhost -u default --password xxx --query="
RESTORE TABLE mydb.my_table_local
FROM S3(
  'https://storage.googleapis.com/your_gcs_bucket/shard0/full-shard0-20250101-180002',
  'gcs_hmac_access_key',
  'gcs_hmac_secret_key'
)"
## shard1
kubectl exec -it -n database clickhouse-shard1-0 -- clickhouse-client -h localhost -u default --password xxx --query="
RESTORE TABLE mydb.my_table_local
FROM S3(
  'https://storage.googleapis.com/your_gcs_bucket/shard1/full-shard1-20250101-180002',
  'gcs_hmac_access_key',
  'gcs_hmac_secret_key'
)"

# incremental restore
## shard0
kubectl exec -it -n database clickhouse-shard0-0 -- clickhouse-client -h localhost -u default --password xxx --query="
RESTORE TABLE mydb.my_table_local
FROM S3(
  'https://storage.googleapis.com/your_gcs_bucket/shard0/incremental-shard0-20250102-070001',
  'gcs_hmac_access_key',
  'gcs_hmac_secret_key'
)"
## shard1
kubectl exec -it -n database clickhouse-shard1-0 -- clickhouse-client -h localhost -u default --password xxx --query="
RESTORE TABLE mydb.my_table_local
FROM S3(
  'https://storage.googleapis.com/your_gcs_bucket/shard1/incremental-shard1-20250102-070001',
  'gcs_hmac_access_key',
  'gcs_hmac_secret_key'
)"
```

> Reference:
>
> 1. [Official Website](https://github.com/ClickHouse/ClickHouse)
> 2. [Repository](https://github.com/ClickHouse/ClickHouse)
> 3. [clickhouse-backup](https://github.com/Altinity/clickhouse-backup)
