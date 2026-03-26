---
description: Prometheus
tags:
  - cncf/observability
  - monitoring
---

# Prometheus

## Introduction

### What is Prometheus?

Prometheus is an open-source systems monitoring and alerting toolkit originally built at SoundCloud. Since its inception in 2012, many companies and organizations have adopted Prometheus, and the project has a very active developer and user community. It is now a standalone open source project and maintained independently of any company. To emphasize this, and to clarify the project's governance structure, Prometheus joined the Cloud Native Computing Foundation in 2016 as the second hosted project, after Kubernetes.

Prometheus collects and stores its metrics as time series data, i.e. metrics information is stored with the timestamp at which it was recorded, alongside optional key-value pairs called labels.

For more elaborate overviews of Prometheus, see the resources linked from the media section.

#### Features

Prometheus's main features are:

- a multi-dimensional data model with time series data identified by metric name and key/value pairs
- PromQL, a flexible query language to leverage this dimensionality
- no reliance on distributed storage; single server nodes are autonomous
- time series collection happens via a pull model over HTTP
- pushing time series is supported via an intermediary gateway
- targets are discovered via service discovery or static configuration
- multiple modes of graphing and dashboarding support

#### Components

- the main Prometheus server which scrapes and stores time series data

````console
Proactively pull monitoring metric data from the HTTP endpoints(usually is /metrics) of configured targets through a pull model on a regular basis(scrape_intervals), and store the data for PromQL queries.

- client libraries for instrumenting application code
- a push gateway for supporting short-lived jobs
```console
Programs or scripts are pushed to Pushgateway via HTTP Post requests, and Prometheus periodically retrieves temporarily stored metrics from Pushgateway.
````

- special-purpose exporters for services like HAProxy, StatsD, Graphite, etc.

```console
Expose application/server metrics, like node-exporter, mysql-exporter.
```

- an alertmanager to handle alerts

```console
Manage alerts, group, suppress, and send notifications.
```

- various support tools

### Concepts

#### Data model

Metric names and labels

```console
api_http_requests_total{method="POST", handler="/messages"}
```

#### Metric types

Counter

Gauge

Histogram

Summary

#### Jobs and instances

## Deploy By Binary

### Quick Start

```bash
# download source and decompress
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
tar xf prometheus-2.45.0.linux-amd64.tar.gz && rm -f prometheus-2.45.0.linux-amd64.tar.gz
mv prometheus-2.45.0.linux-amd64 /opt/prometheus
cd /opt/prometheus

# postinstallation
groupadd prometheus
useradd -r -g prometheus -s /bin/false prometheus
chown prometheus:prometheus /opt/prometheus -R

# startup
./prometheus --config.file=prometheus.yml [--web.enable-lifecycle]
# prometheus metrics
curl 127.0.0.1:9090/metrics
# dynamics reload
curl 127.0.0.1:9090/-/reload -X POST

```

### Config and Boot

#### Config

**/opt/observability/prometheus/prometheus.yml**

```yaml
# Global config
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  scrape_timeout: 10s

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets: ["alertmanager:9093"]

# Rule files
rule_files:
  # - /etc/config/rules/*.rules.yaml
  - "alerting.rules.yaml"
  - "recording.rules.yaml"

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
  - job_name: "example-random"
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:8080', 'localhost:8081']
        labels:
          group: 'production'
      - targets: ['localhost:8082']
        labels:
          group: 'canary'

remote_read:
  # Thanos
  - url: "http://thanos-query:10902/api/v1/read"
    basic_auth:
      username: "user"
      password: "password"
    tls_config:
      insecure_skip_verify: true
  # VictoriaMetrics
  - url: "http://vmselect:8481/select/0/prometheus/api/v1/read"
remote_write:
  # Thanos
  - url: "http://thanos-receive:10908/api/v1/receive"
  # VictoriaMetrics
  - url: "http://vminsert:8480/insert/0/prometheus"

# tls_server_config:
#   cert_file: <filename>
#   key_file: <filename>
```

**/opt/observability/prometheus/alerting.rules.yaml**

```yaml
# alerting rules file
groups:
- name: alerting.rules
  rules:
  # Alert for any instance that is unreachable for >5 minutes.
  - alert: InstanceDown
    expr: up == 0
    for: 5m
    labels:
      severity: page
    annotations:
      summary: "Instance {{ $labels.instance }} down"
      description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 5 minutes."

  # Alert for any instance that has a median request latency >1s.
  - alert: APIHighRequestLatency
    expr: api_http_request_latencies_second{quantile="0.5"} > 1
    for: 10m
    annotations:
      summary: "High request latency on {{ $labels.instance }}"
      description: "{{ $labels.instance }} has a median request latency above 1s (current value: {{ $value }}s)"
