---
description: AI Gateway | AI Native API Gateway
tags:
  - cncf/orchestration
  - api-gateway
---

# Higress

## Introduction

Higress is an AI-native API gateway built on Envoy and Istio, originally developed by Alibaba and now a CNCF project. It unifies traffic gateway, microservice gateway, and security gateway into a single architecture, with first-class support for AI/LLM routing and management. Higress is fully compatible with Kubernetes Ingress and Gateway API standards.

## Key Features

- **AI Gateway**: Built-in support for LLM proxy, token rate limiting, prompt caching, and multi-model load balancing
- **Kubernetes Native**: Full compatibility with Ingress, Gateway API, and Istio resources
- **Wasm Plugin System**: Extend gateway functionality using WebAssembly plugins (Go, Rust, JS)
- **Hot Reload**: Configuration changes take effect without connection drops
- **Service Discovery**: Integrates with Nacos, Consul, Eureka, and Kubernetes service discovery
- **Rich Protocol Support**: HTTP, gRPC, WebSocket, and Dubbo protocol proxying

## Installation

### Helm Installation

```bash
helm repo add higress https://higress.io/helm-charts
helm repo update

# Install in standalone mode (without Istio dependency)
helm install higress higress/higress \
  -n higress-system --create-namespace

# Install with Istio integration
helm install higress higress/higress \
  -n higress-system --create-namespace \
  --set global.istioEnabled=true
```

## Configuration

### Basic Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    higress.io/destination: my-service.default.svc.cluster.local:8080
spec:
  ingressClassName: higress
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-service
                port:
                  number: 8080
```

### AI Route Configuration

Route requests to different LLM providers with fallback:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ai-route
  annotations:
    higress.io/destination: openai-api.dns
    higress.io/ai-route: "true"
spec:
  ingressClassName: higress
  rules:
    - host: ai.example.com
      http:
        paths:
          - path: /v1/chat
            pathType: Prefix
            backend:
              resource:
                apiGroup: networking.higress.io
                kind: McpBridge
                name: default
```

### Wasm Plugin Example

Apply a Wasm plugin to an Ingress route:

```yaml
apiVersion: extensions.higress.io/v1alpha1
kind: WasmPlugin
metadata:
  name: request-block
  namespace: higress-system
spec:
  defaultConfig:
    block_urls:
      - /admin
      - /internal
  url: oci://higress-registry.cn-hangzhou.cr.aliyuncs.com/plugins/request-block:1.0.0
```

> Reference:
>
> 1. [Official Website](https://higress.io/)
> 2. [Repository](https://github.com/alibaba/higress)
