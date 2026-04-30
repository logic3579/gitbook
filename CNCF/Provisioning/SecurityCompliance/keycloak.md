---
description: Keycloak is an open-source identity and access management solution for modern applications and services.
tags:
  - cncf/provisioning
  - security
---

# Keycloak

## Introduction

Keycloak is an open-source Identity and Access Management (IAM) solution developed by Red Hat. It provides single sign-on (SSO), identity brokering, and user federation capabilities out of the box, with support for standard protocols including OpenID Connect, OAuth 2.0, and SAML 2.0.

### Key Features

- **Single Sign-On (SSO)** — Users authenticate once and gain access to all connected applications.
- **Identity Brokering** — Integrate with external identity providers (Google, GitHub, LDAP, Active Directory, SAML IdPs).
- **User Federation** — Connect existing user stores (LDAP, Active Directory) without migrating users.
- **Fine-Grained Authorization** — Role-based (RBAC) and attribute-based access control policies.
- **Admin Console** — Web UI for managing realms, users, roles, clients, and identity providers.
- **Account Console** — Self-service UI for users to manage their profiles, sessions, and 2FA.

### Core Concepts

| Concept  | Description                                                          |
| -------- | -------------------------------------------------------------------- |
| Realm    | A security namespace that manages a set of users, credentials, roles, and clients |
| Client   | An application or service that requests authentication               |
| Role     | A type of authorization (realm-level or client-level)                |
| User     | An entity that can authenticate and be granted roles                 |
| Group    | A collection of users to which roles can be assigned                 |
| Identity Provider | External authentication source (social login, SAML IdP, etc.) |

## How to Install

### Starting via Docker

```bash
# Development mode (in-memory storage, no TLS)
docker run -d --name keycloak \
  -p 8080:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
  quay.io/keycloak/keycloak:26.1 start-dev

# Production mode with external database
docker run -d --name keycloak \
  -p 8443:8443 \
  -e KC_DB=postgres \
  -e KC_DB_URL=jdbc:postgresql://postgres:5432/keycloak \
  -e KC_DB_USERNAME=keycloak \
  -e KC_DB_PASSWORD=keycloak \
  -e KC_HOSTNAME=auth.example.com \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
  quay.io/keycloak/keycloak:26.1 start
```

### Starting via Kubernetes

```bash
# Install Keycloak Operator
kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/refs/heads/main/kubernetes/keycloaks.k8s.keycloak.org-v1.yml
kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/refs/heads/main/kubernetes/keycloakrealmimports.k8s.keycloak.org-v1.yml
kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/refs/heads/main/kubernetes/kubernetes.yml
```

```yaml
# keycloak-cr.yaml
apiVersion: k8s.keycloak.org/v2alpha1
kind: Keycloak
metadata:
  name: keycloak
spec:
  instances: 2
  db:
    vendor: postgres
    host: postgres-db
    usernameSecret:
      name: keycloak-db-secret
      key: username
    passwordSecret:
      name: keycloak-db-secret
      key: password
  hostname:
    hostname: auth.example.com
  http:
    tlsSecret: keycloak-tls-secret
```

```bash
kubectl apply -f keycloak-cr.yaml
```

> Reference:
>
> 1. [Official Website](https://www.keycloak.org/)
> 2. [Repository](https://github.com/keycloak/keycloak)
> 3. [Keycloak Guides](https://www.keycloak.org/guides)
