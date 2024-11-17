---
description: GitLab
---

# GitLab

## Introduction
...


## Deploy With Binary
### Quick Start
```bash
# Run On SourceCode
https://docs.gitlab.com/ee/install/installation.html#overview


### Run On Ubuntu
# Install and configure the necessary dependencies
apt update
apt install -y curl openssh-server ca-certificates tzdata perl

# Add the Gitlab package repository and install package
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | bash
GITLAB_ROOT_PASSWORD="passwOrd123" EXTERNAL_URL="http://gitlab.yakir.com" apt install gitlab-ee

# Browse to the hostname and login
cat /etc/gitlab/initial_root_password
```

## Deploy With Container
### Run in Docker
```bash
# run container
GITLAB_HOME=/opt/gitlab
docker run --detach \
  --hostname gitlab.example.com \
  --publish 443:443 --publish 80:80 --publish 22:22 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/config:/etc/gitlab \
  --volume $GITLAB_HOME/logs:/var/log/gitlab \
  --volume $GITLAB_HOME/data:/var/opt/gitlab \
  --shm-size 256m \
  gitlab/gitlab-ce:latest

# gitlab password
docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password

# offcial image
gitlab/gitlab-ce
gitlab/gitlab-ee

# docker-compose 
[install by docker-compose](https://docs.gitlab.com/ee/install/docker.html#install-gitlab-using-docker-compose)
```

### Run in Kubernetes
[[cc-k8s|deploy by kubernetes manifest]]
```bash
# manifest resource yaml
deployments = redis, postgresql, gitlab
service = redis, postgresql, gitlab
ingress = gitlab
```

[[cc-helm|deploy by helm]]
```bash
# Add and update repo
helm repo add gitlab https://charts.gitlab.io/
helm repo update

# Get charts package
helm pull gitlab/gitlab --untar  
cd gitlab

# Configure and run
vim values.yaml
...

helm -n cicd install gitlab . --create-namespace \
  --timeout 600s \
  --set global.hosts.domain=yakir.com \
  --set global.hosts.externalIP=1.1.1.1 \
  --set certmanager-issuer.email=yakir@gmail.com \
  --set certmanager.installCRDs=false \
  --set certmanager.install=false \
  --set nginx-ingress.enabled=false \
  --set prometheus.install=false 

# Install the Community Edition
--set global.edition=ce
```

[deploy by gitlab-operator](https://docs.gitlab.com/operator/)

access and use
```bash
# patch harbor ingress resource
kubectl -n cicd patch ingress gitlab-webservice-default --patch '{"spec":{"ingressClassName": "nginx"}}'

# get password
kubectl -n cicd get secrets gitlab-gitlab-initial-root-password -ogo-template='{{.data.password|base64decode}}'

# access by https
https://harbor-core.yakir.com
admin
Harbor12345
```



> Reference:
> 1. [Official Website](https://docs.gitlab.com/)
> 2. [Repository](https://github.com/gitlabhq/gitlabhq)
