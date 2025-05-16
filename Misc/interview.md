---
description: interview
---

# interview

## Network

### CDN

```text
内容分发网络，其目的是通过限制的 internet 中增加一层新的网络架构。将网站的内容发布到最接近用户的网络边缘，使用户可以就近取得所需的内容，提高用户访问网站的响应速度。

静态文件加速缓存, 动态请求加速.
```

### DNS

- 递归查询与迭代查询

```text
递归查询(本地 DNS 服务器使用的方式)
如果主机所询问的本地域名服务器不知道被查询的域名的 IP 地址，那么本地 DNS 服务器就以 DNS 客户的身份，向其它根域名服务器继续发出 DNS 请求报文(即替主机继续查询)，而不是让主机自己进行下一步查询。因此，递归查询返回的查询结果或者是所要查询的 IP 地址，或者是报错，表示无法查询到所需的 IP 地址。

迭代查询:
当根域名服务器收到本地 DNS 服务器发出的迭代 DNS 查询请求报文时，要么给出所要查询的 IP 地址，要么告诉本地 DNS 服务器: “你下一步应当向哪一个域名服务器进行查询”。然后让本地 DNS 服务器进行后续的查询。根域名服务器通常是把自己知道的顶级域名服务器的 IP 地址告诉本地 DNS 服务器，让本地 DNS 服务器再向顶级域名服务器查询。顶级域名服务器在收到本地 DNS 服务器的查询请求后，要么给出所要查询的 IP 地址，要么告诉本地 DNS 服务器下一步应当向哪一个权威域名服务器进行查询。最后，知道了所要解析的 IP 地址或报错，然后把这个结果返回给发起查询的主机.
```

- DNS 解析过程

```text
1. 本地缓存.
2. 本地 hosts 文件.
3. 本地设置的 DNS 服务器(/etc/resolve.conf) .
4. ISPDNS 检查是否有缓存,有则返回, 无则向配置文件设置的13台 root 根服务器随机请求

客户端访问 www.baidu.com 这个域名时，会先查看本地是否有缓存，如无缓存会去查看本地hosts文件是否有相关信息，如果没有，则会去向设置的dns服务器: ISPDNS 如223.6.6.6，ISPDNS会检查是否有缓存，有则返回结果。无则会向配置文件中设置的13台根服务器的其中一台发送请求。根服务器拿到请求后，查看是com.这级域下的，就会返回com.的ns记录。
ISPDNS向com中的服务器再次发起请求，com域的服务器发现你这请求是baidu.com这个域的，查看到发现了这个域的NS，则会返回给NS记录给ISPDNS
ISPDNS收到信息后去向baidu.com,查到自己下面有个www的主机，则会返回结果到ISPDNS。
ISPDNS收到消息后，会在本地保存一份，再将结果返回给客户端。客户端根据结果中解析出来的主机ip再去请求访问。
```

### LVS

- 调度算法

```text
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

## Database

### Redis

- 特点

```text
1. redis 采用多路复用机制
2. 数据结构简单
3. 纯内存操作 运行在内存缓存区中，数据存储在内存中，读取时无需进行磁盘IO
4. 单线程无锁竞争损耗

频繁被访问的数据，经常被访问的数据如果放在关系型数据库，每次查询的开销都会很大，而放在 redis 中，因为 redis 是放在内存中的可以很高效的访问。
```

- 数据类型

```text
1. String 整数，浮点整数或者字符串
2. Set 集合
3. Zset 有序集合
4. Hash 散列
5. List 列表
```

- 使用场景

```text
1. 缓存
2. 排行榜 常用实现数据类型: 有序集合实现
3. 好友关系 利用集合 如交集、差集、并集等
4. 简单的消息队列
5. Session 共享: 默认 Session 是保存在服务器的文件中，如果是集群服务，同一个用户过来可能落在不同机器上，这就会导致用户频繁登陆；采用 Redis  保存 Session后，无论用户落在那台机器上都能够获取到对应的 Session 信息。
```

- 数据淘汰机制

```text
1.volatile-lru     从已设置过期时间的数据集中挑选最近最少使用的数据淘汰
2.volatile-ttl     从已设置过期时间的数据集中挑选将要过期的数据淘汰
3.volatile-random  从已设置过期时间的数据集中任意选择数据淘汰
4.allkeys-lru      从所有数据集中挑选最近最少使用的数据淘汰
5.allkeys-random   从所有数据集中任意选择数据进行淘汰
6.noeviction       禁止驱逐数据
```

- 缓存穿透, 缓存击穿, 缓存雪崩

```text
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