```

**/opt/observability/prometheus/recording.rules.yaml**

```yaml
# recoding rules file
groups:
- name: recording.rules
  rules:
  - record: code:prometheus_http_requests_total:sum
    expr: sum by (code) (prometheus_http_requests_total)
- name: rpc_random
  rules:
  - record: job_service:rpc_durations_seconds_count:avg_rate5m
    expr: avg(rate(rpc_durations_seconds_count[5m])) by (job, service)
```

syntax-checking rules

```bash
./promtool check rules alerting.rules.yml recording.rules.yaml
```

#### Boot(systemd)

```bash
# boot
cat > /etc/systemd/system/prometheus.service << "EOF"
[Unit]
Description=Prometheus Server
Documentation=https://prometheus.io/docs/introduction/overview/
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Restart=on-failure
ExecStart=/opt/prometheus/prometheus \
  --config.file=/opt/prometheus/prometheus.yml \
  --storage.tsdb.path=/opt/prometheus/data \
  --storage.tsdb.retention.time=30d \
  --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start prometheus.service
systemctl enable prometheus.service

# verify
# random client and metrics
git clone https://github.com/prometheus/client_golang.git
cd client_golang/examples/random
go get -d && go build
./random -listen-address=:8080
./random -listen-address=:8081
./random -listen-address=:8082
# get metrics(browser access localhost:9090/graph)
avg(rate(rpc_durations_seconds_count[5m])) by (job, service)
# custom record metrics
job_service:rpc_durations_seconds_count:avg_rate5m

```

## Deploy By Container

### Run On Docker

```bash
mkdir /opt/prometheus
cat > /opt/prometheus/prometheus.yml << "EOF"
...
EOF

# dockerhub
docker run --name prometheus --rm -p 9090:9090 -v /opt/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus
# quay.io
docker run --name prometheus --rm -p 9090:9090 -v /opt/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml quay.io/prometheus/prometheus

```

### Run On Kubernetes

```bash
# add and update repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm update

# get charts package
helm pull prometheus-community/prometheus --untar
cd prometheus

# configure and run
vim values.yaml
server:
  configPath: /etc/config/prometheus.yml
  persistentVolume:
    enabled: true
    size: 20Gi
    storageClass: "nfs-client"
serverFiles:
  alerting_rules.yml: {}
  recording_rules.yml:
    groups:
    - name: k8s.rules
      rules:
      - expr: |-
          xxx
        record: xxx_xxx
alertmanager:
  enabled: true
kube-state-metrics:
  enabled: true
prometheus-node-exporter:
  enabled: true

# install
helm -n monitoring install prometheus .

# access and test

```

## Visualization

### [console template](https://prometheus.io/docs/visualization/consoles/)

## AlertManager

### Quick Start

```bash
# binary
cd /opt/prometheus
wget https://github.com/prometheus/alertmanager/releases/download/v0.25.0/alertmanager-0.25.0.linux-amd64.tar.gz
tar xf alertmanager-0.25.0.linux-amd64.tar.gz && rm -f alertmanager-0.25.0.linux-amd64.tar.gz
mv alertmanager-0.25.0.linux-amd64 alertmanager

# helm
# include prometheus chart package
```

### Alert Config

**/opt/observability/alertmanager/alertmanager.yml**

```yaml
global:
  resolve_timeout: 5m
  smtp_smarthost: 'smtp.163.com:465'
  smtp_from: 'example@163.com'
  smtp_auth_username: 'user@163.com'
  smtp_auth_password: 'password'
  smtp_hello: '163.com'
  smtp_require_tls: false
route:
  group_by: ['cluster', 'alertname']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 1h
  receiver: 'default-receiver'
  routes:
    - receiver: 'database-pager'
      group_wait: 10s
      matchers:
      - service=~"mysql|cassandra"
receivers:
  - name: 'default-receiver'
    webhook_configs:
    - url: 'http://127.0.0.1:5001/'
  - name: 'database-pager'
    email_configs:
    - to: 'xxx@gmail.com'
      send_resolved: true
templates:
  - /opt/prometheus/alertmanager/*.tmpl
```

**/opt/observability/alertmanager/email.tmpl**

```html
{{ define "email.html" }} {{ range .Alerts }}
<pre>
	========start==========
   Alert Program: prometheus_alert_email
   Alert Level: {{ .Labels.severity }}
   Alert Type: {{ .Labels.alertname }}
   Affected Host: {{ .Labels.instance }}
   Alert Subject: {{ .Annotations.summary }}
   Alert Details: {{ .Annotations.description }}
   Resolution: {{ .Annotations.console }}
   Trigger Time: {{ .StartsAt.Format "2006-01-02 15:04:05" }}
   ========end==========
</pre>
{{ end }} {{ end }}
```

