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

[Fluentd Config](/Operations/ServiceConf/fluentd.md)

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

**Fluent Bit** 是一个开源的多平台日志处理器工具，它旨在成为用于日志处理和分发的通用利器。
如今，系统中信息源数量正在不断增加。处理大规模数据非常复杂，收集和汇总各种数据需要一种专门的工具，该工具可以解决如下问题:

- 不同的数据源
- 不同的数据格式
- 数据可靠性
- 安全性
- 灵活的路由
- 多目的地
  Fluent Bit 在设计时就考虑了高性能和低资源消耗。

**Fluent Bit & Fluentd 区别**
Fluentd 和 Fluent Bit 都可以充当聚合器或转发器，它们可以互补使用或单独用作为解决方案。[详情](https://hulining.gitbook.io/fluentbit/about/fluentd-and-fluent-bit)

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

#### 相关概念

Kubernetes 管理 nodes 集群，因此我们的日志代理工具需要在每个节点上运行以从每个 POD 收集日志，因此 Fluent Bit 被部署为 DaemonSet(在集群的每个 node 上运行的 POD)。
当 Fluent Bit 运行时，它将读取，解析和过滤每个 POD 的日志，并将使用以下信息(元数据)丰富每条数据:

- Pod Name
- Pod ID
- Container Name
- Container ID
- Labels
- Annotations

#### 日志输出方式

当前集群环境容器日志都为 console 输出，分为两部分：

- 输出到 Elasticsearch，用于 Kibana 前台搜索日志。
- 输出到 forward 接口，接口由 fluentd 服务提供并持久化日志，本地存储15天，归档3个月日志到云存储（如 S3、GCS、OSS 等）。

#### helm 下载 charts 包

```bash
# 创建可观测性 chart 包目录
mkdir /opt/helm-charts/logging
cd /opt/helm-charts/logging

# 添加 helm 仓库，下载 fluent-bit charts 包
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
        # 指定tail插件使用的最大内存，如果达到限制，插件会停止采集，刷新数据后会恢复
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
        # 解析log字段的json内容，提取到根层级, 附加到Merge_Log_Key指定的字段上
        Merge_Log Off
        Keep_Log Off
        K8S-Logging.Parser Off
        K8S-Logging.Exclude Off
        Labels Off
        Annotations Off
    # nest过滤器主要是对包含pod_name的日志，在其字段中追加kubernetes_前缀
    [FILTER]
        Name         nest
        Match        kube.*
        Wildcard     pod_name
        Operation    lift
        Nested_under kubernetes
        Add_prefix   kubernetes_
    # modify过滤器主要是调整部分kubernetes元数据字段名，同时追加一些额外的字段
    [FILTER]
        Name modify
        Match kube.*
        # 将log字段重命名为message
        Rename log message
        # 移除冗余 kubernetes 字段数据
        Remove kubernetes_container_image
        Remove kubernetes_container_hash
    # 将错误日志由多行转为一行
    [FILTER]
        name multiline
        match kube.*
        multiline.key_content message
        multiline.parser multiline_stacktrace_parser
    # 自定义lua函数过滤，设置 es 索引名称字段
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
      # 自定义 lua 文件
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

#### 配置启动

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
        # 指定tail插件使用的最大内存，如果达到限制，插件会停止采集，刷新数据后会恢复
        Mem_Buf_Limit 15MB
        # 初始buffer size
        Buffer_Chunk_Size 1M
        # 每个文件的最大buffer size
        Buffer_Max_Size 5M
        # 跳过长度大于 Buffer_Max_Size 的行，Skip_Long_Lines 若设为Off遇到超过长度的行会停止采集
        Skip_Long_Lines On
        # 跳过空行
        Skip_Empty_Lines On
        # 监控日志文件 refresh 间隔
        Refresh_Interval 10
        # 采集文件没有数据库偏移位置记录的，从文件的头部开始读取，日志文件较大时会导致fluent内存占用率升高出现oomkill
        #Read_from_Head On
  filters: |
    [FILTER]
        Name kubernetes
        Match kube.*
        # 当源日志来自tail插件，用于指定tail插件使用的前缀值
        Kube_Tag_Prefix kube.var.log.containers.
        # 解析log字段的json内容，提取到根层级, 附加到Merge_Log_Key指定的字段上
        Merge_Log Off
        # 合并log字段后是否保持原始log字段
        Keep_Log Off
        # 允许Kubernetes Pod 建议预定义的解析器
        K8S-Logging.Parser Off
        # 允许Kubernetes Pod 从日志处理器中排除其日志
        K8S-Logging.Exclude Off
        # 是否在额外的元数据中包含 Kubernetes 资源标签信息
        Labels Off
        # 是否在额外的元数据中包括 Kubernetes 资源信息
        Annotations Off
    # nest过滤器主要是对包含pod_name的日志，在其字段中追加kubernetes_前缀
    [FILTER]
        Name         nest
        Match        kube.*
        Wildcard     pod_name
        Operation    lift
        Nested_under kubernetes
        Add_prefix   kubernetes_
    # modify过滤器主要是调整部分kubernetes元数据字段名，同时追加一些额外的字段
    [FILTER]
        # 使用modify过滤器
        Name modify
        Match kube.*
        # 将log字段重命名为message
        Rename log message
        # 将kubernetes_host字段重命名为host_ip
        Rename kubernetes_host host_ip
        # 将kubernetes_pod_name字段重命名为host
        Rename kubernetes_pod_name host
        # 移除所有匹配kubernetes_的字段
        # Remove_wildcard kubernetes_
    # 将错误日志由多行转为一行
    [FILTER]
        name multiline
        match kube.*
        multiline.key_content message
        multiline.parser multiline_stacktrace_parser
    # 自定义lua函数过滤，设置 es 索引名称字段
    [FILTER]
        Name    lua
        Match   kube.*
        script  /fluent-bit/etc/fluentbit.lua
        call    set_index
    # 自定义lua函数过滤，新增local_time字段，用于es查询
    [FILTER]
        Name    lua
        Match   kube.*
        script  /fluent-bit/etc/add_local_time.lua
        call    add_local_time
  outputs: |
    # 输出到 ES 相关配置
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

**快速部署 fluent-bit & es 服务（仅用于测试环境）**

```bash
kubectl create -f https://raw.githubusercontent.com/fluent/fluent-bit-kubernetes-logging/master/output/elasticsearch/fluent-bit-ds.yaml
```

### OUTPUT 插件服务相关配置

#### Elasticsearch 配置

```bash
# elasticsearch 部署配置：略


# ES 调整配置
# 1、写入的索引名称定义，通过 fluent-bit 写入前定义好 index 名称
# 2、分词器安装
./bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v8.4.3/elasticsearch-analysis-ik-8.4.3.zip
# 3、索引模板创建：副本数、分片、生命周期策略设置
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

#### Logstash 配置

```bash
# 下载解压
cd /opt
wget https://artifacts.elastic.co/downloads/logstash/logstash-8.4.3-linux-x86_64.tar.gz
tar xf logstash-8.4.3-linux-x86_64.tar.gz && rm -f logstash-8.4.3-linux-x86_64.tar.gz

# 配置
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
