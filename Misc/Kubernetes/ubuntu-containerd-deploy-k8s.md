---
title: Ubutun Deploy Kubernetes With Containerd
categories:
  - Kubernetes
---

## Environment Preparation

### 1. multipass Virtual Machine Creation

```shell
# Generate key pair
ssh-keygen -t rsa -b 4096 -f ~/k8s_rsa -C k8s

# Create Master node
multipass launch -c 2 -m 2G -d 20G -n master --cloud-init - << EOF
ssh_authorized_keys:
- $(cat ~/.ssh/k8s_rsa.pub)
EOF

# Create Node nodes
multipass launch -c 1 -m 2G -d 20G -n node1 --cloud-init - << EOF
ssh_authorized_keys:
- $(cat ~/.ssh/k8s_rsa.pub)
EOF

multipass launch -c 1 -m 2G -d 20G -n node2 --cloud-init - << EOF
ssh_authorized_keys:
- $(cat ~/.ssh/k8s_rsa.pub)
EOF
```

> --cloud-init: Import locally generated public key into the initialization system, enabling passwordless SSH

### 2. Host and Network Planning

| **Host IP**  | **Hostname** | **Host Config** | **Node Role** |
| ------------ | ------------ | --------------- | ------------- |
| 192.168.64.4 | master1      | 2C/2G           | master node   |
| 192.168.64.5 | node1        | 1C/1G           | node          |
| 192.168.64.6 | node2        | 1C/1G           | node          |

| **Subnet**      | **CIDR Range**  |
| --------------- | --------------- |
| nodeSubnet      | 192.168.64.0/24 |
| PodSubnet       | 172.16.0.0/16   |
| ServiceSubnet   | 10.10.0.0/16    |

### 3. Software Versions

| **Software**            | **Version**        |
| ----------------------- | ------------------ |
| Operating System        | Ubuntu 20.04.4 LTS |
| Kernel Version          | 5.4.0-109-generic  |
| containerd              | 1.5.10-1           |
| kubernetes              | v1.23.2            |
| kubeadm                 | v1.23.2            |
| kube-apiserver          | v1.23.2            |
| kube-controller-manager | v1.23.2            |
| kube-scheduler          | v1.23.2            |
| kubectl                 | v1.23.2            |
| kubelet                 | v1.23.2            |
| kube-proxy              |                    |
| etcd                    | v3.5.1             |
| CNI Plugin (calico)     | v3.18              |

## Cluster Configuration (Execute on All Nodes)

### 1. Node Initialization

- Hostname and host resolution

```shell
hostnamectl --static set-hostname master    # Execute on master node
hostnamectl --static set-hostname node1     # Execute on node1
hostnamectl --static set-hostname node2     # Execute on node2

sudo tee -a /etc/hosts << EOF
192.168.64.4 master
192.168.64.5 node1
192.168.64.6 node2
EOF
```

- Disable firewall and swap partition

```shell
sudo ufw disable && sudo systemctl disable ufw

swapoff -a
sed -ri 's/.*swap.*/#&/' /etc/fstab
```

> Why does K8s cluster installation require disabling swap? Swap must be disabled, otherwise kubelet cannot start, which prevents the K8s cluster from starting. Additionally, if kubelet uses swap for data exchange, it significantly impacts performance.

- Synchronize time and timezone

```shell
sudo cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
sudo timedatectl set-timezone Asia/Shanghai

# Write the current UTC time to hardware clock (hardware time defaults to UTC)
sudo timedatectl set-local-rtc 0
# Enable NTP time synchronization:
sudo timedatectl set-ntp yes

# Time server calibration - time synchronization (chronyc smooth sync recommended)
sudo apt-get install chrony -y
sudo chronyc tracking
# Manual calibration - force time update
# chronyc -a makestep
# Synchronize system clock to hardware clock
sudo hwclock -w

# Restart services that depend on system time
sudo systemctl restart rsyslog.service cron.service
```

- Kernel module loading and configuration

```shell
# 1. Install ipvs
sudo apt-get install ipset ipvsadm -y

# 2. Load kernel modules
# Configure modules to load permanently after reboot
sudo tee /etc/modules-load.d/k8s.conf << EOF
# netfilter
br_netfilter
# containerd.
overlay
# ipvs
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
EOF
# Temporarily load modules
mod_tmp=(br_netfilter overlay ip_vs ip_vs_rr ip_vs_wrr ip_vs_sh nf_conntrack)
for m in ${mod_tmp[@]};do sudo modprobe $m; done
lsmod | egrep "ip_vs|nf_conntrack_ipv4"

# 3. Configure kernel parameters
# Set required sysctl parameters, persistent after reboot
sudo tee /etc/sysctl.d/99-kubernetes-cri.conf << EOF
net.bridge.bridge-nf-call-ipv6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
# Apply sysctl parameters temporarily without reboot
sudo sysctl --system
```

- Configure passwordless login (execute on master node, optional)

```shell
# Execute on master node
ssh-keygen
ssh-copy-id -i ~/.ssh/id_rsa.pub root@node1
ssh-copy-id -i ~/.ssh/id_rsa.pub root@node2
```

