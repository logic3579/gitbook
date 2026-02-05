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
# Data and log directories
path.data: /opt/elasticsearch/data/
path.logs: /opt/elasticsearch/logs/
# Cluster name, must be the same for all nodes in the same cluster
cluster.name: es-cluster
# Node name, each node must use a different name
node.name: node-1
# Node roles
node.roles: [master, data]
# Listening port
http.port: 9200
# Listening address; use a fixed network interface address when a Docker network interface exists
network.host: 0.0.0.0
# Enable CORS (Cross-Origin Resource Sharing)
http.cors.enabled: true
http.cors.allow-origin: "*"
# X-Pack security feature configuration
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: false
# Cluster discovery for ES 7.x and above
discovery.seed_hosts: ["1.1.1.1", "2.2.2.2", "3.3.3.3"]
# Whether to lock memory, recommended to set to true
bootstrap.memory_lock: true
# This parameter is required when starting a brand new cluster; it can be omitted on subsequent restarts. Initial master nodes for cluster bootstrapping
cluster.initial_master_nodes: ["node-1", "node-2", "node-3"]

# Legacy configuration for older ES 7.x versions
# Cluster discovery
# discovery.zen.ping.unicast.hosts: ["1.1.1.1", "2.2.2.2", "3.3.3.3"]
# discovery.zen.minimum_master_nodes: 2
# cluster.initial_master_nodes: ["node-1", "node-2", "node-3"]
# Cluster roles
# node.master: true
# node.data: true
```
