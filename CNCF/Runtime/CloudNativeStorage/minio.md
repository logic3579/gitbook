---
description: Minio
---

# Minio

## Introduction
...


## Deploy With Binary
### Quick Start
```bash
# download source
wget https://dl.min.io/server/minio/release/linux-amd64/minio
chmod +x minio
mkdir -p /opt/minio/data /opt/minio/bin
mv minio /opt/minio/bin/

# postinstallation
groupadd -r minio-user
useradd -M -r -g minio-user -s /bin/false minio-user
chown minio-user:minio-user /mnt/disk1 /mnt/disk2 /mnt/disk3 /mnt/disk4 -R

# startup: single node
export PATH=$PATH:/opt/minio/bin
minio server /opt/minio/data

# startup: multi node
# need add new disk driver for /opt/minio/data
minio server --console-address :9001 http://1.1.1.1/opt/minio/data http://2.2.2.2/opt/minio/data http://3.3.3.3/opt/minio/data
```

### Storage Requirements
```bash
# Use local Storage
mkdir /opt/minio/data
# create lvm and mount data dir
mount /dev/vg_name/lv_name /opt/minio/data

# Persist Drive Mounting and Mapping Across Reboots
cat /etc/fstab
```

### Config and Boot
#### Config
```bash
cat > /etc/default/minio << "EOF"
# set this for MinIO to reload entries with 'mc admin service restart'
MINIO_CONFIG_ENV_FILE=/etc/default/minio

# Single-Node Single-Drive
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin123
MINIO_VOLUMES="/opt/minio/data"
MINIO_OPTS="-console-address :9001"

# Single-Node Multi-Drive
#MINIO_ROOT_USER=minioadmin
#MINIO_ROOT_PASSWORD=minioadmin123
#MINIO_VOLUMES="/data-{1...4}"
#MINIO_OPTS="-console-address :9001"

# Multi-Node Single-Drive: Do not use
#MINIO_ROOT_USER=minioadmin
#MINIO_ROOT_PASSWORD=minioadmin123
#MINIO_VOLUMES="https://minio{1...4}.example.net:9000/opt/minio/data"
#MINIO_OPTS="--console-address :9001"

# Multi-Node Multi-Drive
#MINIO_ROOT_USER=minioadmin
#MINIO_ROOT_PASSWORD=minioadmin123
#MINIO_VOLUMES="https://minio{1...4}.example.net:9000/mnt/disk{1...4}/minio"
#MINIO_OPTS="--console-address :9001"
#MINIO_SERVER_URL="https://minio.example.net:9000"
EOF
```

#### Boot(systemd)
```bash
cat > /etc/systemd/system/minio.service << "EOF"
[Unit]
Description=MinIO
Documentation=https://min.io/docs/minio/linux/index.html
Wants=network-online.target
After=network-online.target
AssertFileIsExecutable=/opt/minio/bin/minio

[Service]
WorkingDirectory=/opt/minio
User=minio-user
Group=minio-user
ProtectProc=invisible
EnvironmentFile=-/etc/default/minio
ExecStartPre=/bin/bash -c "if [ -z \"${MINIO_VOLUMES}\" ]; then echo \"Variable MINIO_VOLUMES not set in /etc/default/minio\"; exit 1; fi"
ExecStart=/usr/local/bin/minio server $MINIO_OPTS $MINIO_VOLUMES
# Type=notify
Restart=always
LimitNOFILE=65536
TasksMax=infinity
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start minio.service
systemctl enable minio.service
```

### Verify
```bash
# download and install minio client
curl https://dl.min.io/client/mc/release/linux-amd64/mc -o mc
chmod +x mc
mv mc /opt/minio/bin

# test
export PATH=$PATH:/opt/minio/bin
# client
mc alias set myminio http://1.1.1.1:9000 accesskey secretkey
mc admin info myminio
mc mb myminio/mybucket
mc cp /tmp/1.txt myminio/mybucket/
mc cat myminio/mybucket/1.txt
```

### Troubleshooting
```bash
# problem 1
# 
```


### Deploy With Container
### Run in Docker
```bash
# single node test
docker run -p 9000:9000 -p 9001:9001 quay.io/minio/minio server /data --console-address ":9001"

```

### Run in Kubernetes
```bash
# add and update repo
helm repo add minio https://helm.min.io/
helm update

# get charts package
helm pull minio/minio --untar
cd minio

# configure and run
vim values.yaml
...
helm -n runtime install minio .

# access and test
kubectl -n runtime get secrets minio -ojsonpath='{.data.accesskey}' |base64 -d
kubectl -n runtime get secrets minio -ojsonpath='{.data.secretkey}' |base64 -d
# client
mc alias set myminio http://pod_ip:9000 accesskey secretkey
mc admin info myminio
mc mb myminio/mybucket
mc ls myminio/mybucket
```


> Reference:
> 1. [Official Website](https://min.io/docs/minio/kubernetes/upstream/)
> 2. [Repository](https://github.com/minio/minio)
