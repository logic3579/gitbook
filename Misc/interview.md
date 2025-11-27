---
description: interview
---

# Interview

## AppDefinition and Development

### Application Definition & Image Build

#### 什么是 Helm？为什么在 Kubernetes 中使用？

```console
Helm 是 Kubernetes 中的包管理器，允许定义、安装和升级复杂的 Kubernetes 程序。

核心概念：
- Chart：Helm 软件包，包含一个应用在 Kubernetes 上运行所需的所有资源定义的文件集合。
- Release：在 Kubernetes 中运行的一个 Chart 实例。安装或更新 Chart 时，会生成一个新的 release。
- Repository：HTTP 服务器，用于存放和共享 Charts。

为什么使用：
- 简化部署：将复杂的 Kubernetes YAML 文件打包成统一的一个 Chart，实现一键部署。
- 管理复杂度：对于由多个 Deployment、Service、ConfigMap 等资源组成的应用，Helm 提供了生命周期的能力。
- 参数化配置：通过 values.yaml 文件，可以将配置与 Chart 模板分离，使得一套 Chart 可以在不同环境（开发、测试、生产）中复用。
- 易于共享和开发：Chart 可以打包并上传到仓库（如 Harbor、GitLab），方便团队内部或社区共享。
```

#### Helm 都有哪些内置对象？helm upgrade 和 helm rollback 是如何工作的？

```console
内置对象：
- {{ .Values }}：访问传入 Chart 的 values.yaml 文件中的值。如：{{ .Values.image.tag }}。
- {{ .Release }}：访问当前 Release 的信息。如：{{ .Release.Name }}。
- {{ .Chart }}：访问 Chart.yaml 文件中的元数据。如：{{ .Chart.Name }}。
- {{ .Capabilities }}：访问关于 Kubernetes 集群的信息。如：{{ .Capabilities.KubeVersion }}。

helm upgrade：
- Helm 获取最新的 Chart 和 Values。
- 使用上面的输入渲染生成新的 Kubernetes 资源清单。
- 将新生成的清单与当前集群中实际运行的资源状态进行对比（三路战略合并补丁）。
- 仅发送必要的更改到 Kubernetes API Server 以将应用更新到期望状态。
- 每次成功的升级都会创建一个新的 Revision（版本号递增）。

helm rollback：
- 从历史版本（Revision）中查找指定版本的 Chart 和 Values。
- 使用这些旧的配置渲染模板。
- 将重新渲染的模板与当前状态对比，计算出如何将应用恢复到旧版本状态。
- 执行更改，并将这次回滚操作也记录为一个新的 Revison。
```

#### 编写一个生产可用的 Helm Chart 最佳实践

```console
- 为资源使用正确的标签：确保所有模板化的资源都有标准标签，如 app.kubernetes.io/name, app.kubernetes.io/instance, app.kubernetes.io/version, helm.sh/chart。

- 定义 values.schema.json：为 values.yaml 提供一个 JSON Schema，可以在安装/升级时验证用户提供的 values 是否有效，避免因配置错误导致部署失败。

- 谨慎使用 Helm Hooks：明确 Hooks 的权重（helm.sh/hook-weight）以确保执行顺序，并为其设置删除策略（"helm.sh/hook-delete-policy": hook-succeeded）。

- 使用 helm lint：在打包 Chart 前，始终使用 helm lint 命令来检查 Chart 的语法和可能的问题。

- 使用 include 函数代替 template：在模板中，使用 include 函数可以更好地处理缩进和上下文，template 函数已弃用。

- 版本化：遵循语义化版本控制（SemVer）为 Chart 编号。
```

### CICD

#### 什么是 ArgoCD？什么是 GitOps，以及 ArgoCD 如何实现 GitOps？

```console
ArgoCD 是一个基于 Kubernetes 的声明式、GitOps 持续交付工具。核心思想是将 Git 仓库作为期望状态的唯一来源，并自动将 Kubernetes 集群的实际状态同步至 Git 中声明的期望状态。

GitOps 核心原则：
- 声明式：系统的期望状态必须以声明方式描述（如 Kubernetes YAML）。
- 版本控制且不可变：声明的期望状态必须存储在版本控制系统（如 Git）中，作为唯一可信源。
- 自动交付：对 Git 仓库的变更会自动部署到系统中。
- 软件代理：使用自动化 Agent（如 ArgoCD）来持续协调实际状态与期望状态之间的差异。

ArgoCD 实现 GitOps：
- 声明式 & 版本控制：ArgoCD 的 Application 资源指向一个 Git 仓库或 Helm 仓库，其中的文件就是声明式的期望状态。
- 自动交付：ArgoCD 可以配置自动同步（automated），Git 仓库有新的提交，ArgoCD 可以检测到并立刻变更应用。
- 软件代理：ArgoCD Controller 就是运行在集群中的 Agent，持续监控集群状态和 Git 状态，并在出现偏差（Drift）时进行协调（reconcile）。
```

#### ArgoCD 的 Application、Project、ApplicationSet 分别什么？如何回滚 ArgoCD 管理的应用

```console
Application：
核心自定义资源（CRD），定义一个来源（Source，如 Git 仓库和路径、Helm Chart）和一个目标（Destination，如目标集群和命名空间）。一个 Application 资源代表一个需要被同步的应用。

Project：用于分组和管理 Applications，提供一套安全隔离和多租户的规则。可以限制：
- 源仓库：Application 只能从哪些 Git/Helm 创建。
- 目标集群和命名空间：Application 可以部署到哪些集群和命名空间。
- 可执行资源：允许部署哪些 Kubernetes 资源（如可以禁止部署 PodSecurityPolicy）。
- 权限：哪些用户/角色可以管理该项目下的 Applications。

ApplicationSet：用于自动化地生成多个 Applications。可以根据一个模板和一组生成器（Generators）来动态创建 Application 资源。
- 使用场景：需要为每个分支、每个环境或每个客户部署一个相同的应用的不同实例时，使用 ApplicationSet 可以避免手动创建大量重复的 Application 资源。比如使用 git 生成器为仓库的每个分支自动创建一个 Application。

如何回滚：
- Git Revert 或 Git Reset：还原提交。或使用分支硬重置到上一个良好的提交（git reset --hard <good-commit-hash> && git push -f）
- 同步：更改推送 Git 后，ArgoCD 检测到新的期望状态，并开始自动同步到之前版本。
- 手动同步（临时）：在 ArgoCD UI 中手动 APPROVE 操作临时将应用同步到历史的某个版本。
```

#### 如何基于 ArgoCD 实现一个部署工作流程？

```console
部署工作流程：
1. 开发者将应用代码提供到 GitHub/GitLab 指定分支，通过 CI 管道（如 Jenkins/GitLab CI/GitHub Actions 等）触发，执行编译、测试、构建等任务。
2. CI 管道将新构建等镜像标签更新到 Kubernetes 清单中（如用 sed 替换 `image: nginx:1.0` 为 `image: nginx:1.1` ），然后将更改提交到 Git 仓库的另一个分支或单独的 ArgoCD 专用仓库。
3. ArgoCD 持续监控 Git 仓库和目标分支。监测到清单发生变化（镜像标签变化）。
4. ArgoCD 根据配置的同步策略（automated 或 manual）：
- automated：自动将更改应用到 Kubernetes 集群。
- manual：在 UI/CLI 中显示 OutOfSync 状态，等待用户手动操作 Sync 动作。
5. ArgoCD 执行滚动更新，部署新版本 Pod。并持续监控应用的健康状态，报告部署成功或失败。
```

#### ArgoCD 最佳实践

```console
推荐架构
1. 两个核心仓库分离：
- 应用代码仓库（Application Code Repository）：存放源代码、Dockerfile 和 CI 流程配置（如 .gitlab-ci.yml 或 Jenkinsfile）
- 配置仓库（GitOps Config Repository）：存放所有 Kubernetes 清单文件（Kustomize/Helm Charts）和 ArgoCD Application 定义。ArgoCD 直接监控的仓库。
2. 流程分离：
- CI（Continuous Integration）：由 Jenkins、GitLab CI、GitHub Actions 等工具完成。负责代码构建、测试、打包镜像并推送到镜像仓库）
- CD（Continuous Delivery）：由 ArgoCD 完成。CI 流程的最后一步是更新 GitOps 配置仓库（如修改 kustomization.yaml 中的镜像标签），ArgoCD 检测到后自动部署应用。

实践细节：
1. 仓库结构与环境分离：dev、staging、prod 使用独立的 namespace 或集群。使用 Kustomize 的 overlays 或 Helm 的 values.yaml 管理不同环境的差异。
2. ArgoCD 配置与管理
- 使用 App of Apps 模式：创建一个母应用（app-of-apps.yaml），只饮用其他 ArgoCD Application，可以一键同步整个环境。
- 同步策略设置：开发/测试/UAT 环境使用自动同步策略，生产环境使用手动同步或同步前需权限校验的策略。
- 同步选项：开启 Prune Resources（自动清理已删除资源）与 Self Heal（自动恢复 Git 中声明的状态）
- 项目与 RBAC：使用 Projects 对应用进行逻辑分组，严格的配置 RBAC 规则限制团队只能访问所属的项目和应用。
3. 安全与密钥管理：集成 Vault 动态拉取密钥。
4. 部署策略与回滚：使用 ArgoCD Rollouts 控制器实现更安全的发布策略。可以自动进行流量切换、分析指标并决定继续发布或回滚。

安全实践：
- 使用 RBAC：精细配置 ArgoCD 的 argocd-rbac-cm ConfigMap，遵循最小权限原则，控制用户和项目对资源的访问。
- 使用 Projects：用 Projects 隔离租户和环境，限制其原仓库和目标命名空间。
- 保护 Git 仓库：Git 仓库是入口，必须严格控制写入权限。只允许 CI 系统和少量管理员推送变更。
- 使用 SSO 集成：尽量不使用本地用户，集成现有的 OIDC 提供商（如 GitHub、GitLab、Google）进行身份验证。
- Secret 管理：不要将密码、密钥等明文放在 Git 中。集成 Sealed Secrets、HashiCorp Vault 等工具管理 secrets。
- 禁用匿名访问：在 argocd-cm ConfigMap 中配置 policy.default: role:readonly 或更严格策略。
```

