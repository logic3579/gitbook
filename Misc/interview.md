---
description: interview
---

# Interview

## CICD

### Argo

```console
```

### Ansible

```console
- 特点
轻量级，无代理结构（基于 SSH）
模块化设计，yaml 语法编写 playbook 模板
幂等性

- 核心组件
Inventory：定义管理主机
Playbook：自动化任务 yaml 文件
Module：执行特定任务的代码单元
Role：组织 Playbook 和文件的目录结构
Task：Playbook 中的单个执行步骤

- 常用 Module
command | shell
copy
file
package
ping
service
template
unarchive
user
group
```

### Saltstack

```console
- 特点
支持主从架构（salt-minion）和无主架构（SSH）
基于轻量级队列快速通信（zeromq）
使用声明式状态系统

- 核心组件
Master：控制服务端
Minio：管理节点客户端
ZeroMQ：消息传输轻量级队列
Salt SSH：无代理模式
Syndic：分级管理节点
Grains：静态 Minion 信息（OS、IP 等），由 Minion 收集
Pillars：Master 定义的敏感数据或 Minion 特定数据，由 Master 分发

- 常用模块
cmd.run
cp.get_file
cp.get_dir
file.managed
pkg.install
```

### Helm

```console
helm-charts
```

### Jenkins

```console
- Job 
SSH Plugin
Kubernetes Plugin
```

### Terraform

```console
AWS
GCP
```

## Database & Streaming

### Elasticsearch

```console

```

### MySQL

- 主从复制

```console
1. 主节点必须启用 mysql binlog 二进制日志，记录任何修改了数据库数据的事件。
2. 从节点开启一个线程(I/O Thread)把自己扮演成 mysql 的客户端，通过 mysql 协议，请求主节点的二进制日志文件中的事件
3. 主节点启动一个线程(dump Thread)，检查自己二进制日志中的事件，跟对方请求的位置对比，如果不带请求位置参数，则主节点就会从第一个日志文件中的第一个事件一个一个发送给从节点。
4. 从节点接收到主节点发送过来的数据把它放置到中继日志（Relay log）文件中。并记录该次请求到主节点的具体哪一个二进制日志文件内部的哪一个位置（主节点中的二进制文件会有多个，在后面详细讲解）。
5. 从节点启动另外一个线程（sql Thread ），把 Relay log 中的事件读取出来，并在本地再执行一次。
```

- 日志类型

```console
错误日志: 记录报错或警告信息
查询日志: 记录所有对数据请求的信息，不论这些请求是否得到正确的执行。
慢查询日志: 设置阕值，将查询时间超过该值的查询语句。
二进制日志: 记录对数据库执行更改得所有操作
中继日志
事务日志
```

### Redis

- 特点

```console
1. redis 采用多路复用机制
2. 数据结构简单
3. 纯内存操作 运行在内存缓存区中，数据存储在内存中，读取时无需进行磁盘IO
4. 单线程无锁竞争损耗

频繁被访问的数据，经常被访问的数据如果放在关系型数据库，每次查询的开销都会很大，而放在 redis 中，因为 redis 是放在内存中的可以很高效的访问。
```

- 数据类型

```console
1. String 整数，浮点整数或者字符串
2. Set 集合
3. Zset 有序集合
4. Hash 散列
5. List 列表
```

- 使用场景

```console
1. 缓存
2. 排行榜 常用实现数据类型: 有序集合实现
3. 好友关系 利用集合 如交集、差集、并集等
4. 简单的消息队列
5. Session 共享: 默认 Session 是保存在服务器的文件中，如果是集群服务，同一个用户过来可能落在不同机器上，这就会导致用户频繁登陆；采用 Redis  保存 Session后，无论用户落在那台机器上都能够获取到对应的 Session 信息。
```

- 数据淘汰机制

```console
1. volatile-lru     从已设置过期时间的数据集中挑选最近最少使用的数据淘汰
2. volatile-ttl     从已设置过期时间的数据集中挑选将要过期的数据淘汰
3. volatile-random  从已设置过期时间的数据集中任意选择数据淘汰
4. allkeys-lru      从所有数据集中挑选最近最少使用的数据淘汰
5. allkeys-random   从所有数据集中任意选择数据进行淘汰
6. noeviction       禁止驱逐数据
```

