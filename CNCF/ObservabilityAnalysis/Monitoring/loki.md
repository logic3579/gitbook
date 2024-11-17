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
...


# install loki
helm install loki grafana/loki -f values.yaml -n logging
# install loki-stack: loki, grafana, prometheus, promtail
helm install loki-stack grafana/loki-stack -f values.yaml -n logging
```



> Reference:
> 1. [Official Website](https://grafana.com/docs/loki/latest/)
> 2. [Repository](https://github.com/grafana/loki)
