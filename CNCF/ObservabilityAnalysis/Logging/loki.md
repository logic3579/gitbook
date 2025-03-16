---
description: Grafana Loki
---

# Loki

## Introduction

### Loki

Log aggregation system.

### Promtail

Like Prometheus, but for logs.

## Deploy By Binary

### Quick Start

```bash
# download and decompression
cd /opt && wget https://github.com/grafana/loki/releases/download/v3.0.1/loki-linux-amd64.zip
unzip loki-linux-amd64.zip && rm -f loki-linux-amd64.zip
mkdir /opt/loki/{bin,config}

# soft link
mv /opt/loki/loki-linux-amd64 /opt/loki/bin/loki

# configure
wget https://raw.githubusercontent.com/grafana/loki/main/examples/getting-started/loki-config.yaml -O /opt/loki/config/loki-config.yaml

# start
/opt/loki/bin/loki -config.file=/opt/loki/config/loki-config.yaml

# logcli
# download
LOGCLI_VERSION=v3.4.2
wget https://github.com/grafana/loki/releases/download/${LOGCLI_VERSION}/logcli-linux-amd64.zip
unzip logcli-linux-amd64.zip && rm -f logcli-linux-amd64.zip
chmod +x logcli-linux-amd64 && mv logcli-linux-amd64 /usr/bin/logcli
# query
export LOKI_ADDR=http://localhost:3100
kubectl port-forward services/loki-query -n logging 3100:3100
logcli query --limit 10 '{namespace="default",instance="my-app"} |= "kube-probe"'
logcli query --limit 10 --since=1h '{namespace="default",instance="my-app"} |= "kube-probe"'
logcli query --limit 10 --from="2025-01-01T00:00:00Z" --to="2025-01-01T08:00:00Z" '{namespace="default",instance="my-app"} |= "kube-probe"'
```

### Config and Boot

#### Config

```bash
echo > /opt/loki/config/loki-config.yaml << "EOF"
...
EOF
```

#### Boot(systemd)

```bash
cat > /etc/systemd/system/loki.service << "EOF"
[Unit]
Description=Grafana Loki
Documentation=https://grafana.com/docs/loki
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/opt/loki/bin/loki --config.file /etc/loki/loki-all.yaml
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID
LimitNOFILE=65535
LimitNPROC=4096
LimitAS=infinity
LimitFSIZE=infinity
KillSignal=SIGTERM
KillMode=process
PrivateTmp=yes
Restart=on-failure
RestartSec=5s
SendSIGKILL=no
StandardError=inherit
StandardOutput=journal
SuccessExitStatus=143
TimeoutStartSec=60
TimeoutStopSec=30
Type=simple
User=loki
Group=loki

[Install]
WantedBy=multi-user.target
EOF


chown loki:loki /opt/loki -R
systemctl daemon-reload
systemctl start loki.service
systemctl enable loki.service
```

## Deploy By Container

### Run In Docker

```bash
# Using by docker
# get loki and promtail config
wget https://raw.githubusercontent.com/grafana/loki/v3.0.0/cmd/loki/loki-local-config.yaml -O loki-config.yaml
wget https://raw.githubusercontent.com/grafana/loki/v3.0.0/clients/cmd/promtail/promtail-docker-config.yaml -O promtail-config.yaml
# run container
docker run --name loki -d -v $(pwd):/mnt/config -p 3100:3100 grafana/loki:3.0.0 -config.file=/mnt/config/loki-config.yaml
docker run --name promtail -d -v $(pwd):/mnt/config -v /var/log:/var/log --link loki grafana/promtail:3.0.0 -config.file=/mnt/config/promtail-config.yaml


# Using by docker compose
wget https://raw.githubusercontent.com/grafana/loki/main/examples/getting-started/docker-compose.yaml -O docker-compose.yaml
docker compose up -d
```

### Run In Kubernetes

