---
description: Network File System
---

# NFS

## 一、 NFS Server 端部署配置
### 原理简介
首先服务器端启动RPC服务，并开启111端口
服务器端启动NFS服务，并向RPC注册端口信息
客户端启动RPC（portmap服务），向服务端的RPC(portmap)服务请求服务端的NFS端口
服务端的RPC(portmap)服务反馈NFS端口信息给客户端。
客户端通过获取的NFS端口来建立和服务端的NFS连接并进行数据的传输。

### Server 部署配置
```bash
# ubuntu 安装
apt install nfs-kernel-server


# 创建共享目录
mkdir /a18_data /qc_data


# 配置文件（* 处可配置IP CIDR，GCP 已有防火墙，直接全放行即可）
cat > /etc/exports << "EOF"
/a18_data *(rw,sync,no_subtree_check)
/qc_data  *(rw,sync,no_subtree_check)
EOF
# 启用 nfs 配置与重载
exportfs -a
exportfs –r
# 查看挂载详细配置（sec 配置见Reference:
exportfs -v
/a18_data       <world>(rw,wdelay,root_squash,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)


# 启动与开机自启，需要确保 rpc 服务已启动
systemctl start rpcbind
systemctl enable rpcbind
systemctl start nfs-kernel-server
systemctl enable nfs-kernel-server


# GCP 放行 2049 端口
略
```


### Client 端挂载
```bash
# nfs 客户端挂载
apt install nfs-common
mkdir /tmp/nfs_test
mount -t nfs 1.1.1.1:/a18_data /tmp/nfs_test


# k8s 集群挂载
通过 pv、pvc 挂载（略）

```


## 二、K8S NFS 供应插件
### NFS CSI Driver
```bash
# create csi driver 
curl -skSL https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/deploy/install-driver.sh | bash -s master --

# verify csi-driver
kubectl -n kube-system get pod |grep csi-nfs
csi-nfs-controller-78b54d4cc4-d6clt 
csi-nfs-node-8z4fm
...

kubectl get csidrivers
nfs.csi.k8s.io 

# create storageclass resource
cat > csi-nfs-client.yaml << "EOF"
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: csi-nfs-client
provisioner: nfs.csi.k8s.io
parameters:
  server: 1.1.1.1
  share: /opt/csi_nfs
reclaimPolicy: Delete
volumeBindingMode: Immediate
mountOptions:
  - nfsvers=4.1
EOF
kubectl apply -f csi-nfs-client.yaml

# create pvc pod verify
...

```


### nfs-subdir-external-provisioner
```bash
# add helm repo
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update

helm pull nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --untar
cd nfs-subdir-external-provisioner

# config
vim values.yaml
nfs:
  server: 1.1.1.1
  path: /middleware

storageClass:
  # 动态存储类名称
  name: nfs-client

# deploy
helm install nfs-subdir-external-provisioner . --namespace kube-system


# create storageclasses and pod 

```


### nfs-ganesha-server-and-external-provisioner
```bash
# https://github.com/kubernetes-sigs/nfs-ganesha-server-and-external-provisioner
```


>K8S 集群 PV 重建切换
```bash
# 删除原 pv 资源
kubectl delete pv qc-nfs-pv


# 此时 pv 资源会进入 Terminaling 状态，需要人工介入
# pvc 资源会进入 lost 状态，等待 pv 资源重建
kubectl edit pv qc-nfs-pv
  # 删除这两行数据，强制删除 pv 资源
  finalizers:
  - kubernetes.io/pv-protection


# 重建 pv（通过 helm 更新）
cd /opt/tc-helm/helm-charts/public/global/
vim values.yaml  #更新 NFS 主机信息
helm -n public upgrade global -f values.yaml .


# 查看 pv，pvc 状态，等待几秒 pvc 变为 Bound 状态即为正常
kubectl get pv,pvc


# rancher 重启 pod ，进入新的 pod 查看 nfs 挂载是否正常生效
mount |grep nfs
```



> Reference:
> 1. [NFS 服务端部署](https://cshihong.github.io/2018/10/16/NFS%E6%9C%8D%E5%8A%A1%E5%99%A8%E6%90%AD%E5%BB%BA%E4%B8%8E%E9%85%8D%E7%BD%AE/)
> 2. [NFS CSI Driver 官方地址](https://github.com/kubernetes-csi/csi-driver-nfs/blob/master/docs/install-csi-driver-master.md)
> 3. [NFS 使用介绍](http://www.lishuai.fun/2021/08/12/k8s-nfs-pv/#/%E5%AD%98%E5%82%A8%E7%B1%BB%E4%BD%BF%E7%94%A8%EF%BC%88%E5%8A%A8%E6%80%81%E9%85%8D%E7%BD%AE)