#### 什么是 Jenkins？主要功能是什么？什么是 Jenkins 的 Master/Agent 架构？

```console
Jenkins 是一个开源的、可扩展的 CI/CD 工具，用于自动化开发过程中的构建、测试、部署等任务。

主要功能：
- 持续集成（CI）：自动触发代码编译、单元测试、代码质量检查等。
- 持续交付/部署（CD）：自动化地将应用部署到各种环境（测试、预生产、生产）。
- 任务调度：执行定时任务（如 nightly build）。
- 丰富的生态系统：超过1800个插件与几乎所有开发、测试、部署工具集成。

Master/Agent 架构：
- Master 主节点：负责管理中心、配置 Job、调度构建任务、管理 Agent。
- Agent（Worker）代理节点：负责具体执行 Master 分配的任务，一台 Master 可以连接和管理多个 Agent。
- 好处：环境隔离（如不同项目使用不同的构建环境）；可以横向扩展，增加 Agent 提高并行构建能力；可以将 Agent 放在哪玩提高安全性。
```

#### 什么是 Jenkinsfile？好处是什么？

```console
Jenkinsfile 是一个文本文件，使用 Groovy DSL 语法来定义整个 CICD 流水线（Pipeline），通常放在项目的源代码仓库根目录下。

好处：
- 流水线即代码（Pipeline as Code）：将流水线的配置像代码一样进行版本控制、评审和迭代。
- 单一可信源：每个分支都可以有自己的流水线定义，便于实现不同分支的不同构建策略。
- 可复用性：可以编写共享库（Shared Libraries），抽象通用逻辑，供多个项目的 Jenkinsfile 调用。
- 更强的功能：相比传统自由风格项目，声明式流水线提供更强大的结构、错误处理和并行执行能力。
```

### Database & Streaming & Messaging

#### MySQL 的数据类型与存储引擎。

```console
数据类型：
- CHAR：定长字符串。定义时为 CHAR(n)，无论实际存储多少内容，都会占用 n 个字符的存储空间（不足部分使用空格填充）。因为长度固定，存取速度比 VARCHAR 快。适用场景：MD5 哈希值、证件 ID、定长代码等。
- VARCHAR：变长字符串。定义时为 VARCHAR(n)，存储的是实际字符串内容+1～2个字节的长度信息，节省存储空间。适用场景：文章标题、用户备注、评论等。

存储引擎：
- MyISAM 引擎：不支持事务；只有表级锁；不支持外键；崩溃恢复功能较弱；非聚簇索引。
- InnoDB：支持 ACID 事务特性；支持行级锁（并发性能高）；支持外键；聚簇索引（数据文件本身按主键索引）。
```

#### 什么是 MySQL 中的索引？都有哪些索引类型？

```console
索引：帮助 MySQL 高效获取数据的数据结构（通过是 B+Tree）。类似于书的目录。
索引优势：加快数据检索速度；通过唯一索引可以保证数据库表中每一行数据的唯一性。
索引劣势：需要占用额外存储空间；会降低写入速度（INSERT/UPDATE/DELETE）。

B+Tree 索引：
- 支持范围查询（>, <, BETWEEN, LIKE 'prefix%'）和排序（ORDER BY）。
- 可以从索引的最左前缀开始匹配，进行高效查找。
- 默认从最常用的索引类型，适用于绝大多数场景。

Hash 索引：
- 不支持范围查询和排序。
- 支持等值查询（=, IN()），且速度极快（O(1)复杂度）。
- 不是按索引值排序的。

聚簇索引：
- 定义：表数据行的物理存储顺序与索引顺序相同。一个表只能有一个聚簇索引。
- InnoDB：InnoDB 的主键就是聚簇索引。如果没有主键，则选择第一个唯一非空索引，如果都没有，则会隐式创建一个主键作为聚簇索引。
- 优点：根据主键查询非常快，因为一次检索就能找到数据。

非聚簇索引（二级索引）：
- 定义：索引的存储顺序与数据的物理存储顺序无关。叶子节点存储的不是完整的数据行，而是对应行的主键值。
- 查询过程：使用非聚簇索引查询时，需要两次查找：首先在二级索引的 B+Tree 中找到对应的主键，然后拿着这个主键回到聚簇索引的 B+Tree 中查找完整的行数据。这个过程称为回表。
```

#### MySQL 的常用的架构有哪些？

```console
主从复制架构描述：
- 一个主节点承担所有写操作。
- 一个或多个从节点异步地复制主节点的数据变更，通常只承担读操作。
- 复制基于主节点的 binlog 实现。

主从复制架构原理：
- 主节点将数据变更事件写入二进制日志。
- 从节点的 I/O 线程从主节点拉取 binlog。
- 从节点的 SQL 线程重放 binlog 中的事件，应用数据变更。

主从复制架构优缺点：
- 读写分离：扩展读能力，将读请求分散到多个从节点。
- 数据备份与高可用：从节点可以作为实时的数据备份节点。主节点故障时可以手动提升一个从节点为主节点。
- 数据延迟：异步复制存在主从延迟，可能导致从节点读到旧数据。
- 写瓶颈：写操作无法扩展，仍然集中在主节点。
- 故障非自动切换：需人工切换或通过第三方工具实现自动故障转移。

主从复制 + MHA/Orchestrator 架构：
- 在基础主从复制架构之上，部署 MHA/Orchestrator 高可用管理组件。
- 管理器持续监控主节点的健康状态。

双主/多主复制架构（不推荐）

Group Replication & InnoDB Cluster（官方方案）：
- Group Replication：基于 Paxos 协议的多主/单主同步插件。节点间通过组通信保持强一致性。
- InnoDB Cluster：在 Group Replication 之上，集成了 MySQL Shell 和 Mysql Router，提供一个完整的、开箱即用的高可用解决方案。
```

#### 什么是 Redis？主要特点和数据类型是什么？

```console
Redis 是一个基于内存的键值数据库，常被用作缓存、消息队列和数据库。支持多种数据结构

Redis 特点：
- 基于内存：数据主要存储在内存中，避免磁盘 I/O 的瓶颈。
- 单线程模型：核心网络请求处理和数据操作是单线程的，避免多线程的上下文切换和竞争条件，保证原子性。
- 高效数据结构：简单高效的数据结构，如动态字符串、跳跃表、压缩列表等。
- I/O 多路复用：使用 epoll、kqueue 等机制，用单个线程处理大量的并发连接。

数据类型：
- String：最简单的键值对。用于缓存、计数器、分布式锁等。
- List：双向链表。用于消息队列、最新文章列表、朋友圈时间线等。
- Hash：键值对集合。用于存储对象信息（如用户信息）。比 String 更节省空间。
- Set：无序、唯一的集合。用于共同关注、抽奖、标签系统等。
- Sorted Set：有序集合。每个元素关联一个分数。用于排行榜、带权重的消息队列。
- Bitmaps：位图。用于大量布尔的存储和统计，如用户签到、日活跃用户统计。
- HyperLogLog：用于基数统计（估算一个集合中不重复元素的个数），如统计网站的 UV。
- Streams：用于消息队列，支持多消费者和消息持久化，Kafka 的轻量级替代。

数据淘汰机制：
- volatile-lru     从已设置过期时间的数据集中挑选最近最少使用的数据淘汰
- volatile-ttl     从已设置过期时间的数据集中挑选将要过期的数据淘汰
- volatile-random  从已设置过期时间的数据集中任意选择数据淘汰
- allkeys-lru      从所有数据集中挑选最近最少使用的数据淘汰
- allkeys-random   从所有数据集中任意选择数据进行淘汰
- noeviction       禁止驱逐数据
```

#### Redis 持久化规则是什么？

```console
RDB（Redis Database）
- 原理：特定的时间点或写入特定的 key 数量时创建整个数据的快照。
- 数据文件：二进制压缩文件（dump.rdb）。
- 优点：文件紧凑，恢复速度快，适合备份和灾难恢复。
- 缺点：可能丢失最后一次快照后的所有数据；数据量大时创建快照的 fork 子进程会阻塞主进程。

AOF（Append Only File）
- 原理：记录每一次写操作命令，以日志形式追加。
- 数据文件：文本文件（appendonly.aof）
- 优点：数据安全性高，默认每秒同步，最多丢失1秒数据；AOF 文件易于理解和解析。
- 缺点：文件通常比 RDB 大，恢复速度通常比 RDB 慢；AOF 重写期间会有阻塞。

如何选择：生产环境通常使用混合持久化（同时开启 RDB 和 AOF）
- 利用 AOF 保证数据的安全性，最多丢失一秒数据。
- 利用 RDB 进行快速数据恢复，并且 AOF 重写时的基础数据时 RDB 格式的。兼具 RDB 和 AOF 的优点。
- Redis4.0 之后，重启 Redis 时优先会加载 AOF 文件。
```

#### Redis 的主从复制原理是什么？有哪些高可用的方案？

