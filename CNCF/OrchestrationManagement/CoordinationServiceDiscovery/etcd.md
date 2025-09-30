---
description: Etcd
---

# Etcd

## Introduction

...

## Deploy By Binary

### Quick Start

```bash
# built from source
git clone -b v3.5.0 https://github.com/etcd-io/etcd.git
cd etcd
./build.sh
install -m 0755 etcd /usr/local/bin
install -m 0755 etcdctl /usr/local/bin
# OR
# download source
wget https://github.com/etcd-io/etcd/releases/download/v3.4.26/etcd-v3.4.26-linux-amd64.tar.gz
tar xf etcd-v3.4.26-linux-amd64.tar.gz && rm -rf etcd-v3.4.26-linux-amd64.tar.gz


# install binaries path
install -m 0755 etcd /usr/local/bin
install -m 0755 etcdctl /usr/local/bin

# create data and config dir
mkdir -p /opt/etcd/data
mkdir -p /opt/etcd/config
```

### Config and Boot

#### Config

```bash
cat > /opt/etcd/config/etcd.conf << "EOF"
ETCD_NAME="etcd01"
ETCD_DATA_DIR="/opt/etcd/data/default.etcd/"
ETCD_LISTEN_PEER_URLS="http://172.22.3.29:2380"
ETCD_LISTEN_CLIENT_URLS="http://172.22.3.29:2379,http://127.0.0.1:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://172.22.3.29:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://172.22.3.29:2379"
ETCD_INITIAL_CLUSTER="etcd01=http://172.22.3.29:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF
```

#### Boot(systemd)

```bash
cat > /etc/systemd/system/etcd.service << "EOF"
[Unit]
Description=Etcd Server
Documentation=https://etcd.io/docs/
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
EnvironmentFile=/opt/etcd/config/etcd.conf
ExecStart=/usr/local/bin/etcd
Restart=on-failure
RestartSec=5s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start etcd.service
systemctl enable etcd.service
```

### cli command

```bash
export ETCDCTL_API=3

#status
etcdctl endpoint status --cluster -w table
etcdctl --endpoints http://x.x.x.x:2379 endpoint status --cluster -w table
etcdctl --endpoints http://x.x.x.x:2379 member list

# operate values
etcdctl  --endpoints http://x.x.x.x:2379 --user=root --password=9A4mEZmkjU put my-key my-value
etcdctl get my-key
```

## Deploy By Container

### Run On Docker

```bash
rm -rf /tmp/etcd-data.tmp && mkdir -p /tmp/etcd-data.tmp && \
docker rmi gcr.io/etcd-development/etcd:v3.4.26 || true && \
docker run \
-p 2379:2379 \
-p 2380:2380 \
--mount type=bind,source=/tmp/etcd-data.tmp,destination=/etcd-data \
--name etcd-gcr-v3.4.26 \
gcr.io/etcd-development/etcd:v3.4.26 \
/usr/local/bin/etcd \
--name s1 \
--data-dir /etcd-data \
--listen-client-urls http://0.0.0.0:2379 \
--advertise-client-urls http://0.0.0.0:2379 \
--listen-peer-urls http://0.0.0.0:2380 \
--initial-advertise-peer-urls http://0.0.0.0:2380 \
--initial-cluster s1=http://0.0.0.0:2380 \
--initial-cluster-token tkn \
--initial-cluster-state new \
--log-level info \
--logger zap \
--log-outputs stderr

# verify
docker exec etcd-gcr-v3.4.26 /usr/local/bin/etcd --version
docker exec etcd-gcr-v3.4.26 /usr/local/bin/etcdctl version
docker exec etcd-gcr-v3.4.26 /usr/local/bin/etcdctl endpoint health
docker exec etcd-gcr-v3.4.26 /usr/local/bin/etcdctl put foo bar
docker exec etcd-gcr-v3.4.26 /usr/local/bin/etcdctl get foo
```

### Run On Kubernetes

[[cc-k8s|deploy by kubernetes manifest]]

```bash
# static pod
# https://www.zhaowenyu.com/etcd-doc/ops/etcd-install-k8s-static-pod.html

# daemonset
# https://www.zhaowenyu.com/etcd-doc/ops/etcd-install-k8s-daemon-set.html
```

[[cc-helm|deploy by helm]]

```bash
# Add and update repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Get charts package
helm pull bitnami/etcd --untar
cd etcd

# Configure and run
vim values.yaml
...

helm -n middleware install etcd . --create-namespace

# get password
kubectl -n middleware get secrets etcd -ojsonpath='{.data.etcd-root-password}' |base64 -d
root
OUE0bUVabWtqVQ==
```

> Reference:
>
> 1. [Official Website](https://etcd.io/)
> 2. [Repository](https://github.com/etcd-io/etcd)
> 3. [中文文档](https://www.zhaowenyu.com/etcd-doc/ops/etcd-install-k8s-static-pod.html)
