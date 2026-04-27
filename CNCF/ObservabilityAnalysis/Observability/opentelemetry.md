---
description: OpenTelemetry is a vendor-neutral observability framework for generating, collecting, and exporting traces, metrics, and logs.
tags:
  - cncf/observability
  - tracing
  - monitoring
  - logging
---

# OpenTelemetry

## Introduction

### What is OpenTelemetry?

OpenTelemetry (OTel) is a CNCF graduated project that provides a unified, vendor-neutral set of APIs, SDKs, and tools for instrumenting, generating, collecting, and exporting telemetry data — traces, metrics, and logs. It is the second-most-active CNCF project after Kubernetes and is the de-facto standard for application observability.

OpenTelemetry decouples instrumentation from the backend: applications produce telemetry once, in a standard format (OTLP), and you can route it to any backend such as Jaeger, Prometheus, Loki, Tempo, Elastic, Datadog, or commercial vendors without changing the instrumentation.

### Signals

A "signal" is a category of telemetry data. OpenTelemetry currently defines:

| Signal   | Description                                                              | Status   |
| -------- | ------------------------------------------------------------------------ | -------- |
| Traces   | Distributed request flows across services, modeled as spans              | Stable   |
| Metrics  | Numerical measurements (counter, gauge, histogram, exponential histogram)| Stable   |
| Logs     | Timestamped, structured records — often correlated with traces via IDs   | Stable   |
| Baggage  | Contextual key/value pairs propagated alongside requests                 | Stable   |
| Profiles | Code-level resource usage (CPU, memory)                                  | Development |

#### Trace data model

A trace is a tree of spans sharing the same `trace_id`. Each span has a `span_id`, an optional `parent_id`, attributes, events, links, and status.

```json
{
  "name": "GET /api/users",
  "context": {
    "trace_id": "5b8aa5a2d2c872e8321cf37308d69df2",
    "span_id": "051581bf3cb55c13"
  },
  "parent_id": null,
  "start_time": "2026-04-01T18:52:58.114201Z",
  "end_time":   "2026-04-01T18:52:58.114687Z",
  "attributes": {
    "http.request.method": "GET",
    "http.route": "/api/users",
    "http.response.status_code": 200
  },
  "events": [
    { "name": "cache.miss", "timestamp": "2026-04-01T18:52:58.114561Z" }
  ],
  "status": { "code": "OK" }
}
```

#### Metric instruments

| Instrument             | Synchronous | Use case                                          |
| ---------------------- | ----------- | ------------------------------------------------- |
| Counter                | yes         | Monotonically increasing (requests, bytes, errors)|
| UpDownCounter          | yes         | Increases and decreases (queue length, in-flight) |
| Histogram              | yes         | Distribution (request latency, payload size)      |
| Gauge / ObservableGauge| no          | Last value (CPU usage, memory, temperature)       |
| ObservableCounter      | no          | Pulled at collection time (process_cpu_seconds)   |

### Components

- **API** — Stable, lightweight contract used by application/library code to emit telemetry.
- **SDK** — Reference implementation of the API; configures sampling, processors, and exporters.
- **Instrumentation libraries** — Auto/manual instrumentation for HTTP frameworks, database drivers, gRPC, messaging, etc.
- **OpenTelemetry Collector** — Vendor-agnostic agent / gateway that receives, processes, and exports telemetry.
- **OpenTelemetry Operator** — Kubernetes operator for managing Collectors and auto-instrumentation injection.
- **OTLP (OpenTelemetry Protocol)** — gRPC and HTTP/JSON wire protocol for transporting telemetry between SDK, Collector, and backends.

### Instrumentation

OpenTelemetry supports two complementary instrumentation styles:

- **Zero-code (auto-instrumentation)** — Attach an agent or SDK that intercepts standard libraries automatically. Available for Java (Java agent), .NET, Python, Node.js, Go (eBPF). Fastest way to start; best for "edge" telemetry.
- **Code-based (manual)** — Use the OpenTelemetry API to create custom spans, metrics, and attributes. Required for business-logic visibility.