### 2. Container Runtime Installation

```shell
# 1. Remove old versions
sudo apt-get remove docker docker-engine docker.io containerd runc

# 2. Update apt package index and install packages to allow apt to use repositories over HTTPS
sudo apt-get update
sudo apt-get install \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release -y

# 3. Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 4. Set up stable repository, add nightly or test repository
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
 $(lsb_release -cs) stable nightly" | sudo tee /etc/apt/sources.list.d/container.list

# 5. Install containerd
# Update apt package index, install latest version of containerd or proceed to install a specific version
sudo apt-get update
# View available versions of containerd.io
apt-cache madison containerd.io
# Install specific version
sudo apt install containerd.io=1.5.10-1 -y

# 6. Configure containerd
containerd config default | sudo tee /etc/containerd/config.toml
# Replace pause image source
sudo sed -i "s#k8s.gcr.io/pause#registry.cn-hangzhou.aliyuncs.com/google_containers/pause#g"  /etc/containerd/config.toml
# docker.io & gcr.io & k8s.gcr.io & quay.io mirror acceleration
sudo tee ~/tmp.txt << EOF
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
          endpoint = ["https://taa4w07u.mirror.aliyuncs.com"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."gcr.io"]
          endpoint = ["https://gcr.mirrors.ustc.edu.cn"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."k8s.gcr.io"]
          endpoint = ["https://gcr.mirrors.ustc.edu.cn/google-containers/", "https://registry.aliyuncs.com/google-containers/"]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."quay.io"]
          endpoint = ["https://quay.mirrors.ustc.edu.cn"]
EOF
sudo sed -i '/registry.mirrors\]/r ./tmp.txt' /etc/containerd/config.toml
# Use SystemdCgroup driver, more stable when node resources are constrained
sudo sed -i 's# SystemdCgroup = false# SystemdCgroup = true#g' /etc/containerd/config.toml

# 7. Start containerd and verify
sudo systemctl daemon-reload
sudo systemctl enable containerd
sudo systemctl restart containerd
# Verify
sudo ctr version


```

## Build Cluster

### 1. Component Installation (Execute on All Nodes)

```shell
# Use Alibaba Cloud mirror acceleration
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -
sudo tee /etc/apt/sources.list.d/kubernetes.list << EOF
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

# Update apt package index & view and install version
sudo apt-get update
apt-cache madison kubeadm |head
sudo apt install kubeadm=1.23.2-00 kubelet=1.23.2-00 kubectl=1.23.2-00 -y
# Lock versions
sudo apt-mark hold kubelet kubeadm kubectl
```

```shell
# Configure client tool runtime and image endpoint
sudo crictl config runtime-endpoint /run/containerd/containerd.sock
sudo tee /etc/crictl.yaml << EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

# Reload systemd daemon and enable kubelet to start on boot
sudo systemctl daemon-reload
sudo systemctl enable --now kubelet
# Check kubelet status - it will restart every few seconds, stuck in a loop waiting for kubeadm instructions
systemctl status kubelet

```

### 2. Initialize Master Node

- Execute on Master Node

```shell
# Export default initialization configuration
kubeadm config print init-defaults > kubeadm.yaml

# Modify initial configuration based on local environment
cat > kubeadm.yaml << EOF
apiVersion: kubeadm.k8s.io/v1beta3
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 192.168.64.4 # Set master node IP
  bindPort: 6443
nodeRegistration:
  criSocket: /run/containerd/containerd.sock # Set container runtime to containerd
  imagePullPolicy: IfNotPresent
  name: master # Set master node name
  taints: # Add taint to master node, preventing application scheduling
  - effect: "NoSchedule"
    key: "node-role.kubernetes.io/master"
---
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta3
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns: {}
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.cn-hangzhou.aliyuncs.com/google_containers # Set image mirror address
kind: ClusterConfiguration
kubernetesVersion: 1.23.0
networking:
  dnsDomain: cluster.local
  podSubnet: 172.16.0.0/16  # Set Pod subnet
  serviceSubnet: 10.10.0.0/16 # Set Service CIDR range
scheduler: {}
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs # Set kube-proxy mode to ipvs, default is iptables
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd # Configure cgroup driver
EOF

# List required images for cluster initialization and pre-pull them
kubeadm config images list --config kubeadm.yaml
kubeadm config images pull --config kubeadm.yaml

# Initialize master node
sudo kubeadm init --config=kubeadm.yaml

```

- Execute on Node

```shell
# Command generated after initialization: execute on Node to join the cluster
sudo kubeadm join 192.168.64.4:6443 --token abcdef.0123456789abcdef \
	--discovery-token-ca-cert-hash sha256:6e25620c2478e38edfe335761b8dd37dbbe0dc8c1df9b41d539b148732d32718
# Print join token value
#kubeadm token create --print-join-command

# Command generated after initialization: for kubectl commands
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 3. Install CNI Network Plugin (calico)

> calico plugin official page: [https://projectcalico.docs.tigera.io/getting-started/kubernetes/quickstart](https://projectcalico.docs.tigera.io/getting-started/kubernetes/quickstart)

```shell
# Download calico plugin deployment manifest from official source
wget https://docs.projectcalico.org/v3.18/manifests/calico.yaml
#wget https://docs.projectcalico.org/v3.22/manifests/calico.yaml

