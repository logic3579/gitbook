---
description: Grafana
---

# Grafana

## Introduction

Grafana Open Source Software (OSS) enables you to query, visualize, alert on, and explore your metrics, logs, and traces wherever they’re stored. Grafana data source plugins enable you to query data sources including time series databases like Prometheus and CloudWatch, logging tools like Loki and Elasticsearch, NoSQL/SQL databases like Postgres, CI/CD tooling like GitHub, and many more. Grafana OSS provides you with tools to display that data on live dashboards with insightful graphs and visualizations.

Grafana Enterprise is a commercial edition of Grafana that includes exclusive data source plugins and additional features not found in the open source version. You also get 24x7x365 support and training from the core Grafana team. To learn more about these features, refer to Enterprise features.

## Deploy With Binary

### Quick Start

```bash
# option.1: Debian / Ubuntu repo
apt install -y apt-transport-https software-properties-common wget
wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | tee -a /etc/apt/sources.list.d/grafana.list
apt update
apt install grafana

# option.2: resource
wget https://dl.grafana.com/oss/release/grafana-10.0.3.linux-amd64.tar.gz
tar -zxvf grafana-10.0.3.linux-amd64.tar.gz && rm -f grafana-10.0.3.linux-amd64.tar.gz
cd grafana-10.0.3
./bin/grafana server --config ./conf/defaults.ini

```

### Config and Boot

[Grafana Config](/Operations/ServiceConf/grafana.md)

#### Boot(systemd)

```bash
# boot
systemctl daemon-reload
systemctl start grafana-server.service
systemctl enable grafana-server.service
```

## Deploy With Container

### Run in Docker

pull images

```bash
# default based images: Alpine
# oss version(open source, default)
docker pull grafana/grafana
docker pull grafana/grafana-oss
# enterprise version
docker pull grafana/grafana-enterprise


# other based images: Ubuntu
# oss version(open source, default)
docker pull grafana/grafana:latest-ubuntu
docker pull grafana/grafana-oss:latest-ubuntu
# enterprise version
docker pull grafana/grafana-enterprise:latest-ubuntu
```

start container

```bash
# run
docker run -d -p 3000:3000 grafana/grafana-enterprise

# run with plugins
docker run -d -p 3000:3000 --name=grafana \
  -e "GF_INSTALL_PLUGINS=grafana-clock-panel 1.0.1" \
  grafana/grafana-oss:latest-ubuntu
docker run -d -p 3000:3000 --name=grafana --rm \
  -e "GF_INSTALL_PLUGINS=grafana-image-renderer" \
  grafana/grafana-enterprise:latest-ubuntu

# run with plugins by source
git clone https://github.com/grafana/grafana.git
cd grafana/packaging/docker/custom
docker build \
  --build-arg "GRAFANA_VERSION=latest" \
  --build-arg "GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource" \
  -t grafana-custom .
docker run -d -p 3000:3000 --name=grafana grafana-custom
```

> docker-compose = https://grafana.com/docs/grafana/latest/setup-grafana/start-restart-grafana/#docker-compose-example

### Run in Kubernetes

**deploy on resource manifest**

```bash
cat > grafana.yaml << "EOF"
kind: PersistentVolumeClaim
...
kind: Deployment
...
kind: Service
...
EOF
# https://grafana.com/docs/grafana/latest/setup-grafana/installation/kubernetes/

# send the manifest to API Server
kubectl -n monitoring apply -f grafana.yaml

# forward port on host
kubectl -n monitoring port-forward service/grafana 3000:3000
```

**deploy on helm**

```bash
# add and update repo
helm repo add grafana https://grafana.github.io/helm-charts
helm update

# get charts package
helm pull grafana/grafana --untar
cd grafana

# configure and run
vim values.yaml
persistence:
  enabled: true
  storageClassName: "xxx-nfs"
imageRenderer:
  enabled: true
...
helm -n monitorning install grafana .
```

## Grafana Labs dashboards

### Basic

```bash
# Node Exporter Full
1860

```

### Kubernetes

```bash
# Kubernetes Dashboard
18283

# Kubernetes Cluster (Prometheus)
6417

# K8S Dashboard EN 20250125
15661
#
```

### Database & Middleware

