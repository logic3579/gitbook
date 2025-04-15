# Container Runtime

## docker / podman

### busybox chroot

```bash
mkdir rootfs
docker export $(docker create busybox) | tar -C rootfs -xvf -
chroot rootfs /bin/ls
chroot rootfs /bin/pwd
chroot rootfs /bin/sh
ls -ld /proc/$(pidof -s sh)/root


# principle: use chroot jail
mkdir jail/{bin,lib,lib64} -p
ldd $(which bash)
cp -r /lib/* jail/lib
cp -r /lib64/* jail/lib64/
cp /bin/ls jail/bin/
cp /bin/bash jail/bin/
chroot jail /bin/bash
[I have no name!@ubuntu /]# ls
bin  lib  lib64
```

### common command

```bash
# common parameters
--env-file strings      Read in a file of environment variables
-p, --publish strings   Publish a containers port
--restart               Restart policy to apply when a container exits
--rm                    Remove container (and pod if created) after exit
-v, --volume stringArray   Bind mount a volume into the container.

# overwrite the default ENTRYPOINT
docker run --rm -it --entrypoint sh hashicorp/terraform:latest

# select container ip
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' yakir-test

# reverse checking Dockerfile content
docker history db6effbaf70b --format {{.CreatedBy}} --no-trunc=true |sed "s#/bin/sh -c \#(nop) *##g" |tac

# commit
docker commmit -m 'commit message' container_id repository/xxx/xxx:tag

# build image
docker build -t yakir/test:latest . -f Dockerfile

# buildx plugin
docker buildx build --platform linux/amd64,linux/arm64 -t yakir/test:latest . -f Dockerfile

# compose plugin
docker compose up -d
docker compose down
docker compose restart

```

### Quick test container

```bash
# busybox
# option1
docker run --name busybox --rm -d docker.io/busybox sleep infinity
docker exec -it busybox sh
# option2
docker run --name busybox --rm -it busybox sh

# kafka-client
docker run --name kafka-client --rm -it bitnami/kafka bash

# mysql-client
docker run --name mysql-client --rm -it bitnami/mysql bash

# redis-client
docker run --rm --name redis-client -it bitnami/redis bash


# minio server
docker run --rm --name minio-server \
  -p 9000-9001:9000-9001 \
  -v $(pwd)/data/minio/:/data \
  quay.io/minio/minio server /data --console-address ":9001"

# mysql server
docker run --name mysql \
  -e MYSQL_ROOT_PASSWORD=root_password \
  -e MYSQL_DATABASE=your_database \
  -p 3306:3306 \
  -v $(pwd)/data/mysql/:/var/lib/mysql \
  -d mysql --character-set-server=utf8mb4

# knowledge-base
docker run --name mrdoc_mysql \
  -e MYSQL_ROOT_PASSWORD=knowledge_base123 \
  -e MYSQL_DATABASE=knowledge_base \
  -v $(pwd)/data/mysql/:/var/lib/mysql \
  -d mysql --character-set-server=utf8mb4
docker run --name mrdoc \
  -p 10086:10086 \
  -v /opt/MrDoc:/app/MrDoc \
  -d zmister/mrdoc:v4
```

## containerd

```bash
# default run by systemd
systemctl start containerd.service
# run by k3s
containerd -c /var/lib/rancher/k3s/agent/etc/containerd/config.toml -a /run/k3s/containerd/containerd.sock --state /run/k3s/containerd --root /var/lib/rancher/k3s/agent/containerd


# ctr (see pause container)
## default
ctr --address /run/containerd/containerd.sock namespace ls
ctr --address /run/containerd/containerd.sock -n k8s.io images ls
## run by k3s
ctr --address /run/k3s/containerd/containerd.sock namespace ls
ctr --address /run/k3s/containerd/containerd.sock -n k8s.io images ls
ctr --address /run/k3s/containerd/containerd.sock -n k8s.io container ls


# crictl
endpoint="/run/k3s/containerd/containerd.sock" URL="unix:///run/k3s/containerd/containerd.sock"
crictl ps
crictl images
```

