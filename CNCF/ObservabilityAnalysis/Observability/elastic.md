---
description: ElasticSearch
---

# ElasticSearch

## Introduction

Elasticsearch is an open source, distributed search and analytics engine built for speed, scale, and AI applications. As a retrieval platform, it stores structured, unstructured, and vector data in real time — delivering fast hybrid and vector search, powering observability and security analytics, and enabling AI-driven applications with high performance, accuracy, and relevance.

## Deploy By Binary

### Quick Start

```bash
# download and decompression
cd /opt && wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.7.1-linux-x86_64.tar.gz
tar -xf elasticsearch-8.7.1-linux-x86_64.tar.gz && rm -f elasticsearch-8.7.1-linux-x86_64.tar.gz

# soft link
ln -svf /opt/elasticsearch-8.7.1/ /opt/elasticsearch
cd /opt/elasticsearch

# configure
vim config/elasticsearch.yml

# options: install plugin
# plugins dir: plugins and config
./bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v8.7.1/elasticsearch-analysis-ik-8.7.1.zip

# set password and verify
./bin/elasticsearch-setup-passwords interactive
curl 127.0.0.1:9200 -u 'elastic:elastic_password'

# start elasticsearch server
./bin/elasticsearch
./bin/elasticsearch -d # daemon
```

### [[sc-elasticsearch|Config]] and Boot

#### Config

```bash
echo > config/elasticsearch.yml << "EOF"
path.data: /opt/elasticsearch/data/
path.logs: /opt/elasticsearch/logs/
bootstrap.memory_lock: false
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: false
EOF
```

#### Boot(systemd)

```bash
cat > /etc/systemd/system/elasticsearch.service << "EOF"
[Unit]
Description=Elasticsearch
Documentation=https://www.elastic.co
Wants=network-online.target
After=network-online.target

[Service]
Environment=ES_HOME=/opt/elasticsearch
Environment=ES_PATH_CONF=/opt/elasticsearch/config
Environment=PID_DIR=/opt/elasticsearch/logs
Environment=ES_SD_NOTIFY=true
EnvironmentFile=-/etc/default/elasticsearch
ExecStart=/opt/elasticsearch/bin/systemd-entrypoint -p ${PID_DIR}/elasticsearch.pid --quiet
LimitNOFILE=65535
LimitNPROC=4096
LimitAS=infinity
LimitFSIZE=infinity
KillSignal=SIGTERM
KillMode=process
PrivateTmp=yes
Restart=on-failure
RestartSec=5s
RuntimeDirectory=elasticsearch
SendSIGKILL=no
StandardError=inherit
StandardOutput=journal
SuccessExitStatus=143
TimeoutStartSec=60
TimeoutStopSec=30
Type=simple
User=elasticsearch
Group=elasticsearch
WorkingDirectory=/opt/elasticsearch

[Install]
WantedBy=multi-user.target
EOF

cat > /opt/elasticsearch/bin/systemd-entrypoint << "EOF"
#!/bin/sh
if [ -n "$ES_KEYSTORE_PASSPHRASE_FILE" ] ; then
  exec /opt/elasticsearch/bin/elasticsearch "$@" < "$ES_KEYSTORE_PASSPHRASE_FILE"
else
  exec /opt/elasticsearch/bin/elasticsearch "$@"
fi
EOF

chmod +x /opt/elasticsearch/bin/systemd-entrypoint
chown elasticsearch:elasticsearch /opt/elasticsearch -R

systemctl daemon-reload
systemctl start elasticsearch.service
systemctl enable elasticsearch.service
```

## Deploy By Container

### Run On Kubernetes

```bash
# add and update repo
helm repo add elastic https://helm.elastic.co
helm update

# get charts package
helm pull elastic/elasticsearch --untar
cd elasticsearch

# create storageclass
# nfs-server or others
[[nfs-server]]

# configure and run
vim values.yaml
esConfig: {}
volumeClaimTemplate:
  storageClassName: "elk-nfs-client"
...

helm -n logging install elasticsearch .

```

> Reference:
>
> 1. [Official Website](https://www.elastic.co/docs)
> 2. [Repository](https://github.com/elastic/elasticsearch)
> 3. [Official elastic-cloud-kubernetes](https://www.elastic.co/downloads/elastic-cloud-kubernetes)
> 4. Elasticsearch UI: [cerebro](https://github.com/lmenezes/cerebro)
