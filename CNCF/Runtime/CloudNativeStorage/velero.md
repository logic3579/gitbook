---
description: Backup and migrate Kubernetes applications and their persistent volumes
---

# Velero

## Install

### Prerequisites
- Access to a Kubernetes cluster, v1.16 or later, with DNS and container networking enabled. For more information on supported Kubernetes versions, see the Velero compatibility matrix.

- kubectl installed locally

### Basic install

1. install minio / s3
```bash
# start minio server
docker run --rm --name minio-server \
  -p 9000-9001:9000-9001 \
  -v $(pwd)/data/minio/:/data \
  quay.io/minio/minio server /data --console-address ":9001"

# create credentials file
cat > ~/.credentials-velero << "EOF"
[default]
aws_access_key_id = your-access-key-id
aws_secret_access_key = your-secret-access-key
EOF
```

2. install cli
```bash
# install
VELERO_VERSION=v1.15.2
wget https://github.com/vmware-tanzu/velero/releases/download/v1.15.2/velero-${VELERO_VERSION}-linux-amd64.tar.gz
tar xf velero-${VELERO_VERSION}-linux-amd64.tar.gz
install -m 0755 velero-${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/
rm -rf velero-${VELERO_VERSION}-linux-amd64.tar.gz velero-${VELERO_VERSON}-linux-amd64/

# verify
velero version

```

3. install and configure the server components
```bash
# install with minio
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.2.1 \
    --bucket velero \
    --secret-file ./credentials-velero \
    --use-volume-snapshots=false \
    --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://minio.velero.svc:9000

# verify
velero backup-location get
```

## Use

### Backup && Restore
```bash
# backup
velero backup create cluster-full-backup
velero backup create namespaces-backup --include-namespaces default,public
velero backup create namespaces-with-pvc-backup --include-namespaces default,public --csi-snapshot-timeout=20m

# schedule backup
velero schedule create cluster-full-daily-backup --schedule="0 1 * * *" --ttl 168h0m0s
velero schedule create cluster-full-weekly-backup --schedule="@every 168h" --ttl 720h0m0s

# Restore
velero restore create --from-backup cluster-full-backup

# get info
velero backup get
velero backup describe <job-name>
velero backup logs <job-name>
velero restore get
velero restore describe <job-name>
velero restore logs <job-name>

# clean up
velero backup delete <job-name>
```

### Cluster migration
```bash
# https://velero.io/docs/v1.15/migration-case/
```



> Reference:
> 1. [Official Website](https://velero.io/)
> 2. [Repository](https://github.com/vmware-tanzu/velero)