## kubectl

### Basic

```bash
# create
# create a tls secret
kubectl create secret tls my-secret-tls --dry-run=client \
    --save-config \
    --cert=./tls.crt \
    --key=./tls.key \
    -oyaml | kubectl apply -f -
# create a private image registry secret
kubectl create secret docker-registry my-harbor \
    --docker-server=harbor.yakir.top \
    --docker-username='username' \
    --docker-password='password'
# create deployment
kubectl create deployment busybox --image=busybox -- sleep infinity

# expose
kubectl expose service/pod nginx --port=8888 --target-port=8080 --name=myname

# run
kubectl run busybox --rm -it --image=busybox --restart=Never -- sh

# set
kubectl set env deployments/my-app KEY_1=VAL_1 ... KEY_N=VAL_N

# explain
kubectl explain cronjobs
kubectl explain deployments
kubectl explain statefulset.spec.updateStrategy.rollingUpdate

# get
kubectl get statefulsets redis-cluster -o jsonpath='{.spec.template.spec.containers[*].resources}'
kubectl get pods -o jsonpath='{range .items[*]};{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status},{end}{end};' | tr ";" "\n"
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' |xargs -n1
# select by custome-columns
kubectl get pod my-pod -o=custom-columns=\
PodName:.metadata.name,\
NodeName:.spec.nodeName,\
ContainerPort:.spec.containers[*].ports[*].containerPort
# get all api info
kubectl get --raw /
kubectl get --raw /apis/apps/v1

# edit
kubectl edit (resource_type) (resource_name)

# delete
kubectl delete pod busybox [--force=true --grace-period=0]
```

### Deploy

```bash
# rollout
kubectl rollout (history|pause|restart|resume|status|undo) (resource_type) (resource_name)

# scale
kubectl scale [--resource-version=version] [--current-replicas=count] --replicas=COUNT (-f x.yaml | deployment mysql)

# autoscale
kubectl autoscale (-f x.yaml | deployment/mysql) [--min=MINPODS] --max=MAXPODS [--cpu-percent=CPU] [options]
```

### Cluster Management

```bash
# top
kubectl -n namespace_name top pod
kubectl top node

# schedulable and evicted
kubectl cordon <node-name>
kubectl uncordon <node-name>
kubectl drain <node-name> [--ignore-daemonsets=true] [--delete-emptydir-data=true]

# taint and affnity
kubectl describe nodes |grep Taints
kubectl taint NODE NAME KEY_1=VAL_1:TAINT_EFFECT_1 ... KEY_N=VAL_N:TAINT_EFFECT_N [options]
```

### Troubleshooting and Debugging

```bash
# describe
kubectl describe -k ./
kubectl describe service service_name

# logs
kubectl get pod --show-labels
kubectl logs -f --tail 10 pod_name -l app.kubernetes.io/instance=ingress-nginx --max-log-requests=5

# attach
kubectl attach -it pod pod_name [-c container_name]

# exec
kubectl exec -it pod_name [-c container_name] -- bash/sh

# port-forward
kubectl -n argocd port-forward --address=0.0.0.0 pods/argocd-server-cd747d9d7-k7k4z 9999:8080
kubectl -n argocd port-forward --address=0.0.0.0 services/argocd-server 9999:80

# proxy(apiserver)
kubectl proxy --address=0.0.0.0

# cp
kubectl cp pod_name:/path/path /tmp/path

# auth
# kubectl auth can-i get pods --as=system:serviceaccount:<namespace>:<serviceaccount-name> -n <namespace>
kubectl auth can-i create applications --as=system:serviceaccount:argocd:argocd-server -n argocd

# debug
kubectl debug -it pod/pod_name --image=busybox [--target=container_name] -- /bin/sh
# debug node(need to be deleted pod manually and node persistent in /host/)
kubectl debug -it node/node_name --image=ubuntu -- /bin/bash
kubectl delete pod node-debuger-xxx

# events
kubectl events -n namespace_name
```

