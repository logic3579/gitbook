# Database

## clickhouse
```bash
# client
clickhouse-client -h clickhouse --port 9000 -m -u root --password pwd123
clickhouse-client -h clickhouse --port 9000 -m -u root --password pwd123 -q "select * from default.tablex_all"


# http api
curl -u "user:pwd123" "http://http://clickhouse.com:8123" --data-binary "select * from default.tablex_all" -i

curl -X POST -u "user:pwd123" "http://clickhouse.com:8123" --data-binary "insert into default.tablex_all (key1,key2) values ('xxx',111) " -i
```

## elasticsearch
```bash
# 查看所有 restful api
curl http://es_server:9200/_cat -u "elastic:es123"
# Basic auth 认证头
-u 'elastic:es123'

# 创建索引
curl http://es_server:9200/index_name -X PUT -H'content-type: application/json' \
-d '{
    "settings": {
        "index": {
            "lifecycle": {
                "name": "yakir_test_policy"
            },
            "number_of_shards": "1",
            "number_of_replicas": "0"
        }
    }
}'
# 查看 es 所有索引
curl http://es_server:9200/_cat/indices?pretty
# 查看 es 所有分片
curl http://es_server:9200/_cat/shards
# 查看索引配置信息
curl http://es_server:9200/index_name/_settings?pretty
# 查看索引映射信息
curl http://es_server:9200/index_name/_mappings
# 查看所有索引
curl http://es_server:9200/_cat/indices |awk '{print $3}' |sort -rn |uniq
# 查看所有索引分片
curl http://es_server:9200/_cat/shards -u "elastic:es123" |awk '{print $1}' |sort -rn |uniq |grep -v "\." > /tmp/index.tmp


# 查看索引模板配置信息
curl http://es_server:9200/_template/logstash_template
# 创建索引/索引模板，默认分片、副本数规则、映射等
curl http://es_server:9200/_template/logstash_template -X PUT -H 'Content-Type: application/json' \
-d '{
	"index_patterns": ["logstash-*"],
	"settings": {
		"number_of_shards": 1,
		"number_of_replicas": 0
		"index.lifecycle.name": "mylifeycle"
		"index.lifecycle.rollover_alias": "myindex-alias"
	}
	...
}' 

# 删除索引/分片
curl http://es_server:9200/_cat/shards |grep xxx |awk '{print $1}' > /tmp/index.tmp
for i in `cat /tmp/index.tmp`
do
     curl -X DELETE http://es_server:9200/$i -u "elastic:es123"
done


# 查看生命周期策略信息
curl http://es_server:9200/_ilm/policy
curl http://es-server:9200/_ilm/policy/policy_name
# 查看索引生命周期策略信息
curl http://es_server:9200/index_name/_ilm/explain
# 新增自定义生命周期策略
curl http://es_server:9200/_ilm/policy/logstash_delete_policy -X PUT -H'content-type: application/json' \
-d '{
    "policy": {
      "phases": {
        "hot": {
          "min_age": "0ms",
          "actions": {
            "rollover": {
              "max_primary_shard_size": "50gb",
              "max_age": "3d",
              "max_docs": 10
            },
            "set_priority": {
              "priority": "100"
            },
            "alias": {
              "hot_alias": {}
            }
          }
        },
        "warm": {
          "min_age": "1m",
          "actions": {
            "shrink": {
              "number_of_shards": 1
            },
            "forcemerge": {
              "max_num_segments": 1
            },
            "allocate": {
              "number_of_replicas": 0
            },
            "set_priority": {
              "priority": "50"
            }
          }
        },
        "cold": {
          "min_age": "3m",
          "actions": {
            "set_priority": {
              "priority": "0"
            }
          }
        },
        "delete": {
          "min_age": "5m",
          "actions": {
            "delete": {
              "delete_searchable_snapshot": true
            }
          }
        }
      }
    }
}'


# 搜索数据
time curl -X POST "http://es-server:9200/index/_search" -d '{"version":true,"size":50,"sort":[{"@timestamp":{"order":"desc","unmapped_type":"boolean"}}],"_source":{"excludes":[]},"stored_fields":["*"],"script_fields":{},"docvalue_fields":["@timestamp","local_time"],"query":{"bool":{"must":[],"must_not":[],"filter":{"bool":{"must":[{"range":{"@timestamp":{"gte":1663209126805,"lte":1663209726805,"format":"epoch_millis"}}}],"must_not":[],"should":[]}}}},"highlight":{"pre_tags":["@kibana-highlighted-field@"],"post_tags":["@/kibana-highlighted-field@"],"fields":{"message":{}},"fragment_size":2147483647},"from":0}' -H'Content-Type: application/json'


# licence 过期报错解决方法
curl -X POST 127.0.0.1:9200/_license/start_basic?acknowledge=true
```

## mysql
```bash
# init reset password
mysql -u root -p
mysql -u root --skip-password
ALTER USER 'root'@'localhost' IDENTIFIED BY 'root-password';

# create database with character
CREATE DATABASE yakir_test DEFAULT CHARACTER SET utf8mb4 COLLATE utf8_general_ci;

# create account and grant
use mysql
CREATE USER 'new_user'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'new_user'@'localhost';
GRANT ALL PRIVILEGES ON *.* TO 'new_user'@'%';
FLUSH PRIVILEGES;


```

## postgres
```bash
# login
psql -U user [-d database]

# create user,database and grant privileges
CREATE USER yakirtest WITH PASSWORD 'yakirtest';
CREATE DATABASE yakirtest OWNER yakirtest;
GRANT ALL PRIVILEGES ON DATABASE yakirtest TO yakirtest;
GRANT ALL PRIVILEGES ON all tables in schema public TO yakirtest;

# select all database
\l

# switch database
\c database

# select custom table and table schema
\d
\d table;

# select all scheme
select * from information_schema.schemata;

# select all tables
select * from pg_tables;

```

## redis
```bash
# common
# redis-cli [-h host] [-p port] [-a password] [-c]
# Examples:
  cat /etc/passwd | redis-cli -x set mypasswd
  redis-cli -D "" --raw dump key > key.dump && redis-cli -X dump_tag restore key2 0 dump_tag replace < key.dump
  redis-cli -r 100 lpush mylist x
  redis-cli -r 100 -i 1 info | grep used_memory_human:
  redis-cli --quoted-input set '"null-\x00-separated"' value
  redis-cli --eval myscript.lua key1 key2 , arg1 arg2 arg3
  redis-cli --scan --pattern '*:12345*'
# Batch delete key
redis-cli -h redis_host -a redis_password --scan --pattern "mykey*" |xargs -I {} redis-cli  -h host -a redis_password del {}


# -c Enable cluster mode (follow -ASK and -MOVED redirections).
redis-cli -h redis_host -p redis_port -a redis_password -c CLUSTER NODES
redis-cli -h redis_host -p redis_port -a redis_password -c CLUSTER INFO
redis-cli -h redis_host -p redis_port -a redis_password -c CLUSTER FORGET xxx


# Cluster Manager command and arguments
redis-cli --cluster help
redis-cli --cluster create 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 --cluster-replicas 0
redis-cli --cluster check 127.0.0.1:7001
redis-cli --cluster reshard 127.0.0.1:7001
redis-cli --cluster rebalance 127.0.0.1:7001
```