```bash
cd /opt/prometheus/alertmanager/
./alertmanager --config.file=alertmanager.yml
```

## Metrics exporter

### node_exporter

Download and Install

```bash
# binary
cd /opt/prometheus
wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.24.0/blackbox_exporter-0.24.0.linux-amd64.tar.gz
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar xf blackbox_exporter-0.24.0.linux-amd64.tar.gz && rm -f blackbox_exporter-0.24.0.linux-amd64.tar.gz
tar xf node_exporter-1.6.1.linux-amd64.tar.gz && rm -f node_exporter-1.6.1.linux-amd64.tar.gz
./blackbox_exporter-0.24.0.linux-amd64/blackbox_exporter
./node_exporter-1.6.1.linux-amd64/node_exporter

# helm
# node_exporter: include prometheus chart package
# blackbox_exporter
helm pull --untar prometheus-community/prometheus-blackbox-exporter
```

### middleware exporter

```bash
### template
# 1.install exporter
# 2.modify exporter config and check exporter
# 3.modify prometheus.yml
# 4.add grafana dashboard

# custom monitor endpoints
kubectl -n monitoring get service prometheus-kube-state-metrics -oyaml
apiVersion: v1
kind: Service
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"

# custom prometheus.yaml of endpints
- job_name: 'kubernetes-service-endpoints'
  relabel_configs:
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
    separator: ;
    regex: "true"
    replacement: $1
    action: keep
  - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
    separator: ;
    regex: (.+)
    target_label: __metrics_path__
    replacement: $1
    action: replace
  - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
    separator: ;
    regex: (.+?)(?::\d+)?;(\d+)
    target_label: __address__
    replacement: $1:$2
    action: replace
  .....
  kubernetes_sd_configs:
  - role: endpoints
    kubeconfig_file: ""
    follow_redirects: true
    enable_http2: true
###
```

redis-exporter

```bash
# helm values
no need

# prometheus.yaml
      - job_name: 'redis_exporter_targets'
        static_configs:
        - targets:
          - redis://1.1.1.1:6379
          - redis://1.1.1.2:6379
          - redis://1.1.1.3:6379
        metrics_path: /scrape
        relabel_configs:
        - source_labels: [__address__]
          target_label: __param_target
        - source_labels: [__param_target]
          target_label: instance
        - target_label: __address__
          replacement: redis-exporter-prometheus-redis-exporter.monitoring:9121

      - job_name: 'redis_exporter'
        static_configs:
        - targets:
          - redis-exporter-prometheus-redis-exporter.monitoring:9121

```

kafka-exporter

```bash
# helm values
kafkaServer:
  - 1.1.1.1:9092
  - 2.2.2.2:9092
  - 3.3.3.3:9092

# prometheus.yaml
# service or serviceMonitor
- job_name: serviceMonitor/monitoring/kafka-exporter-svc/0
  honor_labels: false
  kubernetes_sd_configs:
  - role: endpoints
    namespaces:
      names:
      - cattle-monitoring-system

```

rocketmq-exporter

```bash
# modify config and build jar
rocketmq:
  config:
    webTelemetryPath: /metrics
    namesrvAddr: rocket-exporter.monitoring:9876
mvn clean install

# create k8s yaml
#./knowledge/CNCF/OrchestrationManagement/SchedulingOrchestration/Kubernetes/k8s-yaml/others/rocketmq-exporter.yaml
kubectl apply -f rocketmq-exporter.yaml

# prometheus.yaml
# option1: rocketmq service scrape
kind: Service
metadata:
  annotations:
    prometheus.io/scrape: "true"
# option2: new job
   - job_name: 'rocketmq-exporter'
     static_configs:
     - targets: ['rocketmq-exporter:5557']
```

> Reference:
>
> 1. [Official Website](https://prometheus.io/docs/introduction/overview/)
> 2. [Repository](https://github.com/prometheus/prometheus)
> 3. [Download](https://prometheus.io/download/)
> 4. [Chinese Community Documentation](https://icloudnative.io/prometheus/)
> 5. [InfluxDB Doc](https://docs.influxdata.com/influxdb/v1.8/introduction/get-started/)
> 6. [redis-exporter](https://github.com/oliver006/redis_exporter)
> 7. [kafka-exporter](https://github.com/danielqsj/kafka_exporter)
> 8. [rocketmq-exporter](https://github.com/apache/rocketmq-exporter)
> 9. [awesome-prometheus-alerts](https://github.com/samber/awesome-prometheus-alerts)