### Advanced

```bash
# diff
kubectl diff -f FILENAME [options]

# apply
# manifest file
kubectl apply -f <manifest.yaml> --dry-run=client
# kustomize directory
kubectl apply -k <kustomization_directory> --dry-run=client

# patch
# option1
kubectl patch ingress harbor-ingress-notary --type='json' -p='[{"op": "add", "path": "/spec", "value":"ingressClassName: nginx"}]'
# option2
kubectl patch ingress gitlab-webservice-default --patch '{"spec":{"ingressClassName": "nginx"}}'

# replace
kubectl replace -f FILENAME [options]

# wait

# kustomize(need kustomization.yaml)
kubectl kustomize <kustomization_directory>
kubectl kustomize ./ |kubectl apply -f -
```

### Settings

```bash
# label
kubectl label nodes Node1 node-role.kubernetes.io/control-plane=true

# annotate
kubectl annotate pods yakir-tools key1=value1

# completion
source <(kubectl completion bash)
```

### Other

```bash
# api resources and versions infomation
kubectl api-resources
kubectl api-versions

# config
# select cluster config
kubectl config current-context
kubectl config get-clusters
kubectl config get-contexts
kubectl config get-users
kubectl config view
# add or set custom config
kubectl config set PROPERTY_NAME PROPERTY_VALUE
# add cluster config
kubectl config set-cluster NAME [--server=server] [--certificate-authority=path/to/certficate/authority] [--insecure-skip-tls-verify=true]
kubectl config set-context NAME [--cluster=cluster_nickname] [--user=user_nickname] [--namespace=namespace]
kubectl config set-credentials NAME [--client-certificate=path/to/certfile] [--client-key=path/to/keyfile] [--token=bearer_token] [--username=basic_user] [--password=basic_password]
# use and set context
kubectl config use-context CONTEXT_NAME
kubectl config set-context NAME [--cluster=cluster_nickname] [--user=user_nickname] [--namespace=namespace]

# check version
kubectl version
```

### Quick test container

```bash
# busybox
# option1
kubectl run busybox --rm busybox --image=docker.io/busybox -- sleep infinity
kubectl exec -it busybox -- sh
# option2
kubectl run busybox --rm -it --image=busybox -- sh

# mysql-client
kubectl run mysql-client --rm -it --image=bitnami/mysql -- bash

# kafka-client
kubectl run kafka-client --rm -it --image=bitnami/kafka -- bash

# redis-client
kubectl run redis-client --rm -it --image=bitnami/redis -- bash

# net-tools
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- bash
```

## helm

```bash
# parameter
-n namespace
--create-namespace
--set hostname=xxx

# completion
source <(helm completion bash)

# create
helm create mychart

# dependency
helm dependency update

# env
helm env

# get
helm get (all|manifest) chart_name --revision int

# history
helm -n cattle-system history rancher

# install,upgrade,uninstall
helm install [RELEASE_NAME] ingress-nginx/ingress-nginx
helm upgrade [RELEASE_NAME] [CHART] --install
helm uninstall [RELEASE_NAME]

# lint
helm lint /opt/helm-charts/*

# list
helm list -A

# package
helm package /opt/helm-charts/*

# pull,fetch and push
helm pull --version=x.x.x rancher-stable/rancher --untar
helm push [chart] [remote] [flags]

# registry
helm registry [command]

# repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm update

# rollback

# search
helm search hub ingress-nginx
helm search repo ingress-nginx
--versions           # search repo all charts version
--max-col-width 150  # search display width

# show
helm show values [CHART] [flags]

# status
helm status RELEASE_NAME [flags]

# template
helm template [NAME] [CHART] [flags]

# test

# verify

# version
helm version
```

> Reference:
>
> 1. [Docker Official Website](https://docs.docker.com/)
> 2. [Podman Official Website](https://podman.io/docs)
> 3. [Kubectl Official Website](https://kubernetes.io/docs/reference/kubectl/)
> 4. [Helm Official Website](https://helm.sh/docs/)
