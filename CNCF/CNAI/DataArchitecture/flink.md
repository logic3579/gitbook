---
description: Apache Flink is a distributed stream and batch processing framework for stateful computations over data streams.
tags:
  - cncf/cnai
  - messaging
---

# Flink

## Introduction

Apache Flink is an open-source, unified stream and batch processing framework. It provides high-throughput, low-latency streaming data processing with exactly-once state consistency guarantees.

### Key Features

- **Unified Stream & Batch** — Treats batch processing as a special case of stream processing.
- **Exactly-Once Semantics** — Ensures consistent state through lightweight distributed snapshots (Chandy-Lamport algorithm).
- **Event Time Processing** — Supports event-time windowing and watermarks for out-of-order event handling.
- **Stateful Computation** — Built-in state management with configurable state backends (RocksDB, HashMaps).
- **Fault Tolerance** — Automatic recovery from failures using periodic checkpoints and savepoints.

### Architecture

```text
┌─────────────────────────────────────────────┐
│              Flink Cluster                   │
│  ┌──────────────┐    ┌───────────────────┐  │
│  │  JobManager   │    │   TaskManagers    │  │
│  │  - Scheduler  │───▶│   - Task Slots    │  │
│  │  - Checkpoint │    │   - State Backend │  │
│  │    Coordinator│    │   - Network Stack │  │
│  └──────────────┘    └───────────────────┘  │
└─────────────────────────────────────────────┘
```

- **JobManager** — Coordinates distributed execution: scheduling tasks, triggering checkpoints, and handling failover.
- **TaskManager** — Worker processes that execute tasks and manage local state.

## Deploy By Binary

### Run On Systemd

```bash
# Download and extract
wget https://dlcdn.apache.org/flink/flink-1.20.1/flink-1.20.1-bin-scala_2.12.tgz
tar -xzf flink-1.20.1-bin-scala_2.12.tgz
cd flink-1.20.1

# Configure flink-conf.yaml
cat conf/flink-conf.yaml
# jobmanager.rpc.address: localhost
# jobmanager.rpc.port: 6123
# jobmanager.memory.process.size: 1600m
# taskmanager.memory.process.size: 1728m
# taskmanager.numberOfTaskSlots: 2
# parallelism.default: 1

# Start cluster
./bin/start-cluster.sh

# Web UI available at http://localhost:8081

# Submit a job
./bin/flink run examples/streaming/WordCount.jar

# Stop cluster
./bin/stop-cluster.sh
```

Create a systemd service:

```ini
# /etc/systemd/system/flink-jobmanager.service
[Unit]
Description=Apache Flink JobManager
After=network.target

[Service]
Type=forking
User=flink
Group=flink
Environment=JAVA_HOME=/usr/lib/jvm/java-11
ExecStart=/opt/flink/bin/jobmanager.sh start
ExecStop=/opt/flink/bin/jobmanager.sh stop
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## Deploy By Container

### Run On Kubernetes

Deploy using the Flink Kubernetes Operator:

```bash
# Install the Flink Kubernetes Operator via Helm
helm repo add flink-operator-repo https://downloads.apache.org/flink/flink-kubernetes-operator-1.10.0/
helm install flink-kubernetes-operator flink-operator-repo/flink-kubernetes-operator
```

```yaml
# flink-session-cluster.yaml
apiVersion: flink.apache.org/v1beta1
kind: FlinkDeployment
metadata:
  name: flink-session
spec:
  image: flink:1.20.1
  flinkVersion: v1_20
  flinkConfiguration:
    taskmanager.numberOfTaskSlots: "2"
  serviceAccount: flink
  jobManager:
    resource:
      memory: "2048m"
      cpu: 1
  taskManager:
    resource:
      memory: "2048m"
      cpu: 1
    replicas: 2
```

```bash
kubectl apply -f flink-session-cluster.yaml
```

> Reference:
>
> 1. [Official Website](https://flink.apache.org/)
> 2. [Repository](https://github.com/apache/flink)
> 3. [Flink Kubernetes Operator](https://nightlies.apache.org/flink/flink-kubernetes-operator-docs-stable/)