- 缓存穿透, 缓存击穿, 缓存雪崩

```console
1. 缓存穿透: 就是客户持续向服务器发起对不存在服务器中数据的请求。客户先在Redis 中查询，查询不到后去数据库中查询。
2. 缓存击穿: 就是一个很热门的数据，突然失效，大量请求到服务器数据库中
3. 缓存雪崩: 就是大量数据同一时间失效。

缓存穿透:
1. 接口层增加校验，对传参进行个校验，比如说我们的id是从1开始的，那么id<=0的直接拦截；
2. 缓存中取不到的数据，在数据库中也没有取到，这时可以将key-value对写为key-null，这样可以防止攻击用户反复用同一个id暴力攻击

缓存击穿:
最好的办法就是设置热点数据永不过期

缓存雪崩:
1. 缓存数据的过期时间设置随机，防止同一时间大量数据过期现象发生。
2. 如果缓存数据库是分布式部署，将热点数据均匀分布在不同的缓存数据库中。
```

- 数据持久化实现

```console
rdb 持久化: 在间隔一段时间或者当 key 改变达到一定的数量的时候，就会自动往磁盘保存一次。如未满足设置的条件，就不会触发保存，如出现断电就会丢失数据。

aof 持久化: 记录用户的操作过程（用户每执行一次命令，就会被 redis 记录到一个aof 文件中，如果发生突然短路，redis 的数据会通过重新读取并执行aof里的命令记录来恢复数据）来恢复数据。
解决了 rdb 的弊端，但 aof 的持久化会随着时间的推移数量越来越多，会占用很大空间。
```

### Kafka

```console

```

### RocketMQ

```console

```

## Observability

### Fluentd

```console

```

### Loki

```console

```

### Grafana

```console

```

### Prometheus

```console

```

### Zabbix

- 主动模式与被动模式原理

```console
主动模式: zabbix-agent 会主动开启一个随机端口去向 zabbix-server 的10051端口发送 tcp 连接。zabbix-server 收到请求后，会将检查间隔时间和检查项发送给 zabbix-agent，agent 采集到数据以后发送给 server.

被动模式: zabbix-server 会根据数据采集间隔时间和检查项，周期性生成随机端口去向 zabbix-agent 的10050发起连接。然后发送检查项给 agent，agent 采集后，在发送给 server。如 server 未主动发送给 agent，agent 就不会去采集数据。

zabbix-proxy
主动模式: agent 请求的是 proxy，由 proxy 向 server 去获取 agent 的采集间隔时间和采集项。再由 proxy 将数据发送给 agent,agent采集完数据后，再由 proxy 中转发送给 server.
被动模式:
```

- 常用监控项

```console
1. 硬件监控: 交换机、防火墙、路由器
2. 系统监控: CPU、内存、磁盘、进程、TCP 等
3. 服务监控: Nginx、Mysql、Redis、Tomcat 等
4. web 监控: 响应时间、加载时间、状态码
```

- 自定义监控

```console
编写 shell 脚本非交互式取值，如 mysql 主从复制，监控从节点的 slave 的IO，show slave status\G;
取出 slave 的俩个线程 Slave_IO_Running 和 Slave_SQL_Running 的值都为yes 则输出一个0，如不同步则输出1，在 zabbix agent  的配置文件中，可以设置执行本地脚本 在zabbix server 的web端上上配置监控项配 mysql_slave_check，在触发器中判断取到的监控值，如1则报警，如0则输出正常。

自定义模板，需要新增图形。
```

## ServiceProxy

### HAProxy

```console

```

### Nginx

- 特点

```console
1. 支持高并发，官方测试连接数支持5万，生产可支持2~4万。
2. 内存消耗成本低
3. 配置文件简单，支持 rewrite 重写规则等
4. 节省带宽，支持 gzip 压缩。
5. 稳定性高
6. 支持热部署
```

- 常用的模块与参数

```console
负载均衡 upstream
反向代理 proxy_pass
路由匹配 location
重定向规则 rewrite

proxy 参数:
proxy_sent_header
proxy_connent_timeout
proxy_read_timeout
proxy_send_timeout
```

- rewrite flag

```console
last: 表示完成当前的 rewrite 规则
break: 停止执行当前虚拟主机的后续 rewrite
redirect :  返回302临时重定向，地址栏会显示跳转后的地址
permanent :  返回301永久重定向，地址栏会显示跳转后的地址
```

