---
description: EMQ Technologies
tags:
  - cncf/app-definition
  - messaging
---

# EMQX

## Introduction

EMQX is an open-source, distributed MQTT broker designed for massively scalable IoT, IIoT, and connected vehicle workloads. It supports MQTT 3.1.1 / 5.0 along with MQTT-SN, CoAP, LwM2M, STOMP, WebSocket, and HTTP, and clusters horizontally to handle tens of millions of concurrent device connections with low latency.

## How to Install

### Starting via Docker
```bash
docker run -d --name emqx -p 1883:1883 -p 8083:8083 -p 8084:8084 -p 8883:8883 -p 18083:18083 emqx/emqx:latest

```

### Starting via Kubernetes
```bash
# add and update repo
# get charts package
git clone https://github.com/emqx/emqx.git
cd emqx/deploy/charts/emqx

# configure and run
vim values.yaml
...

helm -n middleware install my-emqx .


# Helm Operator
# https://github.com/emqx/emqx-operator/blob/main/docs/en_US/getting-started/getting-started.md
```

## How To Use
emqx
```bash
# manual cluster
./bin/emqx ctl cluster join emqx@node1.emqx.com
# static cluster
cluster {
    discovery_strategy = static
    static {
        seeds = ["emqx@node1.emqx.com", "emqx@node2.emqx.com"]
    }
}


# cluster status
./bin/emqx ctl cluster status
# remove node
./bin/emqx ctl cluster leave
./bin/emqx ctl cluster force-leave emqx@s2.emqx.io


```

### mqttx
```bash
# connect 
mqttx conn -h 'broker.emqx.io' -p 1883 -u 'admin' -P 'public'

# subscribe
mqttx sub -t 'hello' -h 'broker.emqx.io' -p 1883 -u 'admin' -P 'public'

# publish
mqttx pub -t 'hello' -h 'broker.emqx.io' -p 1883 -m 'Hello from MQTTX CLI' -u 'admin' -P 'public'

# args
-t the message topic
-m the message
-q the QoS of the message <0|1|2>
-v print the topic before the message
-h the broker host
-p the broker port
-u the username
-P the password
-l the protocol to use,<mqtt|ws|wss>
```



> Reference:
>
> 1. [Official Website](https://www.emqx.io/docs/)
> 2. [Repository](https://github.com/emqx/emqx)
> 3. [Kubernetes Operator](https://docs.emqx.com/zh/emqx-operator/latest/getting-started/getting-started.html)
> 4. [MQTTX Client Tools](https://mqttx.app/)
