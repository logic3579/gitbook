## Alertmanager

/opt/observability/alertmanager/alertmanager.yml
```bash
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

/opt/observability/alertmanager/email.tmpl

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
## Fluentd

/etc/td-agent/td-agent.conf

```bash
<system>
  workers 4
</system>

# for filebeat logs of opt,var,etc..
# /opt/td-agent/bin/gem install fluent-plugin-beats --no-document
<worker 0>
  <source>
    @type beats
    port 5044
    metadata_as_tag
    @label @filebeat_logs
  </source>
</worker>

# for uat application logs
<worker 1>
  <source>
    @type forward
    port 24224
    @label @uat_logs
  </source>
</worker>

# for prod application logs
<worker 2-3>
  <source>
    @type forward
    port 24225
    @label @prod_logs
  </source>
</worker>

#########

<label @filebeat_logs>
  <filter *beat>
    @type record_transformer
    enable_ruby true

    <record>
      log_path ${record["log"]["file"]["path"]}
    </record>
  </filter>

  <match *beat>
    <format>
      @type single_value
      message_key message
    </format>

    @type file
    path /opt/backup_logs/%Y-%m-%d/${$.log_path}
    append true
    add_path_suffix false
    compress gzip

    <buffer time,$.log_path>
      @type file
      path /tmp/beat/%Y-%m-%d/${$.log_path}
      timekey 1d
      timekey_wait 10s
      timekey_use_utc true

      flush_at_shutdown true
      flush_mode interval
      flush_interval 10s
    </buffer>
  </match>
</label>

<label @uat_logs>
  <filter kube.**>
    @type record_transformer
    remove_keys time,stream,_p,host,kubernetes_namespace_name,kubernetes_pod_id,kubernetes_docker_id,kubernetes_container_hash,kubernetes_container_image,kubernetes_pod_name,kubernetes_host,host_ip

    <record>
      log_path ${record["host_ip"]}_${record["kubernetes_container_name"]}
    </record>
  </filter>

  <match kube.**>
    <format>
      @type single_value
      message_key message
      #@type out_file
      #output_tag false
      #output_time false
    </format>

    #@type stdout
    @type file
    path /opt/backup_logs/uat/%Y-%m-%d/${$.log_path}/${$.kubernetes_container_name}
    # flushed chunk appended to one file
    append true
    compress gzip

    # <buffer tag,time>
    <buffer time,$.log_path,$.kubernetes_container_name>
      @type file
      timekey 1d
      timekey_wait 10s
      timekey_use_utc true
      flush_at_shutdown true
      flush_mode interval
      flush_interval 10s
    </buffer>
  </match>
</label>

<label @prod_logs>
  <filter kube.**>
    @type record_transformer
    remove_keys time,stream,_p,host,kubernetes_namespace_name,kubernetes_pod_id,kubernetes_docker_id,kubernetes_container_hash,kubernetes_container_image,kubernetes_pod_name,kubernetes_host,host_ip,es_index,local_time

    <record>
      log_path ${record["host_ip"]}_${record["kubernetes_container_name"]}
    </record>
  </filter>

  <match kube.**>
    <format>
      @type single_value
      message_key message
    </format>

    @type file
    path /opt/backup_logs/prod/%Y-%m-%d/${$.log_path}/${$.kubernetes_container_name}
    append true
    compress gzip

    <buffer time,$.log_path,$.kubernetes_container_name>
      @type file
      timekey 1d
      timekey_wait 10s
      timekey_use_utc true
      flush_at_shutdown true
      flush_mode interval
      flush_interval 10s
    </buffer>
  </match>
</label>
```

## Logstash

/opt/logstash/logstash.conf

```bash
# input config
input {
    # filebeat plugin
    beats {
	    port => 5044
    }
    # http plugin
    http {
	    host => "0.0.0.0"
	    port => 5999
	    additional_codecs => {"application/json"=>"json"}
	    codec => json {charset=>"UTF-8"}
	    ssl => false
	}
}
# filter config
filter {
    ruby {
        code => "
            event.set('local_time' , Time.now.strftime('%Y-%m-%d'))
            event.set('backup_time' , Time.now.strftime('%Y-%m-%d'))
        "
    }

    if [agent][type] == "filebeat" {
        mutate { update => { "host" => '%{[agent][name]}' }}
        mutate { replace => { "source" => '%{[log][file][path]}' }}
    }
    else if [user_agent][original] == "Fluent-Bit" {
      json {
        source => "message"
      }
      mutate {
        add_field => { "index_name" => "%{[kubernetes_container_name]}" }
      }
      mutate {
        gsub => ["[index_name]", "-", "_"]
      }
    }
}
# output config
output {
    # stdout { codec => rubydebug } #Used to validate/troubleshoot

    # backup to file
    if [user_agent][original] == "Fluent-Bit" {
      file {
          path => "/opt/backup_logs/%{backup_time}/%{host_ip}_%{index_name}/%{index_name}.gz"
          gzip => true
          codec =>  line {
              format => "[%{index_name} -->| %{message}"
              }
          }
    }
    if [agent][type] == "filebeat" {
      file {
        path => "/opt/all_logs/%{local_time}/%{[host]}/%{[source]}.gz"
        gzip => true
        codec =>  line {
            format => "[%{[host]} -- %{[source]}] -->| %{message}"
            }
        }
    }

    # send to elasticsearch
    if [host_ip] == "xxx" and [namespace_name] == "default" {
      elasticsearch {
        hosts => ["http://es_server_1:9200"]
        user => elastic
        password => "es123"
        index => "logstash-uat_%{index_name}-%{local_time}"
      }

    }
    else if [host_ip] == "xxx" and [namespace_name] == "default"  {
     elasticsearch {
       hosts => ["http://es_server_2:9200"]
       user => elastic
       password => "es123"
       index => "logstash-%{index_name}-%{local_time}"
     }
   }
}
```

## Prometheus

/opt/observability/prometheus/prometheus.yml

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

/opt/observability/prometheus/alerting.rules.yaml

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

/opt/observability/prometheus/recording.rules.yaml

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

## Promtail

/opt/observability/promtail/config.yml

```bash
server:
  log_level: info
  log_format: logfmt
  http_listen_port: 3101

clients:
  - url: http://loki-gateway.revosurge-uat.com/loki/api/v1/push

positions:
  filename: /tmp/positions.yaml

scrape_configs:
- job_name: docker-containers-debug
  docker_sd_configs:
    - host: unix:///var/run/docker.sock
      refresh_interval: 5s
      port: 80

  # 将 Docker Compose 的服务名作为 'app' 标签
  relabel_configs:
  - source_labels: [__meta_docker_container_label_com_docker_compose_service]
    target_label: app
  - source_labels: [__meta_docker_container_name]
    regex: '/(.+)'
    target_label: container_name
    replacement: '$1'

  # 添加静态标签
  - target_label: namespace
    replacement: 'revosurge'
  - target_label: node_name
    replacement: '${HOSTNAME:-unknow_node}'

  # 过滤掉 Promtail 自己的日志，防止循环
  - source_labels: [__meta_docker_container_name]
    regex: '.*promtail.*'
    action: drop

  pipeline_stages:
  - docker: {}
```