```console
主从复制原理：
1. 从节点执行 SLAVEOF 命令，向主节点发起连接。
2. 主节点执行 BGSAVE 生成 RDB 快照文件，并缓存在内存中。
3. 主节点将 RDB 文件发送给从节点，从节点清空旧数据后载入 RDB 文件。
4. 复制过程中，主节点会将新的写命令缓存在复制缓冲区。
5. 主节点将复制缓冲区的写命令发送从节点，从节点执行写命令，保持与主节点的数据一致性。
6. 主节点持续地将写命令异步发送给从节点。

Redis Sentinel（哨兵）高可用方案：分布式系统，用于管理多个 Redis 实例，提供自动故障转移。
- 监控：持续检查主节点和从节点是否正常运行。
- 通知：当监控的实例出现问题时，可通过 API 通过管理员或应用程序。
- 自动故障转移：如果主节点故障，Sentinel 会将一个从节点提升为新的主节点，并让其他从节点指向新的主节点。
- 配置提供者：客户端应用会连接到 Sentinel 来获取当前主节点的地址。

Redis Cluster（集群）高可用方案：数据自动分片到多个节点，在部分节点故障时，集群仍能继续对外提供服务。它是一个 AP 系统（CAP 定理中），即在网络分区发生时，优先保证可用性，并尽可能保证数据的一致性。
- 数据分片：整个集群分为 16384 个槽，每个主节点在集群初始化时分配 0-16383 中属于自己的哈希槽，可以通过 CLUSTER SLOTS 查看槽的分配情况。
- 路由：数据通过哈希算法后得到 0-16383 之间的槽编号，某些 Redis 客户端也会在内部维护一份“槽位-节点”的映射表。通过直接连接或重定向（MOVED 或 ASK）将数据写入到正确的节点的槽位中。
- 节点：主节点负责槽相关的数据读写命令，并参与故障选举。从节点通过异步复制同步数据，当主节点故障时提升从节点为主节点实现故障转移。
- 故障检测：Gossip 协议与投票
    1. PING/PONG：集群中每个节点都会定期通过 Gossip 协议向其他节点发送 PING 消息，接收方回复 PONG。以此交换元数据并检测节点是否可达。
    2. 主观下线：如果节点 A 在 cluster-node-timeout 时间内无法与节点 B 通信，节点 A 会将节点 B 标记为主观下线。
    3. 客观下线：主观下线只是节点 A 的“个人观点”。节点 A 会通过 Gossip 消息在集群中传播“节点B可能下线了”的信息。当集群中大多数主节点都认为节点 B 主观下线时，节点 B 的状态就被提升为客观下线。此时，集群认为节点 B 真的故障了，可以开始故障转移。
- 故障转移：从节点晋升
    1. 当一个主节点被标记为客观下线后，它的从节点会开始竞选成为新的主节点。
    2. 选举资格：从节点的数据不能太旧，其主从复制偏移量需要尽可能接近原主节点（数据尽可能新）。
    3. 投票：所有正常的主节点都会参与投票。每个主节点在一次故障转移选举中只有一票。
    4. 获胜条件：一个从节点需要获得超过半数主节点的投票才能获胜。
    5. 槽继承：获胜的从节点执行 SLAVEOF NO ONE，提升自己为主节点，并接管原主节点负责的所有哈希槽。然后通过 Gossip 协议广播，通知整个集群这一变化。
```

#### 什么是 Redis 的缓存穿透、缓存击穿以及缓存雪崩？如何解决？

```console
缓存穿透：大量请求查询一个数据库不存在的数据，导致请求直接穿透 Redis 缓存，全部打到数据库上，造成数据库压力大。

缓存穿透解决方案：
- 缓存空对象：即使从数据库中没查到，也把一个空值（如 key=null）缓存起来，并设置一个较短的过期时间。后续的请求可以命中缓存。
- 布隆过滤器：在缓存之前加一层布隆过滤器，它能够以较小的空间代价判断一个元素是否一定不存在于集合中。对于布隆过滤器判断为不存在的请求，可以直接返回无需查询缓存和数据库。
- 接口层增加校验：对传参进行校验（如说 id 是从1开始的，那么id<=0的直接拦截）


缓存击穿：一个热点 key 在缓存过期的瞬间，同时有大量请求过来，导致大量请求到数据库中。

缓存击穿解决方案：
- 设置热点数据永不过期：通过业务逻辑或后台任务定期更新缓存。
- 互斥锁：缓存失效后，只允许一个线程去查询数据库并构建缓存，其他线程等待。可以使用 Redis 的 SETNX 命令实现分布式锁。

缓存雪崩：某一时刻大量缓存 key 同时失效，或者 Redis 集群宕机，导致所有请求直接到数据库导致数据库崩溃。

缓存雪崩解决方案：
- 设置不同的过期时间：在原有的过期时间加上一个睡机制，避免大量 key 在同一时间过期。
- 构建高可用 Redis 集群：通过主从、哨兵或 Cluster 模式，防止 Redis 本身宕机。
- 服务降级与熔断：在应用层做限流和降级，当检测到数据库压力过大时，对非核心业务直接返回默认值或错误页面。
```

#### Redis 最佳实践

```console
集群模式部署：
- 至少三主三从，如果只有两个主节点，当一个主节点宕机时，剩下的一个主节点无法满足“大多数”（N/2+1）的投票条件，导致集群无法完成故障转移。
- 合理的 cluster-node-timeout：默认15秒。在网络环境较差或机器负载较高时，可以适当调大，避免因临时拥塞导致不必要的故障转移。
- 所有节点全互联：确保防火墙规则允许所有节点之间的端口（客户端端口和集群总线端口=客户端端口+10000）互通。
```

#### 什么是 Kafka？核心架构与应用场景是什么？

```console
Kafka 是一个高吞吐、低延迟、分布式的发布-订阅消息系统，基于磁盘实现持久化。更像是一个分布式提交日志。

核心架构：
- Broker：独立的 Kafka 服务器节点，多个 Broker 组成一个集群。
- Topic：消息的类别或主题，逻辑上的概念。生产者发送消息到 Topic，消费者从 Topic 拉取消息。
- Partition：分区，是 Topic 在物理上的分组。一个 Topic 可以分层多个 Partition，分布在不同 Broker 上。每个 Partition 是一个有序、不可变的序列，且每条消息在 Partition 内部都有一个 offset。
- Producer：生产者，向 Topic 发布消息的客户端。
- Consumer：消费者，向 Topic 订阅并消费消息的客户端。
- Consumer Group：消费者组，由多个 Consumer 实例组成，共同消费一个 Topic。Group 是 Kafka 实现队列和发布-订阅模型的关键。
  - 队列模型：所有 Consumer 在一个 Group 内，每条消息只会被组内一个 Consumer 消费。
  - 发布-订阅模型：每个 Consumer 在不同 Group 中，每条消息会被所有 Group 消费。

应用场景：
- 消息队列/系统解耦：连接上下游系统，实现异步通信。
- 流处理平台：作为实时流数据处理管道（如 Flink、Spark Streaming）的数据源。
- 用户行为追踪/日志聚合：收集各服务的日志和用户活动数据，统一存入大数据处理系统。
- 事件驱动架构：作为事件的骨干，驱动微服务之间的状态变更和通信。
```

#### 为什么 Kafka 能做到高吞吐、低延迟？

```console
顺序读写：Kafka 将消息追加到 Partition 末尾，充分利用磁盘顺序读写性能，性能堪比内存。

零拷贝：使用 sendfile 系统调用，数据直接从磁盘文件通过 DMA 拷贝到网卡缓冲区，bypass 了应用程序和内核缓冲区，减少上下文切换和数据拷贝次数。

页缓存：Kafka 不使用 JVM 内存，而是利用操作系统的页缓存来缓存数据。避免了 JVM GC 的开销，并且可以利用操作系统的内存管理优势。

批量处理：Producer 和 Consumer 都支持批量发送和拉取消息，大大减少了网络 I/O 开销。

数据压缩：Producer 端可以对批量消息进行压缩（如 Snappy、LZ4、GZIP），减少网络传输和磁盘存储的压力。
```

#### Kafka 的消息投递语义都有哪些？什么是 Kafka 副本机制与 ISR？Kafka 如何保证消息不丢失？

```console
消息投递语义：
- At least once：消息绝不会丢失，但可能重复。通过 Producer 的 retries 和 Consumer 处理完再提交 offset 实现。
- At most once：消息可能丢失，但绝不会重复。通过 Producer 不重试和 Consumer 自动提交 offset 实现。
- Exactly once：消息有且仅被处理一次。Kafka 通过幂等性 Producer 和事务来实现精确一次。
  - 幂等性 Producer：通过为每个 Producer 实例分配一个 PID 和每个消息分配一个序列号，Broker 去重，避免因 Producer 重试导致的重复。
  - 事务：允许将消费和生产作为一个原子操作，实现 读-处理-写 模式的精确一次。

副本机制：Kafka 为每个 Partition 创建多个副本，分布在不同 Broker 上。其中一个是 Leader 副本，处理所有读写请求，其他是 Follower 副本，被动从 Leader 同步数据。

ISR：In-Sync Replicas，指与 Leader 副本保持同步的副本集合（包含 Leader）
- Follower 副本会定期向 Leader 发送 FETCH 请求来同步数据。
- 如果一个 Follower 在 replica.lag.time.max.ms 时间内没有向 Leader 发起 fetch 请求，或者落后 Leader 的消息数量超过 replica.lag.max.messages（已弃用），就会被 Leader 从 ISR 中移除，重新追上 Leader 进度后再加回。
- 重要性：只有 ISR 中的副本才有资格在 Leader 宕机时选举为新的 Leader。

如何保证消息不丢失？
Producer 端：
- 设置 acks=all（或-1）。意味着 Leader 副本必须等待所有 ISR 副本都成功接收消息后，才会向 Producer 返回确认。
- 设置 retries 为一个较大的值，并处理好重试可能带来的消息重复问题。
Broker 端：
- 设置 unclean.leader.electon.enable = false。防止落后太多的非 ISR 副本成为 leader，导致数据丢失。
- 设置 replicas.factor >= 3，确保每个 Partition 有足够的副本。
- 设置 min.insync.replicas >= 2，表示最少存在2个 ISR 副本，Producer 才认为写入成功。与 acks=all 配合构成 Quorum 机制。
Consumer 端：
- 关闭自动提交 offset （enable.auto.commit = false），改为在消息被业务逻辑成功处理后再手动提交 offset。
```

