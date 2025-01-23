---
description: Jenkins
---

# Jenkins

## Introduction
...


## Deploy With Binary
### Quick Start
```bash
# download and decompression
# https://www.jenkins.io/download/
wget https://get.jenkins.io/war-stable/2.401.1/jenkins.war

# run and init password
mkdir /opt/jenkins-config
JENKINS_HOME=/opt/jenkins-config java -jar jenkins.war
cat /opt/jenkins-config/secrets/initialAdminPassword


# Run On Ubuntu
# https://www.jenkins.io/doc/book/installing/linux/#debianubuntu
```

## Deploy With Container
### Run in Docker
[[cc-docker|Docker常用命令]]
```bash
# create bridge network
docker network create jenkins

# run 
docker run -d -v jenkins_home:/var/jenkins_home -p 8080:8080 -p 50000:50000 --restart=on-failure jenkins/jenkins:lts-jdk11 --name jenkins
# persistence storage info and init password
docker inspect jenkins_home
...
cat /var/lib/docker/volumes/jenkins_home/_data/secrets/initialAdminPassword 
```

### Run in Kubernetes
[[cc-k8s|deploy by kubernetes manifest]]
```bash
# manifest resource yaml
namespace
serviceAccout
persistence volume
Deployment
Service

# more detail
https://www.jenkins.io/doc/book/installing/kubernetes/
```

[[cc-helm|deploy by helm]]
```bash
# Add and update repo
helm repo add jenkinsci https://charts.jenkins.io
helm repo update

# Get charts package
helm pull jenkinsci/jenkins --untar  
cd jenkins

# Configure and run
vim values.yaml
  ingress:
    enabled: true

helm -n cicd install jenkins . --create-namespace

```

[deploy by jenkins-operator](https://jenkinsci.github.io/kubernetes-operator/docs/getting-started/latest/)

access and use
```bash
# patch harbor ingress resource
kubectl -n cicd patch ingress jenkins --patch '{"spec":{"ingressClassName": "nginx"}}'

# get password
kubectl -n cicd get secrets jenkins -ojsonpath='{.data.jenkins-admin-password}' |base64 -d 

# access by https
https://jenkins.yakir.top
admin
mxP4KKfGtn6hJ8IF2zMMLt
```



> Reference:
> 1. [Official Website](https://www.jenkins.io/doc/book/installing/)
> 2. [Repository](https://github.com/jenkinsci/jenkins)
