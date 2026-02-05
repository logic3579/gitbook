---
description: Fluentd and Fluent Bit
---

# Fluentd & Fluent Bit

## Fluentd

### Introduction

...

### Deploy By Binary

#### Quick Start

```bash
# Ubuntu Package install
# https://docs.fluentd.org/installation/install-by-deb

```

#### Config and Boot

[Fluentd Config](/DevOps/ServiceConf/observability.md)

```bash
# change storage permission
# td-agent
chown td-agent.td-agent /opt/log_path/ -R
# fluentd
chown _fluentd:_fluentd /opt/log_path/ -R

# boot
systemctl daemon-reload
systemctl start td-agent.service
systemctl enable td-agent.service
```

#### Verify

```bash
# syntax check
# td-agent
td-agent -c td-agent.conf --dry-run
# fluentd
fluentd -c fluentd.conf --dry-run
```

#### Troubleshooting

```bash
#
```

### Deploy By Container

#### Run On Kubernetes

```bash
# add and update repo
helm repo add fluent https://fluent.github.io/helm-charts
helm update

# get charts package
helm pull fluent/fluentd --untar
cd fluentd

# configure and run
vim values.yaml
...
helm -n logging install fluentd .

```

## Fluent Bit

### Introduction

**Fluent Bit** is an open-source, multi-platform log processor tool designed to be a versatile solution for log processing and distribution.
Today, the number of information sources in systems is continuously increasing. Handling large-scale data is complex, and collecting and aggregating various data requires a specialized tool that can address the following challenges:

- Different data sources
- Different data formats
- Data reliability
- Security
- Flexible routing
- Multiple destinations
  Fluent Bit was designed with high performance and low resource consumption in mind.