```text
rdb 持久化: 在间隔一段时间或者当 key 改变达到一定的数量的时候，就会自动往磁盘保存一次。如未满足设置的条件，就不会触发保存，如出现断电就会丢失数据。

aof 持久化: 记录用户的操作过程（用户每执行一次命令，就会被 redis 记录到一个aof 文件中，如果发生突然短路，redis 的数据会通过重新读取并执行aof里的命令记录来恢复数据）来恢复数据。
解决了 rdb 的弊端，但 aof 的持久化会随着时间的推移数量越来越多，会占用很大空间。
```

### MySQL

- 主从复制

```text
1. 主节点必须启用 mysql binlog 二进制日志，记录任何修改了数据库数据的事件。
2. 从节点开启一个线程(I/O Thread)把自己扮演成 mysql 的客户端，通过 mysql 协议，请求主节点的二进制日志文件中的事件
3. 主节点启动一个线程(dump Thread)，检查自己二进制日志中的事件，跟对方请求的位置对比，如果不带请求位置参数，则主节点就会从第一个日志文件中的第一个事件一个一个发送给从节点。
4. 从节点接收到主节点发送过来的数据把它放置到中继日志（Relay log）文件中。并记录该次请求到主节点的具体哪一个二进制日志文件内部的哪一个位置（主节点中的二进制文件会有多个，在后面详细讲解）。
5. 从节点启动另外一个线程（sql Thread ），把 Relay log 中的事件读取出来，并在本地再执行一次。
```

- 日志类型

```text
错误日志: 记录报错或警告信息
查询日志: 记录所有对数据请求的信息，不论这些请求是否得到正确的执行。
慢查询日志: 设置阕值，将查询时间超过该值的查询语句。
二进制日志: 记录对数据库执行更改得所有操作
中继日志
事务日志
```

## CICD

### Ansible

- 常用模块

```text
面试题: 常见的ansible模块？
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

```text
server client 结构
ssh

zeromq 轻量级队列
```

### Jenkins

```text

```

## Monitoring

### Grafana

```text

```

### Prometheus

```text

```

### Zabbix

- 主动模式与被动模式原理

```text
主动模式: zabbix-agent 会主动开启一个随机端口去向 zabbix-server 的10051端口发送 tcp 连接。zabbix-server 收到请求后，会将检查间隔时间和检查项发送给 zabbix-agent，agent 采集到数据以后发送给 server.

被动模式: zabbix-server 会根据数据采集间隔时间和检查项，周期性生成随机端口去向 zabbix-agent 的10050发起连接。然后发送检查项给 agent，agent 采集后，在发送给 server。如 server 未主动发送给 agent，agent 就不会去采集数据。

zabbix-proxy
主动模式: agent 请求的是 proxy，由 proxy 向 server 去获取 agent 的采集间隔时间和采集项。再由 proxy 将数据发送给 agent,agent采集完数据后，再由 proxy 中转发送给 server.
被动模式:
```

- 常用监控项

```text
1. 硬件监控: 交换机、防火墙、路由器
2. 系统监控: CPU、内存、磁盘、进程、TCP 等
3. 服务监控: Nginx、Mysql、Redis、Tomcat 等
4. web 监控: 响应时间、加载时间、状态码
```

- 自定义监控

```text
编写 shell 脚本非交互式取值，如 mysql 主从复制，监控从节点的 slave 的IO，show slave status\G;
取出 slave 的俩个线程 Slave_IO_Running 和 Slave_SQL_Running 的值都为yes 则输出一个0，如不同步则输出1，在 zabbix agent  的配置文件中，可以设置执行本地脚本 在zabbix server 的web端上上配置监控项配 mysql_slave_check，在触发器中判断取到的监控值，如1则报警，如0则输出正常。

自定义模板，需要新增图形。
```

## Web

### Tomcat

- 特点

```text
Tomcat是一个 JSP/Servlet 容器。其作为 Servlet 容器，有三种工作模式: 独立的 Servlet 容器、进程内的 Servlet 容器和进程外的 Servlet 容器。

进入 Tomcat 的请求可以根据 Tomcat 的工作模式分为如下两类:
1. Tomcat 作为应用程序服务器: 请求来自于前端的 web 服务器，这可能是 Apache, IIS, Nginx 等；
2. Tomcat 作为独立服务器: 请求来自于 web 浏览器；
```

- 运行模式

```text
1. bio tomcat7 以下默认模式
阻塞式I/O操作，此模式，每一个请求都要创建一个线程，线程开销较大，不能处理高并发的场景。通常最多处理几百个并发，效率低，不常用。

