---
description: Database CLI references for ClickHouse, Elasticsearch, MongoDB, MySQL, PostgreSQL, Redis, and TiDB
tags:
  - devops/command
  - database
---

# Database

> Tip: passing passwords on the command line (`-a`, `--password`, `-p`) leaks them into shell history and `ps`. Prefer environment variables: `MYSQL_PWD`, `PGPASSWORD`, `REDISCLI_AUTH`, or interactive prompts.

## ClickHouse

```bash
# Client
clickhouse-client -h <host> --port 9000 -m -u default --password <password>
clickhouse-client -h <host> --port 9000 -m -u default --password <password> -q "SELECT cluster, shard_num, replica_num, host_name, port FROM system.clusters"

# Import / export data
clickhouse-client -h <host> --port 9000 -m -u default --password <password> --query "SELECT * FROM mydb.mytable FORMAT TSV" > /tmp/mytable.tsv
cat /tmp/mytable.tsv | clickhouse-client -h <host> --port 9000 -m -u default --password <password> --query "INSERT INTO mydb.mytable FORMAT TSV"

# HTTP API
## Select
curl -u "default:<password>" "http://<host>:8123" --data-binary "SELECT cluster,shard_num,replica_num,host_name,port FROM system.clusters"
curl -u "default:<password>" "http://<host>:8123" --data-binary "SELECT * FROM system.zookeeper WHERE path IN ('/', '/clickhouse')"
curl -u "default:<password>" "http://<host>:8123" --data-binary "SELECT * FROM default.tablex_all"
## Insert
curl -X POST -u "default:<password>" "http://<host>:8123" --data-binary "INSERT INTO default.tablex_all (key1,key2) values ('xxx',111)"
```

```sql
-- Create distributed table
CREATE DATABASE IF NOT EXISTS mydb ON CLUSTER cluster_2s_2r;
-- Local table
CREATE TABLE IF NOT EXISTS mydb.mytable_local ON CLUSTER cluster_2s_2r
(
    id UInt32,
    name String,
    create_date Date
) ENGINE = ReplicatedMergeTree('/clickhouse/tables/{database}/{table}/{shard}', '{replica}')
PARTITION BY toYYYYMM(create_date)
ORDER BY id;
-- Distributed table
CREATE TABLE IF NOT EXISTS mydb.mytable_distributed ON CLUSTER cluster_2s_2r
(
    id UInt32,
    name String,
    create_date Date
) ENGINE = Distributed('cluster_2s_2r', 'mydb', 'mytable_local', rand());

-- Drop tables
DROP TABLE mydb.mytable_distributed ON CLUSTER cluster_2s_2r;
DROP TABLE mydb.mytable_local ON CLUSTER cluster_2s_2r;
DROP DATABASE mydb ON CLUSTER cluster_2s_2r;
```

## Elasticsearch

```bash
# All RESTful APIs
curl http://localhost:9200/_cat
curl -u "elastic:<password>" http://localhost:9200/_cat

# Index lifecycle
## Create lifecycle
curl http://localhost:9200/_ilm/policy/my-index-policy -X PUT -H 'Content-Type: application/json' \
-d '{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "alias": {
            "hot_alias": {}
          },
          "rollover": {
            "max_primary_shard_size": "50gb",
            "max_age": "30d"
          },
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
## Query lifecycle
curl http://localhost:9200/_ilm/policy
curl http://localhost:9200/_ilm/policy/my-index-policy
curl http://localhost:9200/my-index-2024-01-01/_ilm/explain

# Index template
## Create template
curl http://localhost:9200/_template/my-index-template -X PUT -H 'Content-Type: application/json' \
-d '{
  "index_patterns": ["my-index-*"],
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 1,
    "index.lifecycle.name": "my-index-policy",
    "index.lifecycle.rollover_alias": "my-index-alias"
  },
  "mappings": {}
}'
## Query template
curl http://localhost:9200/_template/my-index-template

# Index and shard
## Create index
curl http://localhost:9200/my-index-2024-01-01 -X PUT -H 'Content-Type: application/json' \
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
## Query index
curl http://localhost:9200/_cat/indices?pretty
curl http://localhost:9200/_cat/indices | awk '{print $3}' | sort -rn | uniq
curl http://localhost:9200/my-index-2024-01-01?pretty
curl http://localhost:9200/my-index-2024-01-01/_settings?pretty
curl http://localhost:9200/my-index-2024-01-01/_mappings?pretty
## Query shard
curl http://localhost:9200/_cat/shards?pretty
## Batch delete index
curl http://localhost:9200/_cat/shards -u "elastic:<password>" | awk '{print $1}' | sort -rn | uniq | grep -v "^\." | grep 2024-01 > /tmp/index.tmp
while read -r idx; do curl -X DELETE -u "elastic:<password>" "http://localhost:9200/$idx"; done < /tmp/index.tmp

# Index search
time curl -X POST "http://localhost:9200/index/_search" \
  -H 'Content-Type: application/json' \
  -d '{
    "version": true,
    "size": 50,
    "from": 0,
    "sort": [{"@timestamp": {"order": "desc", "unmapped_type": "boolean"}}],
    "query": {
      "bool": {
        "must": [],
        "must_not": [],
        "filter": {
          "bool": {
            "must": [{"range": {"@timestamp": {"gte": 1663209126805, "lte": 1663209726805, "format": "epoch_millis"}}}],
            "must_not": [],
            "should": []
          }
        }
      }
    },
    "highlight": {
      "pre_tags": ["@kibana-highlighted-field@"],
      "post_tags": ["@/kibana-highlighted-field@"],
      "fields": {"message": {}},
      "fragment_size": 2147483647
    }
  }'

# Misc
## Resolve license error
curl -X POST http://localhost:9200/_license/start_basic?acknowledge=true
```