## Network & System

### CDN

```console
内容分发网络，其目的是通过限制的 internet 中增加一层新的网络架构。将网站的内容发布到最接近用户的网络边缘，使用户可以就近取得所需的内容，提高用户访问网站的响应速度。

静态文件加速缓存, 动态请求加速.
```

### DNS

- 递归查询与迭代查询

```console
递归查询(通常为客户端)
1. 客户端向本地 DNS 服务器（通常为 ISP DNS 或8.8.8.8）发起递归 DNS 查询报文请求。
2. 本地 DNS 服务器有缓存则立即返回，没有缓存则负责代替客户端向根域名服务器、顶级域名服务器（如.com）、权威服务器逐级查询。
3. 本地 DNS 服务器将最终 IP 或错误信息返回客户端。

迭代查询(通常为本地 DNS 服务器)
1. DNS 服务器（本地 DNS 服务器）向根域名服务器发起迭代 DNS 查询报文请求。
2. 根域名服务器返回顶级域名服务器（如.com）的地址。
3. 本地 DNS 服务器再向顶级域名服务器查询，得到权威域名服务器的地址。
4. 本地 DNS 服务器继续向权威域名服务器查询，最终获取目标域名的 IP 地址。
5. 每一步查询都由发起查询的 DNS 服务器自己完成，而不是将任务完全交给其他服务器。
```

- 访问域名过程

```console
客户端访问 www.example.com 时
1. 检查浏览器自身的 DNS 缓存（域名与 IP 映射,有 TTL），没有缓存则下一步。
2. 调用操作系统 DNS 解析接口，检查本地操作系统 DNS 缓存（ipconfig /displaydns 或 nscd 命令），没有缓存则下一步。
3. 检查本地 hosts 文件是否存在域名与 IP 映射，没有则下一步。
4. 客户端向本地 DNS 服务器发起递归 DNS 查询请求（ISP DNS 或公共 DNS），没有缓存则下一步。
5. 本地 DNS 服务器向根域名服务器、顶级域名服务器、权威 DNS 服务器发起迭代 DNS 查询请求，返回 IP 或错误信息。

> 5.1 查询根域名服务器：向根域名服务器查询 www.example.com 信息，根域名返回顶级域名（.com TLD 服务器）的 IP 地址。
> 5.2 查询顶级域名服务器：本地 DNS 服务器向 .com TLD 服务器查询，询问 example.com 的权威 DNS 服务器地址（ns1.example.com）的 IP 地址。
> 5.3 查询权威域名服务器：本地 DNS 服务器向 example.com 的权威 DNS 服务器查询 www.example.com 的记录。权威服务器返回 www.example.com 对应的 A 记录或 CNAME 记录。
> 5.4 如果返回的是 CNAME 记录（如 www.example.com 指向 cdn.example.com），本地DNS服务器会重复上述过程，解析 CNAME 指向的域名，直到获取最终 IP 地址（A 记录）。
```

### LVS

- 调度算法

```console
静态算法:
RR: 轮询算法
WRR: 加权轮询
SH: 源 IP 地址 hash,将来自同一个 IP 地址的请求发送给第一次选择的 RS。实现会话绑定。
DH: 目标地址 hash，第一次做轮询调度，后续将访问同一个目标地址的请求，发送给第一次
挑中的 RS。适用于正向代理缓存中

动态算法:
LC: least connection 将新的请求发送给当前连接数最小的服务器。
WLC: 默认调度算法。加权最小连接算法
SED: 初始连接高权重优先,只检查活动连接,而不考虑非活动连接
NQ: Never Queue，第一轮均匀分配，后续SED
LBLC: Locality-Based LC，动态的DH算法
LBLCR: LBLC with Replication，带复制功能的LBLC，解决LBLC负载不均衡问题，从负载重的复制
到负载轻的RS,,实现Web Cache等
```

## Docker & Containerd

- Docker 简述