```bash
# add and update repo
helm repo add grafana https://grafana.github.io/helm-charts
helm update

# configure and run
vim values.yaml
deploymentMode: SimpleScalable  # single-binary, simple-scalable, distributed(microservices)
loki:
  tenants: []
  server:
    http_listen_port: 3100
    grpc_listen_port: 9095
    http_server_read_timeout: 600s
    http_server_write_timeout: 600s
  limits_config:
    ingestion_rate_mb: 10
    ingestion_burst_size_mb: 20
    max_label_names_per_series: 15
    reject_old_samples: true
    reject_old_samples_max_age: 1w
    max_line_size: 256KB
    max_line_size_truncate: true
    max_streams_per_user: 10000
    max_global_streams_per_user: 50000
    per_stream_rate_limit: 3MB
    per_stream_rate_limit_burst: 15MB
    max_chunks_per_query: 2000000
    max_query_length: 30d1h
    max_query_parallelism: 32
    query_timeout: 1m
    split_queries_by_interval: 1h
    retention_period: 30d
  storage:
    bucketNames:
      chunks: loki-chunks-bucket
      # ruler: FIXME
      # admin: FIXME
    type: s3 # s3, gcs, filesystem etc..
    s3:
      s3: null
      endpoint: "oss-ap-southeast-1.aliyuncs.com"
      region: "ap-southeast-1"
      accessKeyId: "xxx"
      secretAccessKey: "xxx"
      signatureVersion: null
      s3ForcePathStyle: false
      insecure: false
      http_config: {}
      backoff_config: {}
      disable_dualstack: false
    # gcs:
    #   chunkBufferSize: 0
    #   requestTimeout: "0s"
    #   enableHttp2: true
    # filesystem:
    #   chunks_directory: /var/loki/chunks
    #   rules_directory: /var/loki/rules
    #   admin_api_directory: /var/loki/admin
  schemaConfig:
    configs:
      - from: 2024-04-01
        store: tsdb
        object_store: s3 # s3, gcs, filesystem etc..
        schema: v13
        index:
          prefix: loki_index_
          period: 24h
        chunks:
          prefix: loki_chunks_
          period: 24h
  useTestSchema: false
  testSchemaConfig: {}
  rulerConfig:
    storage:
      type: local
      local:
        directory: /var/loki/rules
    wal:
      dir: /var/loki/ruler-wal
  query_scheduler: {}
  storage_config:
    tsdb_shipper:
      index_gateway_client:
        server_address: '{{ include "loki.indexGatewayAddress" . }}'
    hedging:
      at: "250ms"
      max_per_second: 20
      up_to: 3
  compactor:
    working_directory: /var/loki/compactor
    retention_enabled: true
    retention_delete_delay: 2h
    delete_request_store: s3 # s3, gcs, filesystem etc..
  querier:
    max_concurrent: 4
  ingester:
    chunk_retain_period: 0s
    chunk_idle_period: 30m
    chunk_block_size: 262144
    chunk_target_size: 1572864
    chunk_encoding: snappy
  index_gateway:
    mode: simple
  distributor: {}
  tracing:
    enabled: false
test:
  enabled: false
lokiCanary:
  enabled: false
networkPolicy:
  enabled: false
gateway:
  enabled: true
  replicas: 3
ingress:
  enabled: false
singleBinary:
  replicas: 0
write:
  replicas: 3
read:
  replicas: 3
backend:
  replicas: 3
  resources:
      requests:
        cpu: 2000m
        memory: 4Gi
      limits:
        cpu: 4000m
        memory: 8Gi
    persistence:
      volumeClaimsEnabled: true
      size: 100Gi
      storageClass: premium-rwo
ingester:
  replicas: 0
distributor:
  replicas: 0
querier:
  replicas: 0
queryFrontend:
  replicas: 0
queryScheduler:
  replicas: 0
indexGateway:
  replicas: 0
compactor:
  replicas: 0
bloomGateway:
  replicas: 0
bloomPlanner:
  replicas: 0
bloomBuilder:
  replicas: 0
ruler:
  enabled: false
  replicas: 0
resultsCache:
  enabled: true
  defaultValidity: 12h
  timeout: 500ms
  replicas: 1
  writebackSizeLimit: 500MB
  writebackBuffer: 500000
  writebackParallelism: 5
chunksCache:
  enabled: true
  batchSize: 4
  parallelism: 5
  timeout: 2000ms
  defaultValidity: 12h
  replicas: 1
  writebackSizeLimit: 500MB
  writebackBuffer: 500000
  writebackParallelism: 5
minio:
  enabled: false

# install promtail
helm install promtail grafana/promtail -f values.yaml -n logging
# install loki
helm install loki grafana/loki -f values.yaml -n logging
```

> Reference:
>
> 1. [Official Website](https://grafana.com/docs/loki/latest/)
> 2. [Repository](https://github.com/grafana/loki)
