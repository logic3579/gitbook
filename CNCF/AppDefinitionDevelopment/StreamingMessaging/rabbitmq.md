---
description: RabbitMQ
---

# RabbitMQ

## Introduction
...


## Deploy With Binary
### Quick Start
```bash
# dependencies: install erlang
wget https://github.com/erlang/otp/releases/download/OTP-25.3.2.4/otp_src_25.3.2.4.tar.gz
tar xf otp_src_25.3.2.4.tar.gz && rm -f otp_src_25.3.2.4.tar.gz 
cd ./otp_src_25.3.2.4
./configure --prefix=/usr/local/erlang
make && make install

# download source
wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.12.2/rabbitmq-server-generic-unix-3.12.2.tar.xz
tar -xf rabbitmq-server-generic-unix-3.12.2.tar.xz && rm -f rabbitmq-server-generic-unix-3.12.2.tar.xz
mv rabbitmq_server-3.12.2 /opt/rabbitmq

# compile 
# no need

# postinstallation
cd /opt/rabbitmq
export PATH=$PATH:/usr/local/erlang/bin:/opt/rabbitmq/sbin
# echo "export PATH=$PATH:/usr/local/erlang/bin:/opt/rabbitmq/sbin" >> ~/.bashrc && source ~/.bashrc

# startup and init
rabbitmq-server -detached
rabbitmqctl add_user admin 123456
rabbitmqctl set_permissions -p "/" admin ".*" ".*" ".*"
rabbitmqctl set_user_tags admin administrator
rabbitmqctl stop && rabbitmq-server -detached

### option: cluster mode
# startup
RABBITMQ_NODE_PORT=5672 RABBITMQ_SERVER_START_ARGS="-rabbitmq_management listener [{port,15672}]" RABBITMQ_NODENAME=rabbitmq1 rabbitmq-server -detached
RABBITMQ_NODE_PORT=5673 RABBITMQ_SERVER_START_ARGS="-rabbitmq_management listener [{port,15673}]" RABBITMQ_NODENAME=rabbitmq2 rabbitmq-server -detached
RABBITMQ_NODE_PORT=5674 RABBITMQ_SERVER_START_ARGS="-rabbitmq_management listener [{port,15674}]" RABBITMQ_NODENAME=rabbitmq3 rabbitmq-server -detached
# add to cluster
rabbitmqctl -n rabbitmq2 stop_app
rabbitmqctl -n rabbitmq2 reset
rabbitmqctl -n rabbitmq2 join_cluster --ram rabbitmq1@`hostname -s` # --ram = memory node
rabbitmqctl -n rabbitmq2 start_app
rabbitmqctl -n rabbitmq3 stop_app
rabbitmqctl -n rabbitmq3 reset
rabbitmqctl -n rabbitmq3 join_cluster --disc rabbitmq1@`hostname -s` # --disc = disk node(default)
rabbitmqctl -n rabbitmq3 start_app
# check status
rabbitmqctl -n rabbitmq1 cluster_status
# set mirror cluster
# rabbitmqctl -n rabbitmq1 set_policy ha-all "^" '{"ha-mode":"all"}'
```

### Config and Boot
#### Config
```bash
# $RABBITMQ_HOME/etc/rabbitmq/rabbitmq.conf
# $RABBITMQ_HOME/etc/rabbitmq/advanced.config
```

#### Boot(systemd)
```bash
cat > /etc/systemd/system/rabbitmq.service << "EOF"
...
EOF

systemctl daemon-reload
systemctl start rabbitmq.service
systemctl enable rabbitmq.service
```

### Verify
```bash
# syntax check
/usr/local/erlang/bin/erl -version
Erlang (SMP,ASYNC_THREADS) (BEAM) emulator version 13.2.2.2

/opt/rabbitmq/sbin/rabbitmqctl status
```

### Troubleshooting
```bash
# problem 1
# 
```


## Deploy With Container
### Run in Docker
```bash
# pull image
docker pull rabbitmq:3

# run
docker run --rm --name rabbitmq -d rabbitmq:3
# run with management
docker run --rm --name -it rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3.12-management

# test
docker exec -it rabbitmq sh

```

### Run in Kubernetes
```bash
# add and update repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm update

# get charts package
helm pull bitnami/rabbitmq --untar
cd rabbitmq

# configure and run
vim values.yaml
...
helm -n middleware install rabbitmq .

```


> Reference:
> 1. [Official Website](https://www.rabbitmq.com/documentation.html)
> 2. [Repository](https://github.com/rabbitmq/rabbitmq-server)
> 3. [Erlang Download](https://erlang.org/download/otp_versions_tree.html)