```console
Docker 是一个完整的容器平台，提供了从容器创建、管理到编排的整套工具链。

核心组件与架构：
1. Docker CLI 与用户交互
2. Docker Daemon（dockerd）后台进程，负责管理容器、镜像、网络、存储等，包含 API 服务器。
3. Containerd：Docker 的默认容器运行时，负责底层容器操作（如创建、启动容器）。
4. runc：轻量级容器运行时，基于 OCI（Open Container Initiative）标准，containerd 使用 runc 执行实际容器进程。
5. 其他组件：如 Docker Compose（多容器编排）、Docker Swarm（集群管理）、Docker Hub（镜像仓库）。

与 Kubernetes 关系：
早期 Kubernetes 使用 Docker 作为默认运行时，但需要 dockershim 适配 CRI。Kubernetes 自 1.20 起弃用 dockershim，推荐 containerd 或 CRI-O
```

- 容器隔离实现原理

**Cgroups**

**Namespace**

```console
Docker Enginer 使用了 namespace 对全区操作系统资源进行了抽象，对于命名空间内的进程来说，他们拥有独立的资源实例，在命名空间内部的进程是可以实现资源可见的。

Dcoker Enginer 中使用的 NameSpace:
UTS nameSpace        提供主机名隔离能力
User nameSpace       提供用户隔离能力
Net nameSpace        提供网络隔离能力
IPC nameSpace        提供进程间通信的隔离能力
Mount nameSpace      提供磁盘挂载点和文件系统的隔离能力
Pid nameSpace        提供进程隔离能力
```

- Docker 网络模型

```console
1. host：共享主机
2. container：容器间共享网络（Network Namespace）
3. none：独立 Network Namespace，但无网络配置
4.bridge：桥接模式，独立 Network Namespace 设置 IP 并连接到虚拟网桥。
```

- Dockershim 工作机制

```console
架构：
1. Kubernetes 的 Kubelet 通过 CRI 接口与 dockershim 通信。
2. Dockershim 将 CRI 请求（如创建、启动、停止容器）转换为 Docker API 调用，发送给 dockerd。
3. Dockerd 再通过 containerd 调用 runc 执行底层容器操作。
4. 进程链：Kubelet(CRI) → dockershim → dockerd → containerd → containerd-shim → runc → 容器进程。

流程：
1. Kubelet 发起 CRI 请求：例如，创建 Pod 中的容器。
2. Dockershim 转换请求：将 CRI 请求翻译为 Docker API 调用（如 docker create、docker start）。
3. Dockerd 处理：Docker daemon 调用 containerd 执行容器操作。
4. Containerd 和 runc：containerd 通过 containerd-shim 调用 runc，创建并运行容器。
5. 返回结果：容器状态通过相反路径返回给 Kubelet。
```

- Containerd 简述

```console
Containerd 是一个轻量级的容器运行时（container runtime），专注于管理和运行容器，强调简单、高效和模块化。供上层工具（Docker、Kubernetes 的 kubelet 等）调用。

核心组件与架构：
1. Containerd Daemon：核心进程，提供 gRPC API，管理容器生命周期、镜像、快照、网络等。
2. runc：containerd 调用 runc 执行 OCI 标准规范容器，处理底层容器运行。
3. Shim：containerd 使用 shim 进程隔离容器进程，确保 containerd 主进程不直接管理容器运行。
4. Plugins：containerd 采用模块化设计，功能（如存储、网络）通过插件实现，易于扩展。

与 Kubernetes 关系：
直接支持 CRI（Container Runtime Interface），是 Kubernetes 的首选运行时。
```

- Containerd-shim 工作机制

```console
架构：
1. Containerd 是一个独立的高层容器运行时，负责镜像管理、存储、网络等。
2. 每个容器对应一个 containerd-shim 进程，containerd-shim 调用 runc（或其他 OCI 运行时）执行容器。
3. 进程链：containerd → containerd-shim → runc → 容器进程。
4. 在 Kubernetes 中：Kubelet → CRI (containerd) → containerd-shim → runc → 容器进程。

流程：
1. Containerd 接收请求：通过 gRPC API（如 CRI 或 Docker 调用）接收容器操作请求。
2. 启动 Containerd-shim：Containerd 启动一个 containerd-shim 进程，传递 OCI 包（bundle）路径，包含 config.json 和根文件系统。Shim 进程调用 runc 的 create 命令，创建容器进程（runc 初始化后退出）。
3. 管理容器生命周期：Shim 进程作为容器进程的父进程，保持标准 I/O（stdin/stdout/stderr）打开，处理日志输出（如 docker logs）；Shim 监控容器退出状态，报告给 containerd；支持附加操作（如 docker exec、kubectl attach）和伪终端（PTY）管理。
4. 隔离与容错：Shim 进程隔离 containerd 主进程，containerd 重启或崩溃不影响运行中的容器。Shim 保持运行直到容器退出，收集退出状态后终止。

验证：
ctr image pull docker.io/library/nginx:latest
ctr run -d docker.io/library/nginx:latest nginx
# containerd 启动 containerd-shim-runc-v2，调用 runc 创建容器
ps aux | grep containerd-shim
```

