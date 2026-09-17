---
description: VictoriaMetrics is a fast, cost-effective, and scalable time-series database, often used as a drop-in long-term store for Prometheus.
tags:
  - cncf/observability
  - monitoring
  - database
---

# VictoriaMetrics

## Introduction

### What is VictoriaMetrics?

VictoriaMetrics is an open-source, high-performance time-series database (TSDB) and monitoring solution. It is wire-compatible with Prometheus and is commonly deployed as a drop-in replacement or as long-term remote-write storage for Prometheus, Thanos, Cortex, M3DB, and InfluxDB. The project is licensed under Apache 2.0 with an additional commercial Enterprise edition.

It targets workloads with millions of active time series and high churn rate (Kubernetes, APM) while running on a single binary with no external dependencies. VictoriaMetrics implements an extended PromQL dialect called **MetricsQL**.

### Prominent Features

- Single, dependency-free Go binary; all configuration via command-line flags.
- Drop-in replacement for the Prometheus query API in Grafana.
- High data compression — typically 7× less storage than Prometheus/Thanos/Cortex; up to 70× compared with TimescaleDB.
- Up to 7× less RAM than Prometheus/Thanos/Cortex on high-cardinality workloads, and up to 10× less than InfluxDB.
- Optimized for high-latency / low-IOPS storage (HDD, NFS, S3-backed block storage).
- Supports many ingestion protocols: Prometheus remote-write, Prometheus exposition format, InfluxDB line protocol, Graphite plaintext, OpenTSDB, JSON line, CSV, native binary, DataDog, NewRelic, OpenTelemetry, Zabbix.
- Built-in stream aggregation (statsd alternative) and metrics relabeling.
- Cardinality / churn-rate explorer and limiter.
- Instant snapshot backups with `vmbackup` / `vmrestore`.
- Open-source [cluster version](https://github.com/VictoriaMetrics/VictoriaMetrics/tree/cluster) for horizontal scaling and multitenancy.

### Components

VictoriaMetrics ships as a family of small Go binaries:

| Component        | Purpose                                                                                       |
| ---------------- | --------------------------------------------------------------------------------------------- |
| `victoria-metrics` | Single-node TSDB; ingest + storage + query in one process. HTTP API on `:8428`.             |
| `vmagent`        | Lightweight scraping & remote-write agent. Replaces Prometheus for collection.                |
| `vmalert`        | Evaluates Prometheus-compatible alerting and recording rules; sends alerts to Alertmanager.   |
| `vmalert-tool`   | Lints / validates alerting and recording rules.                                               |
| `vmauth`         | Auth proxy and load balancer with per-user routing.                                           |
| `vmgateway`      | Auth proxy with per-tenant rate limiting (Enterprise).                                        |
| `vmctl`          | Migrate data between TSDBs (Prometheus, InfluxDB, OpenTSDB, Thanos, Mimir, remote-read).     |
| `vmbackup` / `vmrestore` / `vmbackupmanager` | Snapshot-based backup/restore to S3, GCS, Azure Blob, or local FS. |
| `vminsert`       | Cluster ingest router; consistent-hashes incoming samples to vmstorage nodes.                 |
| `vmselect`       | Cluster query node; fans out to vmstorage and merges results. HTTP API on `:8481`.            |
| `vmstorage`      | Cluster storage node; stores samples and indexes. Shared-nothing.                             |
| `VictoriaLogs`   | Companion log database, sister project (separate binary, separate docs).                     |

### Architecture

#### Single-node

```text
            scrape / remote_write / OTLP
                       │
                       ▼
        ┌──────────────────────────────┐
        │     victoria-metrics :8428   │
        │  (ingest + storage + query)  │
        └──────────────┬───────────────┘
                       ▼
                 -storageDataPath
```

#### Cluster

```text
   write path                                 read path
       │                                          │
       ▼                                          ▼
 ┌──────────┐                              ┌──────────┐
 │ vminsert │──┐  consistent hashing  ┌── │ vmselect │
 │  :8480   │  │   over labels        │   │  :8481   │
 └──────────┘  ▼                      ▼   └──────────┘
        ┌────────────┐  ┌────────────┐  ┌────────────┐
        │ vmstorage  │  │ vmstorage  │  │ vmstorage  │
        │   :8482    │  │   :8482    │  │   :8482    │
        └────────────┘  └────────────┘  └────────────┘
            (shared nothing — no peer-to-peer traffic)
```

Each tier scales independently; `vmstorage` nodes do not communicate with each other.

### MetricsQL

[MetricsQL](https://docs.victoriametrics.com/victoriametrics/metricsql/) is a PromQL-compatible query language with practical extensions:

- `WITH (x = …)` template expressions for reusing sub-queries.
- Functions such as `rollup_rate`, `quantile_over_time`, `histogram_quantiles`, `keep_last_value`, `topk_max`.
- `default` operator: `metric_a or default 0`.
- `@` modifier and `subquery` semantics that fix common PromQL footguns.
- Native support for VictoriaMetrics histograms (`vmrange` buckets) in addition to Prometheus histograms.

## How to Install

### Starting via Binary

#### Quick Start (single-node)

```bash
VM_VERSION=1.140.0

# Download
wget https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${VM_VERSION}/victoria-metrics-linux-amd64-v${VM_VERSION}.tar.gz
sudo tar -xzf victoria-metrics-linux-amd64-v${VM_VERSION}.tar.gz -C /usr/local/bin

# Data dir + user
sudo useradd -r -s /usr/sbin/nologin victoriametrics
sudo mkdir -p /var/lib/victoria-metrics
sudo chown -R victoriametrics:victoriametrics /var/lib/victoria-metrics

# Start (foreground)
/usr/local/bin/victoria-metrics-prod \
  -storageDataPath=/var/lib/victoria-metrics \
  -retentionPeriod=90d \
  -httpListenAddr=:8428

# Verify
curl http://127.0.0.1:8428/health
curl 'http://127.0.0.1:8428/api/v1/query?query=vm_app_uptime_seconds'
```

#### Config and Boot

##### Config

VictoriaMetrics is configured via command-line flags. Run `victoria-metrics-prod -help` to see the full list. The most common ones:

| Flag                              | Purpose                                                 |
| --------------------------------- | ------------------------------------------------------- |
| `-storageDataPath`                | Data directory.                                         |
| `-retentionPeriod`                | How long to keep data (e.g. `30d`, `1y`). Min `24h`.    |
| `-httpListenAddr`                 | HTTP listen address (default `:8428`).                  |
| `-promscrape.config`              | Path to a Prometheus-style scrape config.               |
| `-selfScrapeInterval`             | Scrape own metrics for self-monitoring.                 |
| `-search.maxQueryDuration`        | Max single query duration.                              |
| `-dedup.minScrapeInterval`        | Deduplication when running HA pairs.                    |
| `-search.maxConcurrentRequests`   | Concurrent query limit.                                 |
| `-envflag.enable`                 | Allow flag values from environment variables.           |

When scraping like Prometheus:

**/opt/victoriametrics/scrape.yml**

```yaml
global:
  scrape_interval: 15s
  external_labels:
    cluster: prod
    region: us-east-1

scrape_configs:
  - job_name: node
    static_configs:
      - targets: ['10.0.0.1:9100', '10.0.0.2:9100']

  - job_name: kubernetes-pods
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        regex: 'true'
        action: keep
```

##### Boot(systemd)

```bash
sudo tee /etc/systemd/system/victoriametrics.service > /dev/null << 'EOF'
[Unit]
Description=VictoriaMetrics single-node TSDB
Documentation=https://docs.victoriametrics.com/
After=network-online.target

[Service]
Type=simple
User=victoriametrics
Group=victoriametrics
Restart=on-failure
RestartSec=5s
LimitNOFILE=65535
ExecStart=/usr/local/bin/victoria-metrics-prod \
  -storageDataPath=/var/lib/victoria-metrics \
  -retentionPeriod=90d \
  -httpListenAddr=:8428 \
  -promscrape.config=/opt/victoriametrics/scrape.yml \
  -selfScrapeInterval=10s

PrivateTmp=yes
ProtectHome=yes
ProtectSystem=full
NoNewPrivileges=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now victoriametrics.service
```

#### vmagent — scrape & remote_write

`vmagent` is a much lighter Prometheus replacement for the collection layer. It supports all `scrape_configs` plus `-remoteWrite.url` to fan out to one or many remote destinations with on-disk persistence.

```bash
/usr/local/bin/vmagent-prod \
  -promscrape.config=/opt/vmagent/scrape.yml \
  -remoteWrite.url=http://victoriametrics:8428/api/v1/write \
  -remoteWrite.url=http://backup-vm:8428/api/v1/write \
  -remoteWrite.tmpDataPath=/var/lib/vmagent
```

#### vmalert — alerting & recording rules

```bash
/usr/local/bin/vmalert-prod \
  -datasource.url=http://victoriametrics:8428 \
  -remoteWrite.url=http://victoriametrics:8428 \
  -remoteRead.url=http://victoriametrics:8428 \
  -notifier.url=http://alertmanager:9093 \
  -rule=/etc/vmalert/rules/*.yml \
  -external.label=cluster=prod
```

Rule files use the standard Prometheus rule format:

```yaml
groups:
  - name: api.rules
    interval: 30s
    rules:
      - alert: APIHighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m]))
            / sum(rate(http_requests_total[5m])) > 0.05
        for: 10m
        labels:
          severity: page
        annotations:
          summary: "High 5xx rate on {{ $labels.service }}"
      - record: job:http_requests:rate5m
        expr: sum by (job) (rate(http_requests_total[5m]))
```

### Starting via Docker

```bash
# Single-node
docker run -d --name victoriametrics \
  -p 8428:8428 \
  -v vm-data:/victoria-metrics-data \
  victoriametrics/victoria-metrics:v1.140.0 \
  -storageDataPath=/victoria-metrics-data \
  -retentionPeriod=90d \
  -selfScrapeInterval=10s
```

`docker-compose.yml` example with vmagent + vmalert + Alertmanager + Grafana:

```yaml
services:
  victoriametrics:
    image: victoriametrics/victoria-metrics:v1.140.0
    ports: ["8428:8428"]
    volumes:
      - vmdata:/storage
    command:
      - -storageDataPath=/storage
      - -retentionPeriod=90d
      - -httpListenAddr=:8428

  vmagent:
    image: victoriametrics/vmagent:v1.140.0
    depends_on: [victoriametrics]
    volumes:
      - ./scrape.yml:/etc/vmagent/scrape.yml
    command:
      - -promscrape.config=/etc/vmagent/scrape.yml
      - -remoteWrite.url=http://victoriametrics:8428/api/v1/write

  vmalert:
    image: victoriametrics/vmalert:v1.140.0
    depends_on: [victoriametrics, alertmanager]
    volumes:
      - ./alerts:/etc/vmalert/rules
    command:
      - -datasource.url=http://victoriametrics:8428
      - -remoteWrite.url=http://victoriametrics:8428
      - -notifier.url=http://alertmanager:9093
      - -rule=/etc/vmalert/rules/*.yml

  alertmanager:
    image: prom/alertmanager:v0.27.0
    ports: ["9093:9093"]

  grafana:
    image: grafana/grafana:11.3.0
    ports: ["3000:3000"]

volumes:
  vmdata:
```

### Starting via Kubernetes

#### Helm — single-node

```bash
helm repo add vm https://victoriametrics.github.io/helm-charts/
helm repo update

helm pull vm/victoria-metrics-single --untar
cd victoria-metrics-single

# values.yaml
cat > values.yaml << 'EOF'
server:
  retentionPeriod: 90d
  persistentVolume:
    enabled: true
    size: 100Gi
    storageClass: premium-rwo
  resources:
    requests: { cpu: 500m, memory: 1Gi }
    limits:   { cpu: 2000m, memory: 4Gi }
  scrape:
    enabled: true
    configMap: ""
    config:
      global:
        scrape_interval: 30s
      scrape_configs:
        - job_name: kubernetes-nodes
          kubernetes_sd_configs:
            - role: node
EOF

helm upgrade --install vm-single . -n monitoring --create-namespace -f values.yaml
```

#### Helm — cluster (vminsert + vmselect + vmstorage)

```bash
helm pull vm/victoria-metrics-cluster --untar
cd victoria-metrics-cluster

cat > values.yaml << 'EOF'
vmstorage:
  replicaCount: 3
  retentionPeriod: 90d
  persistentVolume:
    enabled: true
    size: 200Gi
    storageClass: premium-rwo
  resources:
    requests: { cpu: 1000m, memory: 4Gi }
    limits:   { cpu: 4000m, memory: 16Gi }

vminsert:
  replicaCount: 3
  resources:
    requests: { cpu: 500m, memory: 1Gi }
    limits:   { cpu: 2000m, memory: 4Gi }

vmselect:
  replicaCount: 3
  cacheMountPath: /cache
  persistentVolume:
    enabled: true
    size: 20Gi
  resources:
    requests: { cpu: 500m, memory: 1Gi }
    limits:   { cpu: 2000m, memory: 4Gi }
EOF

helm upgrade --install vm-cluster . -n monitoring -f values.yaml
```

Cluster URL format:

| Operation       | URL                                                            |
| --------------- | -------------------------------------------------------------- |
| Remote write    | `http://vminsert:8480/insert/<accountID>/prometheus/api/v1/write` |
| Influx write    | `http://vminsert:8480/insert/<accountID>/influx/write`           |
| Prom query      | `http://vmselect:8481/select/<accountID>/prometheus/api/v1/query`|
| vmui            | `http://vmselect:8481/select/<accountID>/vmui/`                  |

`<accountID>` is the tenant ID (use `0` for single-tenant deployments).

#### vm-operator (recommended for K8s)

The [VictoriaMetrics Operator](https://docs.victoriametrics.com/operator/) introduces CRDs (`VMCluster`, `VMSingle`, `VMAgent`, `VMAlert`, `VMRule`, `VMServiceScrape`, `VMPodScrape`) that mirror the Prometheus Operator API.

```bash
helm install vm-operator vm/victoria-metrics-operator -n monitoring
```

```yaml
apiVersion: operator.victoriametrics.com/v1beta1
kind: VMCluster
metadata:
  name: vm
  namespace: monitoring
spec:
  retentionPeriod: "90d"
  vmstorage:
    replicaCount: 3
    storage:
      volumeClaimTemplate:
        spec:
          resources: { requests: { storage: 200Gi } }
          storageClassName: premium-rwo
  vminsert:
    replicaCount: 3
  vmselect:
    replicaCount: 3
    cacheMountPath: /select-cache
    storage:
      volumeClaimTemplate:
        spec:
          resources: { requests: { storage: 20Gi } }
```

## Integrations

### Prometheus remote_write

Have Prometheus offload long-term storage to VictoriaMetrics:

```yaml
# prometheus.yml
remote_write:
  - url: http://victoriametrics:8428/api/v1/write
    queue_config:
      max_samples_per_send: 10000
      capacity: 100000
      max_shards: 30
```

For the cluster version:

```yaml
remote_write:
  - url: http://vminsert:8480/insert/0/prometheus/api/v1/write
```

### Grafana

Add a Prometheus-type data source pointing at VictoriaMetrics:

- Single-node: `http://victoriametrics:8428`
- Cluster: `http://vmselect:8481/select/0/prometheus`

All Prometheus dashboards work unchanged; queries can additionally use MetricsQL extensions.

### OpenTelemetry

VictoriaMetrics accepts OTLP metrics directly:

```bash
# Single-node
http://victoriametrics:8428/opentelemetry/api/v1/push

# Cluster
http://vminsert:8480/insert/0/opentelemetry/api/v1/push
```

### Migration with vmctl

```bash
# Migrate from Prometheus snapshot
vmctl prometheus \
  --prom-snapshot=/path/to/prometheus/snapshot \
  --vm-addr=http://victoriametrics:8428

# Migrate from InfluxDB
vmctl influx \
  --influx-addr=http://influxdb:8086 \
  --influx-database=metrics \
  --vm-addr=http://victoriametrics:8428
```

## High Availability and Backups

- **HA pairs**: run two identical single-node instances behind `vmauth`. Set `-dedup.minScrapeInterval=<scrape_interval>` on both so duplicate samples are collapsed at query time.
- **Replication (cluster)**: set `-replicationFactor=N` on `vminsert` and `vmselect`; samples are written to `N` `vmstorage` nodes.
- **Backups**: `vmbackup` creates incremental backups from instant filesystem snapshots to S3/GCS/Azure/local; `vmrestore` restores them. `vmbackupmanager` (Enterprise) automates retention.

```bash
vmbackup \
  -storageDataPath=/var/lib/victoria-metrics \
  -snapshot.createURL=http://localhost:8428/snapshot/create \
  -dst=s3://my-bucket/vm-backups/$(date +%Y-%m-%d)
```

> Reference:
>
> 1. [Official Website](https://victoriametrics.com/)
> 2. [Documentation](https://docs.victoriametrics.com/victoriametrics/)
> 3. [Repository](https://github.com/VictoriaMetrics/VictoriaMetrics)
> 4. [Cluster Documentation](https://docs.victoriametrics.com/victoriametrics/cluster-victoriametrics/)
> 5. [MetricsQL](https://docs.victoriametrics.com/victoriametrics/metricsql/)
> 6. [Helm Charts](https://github.com/VictoriaMetrics/helm-charts)
> 7. [VictoriaMetrics Operator](https://docs.victoriametrics.com/operator/)
> 8. [vmagent](https://docs.victoriametrics.com/victoriametrics/vmagent/)
> 9. [vmalert](https://docs.victoriametrics.com/victoriametrics/vmalert/)
