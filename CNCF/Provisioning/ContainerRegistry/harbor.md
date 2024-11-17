---
description: Harbor
---

# Harbor

## Introduction
...


## Deploy With Container
### Run in Docker
```bash
# download offline or online installer and verify
# configure HTTPS Access to Harbor
https://github.com/goharbor/harbor/releases
https://goharbor.io/docs/2.8.0/install-config/download-installer/


```

### Run in Kubernetes
```bash
# add and update repo
helm repo add harbor https://helm.goharbor.io
helm update

# get charts package
helm pull harbor/harbor --untar
cd harbor

# configure and run
vim values.yaml
expose:
  ingress:
    hosts:
      core: harbor-core.yakir.com
      notary: harbor-notary.yakir.com
externalURL: https://harbor.yakir.com

helm -n provisioning install harbor . --create-namespace

# access and use
# patch harbor ingress resource
kubectl -n provisioning patch ingress harbor-ingress --patch '{"spec":{"ingressClassName": "nginx"}}'

# get password
kubectl -n provisioning get secrets harbor-core -ogo-template='{{.data.HARBOR_ADMIN_PASSWORD|base64decode}}'

# access by https
https://harbor-core.yakir.com
admin
Harbor12345
```




> Reference:
> 1. [Official Website](https://goharbor.io/docs/2.8.0/install-config/)
> 2. [Repository](https://github.com/goharbor/harbor)
