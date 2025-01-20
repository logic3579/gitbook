---
description: Network File System
---

# NFS

NFS or Network File System is a distributed file system protocol that allows you to share directories over a network. With NFS, you can mount remote directories on your system and work with the files on the remote machine as if they were local files.

## NFS Server
### Install
```bash
# install server
apt install nfs-kernel-server

# sharde directory
mkdir /nfs

# config
cat > /etc/exports << "EOF"
/nfs *(rw,sync,no_subtree_check)
EOF

# apply and reload
exportfs -a
exportfs –r

# mount verbose
exportfs -v
/nfs       <world>(rw,wdelay,root_squash,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)

# systemd manage
systemctl start rpcbind
systemctl enable rpcbind
systemctl start nfs-kernel-server
systemctl enable nfs-kernel-server
```

### client mount
```bash
# install client
apt install nfs-common

# mount a shared NFS directory
mkdir /opt/nfs
mount -t nfs 1.1.1.1:/nfs /opt/nfs

# option: startup mount
1.1.1.1:/nfs /opt/nfs nfs rsize=8192,wsize=8192,timeo=14,intr
```

## Kubernetes CSI Driver
### csi-driver-nfs
```bash
# install a specific version
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs --namespace kube-system --version v4.9.0

# kubernetes csi-driver verbose
kubectl get csidrivers |grep 
kubectl -n kube-system get pod |grep csi-nfs

# create storageclass resource
cat > storageclass-nfs.yaml << "EOF"
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-csi
provisioner: nfs.csi.k8s.io
parameters:
  server: nfs-server.default.svc.cluster.local
  share: /
  # csi.storage.k8s.io/provisioner-secret is only needed for providing mountOptions in DeleteVolume
  # csi.storage.k8s.io/provisioner-secret-name: "mount-options"
  # csi.storage.k8s.io/provisioner-secret-namespace: "default"
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: true
mountOptions:
  - nfsvers=4.1
EOF
kubectl apply -f storageclass-nfs.yaml
```

### example
```bash
# option1: manual create pv
cat > pv-nfs-csi.yaml << "EOF"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    pv.kubernetes.io/provisioned-by: nfs.csi.k8s.io
  name: pv-nfs
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs-csi
  mountOptions:
    - nfsvers=4.1
  csi:
    driver: nfs.csi.k8s.io
    # volumeHandle format: {nfs-server-address}#{sub-dir-name}#{share-name}
    # make sure this value is unique for every share in the cluster
    volumeHandle: nfs-server.default.svc.cluster.local/share##
    volumeAttributes:
      server: nfs-server.default.svc.cluster.local
      share: /
EOF
kubectl apply -f pv-nfs-csi.yaml

# option2: dynamics pvc
cat > nginx-pod-nfs.yaml << "EOF"
---
kind: Pod
apiVersion: v1
metadata:
  name: nginx-nfs
  namespace: default
spec:
  nodeSelector:
    "kubernetes.io/os": linux
  containers:
    - image: mcr.microsoft.com/oss/nginx/nginx:1.19.5
      name: nginx-nfs
      command:
        - "/bin/bash"
        - "-c"
        - set -euo pipefail; while true; do echo $(date) >> /mnt/nfs/outfile; sleep 1; done
      volumeMounts:
        - name: persistent-storage
          mountPath: "/mnt/nfs"
          readOnly: false
  volumes:
    - name: persistent-storage
      persistentVolumeClaim:
        claimName: pvc-nfs-dynamic
EOF
kubectl apply -f nginx-pod-nfs.yaml
```

<!-- ### nfs-subdir-external-provisioner -->
<!-- ```bash -->
<!-- # add helm repo -->
<!-- helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/ -->
<!-- helm repo update -->
<!---->
<!-- helm pull nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --untar -->
<!-- cd nfs-subdir-external-provisioner -->
<!---->
<!-- # config -->
<!-- vim values.yaml -->
<!-- nfs: -->
<!--   server: 1.1.1.1 -->
<!--   path: /middleware -->
<!-- storageClass: -->
<!--   name: nfs-client -->
<!---->
<!-- # deploy -->
<!-- helm install nfs-subdir-external-provisioner . --namespace kube-system -->
<!---->
<!-- # create storageclasses and pod  -->
<!-- ``` -->



> Reference:
> 1. [NFS](https://ubuntu.com/server/docs/network-file-system-nfs)
> 2. [Kubernetes NFS CSI Driver](https://github.com/kubernetes-csi/csi-driver-nfs)
> 3. [StorageClass Resources](https://github.com/kubernetes-csi/csi-driver-nfs/blob/master/docs/driver-parameters.md)