Both can be used together. Auto-instrumentation provides framework spans; manual instrumentation enriches them with domain context.

### Collector Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                  OpenTelemetry Collector                         │
│                                                                  │
│  Receivers ──▶ Processors ──▶ Exporters                          │
│  (OTLP,        (batch,         (OTLP, Prometheus,                │
│   Prometheus,   memory_limiter, Jaeger, Loki, Kafka,             │
│   Jaeger,       attributes,     ClickHouse, vendor SaaS, ...)    │
│   Filelog,      transform,                                       │
│   Kafka,        tail_sampling,                                   │
│   Hostmetrics,  filter,                                          │
│   Kubeletstats, k8sattributes, ...)                              │
│   Zipkin, ...)                                                   │
│                                                                  │
│              Connectors (route between pipelines)                │
│              Extensions (health_check, pprof, zpages, ...)       │
└─────────────────────────────────────────────────────────────────┘
```

- **Receivers** — Pull or accept data (OTLP, Prometheus scrape, Jaeger, Zipkin, Kafka, syslog, hostmetrics, k8s_cluster).
- **Processors** — Filter, batch, transform, sample, redact PII, enrich with k8s metadata.
- **Exporters** — Send data downstream over OTLP or backend-specific protocols.
- **Connectors** — Bridge pipelines (e.g., generate metrics from spans via `spanmetrics`).
- **Extensions** — Side capabilities such as health checks, pprof, and zpages.

### Deployment Patterns

| Pattern             | Description                                                              |
| ------------------- | ------------------------------------------------------------------------ |
| No collector        | SDK exports directly to the backend. Simplest, but couples app to vendor.|
| Agent (sidecar/host)| One Collector per host or pod, close to the app. Offloads buffering/retries.|
| Gateway             | Cluster of standalone Collectors that receive from agents and export to backends. Centralizes config, sampling, and tenancy. |
| Agent + Gateway     | Recommended for production: agent batches/enriches locally, gateway aggregates. |

## Deploy By Binary

### Quick Start

```bash
# Download the contrib distribution (includes most receivers/exporters)
OTELCOL_VERSION=0.115.0
wget https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTELCOL_VERSION}/otelcol-contrib_${OTELCOL_VERSION}_linux_amd64.tar.gz
mkdir -p /opt/otelcol && tar -xzf otelcol-contrib_${OTELCOL_VERSION}_linux_amd64.tar.gz -C /opt/otelcol
cd /opt/otelcol

# Validate config
./otelcol-contrib validate --config=/opt/otelcol/config.yaml