- CRI-O 简述

```console
CRI-O 是一个轻量级的容器运行时，专为 Kubernetes 开发，用于直接与 Kubernetes 的 CRI 接口交互，管理容器生命周期（创建、启动、停止、删除等）、镜像和存储。它基于 OCI（Open Container Initiative）标准，使用 runc 或其他 OCI 兼容运行时执行容器。

核心组件与架构：
1. CRI-O Daemon：
核心进程，运行在主机上，通过 gRPC 提供 CRI 接口，与 Kubernetes 的 Kubelet 交互。负责协调镜像管理、存储、网络和容器生命周期。
2. OCI 运行时：
CRI-O 使用 runc（默认）或其他 OCI 兼容运行时（如 Kata Containers）来执行容器。runc 负责创建容器进程，基于 OCI 包（bundle，包含 config.json 和根文件系统）。
3. CNI 插件：
CRI-O 使用 CNI 插件（如 flannel、Calico）配置容器网络，支持桥接、overlay 等网络模型。
4. Storage 驱动：
支持 overlayfs、devicemapper 等存储驱动，管理容器镜像和文件系统快照。
5. Conmon：
CRI-O 的一个轻量级监控工具，类似于 containerd 的 containerd-shim。每个容器对应一个 conmon 进程，负责管理容器进程的生命周期、标准 I/O（stdin/stdout/stderr）、日志收集和退出状态。
6. Image and Storage Libraries：
使用 containers/storage 管理镜像和存储层。使用 containers/image 处理镜像拉取和分发，支持 Docker 和 OCI 镜像格式。
```

- CRI-O 工作机制

```console
1. Kubelet 发起 CRI 请求：
Kubernetes 的 Kubelet 根据 Pod 定义（如 YAML 文件）向 CRI-O 发送 CRI 请求（如 RunPodSandbox、CreateContainer）。
请求通过 gRPC 传递，包含 Pod 和容器的配置信息。

2. Pod 沙箱（Sandbox）创建：
CRI-O 首先为 Pod 创建一个“沙箱”（Pod Sandbox），即 Pod 的运行环境。
调用 CNI 插件配置网络（如分配 IP、设置网络命名空间）。
创建一个 pause 容器（基础设施容器），用于维持 Pod 的网络和命名空间。

3. 镜像拉取：
CRI-O 使用 containers/image 从镜像仓库（如 Docker Hub、Quay.io）拉取所需镜像。
镜像存储在本地，使用 containers/storage 管理，支持多层缓存。

4. 容器创建和启动：
CRI-O 生成 OCI 包（bundle），包含 config.json（OCI 运行时规范）和容器根文件系统。
调用 runc（或指定 OCI 运行时）创建容器进程。
为每个容器启动一个 conmon 进程，负责监控容器进程状态、转发标准 I/O（如 kubectl logs）、处理附加操作（如 kubectl exec）、收集退出状态。

5. 容器运行和监控：
Conmon 作为容器进程的父进程，保持运行以支持日志收集和状态监控。
CRI-O daemon 通过 gRPC 返回容器状态给 Kubelet（如运行中、已退出）。
支持动态操作，如停止、删除容器或更新配置。

6. 清理和销毁：
Pod 或容器删除时，CRI-O 调用 CNI 清理网络，释放资源。
删除容器文件系统和相关元数据。

进程链：
Kubelet(CRI) → CRI-O daemon → conmon → runc → 容器进程

验证：
crictl pull docker.io/library/nginx:latest
crictl runp pod-config.json # 创建 Pod 沙箱
crictl create <pod-id> container-config.json pod-config.json
crictl start <container-id>
crictl ps
```