## MongoDB

```bash
# Connect
# mongosh "mongodb://<username>:<password>@<host>:<port>/<database>"
mongosh "mongodb://<host>:<port>" --username root
```

```javascript
// Usage
use mydb
db.myCollection.insertOne({ name: "xxx", age: 333 })
db.myCollection.find()
db.myCollection.updateOne({ name: "xxx" }, { $set: { age: 555 } })
db.myCollection.deleteOne({ name: "xxx" })
```

## MySQL

```bash
# Init / reset password
mysql -u root -p
mysql -u root --skip-password
```

```sql
-- Reset root password
ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';

-- Create database with character set
CREATE DATABASE mydatabase DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

-- Create account and grant
USE mysql;
-- CREATE USER 'readonly'@'%' IDENTIFIED WITH mysql_native_password BY 'readonly_password';
CREATE USER 'readonly'@'%' IDENTIFIED BY 'readonly_password';
GRANT SELECT, PROCESS, REPLICATION CLIENT ON *.* TO 'readonly'@'%';
CREATE USER 'app'@'10.%' IDENTIFIED BY 'app_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON `db_a`.* TO 'app'@'10.%';
GRANT SELECT, INSERT, UPDATE, DELETE ON `db_b`.* TO 'app'@'10.%';
FLUSH PRIVILEGES;
SELECT user, host, authentication_string, plugin FROM mysql.user WHERE user='readonly';

-- Variables
SHOW PROCESSLIST;
SHOW STATUS LIKE 'Threads_connected';
SHOW VARIABLES LIKE 'max_connections';
SET GLOBAL max_connections = 3000;

-- Role
-- Create roles
CREATE ROLE 'user_ro_role';
CREATE ROLE 'user_rw_role';
CREATE ROLE 'user_admin_role';
-- Grant permission
GRANT SELECT ON user_info.* TO 'user_ro_role';
GRANT SELECT, INSERT, UPDATE, DELETE ON user_info.* TO 'user_rw_role';
GRANT ALL PRIVILEGES ON user_info.* TO 'user_admin_role';
-- Create real user
CREATE USER 'readonly'@'%' IDENTIFIED BY 'your_password';
GRANT 'user_ro_role' TO 'readonly'@'%';
SET DEFAULT ROLE 'user_ro_role' TO 'readonly'@'%';
CREATE USER 'operator'@'%' IDENTIFIED BY 'your_password';
GRANT 'user_rw_role' TO 'operator'@'%';
SET DEFAULT ROLE 'user_rw_role' TO 'operator'@'%';
```

## PostgreSQL

```bash
# Connect
psql -U user [-d database]
psql -h pghost -U admin -d mydb
```