#### Kafka 最佳实践

```console
集群规划与设置
- Broker 配置：
  - log.dirs：配置多个物理磁盘路径，不同 Partition 分布不同磁盘，提升 I/O 并行度。
  - num.network.threads 和 num.io.threds：根据服务器 CPU 核心数和网络情况适当调大。
  - auto.create.topic.enable：生产环境必须为 false，防止创建无用 Topic。
- Topic 规划：
  - 分区数：决定 Topic 最大并发能力。通常总分区数不应超过集群 Broker 数 * (num.io.threads | number of CPU cores)，建议从最小（如6-12）开始，根据监控数据进行扩容。
  - 副本数：生产环境至少为3。保证即使一台 Broker 宕机，数据依然可用且不影响写入（在 min.insync.replicas = 2）。

运维与监控
- 容量规划与监控：
  - 磁盘：磁盘使用率，设置合理的数据保留策略（log.retention.hours 或 log.retention.bytes）。Kafka 在磁盘使用率超过85-90%后会急剧下降。
  - 网络：监控网络吞吐量，避免成为瓶颈。
  - 关键指标：监控 ISR 数量变化、Under Replicated Partitions、Controller 状态、请求处理延迟。
- 客户端最佳实践：
  - Producer：
    - 使用带回调的 send 方法，处理发送失败的情况。
    - 根据业务对延迟和可靠性的要求，合理设置 linger.ms 和 batch.size 以优化批量发送。
    - 对可靠性要求高的场景，使用 acks=all 和 min.sync.replicas。
  - Consumer：
    - 始终使用 Consumer Group。
    - 手动提交 offset，并确保消息处理成功后再提交。
    - 处理好 Rebalance：在 ConsumerRebalanceListener 中实现优雅的推出逻辑，如在 Rebalance 开始时提交 offset。

常见问题排查：
- Consumer Lag 高：消费速度跟不上生产速度。需要检查 Consumer 应用性能（GC、CPU）、网络、是否处理中阻塞。可以考虑增加分区数和同 Group 下的 Consumer 实例数。
- Leader Not Available：通常是由于 Controller 选举或网络分区导致 Partition Leader 暂不可用。需要检查 Broker 健康状态、网络连通性、Zookeeper 连接状态。
- 消息重复消费：Consumer 处理完消息后提交 offset 前崩溃，重启后会重新消费已处理的消息。需要在消费逻辑中具备幂等性。
```

#### 什么是 RocketMQ？核心架构与特点是什么？存储模型是什么？

```console
RocketMQ 是一个分布式、队列模型的消息中间件，具有低延迟、高可靠、万亿级容量和灵活的扩展性。

核心架构：
- NameServer: 轻量级服务发现与路由中心。Broker 向所有 NameServer 注册，Producer 和 Consumer 从 NameServer 获取路由信息（哪个 Topic 在哪个 Broker 上）。NameServer 之间互不通信，是无状态的，因此非常轻量级和高效。
- Broker：消息存储和转发节点。负责消息的存储、投递和查询。通常采用主从架构（Master-Slave）实现高可用。
- Producer：消息生产者，向 Broker 生产消息。
- Consumer：消息消费者，从 Broker 拉取消息。消费者必须属于一个消费者组。

存储模型：
- CommitLog：所有 Topic 的所有消息都顺序追加到同一个 CommitLog 文件中。极致利用磁盘顺序写性能，写入吞吐量非常高。
- ConsumeQueues：
  - CommitLog 的索引文件，每个 Topic 的每个 Queue 都有一个对应的 ConsumeQueue。
  - 存储的是消息在 CommitLog 中的物理偏移量、消息大小和 Tag 哈希码。
  - 优点：消费时，先查询轻量级 ConsumeQueue，再根据物理偏移量到 CommitLog 中精准读取消息内容。实现了写时合并，读时分离，兼顾了写入性能和消费速度。
- 工作流程：
  - 生产者发送消息，Broker 将其顺序写入 CommitLog。
  - 一个后台线程 ReputMessageService 异步地将消息的索引构建到对应的 ConsumeQueue 中。
  - 消费者拉取消息时，先读 ConsumeQueue 得到索引，再根据索引去 CommitLog 拿到完整的消息体。

```

#### RocketMQ 支持哪些消息类型？什么是 RocketMQ 的事务消息机制？RocketMQ 如何保证消息不丢失？

```console
支持消息类型：
- 普通消息：无特殊功能的消息。
- 顺序消息：保证消息在同一个 MessageQueue 内被严格顺序地生产和消费。全局顺序需要 Topic 只有一个 MessageQueue。
- 广播消息：一条消息被一个 Consumer Group 下的所有 Consumer 实例消费一次。
- 延迟消息：消息发送后，不会立即被消费，而是在指定延迟时间后才会投递给 Consumer。RocketMQ 原生支持 18 个延迟级别（1s, 5s, 10s, 30s, 1m ... 2h）。
- 事务消息：事务消息机制的消息。

事务消息：用于解决本地事务执行和消息发送的原子性问题。核心阶段是两阶段提交和事务状态回查。
- 第一阶段：
  - 发送半消息，Producer 向 Broker 发送一条“半消息”，此时这条消息对 Consumer 不可见。
  - 执行本地事务：Producer 执行本地数据库事务。
- 第二阶段：提交或回滚
  - 根据本地事务执行结果。Producer 向 Broker 发送 Commit 或 Rollback 指令。
  - Commit：半消息变为正式消息，对 Consumer 可见。
  - Rollback：半消息被删除。
- 事务状态回查：
  - 如果 Producer 在第二阶段因为宕机等原因没有返回指令，Broker 会定时向 Producer 发起回查。
  - Producer 需要检查本地事务的最终状态，并返回 Commit 或 Rollback。

如何保证消息不丢失：
- Producer 端
  - 使用同步发送，并处理发送失败的情况（重试）。
  - 对于可靠性要求极高的场景，可以采用事务消息机制。
- Broker 端
  - 刷盘策略：默认是异步刷盘，性能高但有丢失风险。可以设置为同步刷盘，保证消息落盘后才返回成功，但性能会下降。
  - 复制策略：默认是异步复制，主从同步有延迟。可以设置为同步双写，保证消息复制到从节点后才返回成功，进一步保证高可用。
  - 组合使用：同步刷盘+同步双写是最高级别的可靠性保证，但性能损耗最大。
- Consumer 端
  - 使用 PUSH 模式或 PULL 模式，在消息业务逻辑处理成功后，再返回 CONSUME_SUCCESS 状态给 Broker。如果处理失败，返回 RECONSUME_LATER，消息会稍后重试。
```

#### RocketMQ 最佳实践

```console
集群部署与配置
- 多 Master 多 Slave 模式：
  - 异步复制：主从异步同步，性能高，有毫秒级延迟。适用于消息可靠性要求稍低的场景。
  - 同步双写：主从同步成功后才返回，数据零丢失。适用于金融等对可靠性要求极高的场景。
- NameServer 集群：至少部署2-3个节点。互不依赖，只要有节点存活整个集群即可工作。
- Broker 配置：
  - flushDiskType：根据业务在性能和可靠性间权衡，选择 ASYNC_FLUSH 或 SYNC_FLUSH。
  - brokerRole：选择 ASYNC_MASTER / SYNC_MASTER 或 SLAVE。

运维与监控
- 容量规划：
  - 磁盘：使用 SSD，监控磁盘使用率，并设置合理的清理策略（默认72小时）。
  - JVM：合理设置堆内存，Old 区过大可能导致 Full GC 时间过长，影响 Broker 与 Slave 或 NameServer 的心跳，造成主从切换。
- 监控告警：
  - 使用 RocketMQ Console：官方控制台，可查看 Topic、消费者组、消息堆积等情况。
  - 关键指标：消息堆积量、TPS、Broker 存活状态和主从同步延迟。
- 客户端最佳实践：
  - Producer：设置合理的 SendMsgTimeout；为消息设置唯一的 key；使用 setInstanceName 为 Producer 设置实例名。
  - Consumer：保证消息逻辑幂等性；关注消费耗时；处理好重试队列和死信队列消息。

常见问题排查
- 消息堆积：
  - 原因：消费速度远低于生产速度。
  - 解决：优化消费逻辑性能；增加 Consumer 实例数量（注意：一个 Queue 只能被一个 Consumer 消费，所以增加 Consumer 数量不能超过 Queue 的总数）。
- 消息重复：
  - 原因：网络波动、Client 重启等可能导致消息重投。
  - 解决：必须在消费端做幂等。利用数据库唯一键、Redis 分布式锁或状态机等方式。
- No route info of this topic：
  - 原因：Producer 无法找到 Topic 的路由信息。
  - 解决：检查 Topic 是否已在 Broker 上创建；检查 Producer 能否正确连接到 NameServer 并获取路由。
```

## Observability

### 什么是可观测性以及三大支柱？与传统的监控区别是什么？

```console
可观测性：指通过系统输出的数据（Metrics、Logs、Traces）理解系统内部状态的能力，适用于复杂分布式系统。

三大支柱（Metrics、Logs、Traces）：
- Metrics（指标）：系统性能的量化数据，通常是聚合后数据，适合实时告警和趋势分析。例如：QPS、错误率、CPU 利用率。
工具：
Prometheus + Exporter
OpenTelemetry
- Logs（日志）：系统事件的文本记录，包含丰富的上下文信息（时间戳、级别、消息、来源等），需聚合和索引。
工具：
收集 = filebeat / fluentd / fluent-bit / promtail
存储 = Elasticsearch / Loki
查询/分析 = Kibana / Grafana / Splunk
- Traces（追踪）：记录请求在分布式系统中流转的完整路径，将分散的日志和指标通过 TraceID 串联。例如：微服务分布式请求链路追踪。
工具：
Jaeger / Zipkin / OpenTelemetry
- 事件（Events）：离散的、有状态变化的事件（如服务器重启）


区别：传统监控关注预定义指标和告警，侧重已知问题（如 CPU 使用率超阈值）；可观测性更主动，允许探索未知问题，通过关联指标、日志和追踪定位更应。（如传统监控告知服务器宕机，可观测性帮助分析为何宕机）
```