2. nio tomcat8以上默认采用 nio
niop是内置的模式，是一个基于缓冲区、并能提供非阻塞I/O操作的Java API，它拥有比传统I/O操作(bio)更好的并发运行性能

3. apr 从操作系统级别解决异步 IO 问题，大幅度的提高服务器的处理和响应性能, 也是 Tomcat 运行高并发应用的首选模式。用这种模式稍微麻烦一些，需要安装一些依赖库。
```

- 优化

```text
toncat自身优化
1、connector 方式选择 nio 或者 apr,默认 bio 支持并发性能低
2、配置文件线程池开启更多线程, 200线程

JVM（java虚拟机）内存优化
设置最大堆内存
设置新生代比例参数
设置新生代与老年代优化参数
```

### Nginx

- 特点

```text
1. 支持高并发，官方测试连接数支持5万，生产可支持2~4万。
2. 内存消耗成本低
3. 配置文件简单，支持 rewrite 重写规则等
4. 节省带宽，支持 gzip 压缩。
5. 稳定性高
6. 支持热部署
```

- 常用的模块与参数

```text
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

```text
last: 表示完成当前的 rewrite 规则
break: 停止执行当前虚拟主机的后续 rewrite
redirect :  返回302临时重定向，地址栏会显示跳转后的地址
permanent :  返回301永久重定向，地址栏会显示跳转后的地址
```

## Docker

- 简述

```text
Docker 一个容器化平台，它以容器的方式将应用程序和其所有依赖打包在一起，以确保应用程序在任何环境都能无缝运行。
```

- 容器隔离实现原理

**Cgroups**

**Namespace**

```text
Docker Enginer 使用了 namespace 对全区操作系统资源进行了抽象，对于命名空间内的进程来说，他们拥有独立的资源实例，在命名空间内部的进程是可以实现资源可见的。

Dcoker Enginer中使用的 NameSpace:
1. UTS nameSpace        提供主机名隔离能力
UTS namespace（UNIX Timesharing System 包含了运行内核的名称、版本、底层体系结构类型等信息）用于系统标识，其中包含了 hostname 和域名  domainname ，它使得一个容器拥有属于自己 hostname 标识，这个主机名标识独立于宿主机系统和其上的其他容器。

1. User nameSpace       提供用户隔离能力
User Namespace 允许在各个宿主机的各个容器空间内创建相同的用户名以及相同的用户 UID 和 GID，只是会把用户的作用范围限制在每个容器内，即 A 容器和 B 容器可以有相同的用户名称和 ID 的账户，但是此用户的有效范围仅是当前容器内，不能访问另外一个容器内的文件系统，即相互隔离、互不影响、永不相见。

1. Net nameSpace        提供网络隔离能力
每一个容器都类似于虚拟机一样有自己的网卡、监听端口、TCP/IP 协议栈等, Docker 使用 network namespace 启动一个 vethX 接口，这样你的容器将拥有它自己的桥接 ip 地址，通常是 docker0，而 docker0 实质就是 Linux 的虚拟网桥,网桥是在 OSI 七层模型的数据链路层的网络设备，通过 mac 地址对网络进行划分，并且在不同网络直接传递数据。

1. IPC nameSpace        提供进程间通信的隔离能力
一个容器内的进程间通信，允许一个容器内的不同进程的(内存、缓存等)数据访问，但是不能跨容器访问其他容器的数据。

1. Mnt nameSpace        提供磁盘挂载点和文件系统的隔离能力
每个容器都要有独立的根文件系统有独立的用户空间，以实现在容器里面启动服
务并且使用容器的运行环境，即一个宿主机是 ubuntu 的服务器，可以在里面启
动一个 centos 运行环境的容器并且在容器里面启动一个 Nginx 服务，此 Nginx 运
行时使用的运行环境就是 centos 系统目录的运行环境，但是在容器里面是不能
访问宿主机的资源，宿主机是使用了 chroot 技术把容器锁定到一个指定的运行
目录里面。

1. Pid nameSpace        提供进程隔离能力
Linux 系统中，有一个 PID 为 1 的进程(init/systemd)是其他所有进程的父进程，那么在每个容器内也要有一个父进程来管理其下属的子进程，那么多个容器的进程通 PID namespace 进程隔离(比如 PID 编号重复、器内的主进程生成与回收子进程等)。
```

- 网络模型

