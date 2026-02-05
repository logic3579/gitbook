---
title: Kubernetes Network
categories:
  - Kubernetes
---

## Introduction

### 1) Basic Concepts of Container Networking

Linux Network Namespace

- Linux network devices: network interface device, loopback device, bridge device, veth device, tun/tap device, vxlan device, ip tunnel device, etc. These devices can send and receive network packets and provide additional packet modification capabilities
- Linux routing table (Layer 3 IP packet routing and addressing), ARP table (provides MAC address information corresponding to IP addresses), FDB (provides network interfaces corresponding to MAC addresses for MAC-based forwarding), etc.
- Linux protocol stack: encapsulation and parsing of network protocol packets, such as Layer 2 ethernet packets, Layer 3 IP/ICMP packets, Layer 4 TCP/UDP packets, etc.
- Linux iptables: based on the kernel module netfilter, manages the Linux firewall, e.g., controlling ingress and egress, NAT address translation, port mapping, etc.

<!-- {% asset_img k8s-nw1.png %} -->

> Linux has more than just network namespaces for network isolation. There are also pid namespaces for process isolation, user namespaces for user isolation, mount namespaces for mount point isolation, ipc namespaces for semaphore and shared memory isolation, and uts namespaces for hostname and domain name isolation.
> Combined with cgroup control groups that limit CPU, memory, IO, and other resources, these form the underlying implementation of containers

- Linux Bridge Device

A Linux bridge device can attach multiple Linux slave devices. It functions like an internal virtual Layer 2 switch that can broadcast Layer 2 packets. Note that a Linux bridge device can have its own IP address. When multiple Linux network devices are attached to a bridge, their IP addresses become ineffective (only Layer 2 functionality remains). When one device receives a packet, the bridge forwards the packet to all other devices attached to the bridge, achieving a broadcast effect.

<!-- {% asset_img k8s-nw2.png %} -->

- Linux Veth Device

Always appears in pairs with two endpoints. Packets flow in from one peer and out to the other peer. A veth pair can span across network namespaces.

<!-- {% asset_img k8s-nw3.png %} -->

### 2) K8s Cluster Container Network Communication Methods

- Network Load Balancing Mode

Controlled by kube-proxy component startup parameters (--proxy-module=ipvs)
iptables: default
ipvs: v1.11 and later

- Network Communication Methods

underlay: flannel host-gw, calico bgp, etc. (requires enabling the ip_forward kernel parameter)
overlay: flannel vxlan, calico ipip, flannel udp (generally not used), etc.

### 3) Test Environment Host Information

| Host IP       | Role   | Container CIDR | CNI Interface Address | Flannel.1 vtep Device |
| ------------- | ------ | ------------ | ------------ | ------------------- |
| 192.168.205.4 | master | 10.42.0.0/24 | 10.42.0.1    | 10.42.0.0           |
| 192.168.205.3 | node1  | 10.42.1.0/24 | 10.42.1.1    | 10.42.1.0           |
| 192.168.205.5 | node2  | 10.42.2.0/24 | 10.42.2.1    | 10.42.2.0           |

## Intra-Host Networking

### 1) Four Network Types of Docker Containers

- bridge mode (default): --net=bridge

The host creates a docker0 network interface with an independent IP range, assigning an IP from this range to each container. Containers communicate through this bridge (similar to a Layer 2 switch)

> Custom bridge network: creates an independent network namespace scoped to the host

<!-- > {% asset_img k8s-nw4.png %} > {% asset_img k8s-nw5.png %} -->

- host mode: --net=host

Shares the host network. When a container exposes a port, it occupies the host port. This network mode is simple with good performance, generally used for single-container services.

<!-- {% asset_img k8s-nw6.png %} -->

- container mode: --net=container:name or id

Specifies that the newly created container shares the Network namespace of an existing container (in K8s, a pod is multiple containers sharing a network namespace). Everything except networking, such as filesystem and processes, remains isolated. Processes between containers can communicate via the lo interface

<!-- {% asset_img k8s-nw7.png %} -->

- none mode: The container has an independent Network namespace but no network configuration. Custom network configuration can be applied. Generally used for CPU-intensive tasks where computation results are saved to disk and no external network access is needed

### 2) Container Networking in the Docker Host Environment

- Each container has its own network namespace with its own network devices, routing table, ARP table, protocol stack, iptables, etc. The network namespaces of different containers are isolated from each other.
- In the host's default network namespace, there is a Linux bridge device, typically named docker0.
- Each container corresponds to a veth pair device, with one end in the container's network namespace and the other end attached to the docker0 Linux bridge in the host's network namespace.
- In the host environment, this is like having a Layer 2 switch (docker0 bridge) connecting all containers within the host. Therefore, containers within the same host can directly access each other in a direct-connection manner

<!-- {% asset_img k8s-nw8.png %} -->

```shell
## Related commands
# View bridge information
# K8s pod companion infrastructure container shares network namespace and veth pair with the base container
brctl show

# View veth pair device information
ip addr
ip -d link show

# View routing table
route -n

# View Docker container information
docker ps/inspect/container
```

