---
description: MySQL
tags:
  - cncf/app-definition
  - database
---

# MySQL

## Introduction

...

## Deploy By Binary

### Quick Start

```bash
# download source with boost lib
wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-boost-8.0.34.tar.gz
tar xf mysql-boost-8.0.34.tar.gz && rm -f mysql-8.0.34

# compile
mkdir /opt/mysql
mkdir bld && cd bld
cmake .. -DCMAKE_INSTALL_PREFIX=/opt/mysql -DMYSQL_DATADIR=/opt/mysql/data -DWITH_BOOST=/root/mysql-8.0.34/boost/ -DSYSCONFDIR=/opt/mysql/sysconfig
make -j `grep processor /proc/cpuinfo | wc -l`
make install

# postinstallation
groupadd mysql
useradd -r -g mysql -s /bin/false mysql
mkdir /opt/mysql/temp /opt/mysql/logs /opt/mysql/sysconfig && chmod 777 /opt/mysql/temp
chown mysql:mysql /opt/mysql -R
./bin/mysqld --initialize --user=mysql --basedir=/opt/mysql --datadir=/opt/mysql/data

# config and startup
cat > /opt/mysql/sysconfig/my.cnf << "EOF"
...
EOF
./bin/mysqld_safe --user=mysql &

# reset root password
./bin/mysql -uroot -p
ALTER USER 'root'@'localhost' IDENTIFIED BY '123qwe';

```

### Config and Boot

#### Config

**/opt/mysql/sysconfig/my.cnf**

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

#### Boot(systemd)

```bash
# boot
cp support-files/mysql.server /etc/init.d/mysql

systemctl daemon-reload
systemctl start mysql.service
systemctl enable mysql.service
```

### Verify

```bash
# syntax check
./bin/mysql -V
Ver 8.0.34 for Linux on x86_64 (Source distribution)
```

### Troubleshooting

```bash
# every remake need to execute
make clean && rm CMakeCache.txt

# problem 1
# CMake Error at cmake/readline.cmake:92 (MESSAGE):
# Curses library not found.  Please install appropriate package,
apt install libncurses5-dev

# problem 2
# CMake Warning at cmake/pkg-config.cmake:29 (MESSAGE):
# Cannot find pkg-config.  You need to install the required package:
apt install pkg-config

```

## Deploy By Container

### Run On Kubernetes

```bash
# add and update repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm update

# get charts package
helm pull bitnami/mysql --untar
cd mysql

# configure and run
vim values.yaml
...
helm -n middleware install mysql .

```

> Reference:
>
> 1. [Official Website](https://www.mysql.com/)
> 2. [Repository](https://github.com/mysql/mysql-server)
> 3. [Download](https://dev.mysql.com/downloads/)
> 4. [Percona Server for MySQL](https://docs.percona.com/percona-server/)
> 5. [ProxySQL](https://proxysql.com/documentation/)