## Kubernetes

### 简述

```console
Kubernetes 是一个开源的容器编排平台，用于自动化管理、部署、扩展和运行容器化应用程序。Kubernetes 通过将应用程序打包到容器中（如 Docker 容器），并在集群中协调这些容器的运行，提供高效、弹性的分布式系统管理。

Kubernetes 的核心功能包括：
容器编排：自动部署、扩展和管理容器化应用。
服务发现和负载均衡：内置服务发现机制，自动分配流量到容器。
自动扩展：根据需求（如 CPU、内存使用率）自动调整容器数量。
自我修复：自动检测并重启故障容器，替换或重新调度到健康的节点。
存储编排：支持动态挂载和管理存储系统。
配置管理：通过 ConfigMaps 和 Secrets 管理应用配置和敏感信息。
滚动更新与回滚：支持无缝更新应用版本，并能在问题发生时回滚。

Pod：Kubernetes 的最小调度单位，通常包含一个或多个容器。
```

### 组件

- 控制平面（Control Plane）

```console
API Server：Kubernetes 的前端接口，集群的中央管理入口，接受和处理来自用户、客户端或内部组件的 RESTful API 请求。
1. 提供 Kubernetes API，处理所有管理操作（如创建、更新、删除资源）。
2. 与 etcd 通信，存储和检索集群状态。
3. 验证和授权请求，确保安全性。
4. 控制平面与其他组件交互的枢纽

Controller Manager：运行多个控制器进程，监控集群状态并确保其与期望状态一致。
1. Replication Controller：确保指定数量的 Pod 副本始终运行。
2. Deployment Controller：管理应用的滚动更新和回滚。
3. StatefulSet Controller：管理有状态应用的 Pod。
4. Node Controller：监控节点状态，处理节点故障。
通过 API Server 读取集群状态，与 etcd 协作，执行必要的调整。

Scheduler：负责将 Pod 调度到合适的 Worker 节点上。
1. 根据资源需求（如 CPU、内存）、节点状态、亲和性规则、约束条件等，选择最合适的节点来运行 Pod。
2. 考虑负载均衡、硬件限制和用户定义的策略（如节点选择器、污点与容忍）。
3. 监控未调度的 Pending 状态 Pod，并动态分配到节点。

Etcd：分布式键值存储数据库，用于存储 Kubernetes 集群的所有状态数据。
1. 保存集群配置、状态和元数据（如 Pod、Service、Deployment 的定义）。
2. 提供高可用性和一致性，保证集群数据的持久性和可靠性。
3. 仅由 API Server 直接访问，其他组件通过 API Server 间接与 etcd 交互。
```

- 工作节点（Worker Nodes）

```console
Kubelet：运行在每个工作节点上的代理进程，负责与控制平面通信并管理节点上的 Pod。
1. 通过 API Server 接收 Pod 定义（PodSpec），确保 Pod 中的容器按预期运行。
2. 监控容器健康状态，报告节点和 Pod 的状态给控制平面。
3. 与容器运行时交互，启动、停止或重启容器。
4. 执行节点级别的健康检查（liveness/readiness probes）。

Kube-Proxy：运行在每个工作节点上的网络代理进程，管理网络通信和负载均衡。
1. 实现 Kubernetes Service 的网络功能，通过规则（如 iptables 或 IPVS）将流量转发到正确的 Pod。
2. 支持服务发现，确保客户端请求到达正确的后端 Pod。
3. 提供负载均衡，均匀分配流量到多个 Pod 副本。
4. 处理外部流量（如通过 NodePort 或 LoadBalancer）。

容器运行时：负责在节点上运行容器的软件，如 Docker、containerd 或 CRI-O。
1. 拉取容器镜像，创建并运行容器。
2. 管理容器的生命周期（如启动、停止、删除）。
3. 与 Kubelet 协作，执行容器相关的操作。
4. 支持 CRI（Container Runtime Interface），确保与 Kubernetes 的兼容性。
```

### Pod 创建过程

