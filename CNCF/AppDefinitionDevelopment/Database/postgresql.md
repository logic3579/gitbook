---
description: PostgreSQL
---

# PostgreSQL

## Introduction

...

## Deploy By Binary

### Quick Start

```bash
# download source
wget https://ftp.postgresql.org/pub/source/v15.1/postgresql-15.1.tar.gz
tar xf postgresql-15.1.tar.gz && rm -f postgresql-15.1.tar.gz
cd postgresql-15.1/

# compile
mkdri bld && cd bld
../configure --prefix=/opt/pgsql --with-systemd
make -j `grep processor /proc/cpuinfo | wc -l`
make install

# postinstallation
groupadd postgres
useradd -r -g postgres -s /bin/false postgres
mkdir /opt/pgsql/data /opt/pgsql/logs
chown postgres:postgres /opt/pgsql -R

# startup
/opt/pgsql/bin/pg_ctl -D /opt/pgsql/data initdb
/opt/pgsql/bin/pg_ctl -D /opt/pgsql/data -l /opt/pgsql/logs/pgsql.log start

```

### Config and Boot

[Postgresql Config](/DevOps/ServiceConf/postgresql.md)

```bash
# boot
cat > /etc/systemd/system/postgresql.service << "EOF"
[Unit]
Description=PostgreSQL database server
Documentation=man:postgres(1)

[Service]
Type=notify
User=postgres
ExecStart=/opt/pgsql/bin/postgres -D /opt/pgsql/data
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
KillSignal=SIGINT
TimeoutSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start postgresql.service
systemctl enable postgresql.service
```

### Verify

```bash
# syntax check
/opt/pgsql/bin/postgres --version
postgres (PostgreSQL) 15.1
```

### Troubleshooting

```bash
# problem 1
# configure: error: readline library not found
apt install libreadline-dev

# problem 2
# configure: error: header file <systemd/sd-daemon.h> is required for systemd support
apt install libsystemd-dev


```

## Deploy By Container

### Run On Kubernetes

```bash
# add and update repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm update

# get charts package
helm pull bitnami/postgresql --untar
cd postgresql

# configure and run
vim values.yaml
...
helm -n middleware install postgresql .

```

> Reference:
>
> 1. [Official Website](https://www.postgresql.org/)
> 2. [Repository](https://github.com/postgres/postgres)
> 3. [Percona Distribution for PostgreSQL](https://docs.percona.com/postgresql/)
> 4. [PGsqlConfig Generate](https://pgtune.leopard.in.ua/)
