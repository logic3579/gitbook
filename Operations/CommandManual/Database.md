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
# all restful api
curl http://localhost:9200/_cat
curl -u "elastic:pwd" http://localhost:9200/_cat


# index lifecycle
# create lifecycle
curl http://localhost:9200/_ilm/policy/my-index-policy -X PUT -H'content-type: application/json' \
-d '{
    "policy": {
      "phases": {
        "hot": {
          "min_age": "0ms",
          "actions": {
            #"alias": {
            #  "hot_alias": {}
            #},
            #"rollover": {
            #  "max_primary_shard_size": "50gb",
            #  "max_age": "30d"
            #},
            "set_priority": {
              "priority": "100"
            }
          }
        },
        "warm": {
          "min_age": "7d",
          "actions": {
            "readonly": {},
            "forcemerge": {
              "max_num_segments": 1
            },
            "set_priority": {
              "priority": "50"
            }
          }
        },
        "cold": {
          "min_age": "15d",
          "actions": {
            "readonly": {},
            "set_priority": {
              "priority": "0"
            }
          }
        },
        "delete": {
          "min_age": "30d",
          "actions": {
            "delete": {
              "delete_searchable_snapshot": true
            }
          }
        }
      }
    }
}'
# query lifecycle
curl http://localhost:9200/_ilm/policy
curl http://localhost:9200/_ilm/policy/my-index-policy
curl http://localhost:9200/my-index-2024-01-01/_ilm/explain


# index template
# create template
curl http://localhost:9200/_template/my-index-template -X PUT -H 'Content-Type: application/json' \
-d '{
	"index_patterns": ["my-index-*"],
	"settings": {
		"number_of_shards": 1,
		"number_of_replicas": 1,
		"index.lifecycle.name": "my-index-policy",
		"index.lifecycle.rollover_alias": "my-index-alias"
	}
	"mappings": {}
}' 
# query template
curl http://localhost:9200/_template/my-index-template


# index and shard
# create index
curl http://localhost:9200/my-index-2024-01-01 -X PUT -H'content-type: application/json' \
-d '{
    "settings": {
        "index": {
            "lifecycle": {
                "name": "my-index-policy"
            },
            "number_of_shards": "1",
            "number_of_replicas": "1"
        }
    }
}'
# query index
curl http://localhost:9200/_cat/indices?pretty
curl http://localhost:9200/_cat/indices |awk '{print $3}' |sort -rn |uniq
curl http://localhost:9200/my-index-2024-01-01?pretty
curl http://localhost:9200/my-index-2024-01-01/_settings?pretty
curl http://localhost:9200/my-index-2024-01-01/_mappings?pretty
# query shard
curl http://localhost:9200/_cat/shards?pretty
# batch delete index/shard
curl http://localhost:9200/_cat/shards -u "elastic:pwd" |awk '{print $1}' |sort -rn |uniq |grep -v "^\." |grep 2024-01 > /tmp/index.tmp
for i in `cat /tmp/index.tmp`;do curl http://localhost:9200/$i -X DELETE -u "elastic:pwd"; done


# index search
time curl -X POST "http://localhost:9200/index/_search" \
  -H 'Content-Type: application/json' \
  -d '{
  "version":true,
  "size":50,
  "sort":[{"@timestamp":{"order":"desc","unmapped_type":"boolean"}}],
  "query":{
  "bool":{
    "must":[],
    "must_not":[],
    "filter":{
      "bool":{
        "must":[{"range":{"@timestamp":{"gte":1663209126805,"lte":1663209726805,"format":"epoch_millis"}}}],
        "must_not":[],
        "should":[]
      }
    }
  }
  },
  "highlight":{
    "pre_tags":["@kibana-highlighted-field@"],
    "post_tags":["@/kibana-highlighted-field@"],
    "fields":{"message":{}},
    "fragment_size":2147483647},
    "from":0
  }'


# misc
# resolve license error
curl -X POST http://localhost:9200/_license/start_basic?acknowledge=true
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

## tidb
```bash
tiup
```