```text
1. host
启动 host 模式，Docker 不会为这个容器分配 NetWork NaneSpace，容器不会虚拟出自己的网卡，而是使用宿主机的 IP 和端口

2. container
这个模式指定新创建的容器和已经存在的一个容器共享一个 Network Namespace，而不是和宿主机共享。新创建的容器不会创建自己的网卡，配置自己的 IP，而是和一个指定的容器共享 IP、端口范围等。同样，两个容器除了网络方面，其他的如文件系统、进程列表等还是隔离的。两个容器的进程可以通过 lo 网卡设备通信。

3. none
在这种模式下，Docker容器拥有自己的 Network Namespace，但是，并不为 Docker容器进行任何网络配置。也就是说，这个 Docker 容器没有网卡、IP、路由等信息。需要我们自己为 Docker 容器添加网卡、配置IP等。

4.bridge
默认模式,此模式会为每一个容器分配 Network Namespace、设置 IP 等，并将一个主机上的 Docker 容器连接到一个虚拟网桥上。下面着重介绍一下此模式。
```

- Dockerfile

```text
FROM 应用基础镜像

COPY 将宿主机的文件拷贝到容器内

ADD 将宿主机的文件拷贝到容器内 具有解压功能

RUN 执行shell命令

CMD 运行容器内进程为为1的命令
```

## Kubernetes

### 概念

```text
Pod是kubernetes创建或部署的最小/最简单的基本单位，一个Pod代表集群上正在运行的一个进程。

一个 Pod 封装一个应用容器（也可以有多个容器），存储资源、一个独立的网络IP以及管理控制容器运行方式的策略选项。Pod 代表部署的一个单位: kubernetes 中单个应用的实例，它可以由单个容器或多个容器共享组成的资源。

Pod 里面有 pause 根容器(创建网络?)和用户业务容器


Runtime: docker, containerd, cni-o

Kubernetes 中的 Pod 使用可分两种主要方式:
1、one-container-per-Pod: Pod 中运行一个容器。可以将 Pod 视为单个封装的容器，但是 Kubernetes 是直接管理 Pod 而不是容器

2、sidecar: Pod 中运行多个需要一起工作的容器。Pod 可以封装紧密耦合的应用，它们需要由多个容器组成，它们之间能够共享资源(IP,网络、cpu、mem、挂载目录等). 网络共享相同的 net namespace 网络堆栈, 挂载目录可共享 volume mount.
```

### 组件

- 核心组件

```text
1. kube-apiserver: 提供了资源操作的唯一入口，并提供认证、授权、访问控制、API 注册和发现等机制；

2. controller manager: 资源对象的自动化控制中心,负责维护集群的状态，比如故障检测、自动扩展、滚动更新等；

3. scheduler: 负责资源调度的进程，按照预定的调度策略将Pod调度到相应的机器上；

4. kubelet: Node 节点上容器生命周期与容器资源管理的进程
+ 管理容器生命周期与容器资源管理
+ 节点管理: 获取 Node 上 Pod 信息，通过 apiserver 监听（watch+list） etcd 列表，同步信息
+ 读取监听信息并对节点 Pod 创建修改操作: 创建 Pod 数据目录、挂载卷、下载 secret、检查 Pod 容器状态以及 pause 容器启动与网络接管、Pod hash 值计算以及 Pod 的启动或重启
+ Pod 健康检测: livenessprobe, readnessprobe, startupprobe

5. container runtime: 负责镜像管理以及 Pod 和容器的真正运行,一般有 Docker 与 Containerd

6. kube-proxy: service 的透明代理与 LB
+ iptables + nat: 监听 apiserver 中 service 与 endpoint 信息，配置 iptables 规则，请求通过 iptables 转发给 Pod（service 与 Pod 过多时，太多 iptables 规则影响性能）
+ ipvs + ipset: 与 iptables 类似，使用 ipset 方式基于 iptables 高性能负载

7. etcd: 保存了整个集群的状态

```

- 可选组件

```text
1. kube-dns: 负责为整个集群提供DNS服务
2. Ingress Controller: 为服务提供外网入口
3. Heapster: 提供资源监控
4. Dashboard: 提供GUI
5. Federation: 提供跨可用区的集群
6. fluentd-bit:  日志组件
```

- 高可用与扩容

```text
1. 将 etcd 与 master 节点组件部署一起
2. 使用独立的 etcd 集群，不与 master 节点混合部署

组件横向与纵向扩容
节点的资源
```

### Pod 创建过程

