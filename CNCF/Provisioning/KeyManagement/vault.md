---
description: Vault
---

# Vault

## Introduction

...

## Deploy With Binary

### Quick Start

```bash
# download and decompress
mkdir -p /opt/vault/bin /opt/vault/data /opt/vault/tls
cd /opt/vault/bin
wget https://releases.hashicorp.com/vault/1.14.1/vault_1.14.1_linux_amd64.zip
unzip vault_1.14.1_linux_amd64.zip && rm -f vault_1.14.1_linux_amd64.zip

# install cli
export PATH=$PATH:/opt/vault/bin
#echo "export PATH=$PATH:/opt/vault/bin" >> ~/.bashrc
```

### Config and Boot

#### Config

```bash
# start server
# option1: start dev
vault server -dev
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN="xxx.xxx"
# option2: start dev with tls
vault server -dev-tls
export VAULT_ADDR='https://127.0.0.1:8200'
export VAULT_TOKEN="xxx.xxx"
export VAULT_CACERT='/tmp/vault-tls3372431693/vault-ca.pem'
# option3: start with config file
cat > /opt/vault/config.hcl << "EOF"
storage "file" {
  path = "/opt/vault/data"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_disable = "true"
  #tls_cert_file = "/opt/vault/tls/tls.crt"
  #tls_key_file  = "/opt/vault/tls/tls.key"
}

api_addr = "http://127.0.0.1:8200"
cluster_addr = "https://127.0.0.1:8201"
ui = true
EOF
vault server -config=/opt/vault/config.hcl
export VAULT_ADDR='http://127.0.0.1:8200'
vault operator init
vault operator unseal
vault operator unseal
vault operator unseal
export VAULT_TOKEN="xxx.xxx"

# verify
vault status
```

### How To Use

```bash
# kv secret
vault kv put -mount=secret kvpath foo=bar
vault kv list -mount=secret
vault kv get -mount=secret [--field=foo] [-version=1] kvpath
vault kv get -mount=secret -format=json kvpath |jq .data.data
vault kv delete -mount=secret kvpath
vault kv undelete -mount=secret -versions=2 kvpath
vault kv metadata delete -mount=secret kvpath

# secrets engines
vault secrets list
vault secrets enable -path=kv -description='here is description' kv
vault kv put -mount=kv mykvpath password="1q@w#E"
vault kv list -mount=kv
vault kv get -mount=kv [--field=foo] [-version=1] [-format=json] mykvpath
vault kv delete kv/mykvpath
vault secrets disable kv/

# dynamic secrets
vault secrets enable -path=aws aws
...

# Authentication
vault token create
export VAULT_TOKEN="xxx.xxxx"
vault token login
vault token revoke $VAULT_TOKEN
# github organization
vault auth enable github
vault write auth/github/config organization=andyinp-org
vault write auth/github/map/teams/andyinp value=default,applications
vault auth list VAULT_TOKEN="xxx_xxx_xxx"

# Policies
vault policy list
vault policy read default
vault policy write my-policy - << EOF
# Dev servers have version 2 of KV secrets engine mounted by default, so will
# need these paths to grant permissions:
path "secret/data/*" {
  capabilities = ["create", "update"]
}

path "secret/data/foo" {
  capabilities = ["read"]
}
EOF
vault policy read my-policy
export VAULT_TOKEN="$(vault token create -field token -policy=my-policy)"
vault token lookup | grep policies
vault kv put -mount=secret creds password="my-long-password"

```

## Deploy With Container

### Run in Kubernetes

```bash
# add and update repo
helm repo add hashicorp https://helm.releases.hashicorp.com
helm update

# get charts package
helm pull hashicorp/vault --untar
cd vault

# configure and run
vim values.yaml
...
helm -n provisioning install vault .
```

> Reference:
>
> 1. [Official Website](https://developer.hashicorp.com/vault/docs?product_intent=vault)
> 2. [Repository](https://github.com/hashicorp/vault)
