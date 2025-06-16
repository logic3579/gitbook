#### Prometheus

##### main config

/opt/prometheus/prometheus.yml

```bash
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

# remote_write:
#   - url: "http://localhost:9094/api/v1/read"
# remote_read:
#   - url: "http://localhost:9094/api/v1/read"

# tls_server_config:
#   cert_file: <filename>
#   key_file: <filename>
```

##### rule files

/opt/prometheus/alerting.rules.yaml

```bash
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

/opt/prometheus/recording.rules.yaml

```bash
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

#### Alertmanager

##### main config

/opt/prometheus/alertmanager/alertmanager.yml

```bash
global:
  resolve_timeout: 5m
  smtp_smarthost: 'smtp.163.com:465'
  smtp_from: 'xxx@163.com'
  smtp_auth_username: 'xxx@163.com'
  smtp_auth_password: 'xxxxxx'
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

##### template config

/opt/prometheus/alertmanager/email.tmpl

```html
{{ define "email.html" }} {{ range .Alerts }}
<pre>
	========start==========
   告警程序: prometheus_alert_email 
   告警级别: {{ .Labels.severity }} 级别 
   告警类型: {{ .Labels.alertname }} 
   故障主机: {{ .Labels.instance }} 
   告警主题: {{ .Annotations.summary }}
   告警详情: {{ .Annotations.description }}
   处理方法: {{ .Annotations.console }}
   触发时间: {{ .StartsAt.Format "2006-01-02 15:04:05" }}
   ========end==========
</pre>
{{ end }} {{ end }}
```

#### Grafana

/etc/grafana/grafana.ini

```bash
...
[smtp]
enabled = true
host = 1.1.1.1
user = ""
password = ""
skip_verify = true
from_address = ""
[alerting]
enabled = true
execute_alerts = true
[rendering]
server_url = http://grafana-image-renderer:8081/render
callback_url = http://grafana/

```