### 可观测性领域都有哪些方法论？

#### 监控分层方法论与告警设计方法论

```console
监控分层：
- 基础设施层
设备：VM、网络设备、存储
指标：CPU、Memory、磁盘 I/O、网络流量
工具：Prometheus、Zabbix
- 应用层
指标：应用存活状态、响应时间、HTTP 错误率、吞吐量
工具：APM 工具、Prometheus
- 服务层
指标：SLA（可用性）、SLO（延迟目标）
方法：合成监控（Synthetic Monitoring，模拟用户请求）
- 日志层
工具：ELK Stack、EFK Stack、Grafana Loki


告警设计：
- 告警分级：Critical、Error、Waring
- 告警收敛
使用抑制规则避免告警风暴
关联拓扑依赖分析根因（如下游服务故障触发上游告警）
- 告警疲劳管理
静默（Mute）：计划内维护时段屏蔽告警
动态阈值：基于历史数据自动调整（如季节性流量波动）
- 告警通知
通知渠道
```

#### SLI、SLO、SLA 概念

- SLI（Service Level Indicator，服务等级指标）

```console
描述：
量化服务健康状态的具体指标，用于客观衡量服务的某个关键维度（如可用性、延迟等）。必须是可测量、明确的数值

常见 SLI 示例：
可用性：成功请求数 / 总请求数 * 100%
延迟：请求响应时间的 P99
吞吐量：每秒处理的请求数（QPS）
持久性（存储服务）：数据不丢失的概率
如 HTTP 服务的 SLI：过去5分钟内，成功响应（HTTP 200）的请求占比 ≥ 99.5%
```

- SLO（Service Level Objective，服务等级目标）

```console
描述：
团队对 SLI 的目标阈值，服务应该在 SLI 应达到的预期水平。

常见 SLO 示例：
可用性：99.9%的请求成功率
延迟：95%的请求响应时间 < 200ms
如 API 服务的 SLO：过去7天内，99% 的请求延迟 < 300ms
```

- SLA（Service Level Agreement，服务等级协议）

```console
描述：
向客户（或上下游团队）承诺的服务质量，包含 SLO 和违约后果。

常见 SLA 示例：
可用性：每月保证最少 99.5% uptime
故障恢复：4小时内恢复严重问题
```

#### 什么是 Google 黄金指标（适用定义 SLO）、RED 方法（适用微服务）、 USE 方法？

```console
Google 黄金指标：
- 延迟（Latency）：请求处理时间、区分成功/失败请求的延迟
- 流量（Traffic）：系统负载（如 QPS、并发连接数）
- 错误（Errors）：显式错误（HTTP 500）和隐式错误（如返回空结果）
- 饱和度（Saturation）：资源过载程度（如磁盘剩余空间、队列长度）


RED 方法：
- Rate（速率）：每秒请求数
- Errors（错误）：失败请求数
- Duration（持续时间）：请求耗时分布（P90/P99）
工具：Grafana + Prometheus，通过 PromQL 计算 RED 指标


USE 方法：
- Utilization（利用率）：资源使用百分比（如 CPU 70%）
- Saturation（饱和度）：资源过载程度（如 CPU 队列长度）
- Errors（错误）：硬件错误（如磁盘坏块）
适用场景：快速定位瓶颈节点（如网络带宽饱和）
```

### Monitoring

#### 如何使用 Alertmanager 触发告警，配置告警规则与通知规则？

```console
1. 触发告警：
在 vmalert / Alertmanager 中定义告警规则（如 up == 0）以及告警持续时间，持续时间内达到指定告警阈值则触发告警。

2. 设置告警规则：
在 Alertmanager 中接收告警，进行分组、抑制、去重。配置 route 和 receiver，发送到 Slack / Email / Webhook 等。

3. 设置告警通知规则：
接收告警后，将告警进行分组、抑制、去重，发送到指定 receiver 中。

**Nightingale**：开源监控项目，侧重告警引擎、告警事件的处理和分发。
将 Prometheus / VictoriaMetrics 数据源接入夜莺，统一管理告警规则以及通知规则。
```

#### 什么是 Prometheus ？ 工作原理是什么？

- Prometheus 核心组件工作原理

```console
- Prometheus Server
通过 pull 模型定期（scrape_interval）主动从配置的 targets 的 HTTP Endpoint（通常是 /metrics）上拉取监控指标数据，并存储数据提供 PromQL 查询。

- Exporter
暴露应用/系统指标（如 node-exporter）。

- Pushgateway
工作流程：程序或脚本通过 HTTP Post 请求形式推送到 Pushgateway，Prometheus 定期从 Pushgateway 抓取暂存的指标。
使用场景：生命周期短的任务、无法暴露指标接口的服务、定时任务或批处理作业

- Alertmanager
管理警报，分组、抑制、发送通知。
```

- 数据模型

```console
http_requests_total{method="POST", handler="/api/users", status="200"} 1024 @1756886000
```

- rate() 与 irate() 函数区别

```console
rate() 计算时间范围内每秒的平均增长率，适合长时间趋势分析与告警。
irate() 计算时间范围内最后两个样本点的瞬时增长率，瞬时波动适合调试与快速定位问题。
```

#### 什么是 Prometheus 联邦集群？如何实现高可用？

```console
联邦集群：全局的 Prometheus Server 从多个下层的 Prometheus Server 聚合特定的时间序列数据，适用于跨数据中心或大规模集群的场景。
实现：
1. 子 Prometheus 配置 scrape_config 暴露聚合指标
2. 全局主 Prometheus 通过 /federate 接口拉取数据
3. 使用 Thanos 扩展存储和查询。用例：跨数据中心监控，降低单实例压力

双活多数据部署
- 实现：部署两个完全相同的 Prometheus 实例，配置相同的抓取任务。
- 架构：
   Grafana -> HA / Nginx -> Prometheus A / Prometheus B -> Targets

远程写入（Remote Write）+ 对象存储
- 实现：部署多个 Prometheus 实例，配置相同的抓取任务。配置 remote_write 接口将数据写入到一个共享高可用的后端存储中，保证数据持久型和全局性。（比如 thanos 写入到 oss）
- 架构：
   Grafana -> Thanos Query -> Thanos Receiver -> OSS
                                  ⬆️ remote_write
                          Prometheus A / Prometheus B
```

#### Prometheus 的缺点是什么？如何与 Thanos 或 VictoriaMetrics 扩展支持？

```console
缺点：
- 单机实例，数据持久化依赖本地磁盘
- 高基数标签容易导致性能问题
- 不适合日志或追踪。

持久化存储与高可用扩展：
- 通过 remote_write 接口与 Thanos / VictoriaMetrics 集成，数据持久化存储到分布式存储（S3/OSS）

查询分离：
将查询组件接入 Grafana 数据源，将查询需求分离。
```

#### 什么是 Zabbix ？常用的监控项是什么？

```console
数据模型：基于监控项（item）+ 触发器（Trigger）

主动模式: zabbix-agent 会主动开启一个随机端口去向 zabbix-server 的10051端口发送 tcp 连接。zabbix-server 收到请求后，会将检查间隔时间和检查项发送给 zabbix-agent，agent 采集到数据以后发送给 server.

被动模式: zabbix-server 会根据数据采集间隔时间和检查项，周期性生成随机端口去向 zabbix-agent 的10050发起连接。然后发送检查项给 agent，agent 采集后，在发送给 server。如 server 未主动发送给 agent，agent 就不会去采集数据。

zabbix-proxy：agent 请求的是 proxy，由 proxy 向 server 去获取 agent 的采集间隔时间和采集项。再由 proxy 将数据发送给 agent,agent采集完数据后，再由 proxy 中转发送给 server.

常用监控项：
1. 硬件监控: 交换机、防火墙、路由器
2. 系统监控: CPU、内存、磁盘、进程、TCP 等
3. 服务监控: Nginx、Mysql、Redis、Tomcat 等
4. web 监控: 响应时间、加载时间、状态码
```

#### 什么是 Grafana ？常用的 Dashboard 都有哪些？

```console
Grafana：开源可视化平台，用于创建仪表盘。展示 Metrics、Logs、Traces。

常用的 Dashboard：
- 基础设施大盘（VM/网络设备）
CPU
Memory
磁盘容量与 I/O
网络流量（in/out）
SLA 展示
- 传统应用或容器应用大盘（按应用/模块）
应用存活状态
响应时间
HTTP 状态/错误率
QPS/吞吐量
域名/证书过期状态
- 中间件 Exporter 大盘
Mysql
PostgreSQL
RocektMQ
Redis
Kafka
- 容器层（按 NameSpace 与 Environment）
CPU
Memory
磁盘 I/O
网络流量（in/out）
- 日志层
Error 级别关键字
```

#### 如何在 Grafana 中配置告警功能？与 Prometheus Alertmanager 有何区别？

```console
配置 Grafana 告警：
1. Edit Panel，添加 Alert rule（如 avg(rate(http_requests_total[5m])) < 100 ）。
2. 设置条件（如触发阈值）和通知渠道（Slack、Email）。
3. 配置评估频率和时间范围。

与 Alertmanager 的区别：
基于 Panel 配置可视化的告警，配置较简单。Alertmanager 支持对于告警的分组、抑制等功能。
```

