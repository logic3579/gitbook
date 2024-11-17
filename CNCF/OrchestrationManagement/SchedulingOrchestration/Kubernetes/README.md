---
description: Kubernetes
---

# Kubernetes

## Introduction

## Components
### Control plane
+ etcd(cluster parallel)
+ kube-apiserver(parallel loadbalance)
+ kube-controller-manager(single instance)
+ kube-scheduler(single instance)


### Data plane
+ kubelet
+ kube-proxy
+ container-runtime(docker, containerd, rkt, ...)
+ kube-dns


### Options components
+ kube-dashboard
+ ingress-nginx
+ metrics-server
+ cni


## Resources

### Pods
```yaml
# Pod template
apiVersion: V1
kind: Pod
metadata:
  annotations: {}
  labels: {}
  name: xxx
  namespace: xxx
spec:
  affnity:
    nodeAntiAffinity: {}
    podAntiAffinity: {}

  # Containers
  containers:
    # Args and Command
  - args: []
    command: []
    # Environment variables
    env: []
    envFrom: []
    # Image
    image: xxx:tag
    imagePullPolicy: IfNotPresent
    # Lifecycle
    lifecycle:
	  postStart: {}
	  preStop: {}
    # Name and Ports
    name: xxx
    ports: []
    # Health probes
    livenessProbe: {}
    readinessProbe: {}
    # Resources
    resources:
      limits: {}
      requests: {}
	# Volume mounts
	volumeMounts: []
  
  # imagePullSecrets
  imagePullSecrets: []
  
  # initContainers
  initContainers: []

  # others
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  serviceAccount: xxx
  serviceAccountName: xxx
  tolerations: {}

  # Volume
  volumes: {}
```


### Apps
Deployments -> ReplicaSets
StatefulSets
DaemonSets
Jobs
CronJobs

### Service Discovery
Ingress: 
Service
Endpoints
LoadBalancer
NodePort


LimitRange
ResourceQuota
HozizontalPodAutoscaler


Configmaps
Secrets


PersistentVolumeClaim
PersistentVolume
StorageClass


## Deploy
### kubeadm

### kubespray



> Reference:
> 1. [Official Website](https://kubernetes.io/)
> 2. [Repository](https://github.com/kubernetes/kubernetes)
> 3. [Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