## Service: ClusterIP Implementation

### 1) How ClusterIP is Accessed

Services in a K8s cluster need to access each other. Typically, a corresponding service is created, and ClusterIP is used for internal cluster access. A ClusterIP is associated with multiple endpoints (actual pod addresses). Accessing a ClusterIP achieves load-balanced access to the multiple endpoints associated with it (load balancing via iptables or ipvs)

### 2) iptables Method

- View service information: ClusterIP and associated endpoint IPs

```shell
# kubectl describe service nginx-test
Name:              nginx-test
Namespace:         default
Labels:            app=nginx-test
Annotations:       <none>
Selector:          app=nginx-test
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.43.6.58
IPs:               10.43.6.58
Port:              80-80  80/TCP
TargetPort:        80/TCP
Endpoints:         10.42.1.6:80,10.42.2.6:80
```

- View host iptables

```shell
# iptables -nvL -t nat |head
Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
pkts bytes target     prot opt in     out     source               destination
298 19090 KUBE-SERVICES  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes service portals */
202 12456 CNI-HOSTPORT-DNAT  all  --  *      *       0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL
```

In the PREROUTING chain, all traffic goes to the KUBE-SERVICES target. Note that the PREROUTING chain is the first entry point after traffic arrives. If you run `curl http://10.43.6.58` inside a pod, based on the container's internal routing table, the packet flow would be:

- In the pod, the routing table shows that the cluster IP (**10.43.6.58**) takes the default route, selecting the default gateway.
- In the pod, the default gateway's IP address is the IP address of **docker0 or cni0** in the host's network namespace, and the default gateway is a directly connected route.
- In the pod, according to the routing table, data is sent using the eth0 device. eth0 is essentially one end of a veth pair in the pod's network namespace, with the other end attached to the **docker0 or cni0** bridge in the host's network namespace.
- Via the veth pair, data sent from one end in the pod's network namespace enters the other end attached to the **docker0 or cni0** bridge.
- After the **docker0 or cni0** bridge receives the data, it naturally enters the PREROUTING chain of the host network namespace

- View KUBE-SERVICES target

```shell
# iptables -nvL -t nat | grep 10.43.6.58
0     0 KUBE-SVC-7CWUT4JBGBRVUN2L  tcp  --  *      *       0.0.0.0/0            10.43.6.58           /* default/nginx-test:80-80 cluster IP */ tcp dpt:80

# iptables -nvL -t nat | grep KUBE-SVC-7CWUT4JBGBRVUN2L -A 5
Chain KUBE-SVC-7CWUT4JBGBRVUN2L (1 references)
pkts bytes target     prot opt in     out     source               destination
0     0 KUBE-SEP-U2YYZT2C3O6VM4EV  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/nginx-test:80-80 -> 10.42.1.6:80 */ statistic mode random probability 0.50000000000
0     0 KUBE-SEP-GWUIQWA2TNZI4ESX  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/nginx-test:80-80 -> 10.42.2.6:80 */
```

In the KUBE-SERVICES target, we can see that the matching target for the destination address cluster IP 10.43.6.58 is KUBE-SVC-7CWUT4JBGBRVUN2L.
**KUBE-SVC-7CWUT4JBGBRVUN2L chain information:**

- There are two targets (corresponding to two Pods): KUBE-SEP-U2YYZT2C3O6VM4EV and KUBE-SEP-GWUIQWA2TNZI4ESX
- KUBE-SEP-U2YYZT2C3O6VM4EV has statistic mode random probability 0.5. The 0.5 uses the iptables kernel random module with a random ratio of 0.5, i.e., 50%
- Since half the traffic randomly enters the KUBE-SEP-U2YYZT2C3O6VM4EV target, the other target also gets 50% of the traffic, achieving load balancing

- View KUBE-SEP-U2YYZT2C3O6VM4EV and KUBE-SEP-GWUIQWA2TNZI4ESX

```shell
# iptables -nvL -t nat | grep KUBE-SEP-U2YYZT2C3O6VM4EV -A 3
Chain KUBE-SEP-U2YYZT2C3O6VM4EV (1 references)
pkts bytes target     prot opt in     out     source               destination
0     0 KUBE-MARK-MASQ  all  --  *      *       10.42.1.6            0.0.0.0/0            /* default/nginx-test:80-80 */
0     0 DNAT       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/nginx-test:80-80 */ tcp to:10.42.1.6:80

# iptables -nvL -t nat | grep KUBE-SEP-GWUIQWA2TNZI4ESX -A 3
Chain KUBE-SEP-GWUIQWA2TNZI4ESX (1 references)
pkts bytes target     prot opt in     out     source               destination
0     0 KUBE-MARK-MASQ  all  --  *      *       10.42.2.6            0.0.0.0/0            /* default/nginx-test:80-80 */
0     0 DNAT       tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/nginx-test:80-80 */ tcp to:10.42.2.6:80
```

In these 2 targets, we can see:

- MASQ operations were performed, which are for outbound egress traffic (with source IP restrictions), not our inbound ingress traffic.
- DNAT operations were performed, converting the original cluster IP to the pod IPs 10.42.1.6 and 10.42.2.6, and converting the original port to port 80.
- After this series of iptables targets, our original request to 10.43.6.58:80 is transformed to either 10.42.1.6:80 or 10.42.2.6:80, with each having a 50% probability.
- Based on iptables, after the PREROUTING chain discovers that the DNAT-translated IP 10.42.1.6 or 10.42.2.6 is not a local IP (these are pod IPs and naturally would not be in the host network namespace), the packet goes to the FORWARDING chain, where the next-hop address is determined by the host network namespace's routing table

```shell
# View routing table information
# ip route
default via 192.168.205.1 dev enp0s1 proto dhcp src 192.168.205.4 metric 100
10.42.0.0/24 dev cni0 proto kernel scope link src 10.42.0.1
10.42.1.0/24 via 10.42.1.0 dev flannel.1 onlink
10.42.2.0/24 via 10.42.2.0 dev flannel.1 onlink
192.168.205.0/24 dev enp0s1 proto kernel scope link src 192.168.205.4 metric 100
192.168.205.1 dev enp0s1 proto dhcp scope link src 192.168.205.4 metric 100

# According to routing table rules, 10.42.1.6 and 10.42.2.6 use the flannel.1 vtep device for cross-host communication to pods on node
```

- ClusterIP type service summary
  - Traffic flows from the pod network namespace to docker0 in the host network namespace.
  - In the host network namespace's **PREROUTING chain**, traffic passes through a series of targets.
  - In these targets, the iptables kernel random module is used to match endpoint targets with evenly distributed random ratios, achieving uniform load balancing. Load balancing is implemented at the kernel level, so custom load balancing algorithms cannot be used.
  - DNAT is implemented in the endpoint targets, converting the destination cluster IP to the actual pod IP.
  - The cluster IP is a virtual IP that is not bound to any device.
  - The host must have IP forwarding enabled (net.ipv4.ip_forward = 1).
  - After transformation and DNAT in the host network namespace, the next-hop address is determined by the host network namespace's routing table

### ipvs Method