### Logging

#### 什么是 Fluentd / Fluentd Bit ？

```console
Fluentd：功能强大的统一日志数据收集器，丰富的插件生态，可以处理复杂的路由、解析、缓存和输出逻辑。功能全面但 CPU 和内存消耗也较高。定位是日志聚合和转发的中枢。

Fluent Bit：超轻量级的日志和指标收集器和转发器。专为性能设计，CPU 和内存占用较低（约 Fluentd 的十分之一），插件相对较少。定位是嵌入式 Linux、容器、以及资源敏感环境的边缘数据收集器

典型架构：在 Kubernetes 环境中，通过 DaemonSet 方式部署 fluent-bit，用于高效收集日志。然后有 fluent-bit 转发给 fluentd 实例，有 fluentd 进行更复杂的过滤、转化和分发到其他目的地（如 ES、Kafka、S3 等）
```

#### Fluentd / Fluentd Bit 的缓冲机制什么？有哪些类型？ 配置结构是什么？

```console
缓冲机制：缓冲区是 Fluentd 实现至少一次（At Least Once）投递和抗后端故障的核心机制。但输出目标（如 ES）不可用时，数据会暂存在缓冲区中，待目标恢复后继续重试发送，防止数据丢失。

缓冲类型：
- 内存缓冲区（memory）：速度快，但进程重启或崩溃时数据丢失。
- 文件缓冲区（file）：速度慢于内存，但进程重启或崩溃时数据不会丢失，可靠性更高。生产环境通常使用文件缓冲区或内存+文件混合模式。

配置结构：
- source：定义输入来源（监听端口、tail 读取日志方式、HTTP 接口接收消息方式）
- filter：定义过滤规则，用于修改或丰富日志事件（如 grep、parse、record_transformer）。
- match：定义输出目的地和匹配规则（如输出到 ES、S3、fluentd），匹配规则使用标签模式。
- system：设置 fluentd 本身的系统级配置（如日志级别、工作进程数）。
```

#### 什么是 Elasticsearch？Elasticsearch 的索引、分片、副本概念是什么？如何管理索引的生命周期？

```console
Elasticsearch：接收、存储和索引来自日志收集组件（如 Logstash、Filebeat、Fluentd）的日志，对日志全文分词索引，并提供 RESTful API 进行快速搜索和分析。
优势：
- 基于倒排索引，支持复杂的查询、过滤和聚合。
- 天然的分布式架构，可通过节点实现水平扩展，通过分片副本实现高可用。
- 丰富的生态和工具。


索引（Index）：是一类文档（Document）的集合，相当于 RDS 中的 database。比如为不同的应用创建不同的索引（user-logs-2025.01.01， gateway-logs-2025.01.01）。

分片（Shard）：索引可以被切割为多个部分，每个部分就是一个分片。分片允许水平切割你的数据量，并行跨分片操作，提高性能和吞吐量。分片分为主分片（Primary）和副本分片（Replica）。

副本（Replica）：主分片的拷贝。副本提供高可用性（防止节点故障导致数据丢失）和更好的性能（读请求可以由主分片或副本分片处理，提高吞吐量）。

生命周期管理：
- 基于时间的索引命名写入不同日志。
- 使用 ILM（Index Lifecycle Management）：定义 ILM 规则，在索引满足条件（如大小、时间）时，将索引转化为 hot、warm、cold 层索引，最终删除过期索引。
```

#### 如何部署 Elasticsearch 集群模式，规划节点与角色？如何合理的设置分片和副本？

```console
节点规划与角色分离：
- 专用主节点
- 专用数据节点
- 专用协调/预处理节点

网络与硬件：
- 所有节点需要位于同一内网中。
- 主节点：对 CPU 和磁盘要求不高，内存应足够存储集群元数据。
- 数据节点：资源消耗主力，需要较高配置的 CPU、内存和磁盘 IO（SSD），内存与磁盘容量大概 1:10~1:30。
- 协调节点：需要良好的 CPU 和内存，负责处理客户端请求、聚合结果等。

集群配置：
- 唯一的集群名称：cluster.name
- 每个节点设置角色和名称：node.roles
- 配置自动发现并组建集群：discovery.seed_hosts

高可用与容灾：
- 跨可用区/跨区域部署节点，防止单物理机或数据中心故障导致整个集群不可用。
- 配置快照仓库（如 S3、HDFS、NFS），定期为集群创建快照。

安全与监控：
- 启用安全功能（如 X-Pack Security），设置用户名密码、SSL 加密传输、基于角色的访问控制。
- 使用监控工具关注集群健康状态、节点性能和资源使用情况。

最佳实践集群数量：
- 主节点（Master Nodes）：负责维护集群状态（元数据），如所有索引的映射、分片等。并决定如何将分片在节点间迁移以实现集群平衡。主节点不处理用户请求，也不存储数据。通常配置3个节点，防止单点故障与脑裂。
- 数据节点（Data Nodes）：负责存储数据、执行数据的索引、搜索和聚合操作。消耗大量 CPU、内存和磁盘 IO。通常配置3个节点，满足副本分片的高可用要求，根据性能监控指标进行水平扩展。
- 协调节点（Coordinating Only Nodes）：可选角色，接收客户端请求，负载均衡并转发请求到正确节点，收集和合并结果，返回给客户端。通常用于查询较多请求到情况下，2~3个节点。

分片设置：
- 大小建议在10GB~50GB
- 数量建议为 总分片数 = 总数据量 / 单个分片大小。或者通过按时间创建索引，一个时间索引使用3个分片

副本设置：
- 至少设置为1，表示每个主分片最少有1个副本分片。

分片和副本设置最佳实践：
1. 预热阶段：使用样本数据测试不同分片策略的性能。
2. 使用生命周期（ILM）策略自动滚动创建新索引、调整副本数、收缩分片（Shrink）、归档和删除旧数据。
3. 避免大索引，优先考虑使用别名和按时间/业务逻辑滚动创建多个索引。
4. 起步配置：默认使用3或5分片，1个副本。
5. 持续监控集群数据，通过负载情况调整分片大小（重建索引）。
```

#### 什么是 ELK / EFK ？

```console
Elasticsearch：接收、存储和索引来自 Logstash / Filebeat 的日志。
Logstash：日志收集，过滤、定制等处理日志管道。
Filebeat：轻量级日志收集，过滤、定制等处理日志管道。
Kibana：可视化查询日志。

ELK Stack：节点部署日志收集器 Logstash，过滤、转化日志内容并转发到 ES / Logstash 中枢，最终从 Kibana 进行可视化查询。

EFK Stack：与 ELK 类似，将节点日志收集器替换为更轻量级的 Filebeat。

中枢 Logstash / Filebeat 写入：
- Elasticsearch：写入 ES 并接入 Kibana 用于日志搜索查询。
- 本地文件：写入本地文件并压缩，上传 S3 / OSS 持久化存储归档日志。
```

#### 什么是 Loki，与传统的 ELK / EFK Stack 的区别是什么？

```console
Loki：水平可扩展、高可用、多租户的日志聚合系统，仅索引标签（如 job，pod，namespace 等）不索引日志内容，通常日志存储在 S3 / OSS 等分布式存储中。直接可与 Grafana 集成。查询时先通过标签筛选出小的日志流，再对流进行关键字（Grep）搜索。
ps: 避免高基数（如 trace_id）值作为标签，导致标签爆炸（High Cardinality）。

Loki 技术栈：Promtail + Loki + Grafana

与 ELK / EFK 的区别：
- Loki：更加轻量，存储成本更低。不全文索引，查询依赖标签。更适合云原生（Kubernetes）环境。
- ELK / EKF：功能全面，支持全文搜索，但存储成本较高且资源消耗较大。更适合复杂的日志分析与传统环境。
```

#### Loki 的架构组件有哪些？做过哪些优化？

```console
架构组件：
- distributor：日志数据写入的入口点，接收来自 Promtail 等客户端等 HTTP/gRPC 请求。
- ingester：接收来自 distributor 的日志流，并负责在内存中构建压缩的日志块，定期将日志块写入后端存储（如 S3）。
- querier：处理 LogQL 查询请求，向索引存储发起查询，并从后端存储和 ingester（内存中）读取日志并合并去重后返回 query-frontend。
- query-frontend(optional)：将大的时间查询拆分为多个子查询，分发给下游的 querier 并行执行。
- ruler(optional)：持续、定期地执行 LogQL 查询，生成警报；预先计算开销大的查询，保存为新的日志流。
- backend storage：将索引存储（单机使用 BoltDB 本地文件、集群使用 TSDB）与块数据（S3、GCS、Minio）分离存储。
- compactor: 定期（如每周）将后端存储（如 S3），将过去多天（如7天）的小索引文件合并为一个大索引文件。

部署方式：
- single-binary: 单点部署所有组件，用于测试。
- simple-scalable：拆分 read 和 write，可用于中小型集群。（每天 TB 级、每秒百万行的日志摄入量）
read：gateway、query-frontend、querier
write：gateway、distributor、ingester
- distributed(microservices)：微服务模式部署所有组件，用于大型集群。

优化：
- 部署 simple-scalable 模式，拆分读写请求。
```

#### 如何做针对日志内容错误的告警？

```console
阿里云 SLS：获取告警关键字，定时任务，如有对应错误关键字则告警。

fluent-bit：自定义 lua 从日志流从获取错误日志关键字，添加日志级别字段，定时任务根据日志流日志级别字段进行告警。
```

### Tracing

#### 什么是分布式追踪？如何使用 Jaeger / Zipkin / OpenTelemetry 实现？

