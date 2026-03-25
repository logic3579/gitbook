---
description: Grafana service configuration for dashboards, alerting, SMTP, and image rendering.
tags:
  - devops/service-conf
  - monitoring
---

# Grafana

## Configuration

Main configuration file: `/etc/grafana/grafana.ini`

### Server

```ini
[server]
protocol = http
http_addr = 0.0.0.0
http_port = 3000
domain = grafana.example.com
root_url = %(protocol)s://%(domain)s/
```

### Database

```ini
# Default is SQLite3. For production, use MySQL or PostgreSQL.
[database]
type = postgres
host = 127.0.0.1:5432
name = grafana
user = grafana
password = grafana
ssl_mode = disable
```

### SMTP & Alerting

```ini
[smtp]
enabled = true
host = smtp.example.com:587
user = grafana@example.com
password = secret
skip_verify = false
from_address = grafana@example.com
from_name = Grafana

[alerting]
enabled = true
execute_alerts = true
```

### Image Rendering

```ini
[rendering]
server_url = http://grafana-image-renderer:8081/render
callback_url = http://grafana/
concurrent_render_request_limit = 10
```

### Authentication

```ini
# OAuth2 with Keycloak / Generic OAuth
[auth.generic_oauth]
enabled = true
name = SSO
client_id = grafana
client_secret = secret
scopes = openid profile email
auth_url = https://auth.example.com/realms/main/protocol/openid-connect/auth
token_url = https://auth.example.com/realms/main/protocol/openid-connect/token
api_url = https://auth.example.com/realms/main/protocol/openid-connect/userinfo
role_attribute_path = contains(groups[*], 'admin') && 'Admin' || 'Viewer'
```

## Deploy By Container

### Run On Docker

```bash
docker run -d --name grafana \
  -p 3000:3000 \
  -v grafana-data:/var/lib/grafana \
  -e GF_SECURITY_ADMIN_USER=admin \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  grafana/grafana-oss:11.5.2
```

### Run On Kubernetes

```bash
# Add Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Grafana
helm install grafana grafana/grafana \
  --namespace monitoring --create-namespace \
  --set persistence.enabled=true \
  --set persistence.size=10Gi \
  --set adminPassword=admin
```

## Provisioning

Grafana supports provisioning data sources and dashboards via YAML files placed in `/etc/grafana/provisioning/`.

### Data Source Provisioning

```yaml
# /etc/grafana/provisioning/datasources/prometheus.yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
```

### Dashboard Provisioning

```yaml
# /etc/grafana/provisioning/dashboards/default.yaml
apiVersion: 1
providers:
  - name: default
    orgId: 1
    folder: ''
    type: file
    options:
      path: /var/lib/grafana/dashboards
      foldersFromFilesStructure: true
```

> Reference:
>
> 1. [Official Website](https://grafana.com/)
> 2. [Repository](https://github.com/grafana/grafana)
> 3. [Configuration Docs](https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/)
