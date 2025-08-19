# Mongodb

/etc/my.cnf
/opt/mysql/sysconfig/my.cnf

```bash
[client]
port=3306
socket=/opt/mysql/mysql.sock

[mysql]

[mysqld]
# default character
character-set-server=utf8mb4
collation-server=utf8mb4_general_ci
init_connect='SET NAMES utf8mb4'
#
skip-external-locking
skip-name-resolve

user=mysql
port=3306
basedir=/opt/mysql
datadir=/opt/mysql/data
tmpdir=/opt/mysql/temp
socket=/opt/mysql/mysql.sock
log-error=/opt/mysql/logs/mysql_error.log
pid-file=/opt/mysql/logs/mysql.pid

open_files_limit=65535
back_log=110
max_connections=300
max_connect_errors=600
table_open_cache=600
interactive_timeout=1800
wait_timeout=1800
lock_wait_timeout=3600

max_allowed_packet=32M
sort_buffer_size=4M
join_buffer_size=4M
thread_cache_size=20
query_cache_type=1
query_cache_size=256M
query_cache_limit=2M
query_cache_min_res_unit=16k
tmp_table_size=64M
max_heap_table_size=64M
key_buffer_size=64M
read_buffer_size=1M
read_rnd_buffer_size=16M
bulk_insert_buffer_size=64M

lower_case_table_names=1

default-storage-engine=INNODB

thread_concurrency=32
long_query_time=3
slow-query-log=on
slow-query-log-file=/opt/mysql/logs/mysql-slow.log

# binlog
server-id = 110
log-bin=mysql-bin
binlog_format=ROW
binlog_row_image=FULL
binlog_expire_logs_seconds=1209600
master_info_repository=TABLE
relay_log_info_repository=TABLE
# log_slave_updates
# relay_log_recovery=1
# slave_skip_errors=ddl_exist_errors
innodb_flush_log_at_trx_commit=1
sync_binlog=1
binlog_cache_size=4M
max_binlog_cache_size=2G
max_binlog_size=1G
gtid_mode=on
enforce_gtid_consistency=1

# innodb engine
innodb_buffer_pool_size=2G
innodb_buffer_pool_instances=4
innodb_log_buffer_size=32M
innodb_log_file_size=2G
innodb_flush_method=O_DIRECT

[mysqldump]
quick
max_allowed_packet=128M

[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
```