```console
第一步：用户通过 kubectl 或直接调用 Kubernetes API 提交 Pod 的资源清单。
1. 用户客户端（如 kubectl）向 API Server（kube-apiserver）发送 HTTP POST 请求，提交 Pod 资源定义。
2. 请求路径通常为 /api/v1/namespaces/{namespace}/pods。
3. Pod 定义包括元数据（metadata，如名称、命名空间）、规格（spec，如容器镜像、资源需求、端口等）。
API Server 行为：
1. 验证请求的合法性（认证和授权，基于 RBAC 或其他机制）。
2. 将 Pod 定义存储到 etcd，更新集群状态。
3. 创建一个新的 Pod 对象，初始状态为 Pending。
4. Controller Manager 根据配置信息将要创建的 Pod 资源对象放到等待队列中。

第二步：调度器 kube-scheduler 分配节点
1. 调度器通过 API Server 的 watch 机制，监控到新的 Pending 状态的 Pod。
2. 调度器根据 Pod 的资源需求（CPU、内存等）、节点状态、亲和性规则、污点与容忍等，选择一个合适的 Worker 节点。
调度算法包括：
过滤（Filtering）：筛选出满足条件的节点（节点有足够资源、NodeSelector、节点亲和性、污点冲突等）。
评分（Scoring）：对候选节点打分，选择最优节点。
3. 调度器通过 API Server 更新 Pod 对象，将 spec.nodeName 设置为选定的节点名称。
4。 更新后的 Pod 状态写入 etcd，标记 Pod 为已调度。

第三步：Kubelet 检测并处理 Pod
1. Kubelet 通过 API Server 的 watch 机制，监控分配到本节点的 Pod（通过 nodeName 字段匹配）。
2. Kubelet 获取 Pod 的完整定义（PodSpec），包括容器镜像、环境变量、卷挂载等。
3. Kubelet 调用容器运行时接口（CRI），与容器运行时（如 containerd、CRI-O 或 Docker）交互开始创建 Pod。

第四步：Kubelet 通过 gRPC 协议与 CRI 通信，CRI 创建 Linux 命名空间、cgroups 和挂载点。创建并初始化 Pod 和容器。
1. 创建 Pod 沙箱（Sandbox）：
Pod 沙箱是一个隔离的环境，通常是一个基础容器（如 pause 容器），用于共享网络和存储命名空间。
CRI 调用容器运行时的 RunPodSandbox 方法，创建沙箱容器。
沙箱容器启动后，分配一个网络命名空间（network namespace）和 IPC 命名空间（如果需要）。
2. 拉取镜像：
Kubelet 通过 CRI 调用 PullImage，从镜像仓库（如 Docker Hub）拉取 Pod 定义中指定的容器镜像。如果镜像已存在本地，则跳过此步骤。
3. 创建容器：
Kubelet 调用 CRI 的 CreateContainer 方法，为 Pod 中的每个容器创建实例。容器共享 Pod 沙箱的网络和存储命名空间。
4. 启动容器：
Kubelet 调用 CRI 的 StartContainer 方法，启动每个容器。

第五步：CNI（Flannel、Calico、Weave 等）配置网络
1. 在创建 Pod 沙箱（RunPodSandbox）时，Kubelet 调用 CNI 插件来配置 Pod 的网络。
2. CNI 插件根据集群的网络配置（如 CNI 配置文件 /etc/cni/net.d/）执行操作：
a. CNI 插件从网络插件的 IP 池中为 Pod 分配一个唯一的 IP 地址。插件可能与外部服务（如 IPAM，IP 地址管理）交互。
b. CNI 插件在 Pod 沙箱的网络命名空间中设置网络接口（如 veth 虚拟以太网接口）。将 Pod 的网络接口连接到集群的虚拟网络（如桥接、Overlay 网络）。
c. 配置 Pod 的路由规则，确保 Pod 可以与集群内其他 Pod 或外部服务通信。配置 DNS（如通过 CoreDNS）以支持服务发现。
CNI 插件完成后，返回网络配置结果给 Kubelet。

第六步：Pod 启动完成
1. Kubelet 确认所有容器启动成功，Pod 进入 Running 状态。
2. Kubelet 通过 API Server 的 PATCH 请求更新 Pod 的状态（如 status.phase 设置为 Running），写入 etcd。
3. 如果 Pod 配置了健康检查（liveness/readiness probes），Kubelet 开始定期执行探针。

第七步：Kube-Proxy 配置网络规则
Kube-Proxy 通过 API Server 监控 Pod 的 IP 地址和 Service 的变化，动态更新网络规则。（如 iptables 或 IPVS）。

总结：
1. 用户通过 kubectl 提交 Pod 定义 → API Server 验证并存储到 etcd（Pod 状态为 Pending）。
2. 调度器检测到新 Pod，分配到 Worker 节点，更新 Pod 的 nodeName 字段。
3. Kubelet 检测到分配到本节点的 Pod，调用 CRI 创建 Pod 沙箱。
4. CRI 调用容器运行时，创建 pause 容器（沙箱）。
5. Kubelet 调用 CNI 插件，配置 Pod 的网络（分配 IP、设置网络接口）。
6. Kubelet 通过 CRI 拉取镜像、创建并启动容器。
7. Kubelet 更新 Pod 状态为 Running，通知 API Server。
8. Kube-Proxy 更新 Service 相关的网络规则（如果适用）。
```