```sql
-- Client meta-commands
-- Show connection info
\conninfo
-- Switch database
\c mydb
\connect mydb
\c mydb readonly
-- Show all users
\du
-- Show role permissions
\du readonly
-- Show all databases
\l
\list
\l+
-- Show all schemas
\dn
\dn+
-- Show database tables
\dt
\dt public.*
-- Show table schema (columns, indexes, constraints)
\d table_name
-- Show view
\dv
-- Show materialized view
\dm
-- Show index
\di
-- Show table permissions
\z table_name
-- Show schema permissions
\z public.*
-- Show functions
\df
\df+ func_name
-- Show sequences
\ds
-- Show current sequence value
SELECT last_value FROM seq_name;
-- Execute SQL file
\i /path/to/file.sql
-- Display
\x auto
\t on
\timing on

-- Users and Roles
-- Create admin
CREATE ROLE admin_role NOLOGIN;
CREATE USER admin WITH PASSWORD 'secure_password_3';
GRANT admin_role TO admin;
-- Create app
CREATE ROLE app_role NOLOGIN;
CREATE USER app WITH PASSWORD 'secure_password_2';
GRANT app_role TO app;
-- Create readonly
CREATE ROLE readonly_role NOLOGIN;
CREATE USER readonly WITH PASSWORD 'secure_password_1';
GRANT readonly_role TO readonly;

-- Create database
-- CREATE DATABASE mydb OWNER app;
CREATE DATABASE mydb;

-- Grant current permissions (connect first: psql -h pghost -U admin -d mydb)
-- Admin: DDL
GRANT ALL PRIVILEGES ON SCHEMA public TO admin_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_role;
-- App: DML
GRANT CONNECT ON DATABASE mydb TO app_role;
GRANT USAGE ON SCHEMA public TO app_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_role;
-- Readonly: SELECT
GRANT CONNECT ON DATABASE mydb TO readonly_role;
GRANT USAGE ON SCHEMA public TO readonly_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_role;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO readonly_role;


-- Grant future permissions (default privileges)
-- Admin
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL PRIVILEGES ON TABLES TO admin_role;
-- App
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO app_role;
-- Readonly
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO readonly_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON SEQUENCES TO readonly_role;
```

## Redis

```bash
# Common
# redis-cli [-h host] [-p port] [-a password] [-c]
## Examples
cat /etc/passwd | redis-cli -x set mypasswd
redis-cli -D "" --raw dump key > key.dump && redis-cli -X dump_tag restore key2 0 dump_tag replace < key.dump
redis-cli -r 100 lpush mylist x
redis-cli -r 100 -i 1 info | grep used_memory_human:
redis-cli --quoted-input set '"null-\x00-separated"' value
redis-cli --eval myscript.lua key1 key2 , arg1 arg2 arg3
redis-cli --scan --pattern '*:12345*'
## Batch delete keys (xargs batches keys into one DEL per chunk)
redis-cli -h <host> -a <password> --scan --pattern "mykey*" | xargs redis-cli -h <host> -a <password> del

# Cluster mode (-c follows -ASK and -MOVED redirections)
redis-cli -h <host> -p <port> -a <password> -c CLUSTER NODES
redis-cli -h <host> -p <port> -a <password> -c CLUSTER INFO
redis-cli -h <host> -p <port> -a <password> -c CLUSTER FORGET <node-id>

# Cluster Manager command
redis-cli --cluster help
redis-cli --cluster create 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 --cluster-replicas 0
redis-cli --cluster check 127.0.0.1:7001
redis-cli --cluster reshard 127.0.0.1:7001
redis-cli --cluster rebalance 127.0.0.1:7001
```

## TiDB

```bash
# Deploy cluster
tiup playground
tiup cluster deploy <cluster-name> <version> topology.yaml

# Cluster management
tiup cluster list
tiup cluster display <cluster-name>
tiup cluster start <cluster-name>
tiup cluster stop <cluster-name>
tiup cluster restart <cluster-name>
tiup cluster scale-out <cluster-name> scale-out.yaml
tiup cluster scale-in <cluster-name> --node <node-id>

# Backup and restore
tiup br backup full --pd <pd-addr> --storage "s3://bucket/backup"
tiup br restore full --pd <pd-addr> --storage "s3://bucket/backup"
```

> Reference:
>
> 1. [ClickHouse Documentation](https://clickhouse.com/docs)
> 2. [Elasticsearch Documentation](https://www.elastic.co/guide/)
> 3. [MongoDB Documentation](https://www.mongodb.com/docs/manual/)
> 4. [MySQL Documentation](https://dev.mysql.com/doc/)
> 5. [PostgreSQL Documentation](https://www.postgresql.org/docs/)
> 6. [Redis Documentation](https://redis.io/docs/)
> 7. [TiDB Documentation](https://docs.pingcap.com/)
