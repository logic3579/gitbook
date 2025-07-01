---
description: Argo Project
---

# Argo Project

## Argo Workflows

### Introduction

...

### Deploy With Container

#### Run by Resource

```bash
# version
ARGO_WORKFLOWS_VERSION=v3.5.10


# install
kubectl create namespace argo
kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/${ARGO_WORKFLOWS_VERSION}/install.yaml
```

#### Run in Kubernetes

```bash
# add and update repo
helm repo add argo https://argoproj.github.io/argo-helm
helm update


# get charts package
helm pull argo/argo-workflows --untar
cd argo-workflows


# configure and run
vim values.yaml
...
helm -n cicd install argo-workflows .
```

### How To Use

#### postinstallation

```bash
# install cli latest version
ARGO_WORKFLOWS_VERSION=v3.5.10
curl -sLO https://github.com/argoproj/argo-workflows/releases/download/${ARGO_WORKFLOWS_VERSION}/argo-linux-amd64.gz
gunzip argo-linux-amd64.gz
install -m 755 argo-linux-amd64 /usr/local/bin/argo && rm -f argo-linux-amd64


# access argo-server
kubectl -n argo port-forward deployment/argo-server --address=0.0.0.0 2746:2746
# kubectl -n argo apply -f argo-ingress.yaml


# switch authentication mode to server
kubectl patch deployment \
  argo-server \
  --namespace argo \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["server","--auth-mode=server"]}]'


# Fix argo namespace default serviceaccount permission problem:
kubectl -n argo create rolebinding argo-cluster-role-default-binding --clusterrole=argo-cluster-role --serviceaccount=argo:default
```

#### application

```bash
# example
argo -n argo submit -w https://raw.githubusercontent.com/argoproj/argo-workflows/master/examples/hello-world.yaml
argo -n argo list
argo -n argo get @latest

# Steps | DAG | Artifacts etc..
```

## Argo CD

### Introduction

...

### Deploy With Container

#### Run by Resource

```bash
# version
ARGO_CD_VERSION=v2.7.9
kubectl create namespace argocd

# non-ha install
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/${ARGO_CD_VERSION}/manifests/install.yaml

# ha install
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/${ARGO_CD_VERSION}/manifests/ha/install.yaml
```

#### Run in Kubernetes

```bash
# add and update repo
helm repo add argo https://argoproj.github.io/argo-helm
helm update

# get charts package
helm pull argo/argo-cd --untar
cd argo-cd

# configure and run
vim values.yaml
...
helm -n cicd install argocd .
```

### How To Use

#### argocd cli

```bash
# install argocd cli latest version
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
install -m 555 argocd-linux-amd64 /usr/local/bin/argocd && rm -f argocd-linux-amd64


# access argocd server
# development env
kubectl -n argocd port-forward svc/argocd-server --address=0.0.0.0 8080:443
# production env
kubectl -n argocd apply -f argocd-ingress.yaml


# argocd server infomation
ARGOCD_SERVER=argocd.example.com
ARGOCD_USERNAME=admin
ARGOCD_PASSWORD=`kubectl -n argocd get secrets argocd-initial-admin-secret -ojsonpath='{.data.password}' |base64 -d`


# argocd cli login
argocd login $ARGOCD_SERVER --username $ARGOCD_USERNAME --password $ARGOCD_PASSWORD
```

#### applications in any namespace

```bash
# Change workload startup parameters
kubectl -n argocd patch configmaps argocd-cmd-params-cm --type='json' -p='[{"op": "add", "path": "/data", "value": {}}, {"op": "add", "path": "/data/application.namespaces", "value": "app-team-one, app-team-two"}]'
kubectl -n argocd rollout restart deployment argocd-server
kubectl -n argocd rollout restart statefulset argocd-application-controller


# Adapt Kubernetes RBAC
git clone https://github.com/argoproj/argo-cd.git
kubectl apply -k examples/k8s-rbac/argocd-server-applications/


# Create an application
argocd app create foo/bar ...
# Sync the application
argocd app sync foo/bar
# Delete the application
argocd app delete foo/bar
# Retrieve application's manifest
argocd app manifests foo/bar
```

#### account management

```bash
# create user in configmaps
kubectl -n argocd patch configmaps argocd-cm --type='json' -p='[{"op": "add", "path": "/data", "value": {}},{"op": "add", "path": "/data/accounts.myuser", "value": "apiKey, login"}]'
# create password in secrets
argocd account update-password --account myuser


# delete user in configmaps
kubectl -n argocd patch configmaps argocd-cm --type='json' -p='[{"op": "remove", "path": "/data/accounts.myuser"}]'
# delete password in secrets
kubectl -n argocd patch secrets argocd-secret --type='json' -p='[{"op": "remove", "path": "/data/accounts.myuser.password"}]'


# get account infomation
argocd account list
argocd account get --account <username>


# generate token
argocd account generate-token --account <username>


# policy
kubectl -n argocd edit configmaps argocd-rbac-cm
...
data:
  policy.csv: |
	# p, somerole, applications, create, <project>/<namespace>/<application>, allow
    p, myuser, *, *, *, allow
```

#### cluster management

```bash
# get info
argocd cluster list
argocd cluster get <cluster_name>

# create a cluster
argocd cluster add
```

#### appproj management

```bash
# get info
argocd proj list


# create a proj
argocd proj create my-proj --description 'for my-namespace project' --dest https://kubernetes.default.svc,my-namespace --source-namespaces my-namespace --src '*'
# or
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: my-proj
  namespace: argocd
spec:
  description: for my-namespace project
  destinations:
  - namespace: my-namespace
    server: https://kubernetes.default.svc
  sourceNamespaces:
  - my-namespace
  sourceRepos:
  - '*'
EOF
```

#### repository management

```bash
# get info
argocd repo list
argocd repocreds list


# create a repo
argocd repo add https://git.example.com/repos/repo --username git --password secret
argocd repo add https://charts.helm.sh/stable --type helm --name stable


# create a repocreds template
argocd repocreds add https://gitlab.com/your_repo/argocd.git --username git --password secret
```

#### application management

```bash
# get infomation
argocd app list
argocd appset list
argocd app get <applications_name>


# create applications
# create a app from manifests
argocd app create guestbook \
  --auto-prune
  --dest-name in-cluster \
  --dest-namespace default \
  --dest-server https://kubernetes.default.svc \
  --project default \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path guestbook \
  --self-heal \
  --sync-policy automated
# create a helm app from a git repo
argocd app create helm-guestbook \
  --auto-prune
  --dest-name in-cluster \
  --dest-namespace default \
  --dest-server https://kubernetes.default.svc \
  --project default \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path helm-guestbook \
  --self-heal \
  --sync-policy automated
# create a Helm app from a Helm repo
argocd app create nginx-ingress \
  --repo https://charts.helm.sh/stable \
  --helm-chart nginx-ingress \
  --helm-set global.key1=val1
  --revision 1.24.3 \
  --release-name nginx-ingress \
  --dest-namespace default \
  --dest-server https://kubernetes.default.svc
  --values values-production.yaml


# sync or deploy application
argocd app sync <applications_name>


# set helm value
argocd app set helm-guestbook -p service.type=LoadBalancer
```

## Argo Events

## Argo Rollouts

> Reference:
>
> 1. [Official Website](https://argoproj.github.io/)
> 2. [Argo Workflows](https://argoproj.github.io/workflows/)
> 3. [Argo CD](https://github.com/argoproj/argo-cd/)
> 4. [Argo Events](https://github.com/argoproj/argo-events/)
> 5. [Argo Rollouts](https://github.com/argoproj/argo-rollouts/)