### Resources

- RS / Deplyment / StatefulSet

```console
Replication Controller
(1)确保 Pod 数量: 它会确保 Kubernetes 中有指定数量的 Pod 在运⾏，如果少于指定数量的 Pod ， RC 就会创建新的，反之这会删除多余的，保证 Pod 的副本数量不变。
(2)确保 Pod 健康: 当 Pod 不健康，比如运⾏出错了，总之无法提供正常服务时， RC 也会杀死不健康的 Pod ，重新创建一个新的Pod。
(3)弹性伸缩: 在业务⾼峰或者低峰的时候，可以通过 RC 来动态调整 Pod 数量来提供资源的利用率，当然我们也提到过如何使用 HPA 这种资源对象的话可以做到自动伸缩。
(4)滚动升级: 滚动升级是⼀种平滑的升级⽅式，通过逐步替换的策略，保证整体系统的稳定性。

Deployment
和 RC ⼀样的都是保证 Pod 的数量和健康，⼆者大部分功能都是完全⼀致的，我们可以看成是⼀个升级版的 RC 控制器
(1)RC 的全部功能:  Deployment 具备上⾯描述的 RC 的全部功能；
(2)事件和状态查看: 可以查看 Deployment 的升级详细进度和状态；
(3)回滚: 当升级 Pod 的时候如果出现问题，可以使用回滚操作回滚到之前的任⼀版本；
(4)版本记录: 每⼀次对 Deployment 的操作，都能够保存下来，这也是保证可以回滚到任⼀版本的基础；
(5)暂停和启动: 对于每⼀次升级都能够随时暂停和启动。

StatefulSet
1. 每个 Pod 都有稳定唯一的网络标识可以发现集群里的其他成员
控制的 Pod 副本的启停顺序是受控的
2. Pod 采用稳定的持久化存储卷
```

- Service

```console
一个 Pod 只是一个运行服务的实例，随时可能在一个节点上停止，在另一个节点以一个新的 IP 启动一个新的 Pod，因此不能以确定的 IP 和端口号提供服务。要稳定地提供服务,需要服务发现和负载均衡能力.

在 k8s 集群中，客户端需要访问的服务就是 Service 对象。每个 Service 会对应一个集群内部有效的虚拟 IP，集群内部通过虚拟 IP 访问一个服务
Service -> Endpoint -> Pod
LB -> NodePort -> CNI bridge -> Pod
```

- Volume

```console
volume（存储卷）是 Pod 中能够被多个容器访问的共享目录
emptyDir Volume 是在 Pod 分配到 Node 时创建的。临时空间分配
```

### Lifecycle

```console
1. livenessProbe
存活探针，检测容器是否正在运行，如果存活探测失败，则 kubelet 会杀死容器，并且容器将受到其重启策略的影响，如果容器不提供存活探针，则默认状态为 Success，livenessprobe 用于控制是否重启 Pod.

2. readinessProbe
就绪探针，如果就绪探测失败，端点控制器将从与 Pod 匹配的所以 Service 的端点中删除该 Pod 的 IP 地址初始延迟之前的就绪状态默认为 Failure（失败），如果容器不提供就绪探针，则默认状态为 Success，readinessProbe 用于控制 Pod 是否添加至 service.

3. startupprobe
启动探针
```

### Others

```console
1. hpa 指标以 request 为准
2. 主机调度 Pod 以 request 为准


request limit 的分级?
如何通过 Deployments 创建 Pod？
```