**Differences between Fluent Bit & Fluentd**
Both Fluentd and Fluent Bit can serve as aggregators or forwarders, and they can be used complementarily or independently as solutions. [Details](https://hulining.gitbook.io/fluentbit/about/fluentd-and-fluent-bit)

### Deploy By Binary

```bash
# source code download
https://docs.fluentbit.io/manual/installation/getting-started-with-fluent-bit

# create source list dir
mkdir -p /usr/share/keyrings/
mkdir -p /etc/apt/sources.list.d/
touch /etc/apt/sources.list.d/fluent-bit.list

# install GPG key and source list
curl https://packages.fluentbit.io/fluentbit.key | gpg --dearmor > /usr/share/keyrings/fluentbit-keyring.gpg
cat > /etc/apt/sources.list.d/fluent-bit.list << "EOF"
"deb [signed-by=/usr/share/keyrings/fluentbit-keyring.gpg] https://packages.fluentbit.io/ubuntu/focal focal main"
EOF

# install td-agent-bit
apt update
apt install td-agent-bit

# configuration file
cat /etc/td-agent-bit/td-agent-bit.conf

# start service
systemctl start td-agent-bit.service
systemctl enable td-agent-bit.service

```

### Deploy By Container

#### Related Concepts

Kubernetes manages a cluster of nodes, so our log agent tool needs to run on every node to collect logs from each POD. Therefore, Fluent Bit is deployed as a DaemonSet (a POD that runs on every node in the cluster).
When Fluent Bit runs, it reads, parses, and filters logs from each POD, and enriches each record with the following metadata:

- Pod Name
- Pod ID
- Container Name
- Container ID
- Labels
- Annotations

#### Log Output Methods

Container logs in the current cluster environment are all console output, divided into two parts:

- Output to Elasticsearch, for searching logs via the Kibana frontend.
- Output to the forward interface, provided by the fluentd service for log persistence, with 15 days of local storage and 3 months of log archiving to cloud storage (e.g., S3, GCS, OSS).

#### Download Helm Charts Package

```bash
# create observability chart package directory
mkdir /opt/helm-charts/logging
cd /opt/helm-charts/logging

# add helm repository, download fluent-bit charts package
helm repo add fluent https://fluent.github.io/helm-charts
helm update
helm pull fluent/fluent-bit --untar
cd fluent-bit

# config
vim values.yaml
...
  inputs: |
    [INPUT]
        Name tail
        Path /var/log/containers/frontend*.log,/var/log/containers/backend*.log
        Exclude_path *fluent-bit-*,*fluentbit-*,*rancher-*,*cattle-*,*sysctl-*
        multiline.parser docker, cri
        Tag kube.*
        # specify the maximum memory used by the tail plugin; if the limit is reached, the plugin stops collecting and resumes after flushing data
        Mem_Buf_Limit 15MB
        Buffer_Chunk_Size 1M
        Buffer_Max_Size 5M
        Skip_Long_Lines On
        Skip_Empty_Lines On
        Refresh_Interval 10
  filters: |
    [FILTER]
        Name kubernetes
        Match kube.*
        Kube_Tag_Prefix kube.var.log.containers.
        # parse JSON content in the log field, extract to root level, append to the field specified by Merge_Log_Key
        Merge_Log Off
        Keep_Log Off
        K8S-Logging.Parser Off
        K8S-Logging.Exclude Off
        Labels Off
        Annotations Off
    # nest filter adds kubernetes_ prefix to fields of logs containing pod_name
    [FILTER]
        Name         nest
        Match        kube.*
        Wildcard     pod_name
        Operation    lift
        Nested_under kubernetes
        Add_prefix   kubernetes_
    # modify filter adjusts some kubernetes metadata field names and appends additional fields
    [FILTER]
        Name modify
        Match kube.*
        # rename the log field to message
        Rename log message
        # remove redundant kubernetes field data
        Remove kubernetes_container_image
        Remove kubernetes_container_hash
    # convert multiline error logs into a single line
    [FILTER]
        name multiline
        match kube.*
        multiline.key_content message
        multiline.parser multiline_stacktrace_parser
    # custom lua function filter to set the ES index name field
    [FILTER]
        Name    lua
        Match   kube.*
        script  /fluent-bit/etc/fluentbit.lua
        call    set_index
  outputs: |
    [OUTPUT]
        Name es
        Match kube.*
        Host 1.1.1.1
        Port 9200
        HTTP_User elastic
        HTTP_Passwd elastic123
        Logstash_Format On
        #Logstash_Prefix logstash-
        Logstash_Prefix_Key $es_index
        Logstash_DateFormat %Y-%m-%d
        Suppress_Type_Name On
        Retry_Limit False

  customParsers: |
    [PARSER]
        Name docker_no_time
        Format json
        Time_Keep Off
        Time_Key time
        Time_Format %Y-%m-%dT%H:%M:%S.%L
    [MULTILINE_PARSER]
        name multiline_stacktrace_parser
        type regex
        flush_timeout 1000
        rule "start_state"      "/\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}.*/" "exception_name"
        rule "exception_name"   "/(\w+\.)+\w+: .*/"                        "cont"
        rule "cont"             "/^\s+at.*/"                               "cont"

  extraFiles:
      # custom lua file
      fluentbit.lua: |
        function set_index(tag, timestamp, record)
            prefix = "logstash-uat"
            if record["kubernetes_container_name"] ~= nil then
                project_initial_name = record["kubernetes_container_name"]
                project_name, _ = string.gsub(project_initial_name, '-', '_')
                record["es_index"] = prefix .. "_" .. project_name
                return 1, timestamp, record
            end
            return 1, timestamp, record
        end
```

#### Configuration and Startup

```bash
# config
cat > values.yaml << "EOF"
config:
  service: |
    [SERVICE]
        Daemon Off
        Flush {{ .Values.flush }}
        Log_Level {{ .Values.logLevel }}
        Parsers_File parsers.conf
        Parsers_File custom_parsers.conf
        HTTP_Server On
        HTTP_Listen 0.0.0.0
        HTTP_Port {{ .Values.metricsPort }}
        Health_Check On
  inputs: |
    [INPUT]
        Name tail
        Path /var/log/containers/public*.log
        Exclude_path *fluent-bit-*,*fluentbit-*,*rancher-*,*cattle-*,*sysctl-*
        multiline.parser docker, cri
        Tag kube.*
        # specify the maximum memory used by the tail plugin; if the limit is reached, the plugin stops collecting and resumes after flushing data
        Mem_Buf_Limit 15MB
        # initial buffer size
        Buffer_Chunk_Size 1M
        # maximum buffer size per file
        Buffer_Max_Size 5M
        # skip lines longer than Buffer_Max_Size; if Skip_Long_Lines is set to Off, collection stops when encountering oversized lines
        Skip_Long_Lines On
        # skip empty lines
        Skip_Empty_Lines On
        # log file monitoring refresh interval
        Refresh_Interval 10
        # for files without a database offset position record, read from the beginning of the file; large log files may cause high fluent memory usage and OOMKill
        #Read_from_Head On
  filters: |
    [FILTER]
        Name kubernetes
        Match kube.*
        # when source logs come from the tail plugin, specify the prefix value used by the tail plugin
        Kube_Tag_Prefix kube.var.log.containers.
        # parse JSON content in the log field, extract to root level, append to the field specified by Merge_Log_Key
        Merge_Log Off
        # whether to keep the original log field after merging
        Keep_Log Off
        # allow Kubernetes Pods to suggest predefined parsers
        K8S-Logging.Parser Off
        # allow Kubernetes Pods to exclude their logs from the log processor
        K8S-Logging.Exclude Off
        # whether to include Kubernetes resource label information in additional metadata
        Labels Off
        # whether to include Kubernetes resource information in additional metadata
        Annotations Off
    # nest filter adds kubernetes_ prefix to fields of logs containing pod_name
    [FILTER]
        Name         nest
        Match        kube.*
        Wildcard     pod_name
        Operation    lift
        Nested_under kubernetes
        Add_prefix   kubernetes_
    # modify filter adjusts some kubernetes metadata field names and appends additional fields
    [FILTER]
        # use modify filter
        Name modify
        Match kube.*
        # rename the log field to message
        Rename log message
        # rename the kubernetes_host field to host_ip
        Rename kubernetes_host host_ip
        # rename the kubernetes_pod_name field to host
        Rename kubernetes_pod_name host
        # remove all fields matching kubernetes_
        # Remove_wildcard kubernetes_
    # convert multiline error logs into a single line
    [FILTER]
        name multiline
        match kube.*
        multiline.key_content message
        multiline.parser multiline_stacktrace_parser
    # custom lua function filter to set the ES index name field
    [FILTER]
        Name    lua
        Match   kube.*
        script  /fluent-bit/etc/fluentbit.lua
        call    set_index
    # custom lua function filter to add local_time field for ES queries
    [FILTER]
        Name    lua
        Match   kube.*
        script  /fluent-bit/etc/add_local_time.lua
        call    add_local_time
  outputs: |
    # output to ES configuration
    [OUTPUT]
        Name es
        Match kube.*
        Host 1.1.1.1
        Port 9200
        HTTP_User elastic
        HTTP_Passwd es123
        Logstash_Format On
        Logstash_Prefix logstash-uat_
        Logstash_Prefix_Key $es_index
        Logstash_DateFormat %Y-%m-%d
        Suppress_Type_Name On
        Retry_Limit False
    [OUTPUT]
        Name forward
        Match kube.*
        Host 1.1.1.1
        Port 24224
        Compress gzip
    [OUTPUT]
        Name http
        Match kube.*
        Host 1.1.1.1
        Port 5999
        Format json_lines
    #[OUTPUT]
    #    name stdout
    #    Match kube.*
  customParsers: |
    [PARSER]
        Name docker_no_time
        Format json
        Time_Keep Off
        Time_Key time
        Time_Format %Y-%m-%dT%H:%M:%S.%L
    [MULTILINE_PARSER]
        name multiline_stacktrace_parser
        type regex
        flush_timeout 1000
        rule "start_state"      "/\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}.*/" "exception_name"
        rule "exception_name"   "/(\w+\.)+\w+: .*/"                        "cont"
        rule "cont"             "/^\s+at.*/"                               "cont"
  extraFiles:
      fluentbit.lua: |
        function set_index(tag, timestamp, record)
            prefix = "logstash-uat"
            if record["kubernetes_container_name"] ~= nil then
                project_initial_name = record["kubernetes_container_name"]
                project_name, _ = string.gsub(project_initial_name, '-', '_')
                record["es_index"] = prefix .. "_" .. project_name
                return 1, timestamp, record
            end
            return 1, timestamp, record
        end
        function filter_error_log(tag, timestamp, record)
            if string.find(string.lower(record["message"] or ""), "%[error") then
                record["severity"] = "ERROR"
            end
            return 1, timestamp, record
        end
      add_local_time.lua: |
        function add_local_time(tag, timestamp, record)
           --local os_date = os.date("%Y-%m-%dT%H:%M:%SZ")
           local os_date = os.date("%Y-%m-%dT00:00:00.000Z")
           record["local_time"] = os_date
           return 1, timestamp, record
        end
logLevel: info
EOF

# start
helm -n logging install fluent-bit-uat .
```

**Quick deployment of fluent-bit & ES services (for testing environments only)**

```bash
kubectl create -f https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/output/elasticsearch/fluent-bit-ds.yaml
```

### OUTPUT Plugin Service Configuration

#### Elasticsearch Configuration

```bash
# elasticsearch deployment configuration: omitted


# ES tuning configuration
# 1. define the index name for writes; the index name is defined in fluent-bit before writing
# 2. install tokenizer plugin
./bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v8.4.3/elasticsearch-analysis-ik-8.4.3.zip
# 3. create index template: set replicas, shards, and lifecycle policy
curl -X PUT 'http://elasticsearch:9200/_template/logstash_template' \
-H 'Content-Type: application/json' \
-d '{
        "order": 100,
        "version": 8010099,
        "index_patterns": [
            "logstash-*"
        ],
        "settings": {
            "index": {
                "max_result_window": "1000000",
                "refresh_interval": "5s",
                "number_of_shards": "1",
                "number_of_replicas": "0",
                "lifecycle.name": "7-days-default",
                "lifecycle.rollover_alias": "7-days-default"
            }
        },
        "mappings": {
            "dynamic_templates": [
                {
                    "message_field": {
                        "path_match": "message",
                        "mapping": {
                            "norms": false,
                            "analyzer": "ik_max_word"
                        },
                        "match_mapping_type": "string"
                    }
                },
                {
                    "string_fields": {
                        "mapping": {
                            "analyzer": "ik_max_word",
                            "fields": {
                                "keyword": {
                                    "ignore_above": 256,
                                    "type": "keyword"
                                }
                            }
                        },
                        "match_mapping_type": "string",
                        "match": "*"
                    }
                }
            ],
            "properties": {
                "@timestamp": {
                    "type": "date"
                },
                "geoip": {
                    "dynamic": true,
                    "properties": {
                        "ip": {
                            "type": "ip"
                        },
                        "latitude": {
                            "type": "half_float"
                        },
                        "location": {
                            "type": "geo_point"
                        },
                        "longitude": {
                            "type": "half_float"
                        }
                    }
                },
                "local_time": {
                    "type": "date"
                },
                "@version": {
                    "type": "keyword"
                }
            }
        },
        "aliases": {}
    }'

```

#### Logstash Configuration

```bash
# download and decompress
cd /opt
wget https://artifacts.elastic.co/downloads/logstash/logstash-8.4.3-linux-x86_64.tar.gz
tar xf logstash-8.4.3-linux-x86_64.tar.gz && rm -f logstash-8.4.3-linux-x86_64.tar.gz

# configure
mkdir -p config/conf.d/
cat > config/conf.d/logstash.conf << "EOF"
# filebeat input
input {
    beats {
      port => 5044
    }
}
# http input
input {
  http {
    host => "0.0.0.0"
    port => 5999
    additional_codecs => {"application/json"=>"json"}
    codec => json {charset=>"UTF-8"}
    ssl => false
  }
}
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
output {
    #stdout { codec => rubydebug }

    # fluent-bit backup
    if [user_agent][original] == "Fluent-Bit" {
      file {
          path => "/opt/backup_logs/%{backup_time}/%{host_ip}_%{index_name}/%{index_name}.gz"
          gzip => true
          codec =>  line {
              format => "[%{index_name} -->| %{message}"
              }
          }
    }
    # filebeast log to es
    if [agent][type] == "filebeat" {
      elasticsearch {
        hosts => ["http://1.1.1.1:9200"]
        user => elastic
        password => "es123"
        index => "logstash-uat_%{index_name}-%{local_time}"
      }
    }
}
```

> Reference:
>
> 1. [Official Website](https://www.fluentd.org/)
> 2. [Repository](https://github.com/fluent/fluentd)
> 3. [fluentd-beat plugin](https://github.com/repeatedly/fluent-plugin-beats)
> 4. [Fluentd-bit](https://fluentbit.io/)
> 5. [Fluentd-bit Repository](https://github.com/fluent/fluent-bit)