```text
1. kubectl create Pod
首先进行认证与权限校验后，kubectl 会调用 apiserver 创建对象的接口，然后向 k8s apiserver 发出创建 Pod 的命令

2. k8s apiserver
apiserver 收到请求后，并非直接创建 Pod，而是先创建一个包含 Pod 创建信息的yaml 文件, 保存 etcd

3. controller manager
创建 Pod 的 yaml 信息会交给 controller manager，controller manager 根据配置信息将要创建的 Pod 资源对象放到等待队列中

4. scheduler
scheduler 查看 apiserver ，类似于通知机制。首先判断 Pod.spec.Node == null? 若为 null，表示这个 Pod 请求是新来的，需要创建；然后进行预选调度和优选调度计算，找出最 “闲” 的且符合调度条件的 Node。最后将信息在 etcd 数据库中更新分配结果: Pod.spec.NodeX(设置一个具体的节点) 同样上述操作的各种信息也要写到 etcd 数据库中。
分配过程需要两层调度: 预选调度和优选调度
(1) 预选调度: 一般根据资源对象的配置信息进行筛选。例如 NodeSelector,  HostSeletor 和节点亲和性等。
(2) 优选调度: 根据资源对象需要的资源和 Node 节点资源的使用情况，为每个节点打分，然后选出最优的节点创建 Pod 资源对象

5. kubelet
目标 NodeX 上的 kubelet 进程通过 apiserver，查看 etcd 数据库（kubelet通过 apiserver 的 WATCH 接口监听 Pod 信息，如果监听到新的 Pod 副本被调度绑定到本节点）监听到 kube-scheduler 产生的 Pod 绑定事件后获取对应的 Pod清单，然后调用本机中的 container runtime 初始化 volume、分配 IP、下载image 镜像，创建容器并启动应用.

6. controller manager
controller manmager 通过 apiserver 提供的接口实时监控资源对象的当前状态，当发生各种故障导致系统状态发生变化时，会尝试将其状态修复到 “期望状态”

### kube exec 原理
kubectl  -> http request upgrade to SPDY -> kube-apiserver -> kubelet -> dockershim/containerd-shim
```

### resources

- yaml

```text
annotation: 注解和 label 类似, 标记一些特殊信息
configmap: 修改配置参数
```

- RC / RS / Deplyment / StatefulSet

```text
1、Replication Controller 和 Replica Set 两种资源对象， RC 和 RS 的功能基本上是差不多的，唯⼀的区别就是 RS ⽀持集合的 selector

RC:
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
每个 Pod 都有稳定唯一的网络标识可以发现集群里的其他成员
控制的 Pod 副本的启停顺序是受控的
Pod 采用稳定的持久化存储卷
```

- Service

```text
一个 Pod 只是一个运行服务的实例，随时可能在一个节点上停止，在另一个节点以一个新的 IP 启动一个新的 Pod，因此不能以确定的 IP 和端口号提供服务。要稳定地提供服务,需要服务发现和负载均衡能力.

在 k8s 集群中，客户端需要访问的服务就是 Service 对象。每个 Service 会对应一个集群内部有效的虚拟 IP，集群内部通过虚拟 IP 访问一个服务

ingress -> service -> endpoint

LB -> NodePort -> CNI bridge -> Pod
```

- Volume

```text
volume（存储卷）是 Pod 中能够被多个容器访问的共享目录
emptyDir Volume 是在 Pod 分配到 Node 时创建的。临时空间分配
```

### lifecycle

```text
1. livenessProbe
存活探针，检测容器是否正在运行，如果存活探测失败，则 kubelet 会杀死容器，并且容器将受到其重启策略的影响，如果容器不提供存活探针，则默认状态为 Success，livenessprobe 用于控制是否重启 Pod.

2. readinessProbe
就绪探针，如果就绪探测失败，端点控制器将从与 Pod 匹配的所以 Service 的端点中删除该 Pod 的 IP 地址初始延迟之前的就绪状态默认为 Failure（失败），如果容器不提供就绪探针，则默认状态为 Success，readinessProbe 用于控制 Pod 是否添加至 service.

3. startupprobe
启动探针
```

### Others

```text
1. hpa 指标以 request 为准

2. 主机调度 Pod 以 request 为准


request limit 的分级?
```

> Reference:
>
> 1. [乌云知识库](https: //github.com/SuperKieran/WooyunDrops)
> 2. [mindoc](https: //github.com/mindoc-org/mindoc)
> 3. [Docker与Containerd](https://www.qikqiak.com/post/containerd-usage/)
