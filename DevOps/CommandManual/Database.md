# Database

## ClickHouse

```bash
# Client
clickhouse-client -h clickhouse --port 9000 -m -u default --password pwd123
clickhouse-client -h clickhouse --port 9000 -m -u default --password pwd123 -q "SELECT cluster, shard_num, replica_num, host_name, port FROM system.clusters"
# import / export data
clickhouse-client -h clickhouse --port 9000 -m -u default --password pwd123 --query "SELECT * FROM mydb.mytable FORMAT TSV" > /tmp/mytable.tsv
cat /tmp/mytable.tsv | clickhouse-client -h clickhouse --port 9000 -m -u default --password pwd123 --query "INSERT INTO mydb.mytable FORMAT TSV"

# HTTP API
## select
curl -u "default:default_pwd" "http://clickhouse.com:8123" --data-binary "SELECT cluster,shard_num,replica_num,host_name,port FROM system.clusters"
curl -u "default:default_pwd" "http://clickhouse.com:8123" --data-binary "SELECT * FROM system.zookeeper WHERE path IN ('/', '/clickhouse')"
curl -u "default:default_pwd" "http://clickhouse.com:8123" --data-binary "SELECT * FROM default.tablex_all"
## insert
curl -X POST -u "default:default_pwd" "http://clickhouse.com:8123" --data-binary "INSERT INTO default.tablex_all (key1,key2) values ('xxx',111) "

# Created distributed table
CREATE DATABASE IF NO EXISTS mydb ON CLUSTER cluster_2s_2r;
# local table
CREATE TABLE IF NOT EXISTS mydb.mytable_local ON CLUSTER cluster_2s_2r
(
    id UInt32,
    name String,
    create_date Date
) ENGINE = ReplicatedMergeTree('/clickhouse/tables/{database}/{table}/{shard}', '{replica}')
PARTITION BY toYYYYMM(create_date)
ORDER BY id;
# distributed table
CREATE TABLE IF NOT EXISTS mydb.mytable_distributed ON CLUSTER cluster_2s_2r
(
    id UInt32,
    name String,
    data Date
) ENGINE = Distributed('cluster_2s_2r', 'mytable_local', rand());

# Delete distributed table
DROP TABLE mydb.mytable_distributed ON CLUSTER cluster_2s_2r;
DROP TABLE mydb.mytable_local ON CLUSTER cluster_2s_2r;
DROP DATABASE mydb ON CLUSTER cluster_2s_2r;
```

## Elasticsearch

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
    "FROM":0
  }'


# misc
# resolve license error
curl -X POST http://localhost:9200/_license/start_basic?acknowledge=true
```

## MongoDB

```bash
# connect
# mongosh "mongodb://<username>:<password>@<host>:<port>/<database>"
mongosh "mongodb://<host>:<port>" --username root

# usage
use mydb
db.myCollection.insertOne({ name: "xxx", age: 333 })
db.myCollection.find()
db.myCollection.updateOne({ name: "xxx" }, { $set: { age: 555 } })
db.myCollection.deleteOne({ name: "xxx" })
```

## MySQL

```bash
# Init reset password
mysql -u root -p
mysql -u root --skip-password
ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';

# Create database with character
CREATE DATABASE mydatabase DEFAULT CHARACTER SET utf8mb4 COLLATE utf8_general_ci;

# Create account and grant
use mysql
#CREATE USER 'readonly'@'%' IDENTIFIED WITH mysql_native_password BY 'readonly_password';
CREATE USER 'readonly'@'%' IDENTIFIED BY 'readonly_password';
GRANT SELECT, PROCESS, REPLICATION CLIENT ON *.* TO 'readonly'@'%';
CREATE USER 'app'@'10.%' IDENTIFIED BY 'app_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON `db_a`.* TO 'app'@'10.%';
GRANT SELECT, INSERT, UPDATE, DELETE ON `db_b`.* TO 'app'@'10.%';
FLUSH PRIVILEGES;
SELECT user, host, authentication_string, plugin FROM mysql.user WHERE user='readonly';

# Variable
SHOW PROCESSLIST;
SHOW STATUS LIKE 'Threads_connected';
SHOW VARIABLES LIKE 'max_connections';
SET GLOBAL max_connections = 3000;

# Role
## create roles
CREATE ROLE 'user_ro_role';
CREATE ROLE 'user_rw_role';
CREATE ROLE 'user_admin_role';
## grant permission
GRANT SELECT ON user_info.* TO 'user_ro_role';
GRANT SELECT, INSERT, UPDATE, DELETE ON user_info.* TO 'user_rw_role';
GRANT ALL PRIVILEGES ON user_info.* TO 'user_admin_role';
## create real user
CREATE USER 'readonly'@'%' IDENTIFIED BY 'your_password';
GRANT 'user_ro_role' TO 'readonly'@'%';
SET DEFAULT ROLE 'user_ro_role' TO 'readonly_user1'@'%';
CREATE USER 'operator'@'%' IDENTIFIED BY 'your_password';
GRANT 'user_rw_role' TO 'operator'@'%';
SET DEFAULT ROLE 'user_rw_role' TO 'operator'@'%';

# View
```

## PostgreSQL

```sql
--- client command
--- login
psql -U user [-d database]
--- show connect
\conninfo
--- switch database
\c mydb
\connect mydb
\c mydb readonly
--- switch custom table and table schema
\d table;
--- show all users
\du
--- show roles permission
\du readonly
--- show all databases
\l
\list
\l+
--- show all scheme
\dn
\dn+
--- show database tables
\dt
\dt.public.*
--- show table schema
\d table_name
--- show view
\dv
--- show meterialized view
\dm
--- show index/constraint
\di
\d table_name
--- show table permission
\z table_name
--- show schema permission
\z public.*
--- show function
\df
\df+ func_name
--- show sequences
\ds
--- show current sequences value
SELECT last_value FROM seq_name;
--- execute sql
\i /path/to/file.sql
--- display
\x auto
\t on
\timing on


--- create user and role
--- admin
CREATE ROLE admin_role NOLOGIN;
CREATE USER admin WITH PASSWORD 'secure_password_3';
GRANT admin_role TO admin;
--- app
CREATE ROLE app_role NOLOGIN;
CREATE USER app WITH PASSWORD 'secure_password_2';
GRANT app_role TO app;
--- readonly
CREATE ROLE readonly_role NOLOGIN;
CREATE USER readonly WITH PASSWORD 'secure_password_1';
GRANT readonly_role TO readonly;


--- create database
---CREATE DATABASE mydb OWNER app;
CREATE DATABASE mydb;


--- grant current permission
\c mydb;
--- admin: DDL
GRANT ALL PRIVILEGES ON SCHEMA public TO admin_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_role;
--- app: DML
GRANT CONNECT ON DATABASE mydb TO app_role;
GRANT USAGE ON SCHEMA public TO app_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_role;
--- readonly: SELECT
GRANT CONNECT ON DATABASE mydb TO readonly_role;
GRANT USAGE ON SCHEMA public TO readonly_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_role;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO app_role;


--- grant future permission
psql -h YOUR_HOST -U admin_role -d mydb
--- admin
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL PRIVILEGES ON TABLES TO admin_role;
--- app
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO app_role;
--- readonly
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO readonly_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON SEQUENCES TO readonly_role;
```

## Redis

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

## TiDB

```bash
tiup
```
