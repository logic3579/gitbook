---
description: Container Storage Interface (CSI) is a standard for exposing block and file storage systems to containerized workloads on Kubernetes.
tags:
  - cncf/runtime
  - storage
  - kubernetes
---

# CSI

## Introduction

Container Storage Interface (CSI) is an industry standard that enables storage vendors to develop plugins for container orchestrators like Kubernetes without touching the core orchestrator code. It defines a common API between container orchestrators and storage providers.

### Key Concepts

- **Volume** — A unit of storage made available to a container workload.
- **CSI Driver** — A storage plugin that implements the CSI specification (Node, Controller, and Identity services).
- **PersistentVolume (PV)** — A piece of storage provisioned by the CSI driver.
- **PersistentVolumeClaim (PVC)** — A request for storage by a user/pod.
- **StorageClass** — Defines a class of storage with a specific CSI driver and parameters.
- **VolumeSnapshot** — A point-in-time copy of a volume.

### Architecture

```text
┌────────────────────────────────────────────────────┐
│                 Kubernetes Cluster                  │
│                                                    │
│  ┌─────────────┐         ┌───────────────────┐    │
│  │  kube-       │         │  CSI Driver       │    │
│  │  controller- │────────▶│  Controller Plugin │    │
│  │  manager     │         │  (CreateVolume,    │    │
│  └─────────────┘         │   DeleteVolume,    │    │
│                           │   Snapshot...)     │    │
│  ┌─────────────┐         ├───────────────────┤    │
│  │  kubelet     │────────▶│  Node Plugin       │    │
│  │  (per node)  │         │  (NodeStageVolume, │    │
│  └─────────────┘         │   NodePublish...)  │    │
│                           └────────┬──────────┘    │
│                                    │               │
│                           ┌────────▼──────────┐    │
│                           │  Storage Backend  │    │
│                           │  (AWS EBS, GCE PD,│    │
│                           │   Ceph, NFS...)   │    │
│                           └───────────────────┘    │
└────────────────────────────────────────────────────┘
```

### CSI Sidecar Containers

Kubernetes provides standard sidecar containers that communicate with CSI drivers:

| Sidecar                  | Description                                          |
| ------------------------ | ---------------------------------------------------- |
| external-provisioner     | Watches PVCs and triggers `CreateVolume` / `DeleteVolume` |
| external-attacher        | Watches VolumeAttachment and triggers `ControllerPublish` / `Unpublish` |
| external-snapshotter     | Watches VolumeSnapshot and triggers `CreateSnapshot`  |
| external-resizer         | Watches PVCs for size changes and triggers `ControllerExpandVolume` |
| node-driver-registrar    | Registers the CSI driver with kubelet                 |
| livenessprobe            | Monitors CSI driver health                           |

### StorageClass Example

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "5000"
  throughput: "250"
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

### PVC Example

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-ssd
  resources:
    requests:
      storage: 50Gi
```

### Common CSI Drivers

| Driver                | Storage Backend                 |
| --------------------- | ------------------------------- |
| aws-ebs-csi-driver    | Amazon EBS                      |
| gcp-pd-csi-driver     | Google Persistent Disk          |
| azuredisk-csi-driver   | Azure Managed Disks             |
| csi-driver-nfs        | NFS                             |
| rook-ceph-csi         | Ceph (via Rook)                 |
| minio-csi             | MinIO Object Storage            |
| longhorn-csi          | Longhorn Distributed Storage    |

> Reference:
>
> 1. [CSI Specification](https://github.com/container-storage-interface/spec)
> 2. [Kubernetes CSI Developer Docs](https://kubernetes-csi.github.io/docs/)
> 3. [CSI Drivers List](https://kubernetes-csi.github.io/docs/drivers.html)