```console
分布式追踪：跟踪请求在微服务之间的传播，记录每个服务的延迟和依赖。

Jaeger 实现：
1. 部署 Jaeger（All-in-One / 生产模式）。
2. 应用集成 Jaeger / OpenTelemetry SDK，发送追踪到 Jaeger Collector。
3. 在 Jaeger UI 查看调用链，分析瓶颈。

Zipkin：类似 Jaeger，支持 OpenTelemetry

```

### 描述一个通过可观测性组件排查相关故障的案例。

```console
问题发现：收到告警，查看 Grafana 仪表盘 http 接口响应时间超过 5s。

日志分析：Grafana 中查询 Loki 或 Kibana 查询 Elasticsearch，分析日志，定位超时接口与日志。

追踪分析：查看日志定位或查看链路，显示请求卡在数据库查询步骤。

解决：优化数据库索引或回滚代码。

改进：
```

## Orchestration Management

### ServiceMesh & ServiceProxy

#### 什么是 Istio？

```console

```

#### 什么是 HAProxy？

```console

```

#### Nginx 的特点是什么？常用的模块与参数是什么？

- 特点

```console
特点：
- 支持高并发，官方测试连接数支持5万，生产可支持2~4万。
- 内存消耗成本低
- 配置文件简单，支持 rewrite 重写规则等
- 节省带宽，支持 gzip 压缩。
- 稳定性高
- 支持热部署

常用的模块与参数：
- 模块
负载均衡 upstream
反向代理 proxy_pass
路由匹配 location
重定向规则 rewrite
- Proxy 参数
proxy_sent_header
proxy_connent_timeout
proxy_read_timeout
proxy_send_timeout
- rewrite flag 参数
last：表示完成当前的 rewrite 规则
break：停止执行当前虚拟主机的后续 rewrite
redirect：返回302临时重定向，地址栏会显示跳转后的地址
permanent：返回301永久重定向，地址栏会显示跳转后的地址
```

## Provisioning

### Automation & Configuration

#### Ansible 和 Saltstack 的架构和工作原理有什么不同？

```console
Ansible：
- 架构：无代理（Agentless，基于 SSH）+ 推送式（Push Mode）
- 工作原理：Ansible 控制机通过 SSH 或 WinRM（Windows）协议直接连接到目标节点执行任务。执行时控制机将模块代码推送到目标节点，临时运行执行完毕后返回结果断开连接。
- 优点：部署简单，无需在节点上安装和维护代理，安全（利用现有 SSH 通道）。
- 缺点：大规模节点并发执行时，SSH 连接可能成为性能和网络瓶颈。

Ansible 核心组件：
- Inventory：定义管理主机。
- Playbook：自动化任务 yaml 文件。
- Module：执行特定任务的代码单元。
- Role：组织 Playbook 和文件的目录结构。
- Task：Playbook 中的单个执行步骤。

Ansible 常用 Ad-hoc 模块：
- commmand/shell
- copy
- file
- package
- service
- template
- archive
- user
- group


Saltstack：
- 架构：通常为有代理（Agent-Based）+ 拉取/事件驱动（Pull/Event-Driven），但也支持无代理模式（SSH）。
- 工作原理：核心是 Master-Minion 架构。Master 是服务端，Minion 是安装目标节点的代理。Master 和 Minion 之间通过 ZeroMQ 进行通信，Master 向 Minion 发送命令，Minion 执行后返回结果。

Saltstack 核心组件：
- Master：控制服务端。
- Minio：管理节点客户端。
- ZeroMQ：消息传输轻量级队列。
- Salt SSH：无代理模式。
- Syndic：分级管理节点。
- Grains：静态 Minion 信息（OS、IP 等），由 Minion 收集。
- Pillars：Master 定义的敏感数据或 Minion 特定数据，由 Master 分发。

Saltstack 常用模块：
- cmd.run
- cp.get_file
- cp.get_dir
- file.managed
- pkg.install
```

#### 在什么场景下选择 Ansible 或 Saltstack？

```console
选择 Ansible 的场景：
- 中小环境规模：节点数量在千台以内。
- 快速开发，简单需求：无需复杂状态管理，主要是临时性命令执行、配置分发和应用部署。
- 安全限制环境：无法在节点安装 Agent，或直接适配 SSH 环境。
- 更适用于 YAML 语法熟悉的团队。

选择 Saltstack 的场景：
- 超大规模数据中心：数万甚至数十万服务器。
- 需要高性能和实时性：如需要实时收集资产信息，执行高速的状态管理。
- 需要强大的扩展性和 API
```

#### Ansible Playbook 中的 roles 和 include_tasks / import_tasks 有什么区别？

```console
Roles：是一种完整的、自包含的代码组织方式。一个 Role 包含了 tasks、handlers、files、templates、vars 等所有相关的组件。用于封装一个完整的功能（如配置 Nginx、配置数据库等）。Roles 是结构化的，易于分享和重用（Ansible Galaxy）。

include_tasks / import_tasks：用于在 Playbook 中动态（include）或静态（import）地插入另一个任务文件。更适用于分解一个很长的 Playbook，或者在特定条件下才引入某些任务。include_* 是运行时动态包含，import_* 是预处理时静态导入。
```

#### Saltstack 的 Grains 和 Pillar 有什么区别？

```console
Grains：
- Minion 端的静态数据。存储的是 Minion 本身的属性信息，如操作系统、CPU架构、内存、主机名等。在 Minion 启动时加载，相对静态。
- 一般用于目标定位。如：salt -G 'os:CentOS' cmd.run 'yum update'

Pillar：
- Master 端的动态数据。存储的是配置信息、秘密数据（如密码、密钥）或任何需要动态分配给特定 Minion 或一组 Minion 的数据。
- 用于安全地分发配置和秘密。Pillar 数据在 Master 上编译，然后只发送给授权的 Minion。通过与状态文件（State SLS）配合使用，将变量注入到配置模板中。
```

#### Terraform

```console
AWS
GCP
```

### Network & System

#### 如何使用 tcpdump & Wireshark 抓包分析网络问题？

- 前置分析

```console
1. 明确问题：清晰定义问题。例如：“访问 xxx.com 慢“，”与服务器 10.0.0.1 的 443 端口连接失败“，“视频卡顿”
2. 选择抓包点：客户端、服务端、中间网络设备（如网关）
3. 过滤器：使用过滤器缩小范围，如 host 1.2.3.4 and tcp and port 443
4. 问题复现，抓包并分析
- 宏观异常流量统计（是否某些 IP/端口流量较大，是否有异常连接）；IO Graph（流量速率是否骤降、高峰或中断）
- 微观协议层定位
物理链路层：CRC 错误或帧过短
网络层：Destination unreachable、Time to live exceed 等错误保温
传输层：TCP 三次握手和四次断开是否正常；Seq/Ack 是否连续，是否有重传（Tcp Retransmission）或乱序（Tcp Out-of-Order）；Flags 是否有连接重置（RST）或连接终止（FIN）；是否存在零窗口（zero window，表示接收方处理不过来）
应用层：HTTP/TLS/DNS 协议分析
```

- 典型案例

```console
连接建立失败：无法建立 TCP 连接
- 服务器端口未开放：客户端发送 SYN，服务器回复 RST，ACK
- 防火墙阻断（客户端出口限制或中间网络设备阻断）：客户端发送 SYN，但没有收到回复。

连接速度慢 / 应用响应延迟：可以建立 TCP 连接，但数据传输速度慢，应用响应时间长
- TCP 重复确认与重传（Dup Ack & Retransmission）：数据包被多次 DAck，表明网络中存在丢包，导致 TCP 拥塞算法触发，降低发送速率。需结合 ping / mtr 工具排查网络链路丢包率。
- TCP 零窗口（Zero Window）：src 向 dst 通告一个 win=0 的接收窗口，表明接收方可能由于负载高导致处理不了数据。需优化接收方服务器性能或排查应用代码性能瓶颈。
- DNS 查询慢：排查 local DNS 或更换公共 DNS。

TLS / SSL 握手失败：HTTPS、FTPS 等加密连接无法建立
- 证书问题或协议不匹配：protocol_version（TLS 版本不匹配，需要调整配置）；unsupported_certificate（可能为证书链不完整、证书过期或自签名证书未被客户端信任）

应用层问题（HTTP）：TCP 与 TLS 连接正常，应用返回错误
- HTTP 协议响应500异常：排查应用程序内部异常
```

#### 什么是递归查询与迭代查询？

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

#### 描述一次访问域名的过程。

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

#### 什么是 LVS？核心组件和工作模式是什么？常用的调度算法是什么？

```console
LVS 是运行在 Linux 操作系统内核上，基于四层的负载均衡软件。可以将来自客户端的网络请求，智能均衡地分发到后端多台服务器集群上，让服务器共同承担高并发的网络流量，从而扩展网络应用的服务能力，提高性能和可靠性。

核心组件：
- 负载均衡器（Load Balancer / Director）：LVS 核心，运行 LVS 软件（如 ipvsadm），配置虚拟 VIP，接收所有客户端请求，并根据预设算法，将请求转发后端服务器。
- 服务器池（Server Pool / Real Servers）：后端真实服务器集群（如 Web 服务器、应用服务器、数据库服务器等），共享同一个 VIP，通常为无状态和共享存储的方式保持一致性。
- 共享存储（Shared Storage）：可选组件，有状态的 RS 需要使用共享存储保持一致性。

工作模式：
- NAT 模式（网络地址转换）：
LB 修改数据包的目标 IP 和端口（转发时），以及源 IP 和端口（返回时）。进出流量都经过 LB。
- TUN 模式（IP 隧道）：
LB 讲收到的请求数据包封装到新的 IP 包中（IP-in-IP），转发给 RS。RS 解包后直接响应客户端，响应不经过 LB。
- DR 模式（直接路由）：
LB 只修改数据帧的 MAC 地址，将其转发给 RS。RS 直接使用 VIP 响应客户端，响应不经过 LB。

调度算法:
- 轮询算法（Round Robin）：将请求一次轮流分配给后端服务器。
- 加权轮询算法（Weighted Round Robin）：根据服务器的处理能力分配权重，性能更好的获得更多请求。
- 最少连接（Least Connections）：将新的请求分配给连接数最少的服务器。
- 加权最少连接（Weighted Least Connections）：在最少连接的基础上，考虑了服务器的权重。
- 源地址哈希（Source Hashing）：根据请求的源 IP 地址哈希计算，将同一个客户端的请求发往同一台服务器，可用于实现会话保持。
- 目标地址哈希（Destination Hashing）：第一次做轮询调度，后续将访问同一个目标地址的请求，发送给第一次挑中的 RS，适用于正向代理缓存中。
- LBLC: Locality-Based LC，动态的 DH 算法。
- LBLCR: LBLC with Replication，带复制功能的 LBLC，解决 LBLC 负载不均衡问题，从负载重的复制到负载轻的 RS，实现 Web Cache 等。
```