# Run
./otelcol-contrib --config=/opt/otelcol/config.yaml
```

### Config and Boot

#### Config

**/opt/otelcol/config.yaml**

```yaml
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
          scrape_interval: 15s
          static_configs:
            - targets: ['0.0.0.0:8888']
  hostmetrics:
    collection_interval: 30s
    scrapers:
      cpu: {}
      memory: {}
      disk: {}
      filesystem: {}
      load: {}
      network: {}
  filelog:
    include: [/var/log/*.log]
    start_at: end

processors:
  memory_limiter:
    check_interval: 1s
    limit_percentage: 75
    spike_limit_percentage: 25
  batch:
    timeout: 10s
    send_batch_size: 1024
    send_batch_max_size: 2048
  resource:
    attributes:
      - key: deployment.environment
        value: production
        action: upsert
  attributes/redact:
    actions:
      - key: http.request.header.authorization
        action: delete
  tail_sampling:
    decision_wait: 10s
    policies:
      - name: errors
        type: status_code
        status_code: { status_codes: [ERROR] }
      - name: slow
        type: latency
        latency: { threshold_ms: 500 }
      - name: probabilistic
        type: probabilistic
        probabilistic: { sampling_percentage: 10 }

exporters:
  otlp/jaeger:
    endpoint: jaeger:4317
    tls: { insecure: true }
  prometheusremotewrite:
    endpoint: http://victoriametrics:8428/api/v1/write
    resource_to_telemetry_conversion: { enabled: true }
  otlphttp/loki:
    endpoint: http://loki:3100/otlp
  debug:
    verbosity: basic

extensions:
  health_check:
    endpoint: 0.0.0.0:13133
  pprof:
    endpoint: 0.0.0.0:1777
  zpages:
    endpoint: 0.0.0.0:55679

service:
  extensions: [health_check, pprof, zpages]
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, resource, attributes/redact, tail_sampling, batch]
      exporters: [otlp/jaeger]
    metrics:
      receivers: [otlp, prometheus, hostmetrics]
      processors: [memory_limiter, resource, batch]
      exporters: [prometheusremotewrite]
    logs:
      receivers: [otlp, filelog]
      processors: [memory_limiter, resource, batch]
      exporters: [otlphttp/loki]
  telemetry:
    metrics:
      address: 0.0.0.0:8888
    logs:
      level: info
```

#### Boot(systemd)

```bash
cat > /etc/systemd/system/otelcol.service << "EOF"
[Unit]
Description=OpenTelemetry Collector
Documentation=https://opentelemetry.io/docs/collector/
After=network-online.target

[Service]
User=otelcol
Group=otelcol
Restart=on-failure
RestartSec=5s
ExecStart=/opt/otelcol/otelcol-contrib --config=/opt/otelcol/config.yaml

[Install]
WantedBy=multi-user.target
EOF

useradd -r -s /bin/false otelcol
chown -R otelcol:otelcol /opt/otelcol
systemctl daemon-reload
systemctl enable --now otelcol.service
```

## Deploy By Container

### Run On Docker

```bash
docker run -d --name otel-collector \
  -p 4317:4317 \
  -p 4318:4318 \
  -p 8888:8888 \
  -p 8889:8889 \
  -p 13133:13133 \
  -v $(pwd)/config.yaml:/etc/otelcol-contrib/config.yaml \
  otel/opentelemetry-collector-contrib:0.115.0
```

### Run On Kubernetes

#### Install the OpenTelemetry Operator

```bash
# cert-manager is a prerequisite for the operator's webhooks
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.3/cert-manager.yaml

# Install the OpenTelemetry Operator
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.115.0/opentelemetry-operator.yaml
```

#### Deploy a Collector via the OpenTelemetryCollector CR

```yaml
# otel-collector.yaml
apiVersion: opentelemetry.io/v1beta1
kind: OpenTelemetryCollector
metadata:
  name: otel
  namespace: observability
spec:
  mode: deployment       # deployment | daemonset | sidecar | statefulset
  image: otel/opentelemetry-collector-contrib:0.115.0
  replicas: 2
  resources:
    requests:
      cpu: 200m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 2Gi
  config:
    receivers:
      otlp:
        protocols:
          grpc: { endpoint: 0.0.0.0:4317 }
          http: { endpoint: 0.0.0.0:4318 }
    processors:
      memory_limiter:
        check_interval: 1s
        limit_percentage: 75
      k8sattributes:
        auth_type: serviceAccount
        passthrough: false
        extract:
          metadata:
            - k8s.namespace.name
            - k8s.pod.name
            - k8s.node.name
            - k8s.deployment.name
      batch:
        send_batch_size: 1024
        timeout: 10s
    exporters:
      otlp/tempo:
        endpoint: tempo-distributor.observability:4317
        tls: { insecure: true }
      prometheusremotewrite:
        endpoint: http://vminsert.observability:8480/insert/0/prometheus
    service:
      pipelines:
        traces:
          receivers:  [otlp]
          processors: [memory_limiter, k8sattributes, batch]
          exporters:  [otlp/tempo]
        metrics:
          receivers:  [otlp]
          processors: [memory_limiter, k8sattributes, batch]
          exporters:  [prometheusremotewrite]
```

```bash
kubectl apply -f otel-collector.yaml
```

#### Auto-instrumentation injection

The Operator can inject language-specific SDKs into pods via an `Instrumentation` CR plus a pod annotation:

```yaml
apiVersion: opentelemetry.io/v1alpha1
kind: Instrumentation
metadata:
  name: app-instrumentation
  namespace: observability
spec:
  exporter:
    endpoint: http://otel-collector.observability:4318
  propagators: [tracecontext, baggage, b3]
  sampler:
    type: parentbased_traceidratio
    argument: "0.25"
  java:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-java:latest
  python:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-python:latest
  nodejs:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-nodejs:latest
  go:
    image: ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-go:latest
```

Add this annotation to the workload spec to inject the SDK:

```yaml
metadata:
  annotations:
    instrumentation.opentelemetry.io/inject-java: "observability/app-instrumentation"
```

#### Helm chart alternative

```bash
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

# Collector chart (agent + gateway)
helm upgrade --install otel-agent open-telemetry/opentelemetry-collector \
  --namespace observability --create-namespace \
  --set mode=daemonset

helm upgrade --install otel-gateway open-telemetry/opentelemetry-collector \
  --namespace observability \
  --set mode=deployment --set replicaCount=3

# kube-stack: Operator + collectors + instrumentation in one chart
helm upgrade --install otel-stack open-telemetry/opentelemetry-kube-stack \
  --namespace observability
```

## Application Instrumentation

### SDK environment variables

The SDK is configured almost entirely via environment variables, so the same image can talk to different backends per environment:

```bash
export OTEL_SERVICE_NAME=checkout-api
export OTEL_RESOURCE_ATTRIBUTES=service.namespace=shop,service.version=1.4.2,deployment.environment=prod
export OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector.observability:4318
export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
export OTEL_TRACES_SAMPLER=parentbased_traceidratio
export OTEL_TRACES_SAMPLER_ARG=0.25
export OTEL_PROPAGATORS=tracecontext,baggage,b3
```

### Code-based example (Go)

```go
package main

import (
    "context"

    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/attribute"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
    "go.opentelemetry.io/otel/sdk/resource"
    sdktrace "go.opentelemetry.io/otel/sdk/trace"
    semconv "go.opentelemetry.io/otel/semconv/v1.26.0"
)

func initTracer(ctx context.Context) (*sdktrace.TracerProvider, error) {
    exp, err := otlptracegrpc.New(ctx)
    if err != nil {
        return nil, err
    }
    res, _ := resource.Merge(resource.Default(), resource.NewWithAttributes(
        semconv.SchemaURL,
        semconv.ServiceName("checkout-api"),
        semconv.ServiceVersion("1.4.2"),
    ))
    tp := sdktrace.NewTracerProvider(
        sdktrace.WithBatcher(exp),
        sdktrace.WithResource(res),
        sdktrace.WithSampler(sdktrace.ParentBased(sdktrace.TraceIDRatioBased(0.25))),
    )
    otel.SetTracerProvider(tp)
    return tp, nil
}

func placeOrder(ctx context.Context, orderID string) {
    tracer := otel.Tracer("checkout")
    ctx, span := tracer.Start(ctx, "placeOrder")
    defer span.End()
    span.SetAttributes(attribute.String("order.id", orderID))
    // ... business logic
}
```

### Zero-code example (Java agent)

```bash
java -javaagent:/opt/otel/opentelemetry-javaagent.jar \
     -Dotel.service.name=checkout-api \
     -Dotel.exporter.otlp.endpoint=http://otel-collector:4318 \
     -Dotel.exporter.otlp.protocol=http/protobuf \
     -jar /opt/app/checkout-api.jar
```

> Reference:
>
> 1. [Official Website](https://opentelemetry.io/)
> 2. [Documentation](https://opentelemetry.io/docs/)
> 3. [Specification](https://opentelemetry.io/docs/specs/otel/)
> 4. [Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/)
> 5. [Collector Repository](https://github.com/open-telemetry/opentelemetry-collector)
> 6. [Collector Contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib)
> 7. [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-operator)
> 8. [Helm Charts](https://github.com/open-telemetry/opentelemetry-helm-charts)
> 9. [Demo Application](https://github.com/open-telemetry/opentelemetry-demo)