- [https://mp.weixin.qq.com/s?\_\_biz=MzI0MDE3MjAzMg==&mid=2648393263&idx=1&sn=d6f27c502a007aa8be7e75b17afac42f&chksm=f1310b40c64682563cfbfd0688deb0fc9569eca3b13dc721bfe0ad7992183cabfba354e02050&scene=178&cur_album_id=2123526506718003213#rd](https://mp.weixin.qq.com/s?__biz=MzI0MDE3MjAzMg==&mid=2648393263&idx=1&sn=d6f27c502a007aa8be7e75b17afac42f&chksm=f1310b40c64682563cfbfd0688deb0fc9569eca3b13dc721bfe0ad7992183cabfba354e02050&scene=178&cur_album_id=2123526506718003213#rd)
- [https://icloudnative.io/posts/ipvs-how-kubernetes-services-direct-traffic-to-pods/](https://icloudnative.io/posts/ipvs-how-kubernetes-services-direct-traffic-to-pods/)

## Service: NodePort Implementation

### 1) How NodePort is Accessed

Access via host port --> cluster IP path (port range: 30000-32767)

### 2) iptables Method

- View service information

```shell
# kubectl describe service nginx-test
Name:                     nginx-test
Namespace:                default
Labels:                   app=nginx-test
Annotations:              <none>
Selector:                 app=nginx-test
Type:                     NodePort
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.43.6.58
IPs:                      10.43.6.58
Port:                     80-80  80/TCP
TargetPort:               80/TCP
NodePort:                 80-80  32506/TCP
Endpoints:                10.42.1.6:80,10.42.2.6:80
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>
```

For a NodePort type service, accessing the host's port accesses the service. From the host network perspective, when the host receives a packet, it should enter the PREROUTING chain of the host network namespace. Let's examine the host network namespace's PREROUTING chain.

- View host iptables

```shell
# iptables -nvL -t nat |head
Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
pkts bytes target     prot opt in     out     source               destination
323 20898 KUBE-SERVICES  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes service portals */
```

According to the rules, in the PREROUTING chain, all traffic goes to the KUBE-SERVICES target.

- View KUBE-SERVICES target

```shell
# iptables -nvL -t nat |grep KUBE-SERVICES -A 10
Chain KUBE-SERVICES (2 references)
pkts bytes target     prot opt in     out     source               destination
0     0 KUBE-SVC-7CWUT4JBGBRVUN2L  tcp  --  *      *       0.0.0.0/0            10.43.6.58           /* default/nginx-test:80-80 cluster IP */ tcp dpt:80
```

In the KUBE-SERVICES target, when accessing nginx-test-service on port 32506 on the host, the rules match the KUBE-NODEPORTS target.

```shell
# iptables -nvL -t nat |grep KUBE-NODEPORTS -A 3
Chain KUBE-NODEPORTS (1 references)
pkts bytes target     prot opt in     out     source               destination
2   124 KUBE-EXT-7CWUT4JBGBRVUN2L  tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/nginx-test:80-80 */ tcp dpt:32506
```

In the KUBE-NODEPORTS target, we can see that when accessing port 32506, traffic goes to the KUBE-EXT-7CWUT4JBGBRVUN2L target

- View KUBE-EXT-7CWUT4JBGBRVUN2L target

```shell
# iptables -nvL -t nat |grep KUBE-EXT-7CWUT4JBGBRVUN2L -A 5
Chain KUBE-EXT-7CWUT4JBGBRVUN2L (1 references)
 pkts bytes target     prot opt in     out     source               destination
    2   124 KUBE-MARK-MASQ  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* masquerade traffic for default/nginx-test:80-80 external destinations */
    2   124 KUBE-SVC-7CWUT4JBGBRVUN2L  all  --  *      *       0.0.0.0/0            0.0.0.0/0

# iptables -nvL -t nat |grep KUBE-MARK-MASQ -A 3
Chain KUBE-MARK-MASQ (20 references)
 pkts bytes target     prot opt in     out     source               destination
    2   124 MARK       all  --  *      *       0.0.0.0/0            0.0.0.0/0            MARK or 0x4000

# iptables -nvL -t nat |grep KUBE-SVC-7CWUT4JBGBRVUN2L -A 5
Chain KUBE-SVC-7CWUT4JBGBRVUN2L (2 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 KUBE-MARK-MASQ  tcp  --  *      *      !10.42.0.0/16         10.43.6.58           /* default/nginx-test:80-80 cluster IP */ tcp dpt:80
    1    64 KUBE-SEP-U2YYZT2C3O6VM4EV  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/nginx-test:80-80 -> 10.42.1.6:80 */ statistic mode random probability 0.50000000000
    1    60 KUBE-SEP-GWUIQWA2TNZI4ESX  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/nginx-test:80-80 -> 10.42.2.6:80 */
```

In KUBE-EXT-7CWUT4JBGBRVUN2L, we can see two targets

- KUBE-MARK-MASQ marks packets, no NAT target
- KUBE-SVC-7CWUT4JBGBRVUN2L target enters the cluster IP rules, repeating the rules from the section above, and traffic ultimately reaches the Pod

- NodePort type service summary:
  - In the host network namespace's PREROUTING chain, the KUBE-SERVICES target is matched.
  - In the KUBE-SERVICES target, the KUBE-NODEPORTS target is matched
  - In the KUBE-NODEPORTS target, the KUBE-SVC-XXX target is matched based on protocol
  - The KUBE-SVC-XXX target works the same as the ClusterIP type service described above, and traffic ultimately reaches the Pod

### 3) ipvs Method

- [https://mp.weixin.qq.com/s?\_\_biz=MzI0MDE3MjAzMg==&mid=2648393266&idx=1&sn=34d2a21b06d6e9ef4f4f7415f2cad567&chksm=f1310b5dc646824b45cbfc8cf25b0f2449f7223006b684da06ba58d95a2be7a3f0ad7aa6c4b9&scene=178&cur_album_id=2123526506718003213#rd](https://mp.weixin.qq.com/s?__biz=MzI0MDE3MjAzMg==&mid=2648393266&idx=1&sn=34d2a21b06d6e9ef4f4f7415f2cad567&chksm=f1310b5dc646824b45cbfc8cf25b0f2449f7223006b684da06ba58d95a2be7a3f0ad7aa6c4b9&scene=178&cur_album_id=2123526506718003213#rd)
- [https://icloudnative.io/posts/ipvs-how-kubernetes-services-direct-traffic-to-pods/](https://icloudnative.io/posts/ipvs-how-kubernetes-services-direct-traffic-to-pods/)

## Service: ipvs vs iptables Comparison

> Requirements for ipvs-based K8s network load balancing:
>
> - Linux kernel version higher than 2.4.x
> - Add --proxy-mode=ipvs to the kube-proxy startup parameters
> - Install the ipvsadm tool (optional) for managing ipvs rules

- Both use Linux kernel modules to perform load balancing and endpoint mapping. All operations are done in kernel space, not in user space of applications.
- The iptables method relies on the Linux netfilter/iptables kernel module.
- The ipvs method relies on the Linux netfilter/iptables module, ipset module, and ipvs module.
- In the iptables method, the number of iptables entries on the host increases as the number of services and their corresponding endpoints increases. For example, with 10 ClusterIP type services, each having 6 endpoints, there would be at least 10 entries (KUBE-SVC-XXX) in the KUBE-SERVICES target corresponding to the 10 services, each KUBE-SVC-XXX target would have 6 KUBE-SEP-XXX entries for the 6 endpoints, and each KUBE-SEP-XXX would have 2 entries for mark masq and DNAT respectively. This adds up to at least 10*6*2=120 entries in iptables. If the number of services and endpoints in an application is large, the iptables entries become enormous, potentially causing performance issues.
- In the ipvs method, the number of iptables entries on the host is fixed because iptables matching uses ipset (KUBE-CLUSTER-IP or KUBE-NODE-PORT-TCP). The number of services determines the ipset size but does not affect the iptables size. This solves the problem of entries growing with the number of services and endpoints in the iptables method.
- For load balancing, the iptables method uses the random module, while the ipvs method supports multiple load balancing algorithms such as round-robin, least connection, source hash, etc. (see http://www.linuxvirtualserver.org/), controlled by the kubelet startup parameter --ipvs-scheduler.
- For destination address mapping, the iptables method uses Linux native DNAT, while the ipvs method uses the ipvs module.
- The ipvs method creates a network device kube-ipvs0 in the host network namespace and binds all cluster IPs to it, ensuring that ClusterIP type service data enters the INPUT chain, allowing ipvs to perform load balancing and destination address mapping.
- The iptables method does not create additional network devices in the host network namespace.
- In the iptables method, the data path through the chains in the host network namespace is: PREROUTING-->FORWARDING-->POSTROUTING. Load balancing, mark masq, and destination address mapping are completed in the PREROUTING chain.

- In the ipvs method, the data path through the chains in the host network namespace is: PREROUTING-->INPUT-->POSTROUTING. Mark masq SNAT is completed in the PREROUTING chain, and ipvs performs load balancing and destination address mapping in the INPUT chain.
- Both iptables and ipvs methods perform next-hop routing based on the host network namespace's routing table after completing load balancing and destination address mapping.

## Cross-Host Network Communication: flannel Component

### 1) flannel underlay Network: host-gw Method

**Underlay Network Concept and Configuration**

- Concept: The underlay network has no additional encapsulation during communication. It achieves packet forwarding by using the container's host as a router

- Configuration: omitted

**Service and Pod Information**

```shell
# kubectl describe service nginx-test
Name:              nginx-test
Namespace:         default
Labels:            app=nginx-test
Annotations:       <none>
Selector:          app=nginx-test
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.43.6.58
IPs:               10.43.6.58
Port:              80-80  80/TCP
TargetPort:        80/TCP
Endpoints:         10.42.0.65:80,10.42.1.9:80
Session Affinity:  None
Events:            <none>

# kubectl get pod -owide
NAME                          READY   STATUS    RESTARTS      AGE   IP           NODE     NOMINATED NODE   READINESS GATES
nginx-test-7646687cc4-n8s9s   1/1     Running   6 (60m ago)   26d   10.42.0.65   master   <none>           <none>
nginx-test-7646687cc4-z8xnq   1/1     Running   0             47s   10.42.1.9    node1    <none>           <none>
```

**Packet Flow Analysis: from 10.42.0.65 to 10.42.1.9**

- Packet from source pod to host

When sending a packet from pod **10.42.0.65** to pod **10.42.1.9**, pod **10.42.0.65**'s network interface is one end of a veth pair. According to the routing rules in the pod's network namespace, data is sent to **10.42.0.1**, which is the cni0 Linux bridge device in the host's network namespace. Since the other end of pod **10.42.0.65**'s veth is attached to the cni0 bridge device, the data is received by cni0 bridge, meaning the data flows from the pod's network namespace to the host's network namespace.

- Packet routing in the source pod's host

Since the destination IP address of the packet is **10.42.1.9** and the host IP of source pod **10.42.0.65** is **192.168.205.4**, the host has IP forwarding enabled (net.ipv4.ip_forward = 1). When the host determines that the destination IP **10.42.1.9** is not its own IP, it performs route forwarding on the packet. Let's examine the routing table of host **192.168.205.4**

```shell
# ip addr |grep 192.168.205.4
    inet 192.168.205.4/24 metric 100 brd 192.168.205.255 scope global dynamic enp0s1

# ip route
10.42.1.0/24 via 192.168.205.3 enp0s1 ...
```

The routing table shows that the next hop for the **10.42.1.0/24** subnet is **192.168.205.3**, which is the host machine of the destination pod **10.42.1.9**. Therefore, ARP destination MAC address encapsulation is performed and data is sent to **192.168.205.3**. Note that the next hop for the destination pod is the host where the destination pod resides, meaning data is sent from the source pod's host to the destination pod's host via the next hop. This means the source pod's host and the destination pod's host must be in the same Layer 2 network, because only then is the next-hop route reachable. This is also the limitation of flannel's underlay host-gw method, which requires all K8s worker nodes to be in the same Layer 2 network (essentially in the same IP subnet).

- Packet routing in the destination pod's host

When the packet is routed to host **192.168.205.3** of destination pod **10.42.1.9** (via Layer 2 switching), the destination pod's host has IP forwarding enabled (net.ipv4.ip_forward = 1). When the host determines that destination IP **10.42.1.9** is not its own IP, it performs route forwarding on the packet. Let's examine the routing table of host **192.168.205.3**

```shell
# ip addr |grep 192.168.205.3
    inet 192.168.205.3/24 metric 100 brd 192.168.205.255 scope global dynamic enp0s1

# ip route
10.42.1.0/24 dev cni0 proto kernel scope link src 10.42.1.1
```

The routing table shows that the next hop for the **10.42.1.0/24** subnet is a directly connected route, forwarded by the cni0 interface. The cni interface **10.42.1.1**, acting as a Linux bridge, sends data via a veth pair from the host network namespace to the network namespace of destination pod **10.42.1.9**. The kernel then hands it to the application for processing, completing pod-to-pod communication. You can use kubectl debug to view the routing path through nodes

```shell
# kubectl debug -it nginx-test-7646687cc4-z8xnq --image=busybox -- /bin/sh

# ip addr
# traceroute 10.42.1.9
```

**flannel underlay (host-gw method) Summary**

- Data flows from the source pod's network namespace to the cni0 Linux bridge in the host network namespace.
- Layer 3 routing is performed on the source pod's host, with the next-hop address being the host where the destination pod resides.
- The packet is sent from the source pod's host to the destination pod's host. (Layer 2 MAC encapsulated packet)
- Layer 3 routing is performed on the destination pod's host, with a locally connected route to the destination pod.
- All nodes must have IP forwarding enabled (net.ipv4.ip_forward = 1)
- All nodes must be in the same Layer 2 network to enable next-hop routing to the destination pod's host

### 2) flannel overlay Network: vxlan Method

**Overlay Network Concept and Configuration**

- Concept

VXLAN is an overlay network technology designed to build Layer 2 networks on top of Layer 3 networks. Layer 2 networks typically use VLAN technology for isolation, but VLAN uses only 4 bytes in the packet with 12 bits to identify different Layer 2 networks, allowing a total of about 4,000 VLANs. VXLAN headers use 8 bytes with 24 bits to identify different Layer 2 networks, allowing a total of over 16 million VXLANs. [VXLAN specification](https://tools.ietf.org/html/rfc7348)

- Configuration: [Reference](https://mp.weixin.qq.com/s?__biz=MzI0MDE3MjAzMg==&mid=2648393268&idx=1&sn=ea7df945f11a57619a81df8599bcbe99&chksm=f1310b5bc646824daaf9ac6cb2dec4b8c8f54fdf4753b5379db991c88e4e5951ec928b9da2d9&scene=178&cur_album_id=2123526506718003213#rd)

  1. When configuring a cluster with VXLAN, the MTU value changes from 1500 to 1450 because VXLAN encapsulates Layer 2 ethernet frames in UDP packet payloads.
  2. VXLAN uses UDP encapsulation. etcd is configured to receive data on UDP port 8472, so port 8472 UDP must be allowed on all nodes.

**Service and Pod Information**

```shell
# kubectl describe service nginx-test
Name:              nginx-test
Namespace:         default
Labels:            app=nginx-test
Annotations:       <none>
Selector:          app=nginx-test
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.43.6.58
IPs:               10.43.6.58
Port:              80-80  80/TCP
TargetPort:        80/TCP
Endpoints:         10.42.0.65:80,10.42.1.9:80
Session Affinity:  None
Events:            <none>

# kubectl get pod -owide
NAME                          READY   STATUS    RESTARTS      AGE   IP           NODE     NOMINATED NODE   READINESS GATES
nginx-test-7646687cc4-n8s9s   1/1     Running   6 (60m ago)   26d   10.42.0.65   master   <none>           <none>
nginx-test-7646687cc4-z8xnq   1/1     Running   0             47s   10.42.1.9    node1    <none>           <none>
```

**kubectl debug to view routing path and network, entering pod 10.42.0.65**

```shell
#kubectl debug -it nginx-test-7646687cc4-n8s9s --image=busybox -- /bin/sh
/ # ping -c 3 10.42.1.9
PING 10.42.1.9 (10.42.1.9): 56 data bytes
64 bytes from 10.42.1.9: seq=0 ttl=62 time=1.447 ms
64 bytes from 10.42.1.9: seq=1 ttl=62 time=2.732 ms
64 bytes from 10.42.1.9: seq=2 ttl=62 time=0.880 ms
/ # traceroute -n 10.42.1.9
traceroute to 10.42.1.9 (10.42.1.9), 30 hops max, 46 byte packets
 1  10.42.0.1  0.027 ms  0.012 ms  0.009 ms
 2  10.42.1.0  1.761 ms  1.440 ms  1.085 ms
 3  10.42.1.9  1.453 ms  0.979 ms  0.976 ms
```

**Packet Flow Analysis: from 10.42.0.65 to 10.42.1.9**

- Data routing in the pod's network namespace

Pod with IP **10.42.0.65** accesses pod **10.42.1.9** from its own network namespace. According to the routing table in **10.42.0.65**'s pod network namespace, data enters the Linux bridge cni0 in the network namespace of **10.42.0.65** pod's host **192.168.205.4**. Let's examine the host routing information

```shell
# ip addr |grep 192.168.205.4
    inet 192.168.205.4/24 metric 100 brd 192.168.205.255 scope global dynamic enp0s1

# ip route
10.42.1.0/24 via 10.42.1.0 dev flannel.1 onlink
```

The next-hop IP address for the **10.42.1.0/24** subnet is **10.42.1.0**, sent via the flannel.1 device. The flannel.1 device is created on the host when flannel starts based on the VXLAN network type. It is a VXLAN device that handles encapsulation and decapsulation of Layer 2 ethernet frames into UDP packets. The ".1" represents the VXLAN Layer 2 network ID of 1, which corresponds to the VXLAN network configuration in etcd. At this point, the packet's source IP is **10.42.0.65**, destination IP is **10.42.1.9**, source MAC is the veth device MAC in pod **10.42.0.65**'s network namespace, and destination MAC is the MAC of next-hop IP **10.42.1.0/32**.

- View VTEP endpoint MAC addresses and forwarding interface information

View MAC address information: On host **192.168.205.4** of pod **10.42.0.65**, query the ARP table for the MAC address of **10.42.1.0/32**, which is 62:c8:a9:ce:ca:4e

```shell
# ip addr |grep 192.168.205.4
    inet 192.168.205.4/24 metric 100 brd 192.168.205.255 scope global dynamic enp0s1

# ip neighbo |grep 10.42.1.0
10.42.1.0 dev flannel.1 lladdr 62:c8:a9:ce:ca:4e PERMANENT

# ip neighbo show dev flannel.1
10.42.1.0 lladdr 62:c8:a9:ce:ca:4e PERMANENT
10.42.2.0 lladdr ca:cb:1f:99:10:97 PERMANENT
```

View MAC address forwarding information: Since the flannel.1 device is a VXLAN device, there is a forwarding interface corresponding to its MAC. Continue querying the flannel.1 device's MAC forwarding interface on host **192.168.205.4** of pod **10.42.0.65**.

```shell
# ip addr |grep 192.168.205.4
    inet 192.168.205.4/24 metric 100 brd 192.168.205.255 scope global dynamic enp0s1

# bridge fdb show |grep 62:c8:a9:ce:ca:4e
62:c8:a9:ce:ca:4e dev flannel.1 dst 192.168.205.3 self permanent

# bridge fdb show dev flannel.1
62:c8:a9:ce:ca:4e dst 192.168.205.3 self permanent
ee:87:b2:4a:fd:62 dst 192.168.205.5 self permanent
```

We can see that the forwarding interface for flannel.1 device MAC address **62:c8:a9:ce:ca:4e** is **192.168.205.3**, meaning the flannel.1 device will send the original Layer 2 packet (source IP **10.42.0.65**, destination IP **10.42.1.9**, source MAC is the veth device MAC in pod **10.42.0.65**'s network namespace, destination MAC is **10.42.1.0/32** MAC) as the UDP payload to port **8472** on **192.168.205.3**. The host of destination pod **10.42.1.9** is indeed **192.168.205.3**, and the flannel.1 device on that host will also process UDP decapsulation on port 8472 data.

- flannel.1 设备处理 udp 封包与解包

```shell
# ip addr |grep 192.168.205.4
    inet 192.168.205.4/24 metric 100 brd 192.168.205.255 scope global dynamic enp0s1

# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.205.1   0.0.0.0         UG    100    0        0 enp0s1
192.168.205.0   0.0.0.0         255.255.255.0   U     100    0        0 enp0s1
192.168.205.1   0.0.0.0         255.255.255.255 UH    100    0        0 enp0s1
```

flannel.1 device UDP encapsulation: From the routing table of host **192.168.205.4** of pod **10.42.0.65**, we know that the **192.168.205.0/24** subnet is a directly connected route, sent via the host network device enp0s1. Therefore:

- Outer UDP packet: source IP is **192.168.205.4**, destination IP is **192.168.205.3**, source MAC is **192.168.205.4** MAC, destination MAC is **192.168.205.3** MAC. Destination port is 8472, VXLAN ID is 1.
- Inner Layer 2 ethernet frame: source IP is **10.42.0.65**, destination IP is **10.42.1.9**, source MAC is the veth device MAC in pod **10.42.0.65**'s network namespace, destination MAC is **10.42.1.0/32** MAC
- After encapsulation, the packet is sent to destination node **192.168.205.3** based on the host routing table

flannel.1 device UDP decapsulation: After host **192.168.205.3** receives the packet

- After the destination node **192.168.205.3** receives the UDP packet on port 8472, it finds a VXLAN ID of 1 in the packet. Since the Linux kernel supports VXLAN, the protocol stack can determine through the VXLAN ID that this is a VXLAN data packet with VXLAN ID 1. It then finds the VXLAN device with VXLAN ID 1 on the host machine for processing, which is the flannel.1 device on **192.168.205.3**.
- After flannel.1 receives the data, it begins decapsulating the VXLAN UDP packet, stripping the UDP packet's IP, port, and MAC information to obtain the internal payload, which is found to be a Layer 2 frame.
- Continuing to decapsulate this Layer 2 frame, the source IP is **10.42.0.65** and the destination IP is **10.42.1.9**.
- Based on the routing table on **192.168.205.3**, the data is locally forwarded via the Linux bridge cni0. cni0, acting as a Linux bridge, uses a veth pair to forward data to the destination pod **10.42.1.9**

```shell
# ip addr |grep 192.168.205.3
    inet 192.168.205.3/24 metric 100 brd 192.168.205.255 scope global dynamic enp0s1

# route -n
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
10.42.1.0       0.0.0.0         255.255.255.0   U     0      0        0 cni0
```

- Writing the host's routing table and flannel.1 device MAC forwarding interface table (FDB forwarding)

Because all hosts run the flannel service and flannel connects to the etcd storage center, each host knows its own subnet CIDR, its own flannel.1 device IP and MAC address within this CIDR, and also knows the subnet CIDRs and flannel.1 device IP and MAC addresses of other hosts. With this information, entries can be written to the routing table and FDB when flannel starts. Using host **192.168.205.4** as an example:

```shell
~# ip addr |grep 192.168.205.4
    inet 192.168.205.4/24 metric 100 brd 192.168.205.255 scope global dynamic enp0s1

# bridge fdb show dev flannel.1
62:c8:a9:ce:ca:4e dst 192.168.205.3 self permanent
ee:87:b2:4a:fd:62 dst 192.168.205.5 self permanent

# etcdctl ....
```

**flannel overlay (VXLAN method) Summary**

- Each host has a VXLAN network device named flannel.x to handle UDP encapsulation and decapsulation of VXLAN data, processed on the host's port 8472 (configurable).
- Data flows from the pod's network namespace into the host's network namespace.
- Based on the routing table in the host network namespace, the next-hop IP is the destination VXLAN device's IP, sent by the current host's flannel.x device.
- The next-hop IP's MAC address is found from the ARP table in the host network namespace.
- The forwarding IP corresponding to the next-hop IP's MAC address is found from the FDB in the host network namespace.
- The current host's flannel.x device performs UDP encapsulation based on the forwarding IP corresponding to the next-hop IP's MAC address and the local routing table. At this point:
  - Outer UDP packet: source IP is the current host IP, destination IP is the matched IP from the MAC forwarding table, source MAC is the current host IP's MAC, destination MAC is the MAC of the matched IP from FDB. Destination port is 8472 (configurable), VXLAN ID is 1 (configurable).
  - Inner Layer 2 ethernet frame: source IP is the source pod IP, destination IP is the destination pod IP, source MAC is the source pod MAC, destination MAC is the MAC of the next-hop IP from the routing table in the host network namespace (typically the flannel.x device IP on the host of the destination pod).
- The packet is routed from the current host to the destination node host.
- After the destination node host receives the UDP packet on port 8472, it finds a VXLAN ID in the packet. Based on the Linux VXLAN protocol, it finds the VXLAN device on the destination host matching the VXLAN ID in the data packet and hands the data to it for processing.
- The VXLAN device decapsulates the VXLAN UDP packet, stripping the UDP packet's IP, port, and MAC information to obtain the internal payload, which is found to be a Layer 2 frame. It then continues decapsulating this Layer 2 frame to obtain the source pod IP and destination pod IP.
- Based on the routing table on the destination node host, data is locally forwarded via the Linux bridge cni0.
- Data is forwarded from the Linux bridge cni0 to the destination pod via a veth pair.
- When the flannel service starts on each host, it reads the VXLAN configuration from etcd and writes the corresponding data to the host's routing table and MAC forwarding interface table (FDB).

### 3) flannel underlay vs overlay Network Comparison

- Both require the host to have network forwarding enabled (net.ipv4.ip_forward = 1).
- The flannel underlay network has no additional packet encapsulation/decapsulation, making it more efficient.
- The flannel underlay network requires all worker nodes to be in the same Layer 2 network to enable next-hop routing to the destination pod. This means underlay network worker nodes cannot span subnets.
- The flannel VXLAN overlay network has encapsulation/decapsulation, with the outer packets being UDP packets. Therefore, worker nodes only need Layer 3 route reachability, supporting worker nodes across subnets.
- The flannel VXLAN overlay network's inner packets are Layer 2 ethernet frames, based on Linux VXLAN devices
- In both flannel underlay and flannel VXLAN overlay networks, all packets are processed in the operating system kernel space without user-space application involvement.

> Reference:
>
> 1. [K8s Cluster Networking](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=MzI0MDE3MjAzMg==&action=getalbum&album_id=2123526506718003213&scene=173&from_msgid=2648393229&from_itemidx=1&count=3&nolastread=1#wechat_redirect)
> 2. [iptables Explained](https://www.jianshu.com/p/ee4ee15d3658)
> 3. [Docker Network Types](https://developer.aliyun.com/article/974008#slide-4)
> 4. [ipvs Working Mode Principles](https://icloudnative.io/posts/ipvs-how-kubernetes-services-direct-traffic-to-pods/)
