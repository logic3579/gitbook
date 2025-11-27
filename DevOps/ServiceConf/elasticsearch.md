# Elasticsearch

/opt/elasticsearch/conf/elasticsearch.conf

```bash
# single node mode
path.data: /opt/elasticsearch/data/
path.logs: /opt/elasticsearch/logs/
bootstrap.memory_lock: false
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: false

# cluster node mode
# 数据与日志目录
path.data: /opt/elasticsearch/data/
path.logs: /opt/elasticsearch/logs/
# 集群名称，同一集群必须相同
cluster.name: es-cluster
# 节点名称，不同节点使用不同名称
node.name: node-1
# 节点角色
node.roles: [master, data]
# 监听端口
http.port: 9200
# 监听地址，如果存在 docker 网卡时使用固定网卡地址
network.host: 0.0.0.0
# 允许跨域
http.cors.enabled: true
http.cors.allow-origin: "*"
# xpack 安全功能配置
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: false
# es7.x 版本以上集群发现
discovery.seed_hosts: ["1.1.1.1", "2.2.2.2", "3.3.3.3"]
# 是否锁定内存，建议设置为 true
bootstrap.memory_lock: true
# 启动全新的集群时需要此参数，再次重新启动时此参数可免。集群初始化master节点
cluster.initial_master_nodes: ["node-1", "node-2", "node-3"]

# es7.x 旧版本配置
# 集群发现
# discovery.zen.ping.unicast.hosts: ["1.1.1.1", "2.2.2.2", "3.3.3.3"]
# discovery.zen.minimum_master_nodes: 2
# cluster.initial_master_nodes: ["node-1", "node-2", "node-3"]
# 集群角色
# node.master: true
# node.data: true
```
