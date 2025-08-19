# Alertmanager

## main config

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

## template config

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
