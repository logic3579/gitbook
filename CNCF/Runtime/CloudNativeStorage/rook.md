---
description: Rook
---

# Rook

## Introduction

...

## Deploy By Container

### Run On Docker

```bash
# https://hub.docker.com/r/rook/ceph/tags
```

### Run On Kubernetes

#### Deploy by Kubernetes Manifest

```bash
# https://rook.io/docs/rook/v1.11/Getting-Started/quickstart/#tldr
git clone https://github.com/rook/rook.git
cd rook/deploy/examples
kubectl create -f crds.yaml -f common.yaml -f operator.yaml

# https://github.com/rook/rook/blob/release-1.11/deploy/examples/cluster-test.yaml
# create rook-cluster
kubectl create -f cluster-test.yaml

# verify the rook-ceph-operator and rook-cluster
kubectl -n rook-ceph get pod,crd
```

#### Deploy by Helm

```bash
# Add and update repo
helm repo add rook https://charts.rook.io/release
helm repo update

# Get charts package
# operator
helm pull rook/rook-ceph --untar
cd rook-ceph

# Configure and run
vim values.yaml
...
helm -n rook-ceph install rook-ceph . --create-namespace

# create rook-cluster
helm pull rook/rook-ceph-cluster --untar
cd rook-ceph-cluster
helm -n rook-ceph install rook-ceph-cluster . --create-namespace

# verify the rook-ceph-operator and rook-cluster
kubectl -n rook-ceph get pod,crd
```

deploy storageclass and use

```bash
# storageclass
# https://github.com/rook/rook/blob/release-1.11/deploy/examples/csi/rbd/storageclass-test.yaml
cat > storage-test.yaml << "EOF"
...
EOF

kubectl -n rook-ceph apply -f storage-test.yaml

# create pvc to bound
cat > pvc-test.yaml << "EOF"
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pv-claim
  labels:
    app: test
spec:
  storageClassName: rook-ceph-block
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF

kubectl -n rook-ceph apply -f pvc-test.yaml
```

> Reference:
>
> 1. [Official Website](https://rook.io/)
> 2. [Repository](https://github.com/rook/rook)
