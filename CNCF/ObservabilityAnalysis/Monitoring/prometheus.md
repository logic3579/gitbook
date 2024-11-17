---
description: Prometheus
---

# Prometheus

## Introduction
...


## Deploy With Binary

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
# prometheus metris
curl 127.0.0.1:9090/metrics
# dynamics reload
curl 127.0.0.1:9090/-/reload -X POST

```

### Config and Boot

#### [[sc-monitoring|Prometheus Config]]

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


## Deploy With Container

### Run in Docker
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

### Run in Kubernetes
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

### [[grafana|Grafana]]

### [console template](https://prometheus.io/docs/visualization/consoles/)


## AlertManager

### Quick Start
```bash
# baniry
cd /opt/prometheus
wget https://github.com/prometheus/alertmanager/releases/download/v0.25.0/alertmanager-0.25.0.linux-amd64.tar.gz
tar xf alertmanager-0.25.0.linux-amd64.tar.gz && rm -f alertmanager-0.25.0.linux-amd64.tar.gz
mv alertmanager-0.25.0.linux-amd64 alertmanager

# helm
# include prometheus chart package
```

### [[sc-monitoring#Alertmanager|Alert Config]]
```bash
cat > /opt/prometheus/alertmanager/alertmanager.yml << "EOF"
...
EOF

cd /opt/prometheus/alertmanager/
./alertmanager --config.file=alertmanager.yml
```


## Metrics exporter

### node_exporter
Download and Install
```bash
# baniry
cd /opt/prometheus
wget https://github.com/prometheus/blackbox_exporter/releases/download/v0.24.0/blackbox_exporter-0.24.0.linux-amd64.tar.gz
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar xf blackbox_exporter-0.24.0.linux-amd64.tar.gz && rm -f blackbox_exporter-0.24.0.linux-amd64.tar.gz 
tar xf node_exporter-1.6.1.linux-amd64.tar.gz && rm -f node_exporter-1.6.1.linux-amd64.tar.gz
./blackbox_exporter-0.24.0.linux-amd64/blackbox_exporter
./node_exporter-1.6.1.linux-amd64/node_exporter

# helm
# node_exporter: include prometheus chart package
# black_exporter
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
> 1. [Official Website](https://prometheus.io/docs/introduction/overview/)
> 2. [Repository](https://github.com/prometheus/prometheus)
> 3. [Download](https://prometheus.io/download/)
> 4. [中文社区文档](https://icloudnative.io/prometheus/)
> 5. [InfluxDB Doc](https://docs.influxdata.com/influxdb/v1.8/introduction/get-started/)
> 6. [redis-exporter](https://github.com/oliver006/redis_exporter)
> 7. [kafka-exporter](https://github.com/danielqsj/kafka_exporter)
> 8. [rocketmq-exporter](https://github.com/apache/rocketmq-exporter)
> 9. [awesome-prometheus-alerts](https://github.com/samber/awesome-prometheus-alerts)
