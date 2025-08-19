# Prometheus

## main config

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

## rule files

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
