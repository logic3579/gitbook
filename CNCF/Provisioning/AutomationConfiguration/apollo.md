---
description: Apollo is a reliable distributed configuration management center for microservices, providing centralized config management with real-time push.
tags:
  - cncf/provisioning
  - configuration
---

# Apollo

## Introduction

Apollo is an open-source distributed configuration management center developed by Ctrip. It centralizes configuration management for applications across different environments and clusters, with changes taking effect in real time.

### Key Features

- **Centralized Management** — Manage configurations for different applications, environments, and clusters in one place.
- **Real-Time Push** — Configuration changes are pushed to clients in real time (within 1 second by default).
- **Version Management** — Every configuration change is versioned for easy rollback.
- **Gray Release** — Push configuration changes to specific instances before rolling out to all.
- **Access Control** — Namespace-level permission control with approval workflow.
- **Multi-Environment** — Built-in support for DEV, FAT, UAT, and PRO environments.

### Architecture

```text
┌─────────┐    ┌─────────────┐    ┌──────────────┐
│  Portal  │───▶│ Admin Service│───▶│   Database   │
│  (UI)    │    │             │    │  (MySQL)     │
└─────────┘    └─────────────┘    └──────────────┘
                                         │
                                         ▼
┌─────────┐    ┌──────────────┐   ┌──────────────┐
│  Client  │◀──│ Config Service│◀──│ Meta Server  │
│  (SDK)   │   │  (real-time)  │   │ (Eureka)     │
└─────────┘    └──────────────┘   └──────────────┘
```

- **Config Service** — Provides configuration reading and real-time push to clients.
- **Admin Service** — Provides configuration management API consumed by the Portal.
- **Portal** — Web UI for managing configurations.
- **Client SDK** — Embedded in applications to fetch and listen for config changes.

## How to Install

### Starting via Docker

```bash
# Start Apollo with docker-compose (quick start)
git clone https://github.com/apolloconfig/apollo-quick-start.git
cd apollo-quick-start
docker-compose up -d
# Portal available at http://localhost:8070 (apollo/admin)
```

### Starting via Kubernetes

```bash
# Add Helm repository
helm repo add apollo https://charts.apolloconfig.com
helm repo update

# Install Apollo Config Service & Admin Service
helm install apollo-service-dev apollo/apollo-service \
  --set configdb.host=mysql-host \
  --set configdb.dbName=ApolloConfigDB \
  --set configdb.userName=apollo \
  --set configdb.password=apollo \
  --set configService.replicaCount=2 \
  --set adminService.replicaCount=2 \
  -n apollo --create-namespace

# Install Apollo Portal
helm install apollo-portal apollo/apollo-portal \
  --set portaldb.host=mysql-host \
  --set portaldb.dbName=ApolloPortalDB \
  --set portaldb.userName=apollo \
  --set portaldb.password=apollo \
  --set config.envs="dev" \
  --set config.metaServers.dev="http://apollo-service-dev-apollo-configservice:8080" \
  -n apollo
```

## Client SDK

### Java

```xml
<!-- Maven dependency -->
<dependency>
    <groupId>com.ctrip.framework.apollo</groupId>
    <artifactId>apollo-client</artifactId>
    <version>2.4.0</version>
</dependency>
```

```java
// Read configuration
Config config = ConfigService.getAppConfig();
String value = config.getProperty("key", "defaultValue");

// Listen for changes
config.addChangeListener(changeEvent -> {
    for (String key : changeEvent.changedKeys()) {
        ConfigChange change = changeEvent.getChange(key);
        System.out.printf("Key: %s, Old: %s, New: %s%n",
            change.getPropertyName(),
            change.getOldValue(),
            change.getNewValue());
    }
});
```

> Reference:
>
> 1. [Official Website](https://www.apolloconfig.com/#/)
> 2. [Repository](https://github.com/apolloconfig/apollo)
> 3. [Apollo Helm Charts](https://github.com/apolloconfig/apollo-helm-charts)
