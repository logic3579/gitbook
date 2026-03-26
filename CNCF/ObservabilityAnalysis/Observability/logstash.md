---
description: Logstash
tags:
  - cncf/observability
  - logging
---

# Logstash

## Introduction

...

## Deploy By Binary

### Quick Start

```bash
# 1.download and decompression
https://www.elastic.co/downloads/logstash

# 2.configure
touch config/logstash.conf
vim config/logstash.conf

# 3.run
bin/logstash -f logstash.conf
```

### Config and Boot

#### Config

**/opt/logstash/logstash.conf**

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

#### Boot(systemd)

```bash
# boot
cat > /usr/lib/systemd/system/logstash.service << "EOF"
[Unit]
Description=logstash
Documentation=https://www.elastic.co
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=logstash
Group=logstash
EnvironmentFile=-/etc/default/logstash
ExecStart=/opt/logstash/bin/logstash "--path.settings" "/opt/logstash/config" "--path.logs" "/opt/logstash/logs" -f /opt/logstash/config/conf.d/logstash.conf
Restart=always
WorkingDirectory=/opt/logstash
Nice=19
LimitNOFILE=65535
TimeoutStopSec=infinity

[Install]
WantedBy=multi-user.target
EOF

# permission
chown logstash:logstash /opt/logstash -R

systemctl daemon-reload
systemctl start .service
systemctl enable .service
```

## Deploy By Container

### Run On Kubernetes

```bash
# add and update repo
helm repo add elastic https://helm.elastic.co
helm update

# get charts package
helm pull elastic/logstash --untar
cd logstash

# configure and run
vim values.yaml
logstashPipeline:
  logstash.conf: |
    input {
      exec {
        command => "uptime"
        interval => 30
      }
    }
    output { stdout { } }
...

helm -n logging install logstash .
```

> Reference:
>
> 1. [Official Website](https://www.elastic.co/guide/en/logstash/current/introduction.html)
> 2. [Repository](https://github.com/elastic/logstash)
> 3. [apt installing](https://www.elastic.co/guide/en/logstash/current/installing-logstash.html)