```bash
# Mysql
7362
# IOPS metrics
sum(irate(mysql_global_status_innodb_data_reads[5m])) by instance + sum(irate(mysql_global_status_innodb_data_writes[5m])) by instance

# Kafka
7589

# Redis
# single
11835
# cluster
763

# RocketMQ
10477
```

### ObservabilityAnalysis

```bash
# loki logs
13186

# loki metrics
17781
```

## Alert

### telegram_bot

```bash
# 1.get bot and token
https://core.telegram.org/bots#how-do-i-create-a-bot
https://core.telegram.org/bots/features#botfather

# 2.create telegram alert group and invited bot into group

# 3.get bot or chat_id info
curl https://api.telegram.org/bot<token>/getMe
curl https://api.telegram.org/bot<token>/getUpdates

# 4.send test message
curl "https://api.telegram.org/bot<token>/sendMessage?chat_id=<chat_id>&text=<msg>"

# 5.add bot to grafana

```

### alerting config

1. Dashboard --> edit panel --> create alert rule from this panel
   ![[/CNCF/ObservabilityAnalysis/Monitoring/attachements/Pasted image 20230821114504.png]]

2. Notifications --> add Labels(related Contact points)
   ![[/CNCF/ObservabilityAnalysis/Monitoring/attachements/Pasted image 20230821114732.png]]
   ![[/CNCF/ObservabilityAnalysis/Monitoring/attachements/Pasted image 20230821114429.png]]

3. Contact points --> Add template --> create notification template
   ![[/CNCF/ObservabilityAnalysis/Monitoring/attachements/Pasted image 20230821143025.png]]

![[/CNCF/ObservabilityAnalysis/Monitoring/attachements/Pasted image 20230822100216.png]]

```html
{{ define "tg_alert_template" -}} {{/* firing info */}} {{- if gt (len
.Alerts.Firing) 0 -}} {{ range $index, $alert := .Alerts }} =========={{
$alert.Status }}========== 告警名称: {{ $alert.Labels.alertname }} 告警级别: {{
$alert.Labels.severity }} 告警详情: {{ $alert.Annotations.summary }};{{
$alert.Annotations.description }} 故障时间: {{ ($alert.StartsAt.Add
28800e9).Format "2006-01-02 15:04:05" }} 实例信息: {{ $alert.Labels.instance }}
当前数值: {{ $alert.Values.B }} 静默告警: {{ .SilenceURL }} 告警大盘: {{
.DashboardURL }} ============END============ {{- end -}} {{- end }} {{/*
resolved info */}} {{- if gt (len .Alerts.Resolved) 0 -}} {{ range $index,
$alert := .Alerts }} =========={{ $alert.Status }}========== 告警名称: {{
$alert.Labels.alertname }} 告警级别: {{ $alert.Labels.severity }} 告警详情: {{
$alert.Annotations.summary }};{{ $alert.Annotations.description }} 故障时间: {{
($alert.StartsAt.Add 28800e9).Format "2006-01-02 15:04:05" }} 恢复时间: {{
($alert.EndsAt.Add 28800e9).Format "2006-01-02 15:04:05" }} 实例信息: {{
$alert.Labels.instance }} 当前数值: {{ $alert.Values.B }} 静默告警: {{
.SilenceURL }} 告警大盘: {{ .DashboardURL }} ============END============ {{- end
-}} {{- end }} {{- end -}}
```

4. Contact points --> Add contact point --> create telegram contact point
   ![[/CNCF/ObservabilityAnalysis/Monitoring/attachements/Pasted image 20230821115559.png]]

```html
# Message {{ template "tg_alert_template" . }}
```

![[/CNCF/ObservabilityAnalysis/Monitoring/attachements/Pasted image 20230822100054.png]]

5. Notification policies --> New nested policy --> create new notification policy
   ![[/CNCF/ObservabilityAnalysis/Monitoring/attachements/Pasted image 20230821115717.png]]

6. Check alert notification
   ![[/CNCF/ObservabilityAnalysis/Monitoring/attachements/Pasted image 20230823080802.png]]

> Reference:
>
> 1. [Official Website](https://grafana.com/docs/)
> 2. [Repository](https://github.com/grafana/grafana)
> 3. [Grafana Alert](https://grafana.com/docs/grafana/latest/alerting/fundamentals/)
> 4. [Telegram Api SDK](https://github.com/python-telegram-bot/python-telegram-bot/wiki/Introduction-to-the-API)
