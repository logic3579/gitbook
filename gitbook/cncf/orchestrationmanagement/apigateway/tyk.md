---
description: Tyk Open Source API Gateway written in Go, supporting REST, GraphQL, TCP and gRPC protocols
tags:
  - cncf/orchestration
  - api-gateway
---

# Tyk

## Introduction

Tyk is an open-source API gateway written in Go that provides full lifecycle API management. It supports REST, GraphQL, TCP, and gRPC protocols with features including rate limiting, authentication, analytics, and developer portal capabilities. Tyk can be deployed as a standalone open-source gateway or as part of the Tyk Dashboard platform for enterprise use.

## Key Features

- **Multi-Protocol**: REST, GraphQL (including federation), gRPC, TCP, and WebSocket support
- **Authentication**: API keys, JWT, OAuth 2.0, mTLS, OpenID Connect, HMAC
- **Rate Limiting**: Global and per-key rate limiting with quota management
- **Analytics**: Request logging and real-time analytics
- **Versioning**: API versioning with deprecation management
- **Middleware Chain**: Request/response transformation, header injection, body transformation
- **GraphQL**: Native GraphQL proxy with schema stitching and federation

## Installation

### Docker Deployment

```bash
docker run -d --name tyk-gateway \
  -p 8080:8080 \
  -v $(pwd)/tyk.conf:/opt/tyk-gateway/tyk.conf \
  -v $(pwd)/apps:/opt/tyk-gateway/apps \
  tykio/tyk-gateway:latest
```

### Helm Installation on Kubernetes

```bash
helm repo add tyk-helm https://helm.tyk.io/public/helm/charts/
helm repo update

helm install tyk-oss tyk-helm/tyk-oss \
  -n tyk --create-namespace \
  --set global.redis.addrs="{redis.tyk.svc:6379}"
```

## Configuration

### Gateway Configuration (`tyk.conf`)

```json
{
  "listen_port": 8080,
  "secret": "change-me",
  "template_path": "/opt/tyk-gateway/templates",
  "use_db_app_configs": false,
  "app_path": "/opt/tyk-gateway/apps",
  "storage": {
    "type": "redis",
    "host": "redis",
    "port": 6379,
    "optimisation_max_idle": 2000,
    "optimisation_max_active": 4000
  },
  "enable_analytics": false,
  "analytics_config": {
    "type": ""
  }
}
```

### API Definition

API definitions are stored as JSON files in the `apps/` directory:

```json
{
  "name": "My API",
  "slug": "my-api",
  "api_id": "1",
  "org_id": "default",
  "use_keyless": true,
  "definition": {
    "location": "header",
    "key": "x-api-version"
  },
  "version_data": {
    "not_versioned": true,
    "versions": {
      "Default": {
        "name": "Default",
        "use_extended_paths": true
      }
    }
  },
  "proxy": {
    "listen_path": "/my-api/",
    "target_url": "http://backend-service:3000/",
    "strip_listen_path": true
  },
  "active": true
}
```

### Rate Limiting

Configure rate limiting in the API definition:

```json
{
  "global_rate_limit": {
    "rate": 100,
    "per": 60
  },
  "disable_rate_limit": false
}
```

> Reference:
>
> 1. [Official Website](https://tyk.io/)
> 2. [Repository](https://github.com/TykTechnologies/tyk)