## Container

### Docker & Containerd

#### 什么是 Docker ？核心组件和 docker-shim 工作机制是什么？

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


docker-shim 工作机制：
- 架构：
1. Kubernetes 的 Kubelet 通过 CRI 接口与 dockershim 通信。
2. Dockershim 将 CRI 请求（如创建、启动、停止容器）转换为 Docker API 调用，发送给 dockerd。
3. Dockerd 再通过 containerd 调用 runc 执行底层容器操作。
4. 进程链：Kubelet(CRI) → dockershim → dockerd → containerd → containerd-shim → runc → 容器进程。
- 流程：
1. Kubelet 发起 CRI 请求：例如，创建 Pod 中的容器。
2. Dockershim 转换请求：将 CRI 请求翻译为 Docker API 调用（如 docker create、docker start）。
3. Dockerd 处理：Docker daemon 调用 containerd 执行容器操作。
4. Containerd 和 runc：containerd 通过 containerd-shim 调用 runc，创建并运行容器。
5. 返回结果：容器状态通过相反路径返回给 Kubelet。
```

#### Docker 容器隔离实现原理是什么？

```console
- Cgroups

- Namespace
Docker Enginer 使用了 namespace 对全区操作系统资源进行了抽象，对于命名空间内的进程来说，他们拥有独立的资源实例，在命名空间内部的进程是可以实现资源可见的。
Dcoker Enginer 中使用的 NameSpace:
UTS nameSpace        提供主机名隔离能力
User nameSpace       提供用户隔离能力
Net nameSpace        提供网络隔离能力
IPC nameSpace        提供进程间通信的隔离能力
Mount nameSpace      提供磁盘挂载点和文件系统的隔离能力
Pid nameSpace        提供进程隔离能力
```

#### Docker 的网络模型都有哪些？

```console
- host：共享主机

- container：容器间共享网络（Network Namespace）

- None：独立 Network Namespace，但无网络配置

- bridge：桥接模式，独立 Network Namespace 设置 IP 并连接到虚拟网桥。
```

#### 什么是 Containerd？核心组件和 containerd-shim 工作机制是什么？

```console
Containerd 是一个轻量级的容器运行时（container runtime），专注于管理和运行容器，强调简单、高效和模块化。供上层工具（Docker、Kubernetes 的 kubelet 等）调用。

核心组件与架构：
1. Containerd Daemon：核心进程，提供 gRPC API，管理容器生命周期、镜像、快照、网络等。
2. runc：containerd 调用 runc 执行 OCI 标准规范容器，处理底层容器运行。
3. Shim：containerd 使用 shim 进程隔离容器进程，确保 containerd 主进程不直接管理容器运行。
4. Plugins：containerd 采用模块化设计，功能（如存储、网络）通过插件实现，易于扩展。

与 Kubernetes 关系：
直接支持 CRI（Container Runtime Interface），是 Kubernetes 的首选运行时。


docker-shim 工作机制：
- 架构：
1. Containerd 是一个独立的高层容器运行时，负责镜像管理、存储、网络等。
2. 每个容器对应一个 containerd-shim 进程，containerd-shim 调用 runc（或其他 OCI 运行时）执行容器。
3. 进程链：containerd → containerd-shim → runc → 容器进程。
4. 在 Kubernetes 中：Kubelet → CRI (containerd) → containerd-shim → runc → 容器进程。
- 流程：
1. Containerd 接收请求：通过 gRPC API（如 CRI 或 Docker 调用）接收容器操作请求。
2. 启动 Containerd-shim：Containerd 启动一个 containerd-shim 进程，传递 OCI 包（bundle）路径，包含 config.json 和根文件系统。Shim 进程调用 runc 的 create 命令，创建容器进程（runc 初始化后退出）。
3. 管理容器生命周期：Shim 进程作为容器进程的父进程，保持标准 I/O（stdin/stdout/stderr）打开，处理日志输出（如 docker logs）；Shim 监控容器退出状态，报告给 containerd；支持附加操作（如 docker exec、kubectl attach）和伪终端（PTY）管理。
4. 隔离与容错：Shim 进程隔离 containerd 主进程，containerd 重启或崩溃不影响运行中的容器。Shim 保持运行直到容器退出，收集退出状态后终止。
- 验证：
ctr image pull docker.io/library/nginx:latest
ctr run -d docker.io/library/nginx:latest nginx
# containerd 启动 containerd-shim-runc-v2，调用 runc 创建容器
ps aux | grep containerd-shim
```

#### 什么是 CRI-O？核心组件和工作机制是什么？

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


工作机制：
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

#### Docker 与 Podman 的区别是什么？

```console
架构模型：
- Docker 是传统的 C/S 架构，核心组件是 Docker Daemon 守护进程，需要通过 Dockerd 调用底层组件 containerd 负载容器的实际操作。
- Podman 是无守护进程（Daemonless）架构，直接与 OCI 运行时（如 runc）交互，通过 Linux 的 fork-exec 模型启动容器。利用 user namespace 使用 Rootless 特性将容器的 root 用户映射到主机的非特权普通用户，安全性更高。

流程：
- 用户 -> docker CLI -> Docker Daemon (dockerd) -> containerd -> runc -> 容器
- 用户 -> podman CLI -> runc -> 容器
```

### Kubernetes

#### 什么是 Kubernetes？核心组件和架构是什么？

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


核心组件与架构：控制平面 + 数据平面
- 控制平面（Control Plane）
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

- 数据平面（Data Plane）/ 工作节点（Works Nodes）
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

#### 描述 Pod 的完整创建过程。

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

#### Resources

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

#### Kubernetes 中都有哪些应用的探针？区别是什么？

```console
- livenessProbe
存活探针，检测容器是否正在运行，如果存活探测失败，则 kubelet 会杀死容器，并且容器将受到其重启策略的影响，如果容器不提供存活探针，则默认状态为 Success，livenessprobe 用于控制是否重启 Pod.

- readinessProbe
就绪探针，如果就绪探测失败，端点控制器将从与 Pod 匹配的所以 Service 的端点中删除该 Pod 的 IP 地址初始延迟之前的就绪状态默认为 Failure（失败），如果容器不提供就绪探针，则默认状态为 Success，readinessProbe 用于控制 Pod 是否添加至 service.

- startupProbe
启动探针
```

#### Others

```console
1. hpa 指标以 request 为准
2. 主机调度 Pod 以 request 为准


request limit 的分级?
如何通过 Deployments 创建 Pod？
```

#### 什么是 Rancher ？Rancher 导入集群的方式有什么？导入集群的流程原理是什么？

```console

核心组件：
Rancher Server：管理控制中心，提供 UI/API，存储所有集群的元数据，并发出管理指令。
Cluster Agent：运行在目标集群（下游集群）中的代理，Deployment 方式部署在 cattle-system namespace 中。
Node Agent：运行在下游集群中，DaemonSet 方式部署。负责执行需要节点级别操作的任务（如升级 Kubernetes 版本、管理节点等）。

导入集群的方式：
General
ACK
EKS
GKE

前置检查：
- 网络连通性检查：Rancher Server 需要连通下游集群的 API Server（默认443）；下游集群需要连通 Rancher Server（默认443）。
- 注册命令的有效性：有效期与 Rancher Server 地址是否正确。
- 权限和安全：Rancher 会创建 cluster-admin 权限的 service account；TLS 证书。
- 资源：Rancher Agent 需要消耗下游集群的资源。

导入集群流程原理：
1. 在 UI 选择导入集群，选择导入的方式。
2. Rancher Server 生成唯一的注册命令（kubectl apply ...），主要创建 namespace、secret、serviceaccount 与 clusterrolebing（绑定 cluster-admin 角色）、Cluster Agent Deployment 等资源。
3. 在下游集群执行 kubetctl apply 命令。
4. 建立连接：Cluster Agent Pod 启动后，读取挂载的 Secret（包含 Rancher Server 的 URL 和认证令牌），然后​主动发起​​一个到 Rancher Server 的​​持久安全的 WebSocket（或 HTTP 长轮询）连接​​。通常是 Agent 连接 Server，而不是 Server 主动连 Agent，简化了防火墙配置（只需下游能访问 Rancher 即可）。
5. 连接建立后，就形成了一条双向通行渠道。
- Rancher Server 向下游集群发送指令：无法调用下游集群 API Server，将指令封装为消息，通过 Websocket 连接发送给集群的 Cluster Agent。Agent 收到消息后使用 Kubernetes Go 客户端库（client-go），通过 serviceaccount 的权限调用下游集群的 API Server 执行对应操作。
- 下游集群向 Rancher Server 上报状态：Cluster Agent 和 Node Agent 定时监视下游集群状态（如 Pod、Node、Deployment）的变化，通过 Websocket 上报给 Rancher Server，Rancher Server 收到后更新数据库并在 UI 展示。
```
