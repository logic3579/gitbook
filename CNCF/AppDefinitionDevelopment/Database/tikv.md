---
description: TiKV
---

# TiKV

## Introduction
...


## Deploy With Binary
### Quick Start
```bash
# create dir
mkdir -p /opt/tidb/tikv1 /opt/tidb/tikv2 /opt/tidb/tikv3 /opt/tidb/pd1
cd /opt/tidb

# download and decompress
# option1
export TIKV_VERSION=v7.2.0
export GOOS=linux
export GOARCH=amd64
curl -O  https://tiup-mirrors.pingcap.com/tikv-$TIKV_VERSION-$GOOS-$GOARCH.tar.gz
curl -O  https://tiup-mirrors.pingcap.com/pd-$TIKV_VERSION-$GOOS-$GOARCH.tar.gz
tar -xzf tikv-$TIKV_VERSION-$GOOS-$GOARCH.tar.gz && rm -f tikv-$TIKV_VERSION-$GOOS-$GOARCH.tar.gz
tar -xzf pd-$TIKV_VERSION-$GOOS-$GOARCH.tar.gz && rm -f pd-$TIKV_VERSION-$GOOS-$GOARCH.tar.gz
# option2
wget https://download.pingcap.org/tidb-latest-linux-amd64.tar.gz
wget http://download.pingcap.org/tidb-latest-linux-amd64.sha256
sha256sum -c tidb-latest-linux-amd64.sha256
tar -xzf tidb-latest-linux-amd64.tar.gz && rm -f tidb-latest-linux-amd64.tar.gz tidb-latest-linux-amd64.sha256
mv tidb-v5.0.1-linux-amd64/bin /opt/tidb && cd /opt/tidb

# startup single or cluster instance for pd-server and tikv
# if cluster
# TIKV_DATA_DIR=/opt/tidb/tikv/data
# TIKV_LOG_DIR=/opt/tidb/tikv/log
# PD_DATA_DIR=/opt/tidb/pd/data
# PD_LOG_DIR=/opt/tidb/pd/log
./bin/pd-server --name=pd1 --data-dir=/opt/tidb/pd1/data --client-urls="http://192.168.1.10:2379" --peer-urls="http://192.168.1.10:2380" --initial-cluster="pd1=http://192.168.1.10:2380" --log-file=/opt/tidb/pd1/log/pd.log

./bin/tikv-server --pd-endpoints="192.168.1.10:2379" --addr="192.168.1.11:20160" --data-dir=/opt/tidb/tikv1/data --log-file=/opt/tidb/tikv1/log/tikv.log

./bin/tikv-server --pd-endpoints="192.168.1.10:2379" --addr="192.168.1.12:20160" --data-dir=/opt/tidb/tikv2/data --log-file=/opt/tidb/tikv2/log/tikv.log

./bin/tikv-server --pd-endpoints="192.168.1.10:2379" --addr="192.168.1.13:20160" --data-dir=/opt/tidb/tikv3/data --log-file=/opt/tidb/tikv3/log/tikv.log
```

### Config and Boot
```bash
# config
# https://tikv.org/docs/6.5/deploy/configure/introduction/

# boot 
cat > /etc/systemd/system/tikv.service << "EOF"
...
EOF

systemctl daemon-reload
systemctl start tikv.service
systemctl enable tikv.service
```

### Verify
```bash
# verify by pd-ctl
./bin/pd-ctl store -u http://127.0.0.1:2379

# verify by python-sdk client
# install client
pip3 install -i https://test.pypi.org/simple/ tikv-client
# python sdk test
from tikv_client import RawClient
client = RawClient.connect("127.0.0.1:2379")
client.put(b'foo', b'bar')
print(client.get(b'foo')) # b'bar'
client.put(b'foo', b'baz')
print(client.get(b'foo')) # b'baz'
```

### Troubleshooting
```bash
# problem 1

```


## Deploy With Container
### Run in Docker
```bash
# not yet
```

### Run in Kubernetes
```bash
# not yet
```


> Reference:
> 1. [Official Website](https://tikv.org/docs/6.5/concepts/overview/)
> 2. [Repository](https://github.com/tikv/tikv)
> 3. [Production Cluster Deploy](https://tikv.org/docs/6.5/deploy/install/production/)
