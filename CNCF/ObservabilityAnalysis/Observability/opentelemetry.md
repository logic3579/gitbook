---
description: OpenTelemetry is a vendor-neutral observability framework for collecting traces, metrics, and logs from applications.
tags:
  - cncf/observability
  - tracing
---

# OpenTelemetry

## Introduction

OpenTelemetry (OTel) is a CNCF project that provides a unified set of APIs, SDKs, and tools for generating, collecting, and exporting telemetry data (traces, metrics, and logs). It is vendor-neutral and supports multiple backends.

### Key Components

- **API & SDK** — Language-specific libraries for instrumenting application code (Go, Java, Python, .NET, JS, etc.).
- **Collector** — A vendor-agnostic proxy that receives, processes, and exports telemetry data.
- **OTLP (OpenTelemetry Protocol)** — The standard protocol for transmitting telemetry data between components.

### Signals

| Signal   | Description                                                   |
| -------- | ------------------------------------------------------------- |
| Traces   | Distributed request flows across services (spans and contexts)|
| Metrics  | Numerical measurements (counters, gauges, histograms)         |
| Logs     | Timestamped text records with structured metadata             |

### Collector Architecture

```text
┌──────────────────────────────────────────────────┐
│              OTel Collector                       │
│                                                  │
│  Receivers ──▶ Processors ──▶ Exporters          │
│  (OTLP,        (batch,        (Jaeger,           │
│   Prometheus,   filter,        Prometheus,        │
│   Kafka...)     transform...)  Loki, OTLP...)    │
└──────────────────────────────────────────────────┘
```

- **Receivers** — Accept data from various sources (OTLP, Prometheus, Jaeger, Zipkin, etc.).
- **Processors** — Transform, filter, batch, or enrich telemetry data in the pipeline.
- **Exporters** — Send processed data to one or more backends.

## Configuration

Collector configuration example:

```yaml
# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  prometheus:
    config:
      scrape_configs:
        - job_name: 'otel-collector'
          scrape_interval: 10s
          static_configs:
            - targets: ['0.0.0.0:8888']

processors:
  batch:
    timeout: 5s
    send_batch_size: 1024
  memory_limiter:
    check_interval: 1s
    limit_mib: 512

exporters:
  otlp:
    endpoint: "jaeger:4317"
    tls:
      insecure: true
  prometheus:
    endpoint: "0.0.0.0:8889"

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlp]
    metrics:
      receivers: [otlp, prometheus]
      processors: [memory_limiter, batch]
      exporters: [prometheus]
```

## Deploy By Container

### Run On Docker

```bash
docker run -d --name otel-collector \
  -p 4317:4317 \
  -p 4318:4318 \
  -p 8888:8888 \
  -p 8889:8889 \
  -v $(pwd)/otel-collector-config.yaml:/etc/otelcol/config.yaml \
  otel/opentelemetry-collector-contrib:0.115.0
```

### Run On Kubernetes

Deploy using the OpenTelemetry Operator:

```bash
# Install cert-manager (prerequisite)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.3/cert-manager.yaml

# Install the OpenTelemetry Operator
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.115.0/opentelemetry-operator.yaml
```

```yaml
# otel-collector-cr.yaml
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: otel
spec:
  mode: deployment    # deployment, daemonset, sidecar, statefulset
  config:
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
    processors:
      memory_limiter:
        check_interval: 1s
        limit_percentage: 75
      batch:
        send_batch_size: 1024
        timeout: 5s
    exporters:
      otlp:
        endpoint: "jaeger-collector:4317"
        tls:
          insecure: true
    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [memory_limiter, batch]
          exporters: [otlp]
```

```bash
kubectl apply -f otel-collector-cr.yaml
```

> Reference:
>
> 1. [Official Website](https://opentelemetry.io/)
> 2. [Repository](https://github.com/open-telemetry/opentelemetry-collector)
> 3. [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-operator)