# Modify custom configuration
vim calico.yaml
- name: CALICO_IPV4POOL_CIDR
  value: "172.16.0.0/16"

# Verify and wait for calico plugin Pods to run successfully
watch kubectl get pod -n kube-system
NAME                                       READY   STATUS    RESTARTS     AGE
calico-kube-controllers-6cfb54c7bb-7xdld   1/1     Running   0            2m51s
calico-node-sjr6r                          1/1     Running   0            2m52s
calico-node-vsczr                          1/1     Running   0            2m51s


```

```shell
# Set node roles
kubectl label nodes master node-role.kubernetes.io/control-plane=
kubectl label nodes node1 node-role.kubernetes.io/work=
kubectl label nodes node2 node-role.kubernetes.io/work=
kubectl get nodes

# kubectl command auto-completion
sudo apt install -y bash-completion
source /usr/share/bash-completion/bash_completion
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc

# nerdctl tool (docker command replacement)
# Official page
# https://github.com/containerd/nerdctl
# Download and install
wget https://github.com/containerd/nerdctl/releases/download/v0.20.0/nerdctl-0.20.0-linux-amd64.tar.gz
tar Cxfz /usr/local/bin/ nerdctl-0.20.0-linux-amd64.tar.gz
# Usage
sudo nerdctl -n k8s.io images
sudo nerdctl -n k8s.io ps
sudo nerdctl -n k8s.io images     # equivalent to = sudo ctr -n k8s.io images ls
sudo nerdctl -n k8s.io pull nginx # equivalent to = sudo crictl pull nginx
```

```shell
# flannel plugin reset method, not applicable to calico
kubeadm reset
ifconfig cni0 down && ip link delete cni0
ifconfig flannel.1 down && ip link delete flannel.1
rm -rf /var/lib/cni/
```

### 4. Cluster Deployment Verification

```shell
# Deploy Nginx Deployment
kubectl create deployment nginx --image=nginx

# Expose Nginx service, type NodePort
kubectl expose deployment nginx --port=80 --target-port=80 --type=NodePort

# Access verification
curl 10.10.225.108:80 -I      # Request Service port (port, cluster internal)
curl 192.168.64.5:31052 -I    # Request Node port (nodePort, accessible from outside the cluster)
curl 172.16.166.132:80 -I     # Request Pod application internal port (targetPort, container's startup port)
```

### 5. Kubernetes Components

**Control Plane Components**

- kube-apiserver: Multi-instance scaling, high availability with traffic balancing?
- etcd: High availability and backup strategies?
- kube-scheduler scheduling policies: Pod resource requirements, hardware/software/policy constraints, affinity and anti-affinity specifications, data locality, inter-workload interference, and deadlines
- kube-controller-manager

**Data Plane Components (All Nodes)**

- kubelet
- kubeproxy
- Container Runtime (CR): containerd (later Kubernetes versions no longer use docker)

**Addons**

- Network plugins: calico, flannel

**Observability: Logging and Monitoring**

- Logging: fluentd
- Monitoring: Prometheus

## Kubernetes Dashboard

### 1. Kubernetes Native Dashboard

> Official documentation: [https://kubernetes.io/zh/docs/tasks/access-application-cluster/web-ui-dashboard/](https://kubernetes.io/zh/docs/tasks/access-application-cluster/web-ui-dashboard/)

```shell
# 1. Deploy Dashboard manifest
#wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.1/aio/deploy/recommended.yaml
#kubectl apply -f recommended.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.6.0/aio/deploy/recommended.yaml

# 2. Enable Dashboard access
# Check if resources started successfully
kubectl get pod,service -n kubernetes-dashboard
# Change service exposure to NodePort type
kubectl edit service kubernetes-dashboard -n kubernetes-dashboard
#=== Key configuration content
  ports:
  - nodePort: 30333  # Added
    port: 443
    protocol: TCP
    targetPort: 8443
  selector:
    k8s-app: kubernetes-dashboard
  sessionAffinity: None
  type: NodePort  # Changed
####

# 3. The default dashboard is deployed with minimal RBAC permissions. To operate resources, a ClusterRole must be created.
# RBAC reference: https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/README.md
# Login to Dashboard
kubectl describe secret -n kubernetes-dashboard $(kubectl get secret -n kubernetes-dashboard |grep kubernetes-dashboard-token |awk '{print $1}')
# Access via browser (use Firefox)  https://192.168.64.4:30333
# Login using the token obtained above (default token only has kubernetes-dashboard namespace permissions)
```

### 2. K9S Cluster Management Tool

Official documentation: [https://k9scli.io/](https://k9scli.io/)

> Reference:
>
> 1. [multipass Official Website](https://multipass.run/)
> 2. [Kubernetes Official Documentation](https://kubernetes.io/zh/docs/concepts/overview/components/#container-runtime)
> 3. [Install Kubernetes Cluster Using Binary Method](https://blog.weiyigeek.top/2022/5-7-654.html)
