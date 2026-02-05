---
description: Kubernetes Network
---

# Kubernetes Network

## 1. Introduction
### a) Container Network Fundamentals

- Linux Network Namespace
   - Linux network devices: network interface device, loopback device, bridge device, veth device, tun/tap device, vxlan device, ip tunnel device, etc. These devices can send/receive network packets and provide additional packet modification capabilities
   - Linux routing table (Layer 3 IP packet routing and addressing), ARP table (provides MAC information corresponding to IP addresses), FDB (provides network interfaces corresponding to MAC addresses for MAC-based forwarding), etc.
   - Linux protocol stack: encapsulation and parsing of network protocol packets, such as Layer 2 Ethernet packets, Layer 3 IP/ICMP packets, Layer 4 TCP/UDP packets, etc.
   - Linux iptables: firewall management for Linux based on the kernel module netfilter, such as controlling ingress and egress, NAT address translation, port mapping, etc.

![image](https://github.com/logic3579/knowledge/assets/30774576/f89d9f70-3f49-4e3f-8064-883fe640369e)
> Linux does not only have network namespace for network isolation; there are also pid namespace for process isolation, user namespace for user isolation, mount namespace for mount point isolation, ipc namespace for semaphore and shared memory isolation, and uts namespace for hostname and domain name isolation.
> Combined with cgroup control groups to limit CPU, memory, I/O, and other resources, these form the underlying implementation of containers

- Linux Bridge Device

A Linux bridge device can attach multiple Linux slave devices. It is similar to an internal virtual Layer 2 switch capable of Layer 2 packet broadcasting. Note that a Linux bridge device can have its own IP address. That is, when multiple Linux network devices are attached to a bridge, the IP addresses of those network devices become ineffective (only Layer 2 functionality remains). When a device receives a packet, the bridge forwards the packet to all other slave devices attached to the bridge, achieving a broadcast effect.
![image](https://github.com/logic3579/knowledge/assets/30774576/2b75e484-bee6-40e4-b9ca-03120da295ec)

- Linux Veth Device

Always appear in pairs, with one pair having two peer endpoints. Packets flow in from one peer and out to the other peer. A veth pair can span across network namespaces.
![image](https://github.com/logic3579/knowledge/assets/30774576/4bcfafbb-f4db-4e31-912f-20a2416b74e9)

### b) K8s Cluster Container Network Communication Methods

- Network load balancing modes

Controlled by kube-proxy component startup parameters (--proxy-module=ipvs)
iptables: default
ipvs: v1.11 and later

- Network communication methods

underlay: flannel host-gw, calico bgp, etc. (requires enabling ip_forward kernel parameter)
overlay: flannel vxlan, calico ipip, flannel udp (generally not used), etc.

### c) Test Environment Host Information
| Host IP | Role | Container CIDR | CNI Interface Address | Flannel.1 VTEP Device |
| --- | --- | --- | --- | --- |
| 192.168.205.4
192.168.205.3
192.168.205.5 | master
node1
node2 | 10.42.0.0/24
10.42.1.0/24
10.42.2.0/24 | 10.42.0.1
10.42.1.1
10.42.2.1 | 10.42.0.0
10.42.1.0
10.42.2.0 |


## 2. Intra-Host Networking
### a) Four Docker Container Network Types

- bridge mode (default): --net=bridge

The host creates a docker0 network interface using an independent IP range, assigns an IP from that range to each container, and containers communicate through this bridge (similar to a Layer 2 switch)
![image](https://github.com/logic3579/knowledge/assets/30774576/d2e0e535-d529-41fb-9cc9-15089f832658)
> Custom bridge network: creates an independent network namespace within the host scope
![image](https://github.com/logic3579/knowledge/assets/30774576/81c1548f-959d-4b7b-8272-4c67b307da23)


- host mode: --net=host

Shares the host network; when a container exposes a port, it occupies a host port. The network mode is simple with good performance, generally used for single-container services.
![image](https://github.com/logic3579/knowledge/assets/30774576/87eaedc3-215b-4eb5-b745-d5569fd8002a)

- container mode: --net=container:name or id

Specifies that the newly created container shares the network namespace of an existing container (in K8s, a pod is multiple containers sharing a network namespace). Besides the network, file systems, processes, etc. are all isolated. Processes between containers can communicate through the lo (loopback) interface
![image](https://github.com/logic3579/knowledge/assets/30774576/4c96e68b-3644-4e3e-8126-f354df90919f)

- none mode: the container has its own independent network namespace but no network configuration; network can be configured manually. Generally used for CPU-intensive tasks where computation results are saved to disk and no external network access is needed

### b) Container Networking in the Docker Host Environment

- Each container has its own network namespace with its own network devices, routing table, ARP table, protocol stack, iptables, etc. The network namespaces of each container are isolated from each other.
- In the host's default network namespace, there is a Linux bridge device, typically named docker0.
- Each container corresponds to a veth pair device. One end of this device is in the container's network namespace, and the other end is attached to the docker0 Linux bridge in the host's network namespace.
- In the host environment, this is like having a Layer 2 switch (docker0 bridge) connecting all containers within the host. Therefore, containers within the same host can directly access each other via direct connection

![image](https://github.com/logic3579/knowledge/assets/30774576/59264cc0-f9f7-44ca-a448-78460c8370f1)

```bash
## Related commands
# View bridge information
# K8s pod infrastructure container shares network namespace and veth pair with the base container
brctl show

# View veth pair device information
ip addr
ip -d link show

# View routing table
route -n

# View docker container information
docker ps/inspect/container
```

## 3. Service: ClusterIP Implementation
### a) How ClusterIP is Accessed
Services in a K8s cluster need to access each other. Typically, a corresponding service is created, and ClusterIP is used for intra-cluster access. A ClusterIP is associated with multiple endpoints (actual pod addresses). Accessing a ClusterIP achieves load-balanced access to the multiple endpoints associated with it (load balancing via iptables or ipvs)

### b) iptables Mode

- View service information: ClusterIP and associated endpoint IPs
```bash
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
```bash
# iptables -nvL -t nat |head
Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
pkts bytes target     prot opt in     out     source               destination
298 19090 KUBE-SERVICES  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes service portals */
202 12456 CNI-HOSTPORT-DNAT  all  --  *      *       0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL
```
In the PREROUTING chain, all traffic flows into the KUBE-SERVICES target. Note that the PREROUTING chain is the first entry point after traffic arrives. If you run `curl http://10.43.6.58` inside a pod, according to the container's internal routing table, the packet flow should be:

   - In the pod, the routing table determines that the ClusterIP (**10.43.6.58**) goes through the default route, selecting the default gateway.
   - In the pod, the default gateway's IP address is the IP address of the host network namespace's **docker0 or cni0**, and the default gateway is a directly connected route.
   - In the pod, according to the routing table, data is sent using eth0 device. eth0 is essentially one end of a veth pair in the pod's network namespace, with the other end attached to the **docker0 or cni0** bridge in the host's network namespace.
   - Via the veth pair, data sent from one end in the pod's network namespace enters the other end attached to the **docker0 or cni0** bridge.
   - After the **docker0 or cni0** bridge receives the data, it naturally enters the PREROUTING chain of the host network namespace

- View KUBE-SERVICES target
```bash
# iptables -nvL -t nat | grep 10.43.6.58
0     0 KUBE-SVC-7CWUT4JBGBRVUN2L  tcp  --  *      *       0.0.0.0/0            10.43.6.58           /* default/nginx-test:80-80 cluster IP */ tcp dpt:80

# iptables -nvL -t nat | grep KUBE-SVC-7CWUT4JBGBRVUN2L -A 5
Chain KUBE-SVC-7CWUT4JBGBRVUN2L (1 references)
pkts bytes target     prot opt in     out     source               destination
0     0 KUBE-SEP-U2YYZT2C3O6VM4EV  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/nginx-test:80-80 -> 10.42.1.6:80 */ statistic mode random probability 0.50000000000
0     0 KUBE-SEP-GWUIQWA2TNZI4ESX  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/nginx-test:80-80 -> 10.42.2.6:80 */
```
In the KUBE-SERVICES target, we can see that the matching target for destination address ClusterIP 10.43.6.58 is KUBE-SVC-7CWUT4JBGBRVUN2L.
**KUBE-SVC-7CWUT4JBGBRVUN2L chain information:**

   - There are two targets (corresponding to two Pods): KUBE-SEP-U2YYZT2C3O6VM4EV and KUBE-SEP-GWUIQWA2TNZI4ESX
   - KUBE-SEP-U2YYZT2C3O6VM4EV has statistic mode random probability 0.5. The 0.5 leverages the iptables kernel random module with a random ratio of 0.5, meaning 50%
   - Since half of the traffic randomly enters the KUBE-SEP-U2YYZT2C3O6VM4EV target, the other target also gets 50%, achieving load balancing

- View KUBE-SEP-U2YYZT2C3O6VM4EV and KUBE-SEP-GWUIQWA2TNZI4ESX
```bash
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
In these 2 targets we can see:

   - MASQ operations were performed, which should be for outbound egress traffic (limited by source IP), not our inbound ingress traffic.
   - DNAT operations were performed, converting the original ClusterIP to pod IPs 10.42.1.6 and 10.42.2.6, and converting the original port to port 80.
   - After this series of iptables targets, our original request to 10.43.6.58:80 becomes either 10.42.1.6:80 or 10.42.2.6:80, with each having a 50% probability.
   - According to iptables, after passing through the PREROUTING chain and DNAT, 10.42.1.6 or 10.42.2.6 is not a local IP (these are pod IPs, which of course are not in the host network namespace). So it enters the FORWARDING chain, and the next-hop address is determined by the host network namespace's routing table
```bash
# View routing table information
# ip route
default via 192.168.205.1 dev enp0s1 proto dhcp src 192.168.205.4 metric 100
10.42.0.0/24 dev cni0 proto kernel scope link src 10.42.0.1
10.42.1.0/24 via 10.42.1.0 dev flannel.1 onlink
10.42.2.0/24 via 10.42.2.0 dev flannel.1 onlink
192.168.205.0/24 dev enp0s1 proto kernel scope link src 192.168.205.4 metric 100
192.168.205.1 dev enp0s1 proto dhcp scope link src 192.168.205.4 metric 100

# According to routing table rules, 10.42.1.6 and 10.42.2.6 go through flannel.1 VTEP device for cross-host communication to pods on other nodes
```

- ClusterIP type service summary
   - Traffic flows from the pod network namespace to docker0 in the host network namespace.
   - In the host network namespace's **PREROUTING chain**, traffic passes through a series of targets.
   - In these targets, the iptables kernel random module is used to match endpoint targets with evenly distributed random ratios, achieving uniform load balancing. Load balancing is implemented in the kernel, so custom load balancing algorithms are not possible.
   - DNAT is implemented in the endpoint targets, converting the destination ClusterIP address to the actual pod IP.
   - ClusterIP is a virtual IP that is not bound to any device.
   - The host must have IP forwarding enabled (net.ipv4.ip_forward = 1).
   - After conversion and DNAT in the host network namespace, the next-hop address is determined by the host network namespace's routing table

### c) ipvs Mode

- [https://mp.weixin.qq.com/s?__biz=MzI0MDE3MjAzMg==&mid=2648393263&idx=1&sn=d6f27c502a007aa8be7e75b17afac42f&chksm=f1310b40c64682563cfbfd0688deb0fc9569eca3b13dc721bfe0ad7992183cabfba354e02050&scene=178&cur_album_id=2123526506718003213#rd](https://mp.weixin.qq.com/s?__biz=MzI0MDE3MjAzMg==&mid=2648393263&idx=1&sn=d6f27c502a007aa8be7e75b17afac42f&chksm=f1310b40c64682563cfbfd0688deb0fc9569eca3b13dc721bfe0ad7992183cabfba354e02050&scene=178&cur_album_id=2123526506718003213#rd)
- [https://icloudnative.io/posts/ipvs-how-kubernetes-services-direct-traffic-to-pods/](https://icloudnative.io/posts/ipvs-how-kubernetes-services-direct-traffic-to-pods/)

## 4. Service: NodePort Implementation
### a) How NodePort is Accessed
Accessed via host port --> ClusterIP path (port range: 30000-32767)

### b) iptables Mode

- View service information
```bash
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
For a NodePort type service, accessing the host's port means accessing the service. So from the host network perspective, when the host receives a data packet, it should enter the PREROUTING chain in the host's network namespace. Let's examine the host network namespace's PREROUTING chain.

- View host iptables
```bash
# iptables -nvL -t nat |head
Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
pkts bytes target     prot opt in     out     source               destination
323 20898 KUBE-SERVICES  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes service portals */
```
According to the rules, in the PREROUTING chain, all traffic flows into the KUBE-SERVICES target.

- View KUBE-SERVICES target
```bash
# iptables -nvL -t nat |grep KUBE-SERVICES -A 10
Chain KUBE-SERVICES (2 references)
pkts bytes target     prot opt in     out     source               destination
0     0 KUBE-SVC-7CWUT4JBGBRVUN2L  tcp  --  *      *       0.0.0.0/0            10.43.6.58           /* default/nginx-test:80-80 cluster IP */ tcp dpt:80
```
In the KUBE-SERVICES target, when accessing nginx-test-service on port 32506 on the host, the rules match the KUBE-NODEPORTS target.
```bash
# iptables -nvL -t nat |grep KUBE-NODEPORTS -A 3
Chain KUBE-NODEPORTS (1 references)
pkts bytes target     prot opt in     out     source               destination
2   124 KUBE-EXT-7CWUT4JBGBRVUN2L  tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            /* default/nginx-test:80-80 */ tcp dpt:32506
```
In the KUBE-NODEPORTS target, we can see that when accessing port 32506, traffic goes to the KUBE-EXT-7CWUT4JBGBRVUN2L target

- View KUBE-EXT-7CWUT4JBGBRVUN2L target
```bash
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

   - KUBE-MARK-MASQ marks the packet, no NAT target
   - KUBE-SVC-7CWUT4JBGBRVUN2L target enters the ClusterIP rules, repeating the rules from section 3, and traffic ultimately reaches the Pod

- NodePort type service summary:
   - In the host network namespace's PREROUTING chain, it matches the KUBE-SERVICES target.
   - In the KUBE-SERVICES target, it matches the KUBE-NODEPORTS target
   - In the KUBE-NODEPORTS target, it matches the KUBE-SVC-XXX target based on port
   - The KUBE-SVC-XXX target is the same as the ClusterIP type service in section 3, and traffic ultimately reaches the Pod

### c) ipvs Mode

- [https://mp.weixin.qq.com/s?__biz=MzI0MDE3MjAzMg==&mid=2648393266&idx=1&sn=34d2a21b06d6e9ef4f4f7415f2cad567&chksm=f1310b5dc646824b45cbfc8cf25b0f2449f7223006b684da06ba58d95a2be7a3f0ad7aa6c4b9&scene=178&cur_album_id=2123526506718003213#rd](https://mp.weixin.qq.com/s?__biz=MzI0MDE3MjAzMg==&mid=2648393266&idx=1&sn=34d2a21b06d6e9ef4f4f7415f2cad567&chksm=f1310b5dc646824b45cbfc8cf25b0f2449f7223006b684da06ba58d95a2be7a3f0ad7aa6c4b9&scene=178&cur_album_id=2123526506718003213#rd)
- [https://icloudnative.io/posts/ipvs-how-kubernetes-services-direct-traffic-to-pods/](https://icloudnative.io/posts/ipvs-how-kubernetes-services-direct-traffic-to-pods/)


## 5. Service: ipvs vs. iptables Comparison
> Requirements for ipvs-based K8s network load balancing:
> - Linux kernel version above 2.4.x
> - Add --proxy-mode=ipvs to the kube-proxy component startup parameters
> - Install ipvsadm tool (optional) for managing ipvs rules


- Both use Linux kernel modules to implement load balancing and endpoint mapping. All operations are performed in kernel space, not in application user space.
- The iptables approach relies on the Linux netfilter/iptables kernel module.
- The ipvs approach relies on the Linux netfilter/iptables module, ipset module, and ipvs module.
- In the iptables approach, the number of iptables entries on the host increases as the number of services and corresponding endpoints grows. For example, if there are 10 ClusterIP type services, each with 6 endpoints, then the KUBE-SERVICES target has at least 10 entries (KUBE-SVC-XXX) corresponding to 10 services. Each KUBE-SVC-XXX target has 6 KUBE-SEP-XXX entries corresponding to 6 endpoints, and each KUBE-SEP-XXX has 2 entries for mark masq and DNAT respectively. This adds up to at least 10*6*2=120 entries in iptables. If the number of services and endpoints in an application is enormous, iptables entries become very large, potentially causing performance issues.
- In the ipvs approach, the number of iptables entries on the host is fixed, because iptables matching uses ipset (KUBE-CLUSTER-IP or KUBE-NODE-PORT-TCP). The number of services determines the size of ipset but does not affect the size of iptables. This solves the problem of entries growing with the number of services and endpoints in the iptables mode.
- For load balancing, the iptables approach uses the random module, while the ipvs approach supports multiple load balancing algorithms such as round-robin, least connection, source hash, etc. (see http://www.linuxvirtualserver.org/), controlled by the kubelet startup parameter --ipvs-scheduler.
- For destination address mapping, the iptables approach uses native Linux DNAT, while the ipvs approach uses the ipvs module.
- The ipvs approach creates a network device kube-ipvs0 in the host network namespace and binds all ClusterIPs to it, ensuring that ClusterIP type service data enters the INPUT chain so that ipvs can perform load balancing and destination address mapping.
- The iptables approach does not create additional network devices in the host network namespace.
- In the iptables approach, the data path through chains in the host network namespace is: PREROUTING-->FORWARDING-->POSTROUTING. Load balancing, mark masq, and destination address mapping are completed in the PREROUTING chain.

- In the ipvs approach, the data path through chains in the host network namespace is: PREROUTING-->INPUT-->POSTROUTING. Mark masq and SNAT are completed in the PREROUTING chain, and ipvs performs load balancing and destination address mapping in the INPUT chain.
- Both iptables and ipvs approaches perform next-hop routing selection based on the host network namespace's routing table after completing load balancing and destination address mapping.

## 6. Cross-Host Network Communication: Flannel
### a) Flannel Underlay Network: host-gw Mode
**Underlay Network Concept and Configuration**

- Concept: The underlay network does not add extra encapsulation during communication; it achieves packet forwarding by using the container's host as a router

- Configuration: omitted

**Service and Pod Mapping Information**
```bash
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

**Packet flow analysis, request from 10.42.0.65 to 10.42.1.9**

- Packet from source pod to host

When sending a packet from pod **10.42.0.65** to pod **10.42.1.9**, pod **10.42.0.65**'s network interface is one endpoint of a veth pair. According to the routing rules in the pod's network namespace, data is always sent to **10.42.0.1**, which is the cni0 Linux bridge device in the host's network namespace. Since the other endpoint of pod **10.42.0.65**'s veth is attached to the cni0 bridge device, the data is received by cni0 bridge, meaning the data flows from the pod's network namespace to the host's network namespace.

- Packet routing in the source pod's host

Since the packet's destination IP address is **10.42.1.9**, and the source pod **10.42.0.65**'s host IP is **192.168.205.4**, the host has IP forwarding enabled (net.ipv4.ip_forward = 1). When the host discovers that the destination IP **10.42.1.9** is not its own IP, it performs routing forwarding on the packet. Let's check the routing table of host **192.168.205.4**
```bash
# ip addr |grep 192.168.205.4
    inet 192.168.205.4/24 metric 100 brd 192.168.205.255 scope global dynamic enp0s1

# ip route
10.42.1.0/24 via 192.168.205.3 enp0s1 ...
```
The routing table shows that the next hop for the **10.42.1.0/24** subnet is **192.168.205.3**, which is the host machine of target pod **10.42.1.9**. So ARP resolution is performed for the destination MAC address, and the data is sent to **192.168.205.3**. Note that the next-hop address for the target pod is the host where the target pod resides, meaning data will be sent from the source pod's host to the target pod's host via the next hop. This means the source pod's host must be in the same Layer 2 network as the target pod's host, because only then is the next-hop route reachable. This is also a limitation of flannel's underlay network host-gw mode, requiring all K8s worker nodes to be in the same Layer 2 network (which can be considered the same IP subnet).

- Packet routing in the target pod's host

When the packet is routed to target pod **10.42.1.9**'s host **192.168.205.3** (via Layer 2 switching), the target pod's host has IP forwarding enabled (net.ipv4.ip_forward = 1). When the host discovers that the destination IP **10.42.1.9** is not its own IP, it performs routing forwarding on the packet. Let's check the routing table of host **192.168.205.3**
```bash
# ip addr |grep 192.168.205.3
    inet 192.168.205.3/24 metric 100 brd 192.168.205.255 scope global dynamic enp0s1

# ip route
10.42.1.0/24 dev cni0 proto kernel scope link src 10.42.1.1
```
The routing table shows that the next hop for the **10.42.1.0/24** subnet is a directly connected route, forwarded by the cni0 network interface. The cni interface **10.42.1.1**, acting as a Linux bridge, sends data through a veth pair from the host network namespace to the target pod **10.42.1.9**'s network namespace. The kernel then hands it to the application for processing, completing the pod-to-pod communication. You can use kubectl debug to view the route hops
```bash
# kubectl debug -it nginx-test-7646687cc4-z8xnq --image=busybox -- /bin/sh

# ip addr
# traceroute 10.42.1.9
```

**Flannel Underlay (host-gw mode) Summary**

- From the source pod's network namespace to the cni0 Linux bridge in the host network namespace.
- Layer 3 routing selection in the source pod's host, with the next-hop address being the target pod's host.
- The packet is sent from the source pod's host to the target pod's host. (Layer 2 MAC-encapsulated packet)
- Layer 3 routing selection in the target pod's host, with a local directly connected route to the target pod.
- All nodes must have IP forwarding enabled (net.ipv4.ip_forward = 1)
- All nodes must be in the same Layer 2 network to enable next-hop routing to the target pod's host

### b) Flannel Overlay Network: VXLAN Mode
**Overlay Network Concept and Configuration**

- Concept

VXLAN is an overlay network technology designed to build Layer 2 networks on top of Layer 3 networks. For Layer 2 networks, VLAN technology is generally used for isolation. However, VLAN uses only 4 bytes in the packet, with 12 bits to identify different Layer 2 networks, allowing a total of about 4000 VLANs. VXLAN header has 8 bytes, with 24 bits to identify different Layer 2 networks, allowing a total of over 16 million VXLANs. [VXLAN specification](https://tools.ietf.org/html/rfc7348)

- Configuration: [reference](https://mp.weixin.qq.com/s?__biz=MzI0MDE3MjAzMg==&mid=2648393268&idx=1&sn=ea7df945f11a57619a81df8599bcbe99&chksm=f1310b5bc646824daaf9ac6cb2dec4b8c8f54fdf4753b5379db991c88e4e5951ec928b9da2d9&scene=178&cur_album_id=2123526506718003213#rd)

1. When configuring a cluster with VXLAN, because VXLAN encapsulates Layer 2 Ethernet packets in the UDP payload, the MTU value changes from 1500 to 1450.
2. VXLAN uses UDP encapsulation. etcd is configured to receive data on UDP port 8472, so port 8472 UDP must be allowed on all nodes.

**Service and Pod Mapping Information**
```bash
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
```bash
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

**Packet flow analysis, request from 10.42.0.65 to 10.42.1.9**

- Data routing in the pod's network namespace

The pod with IP **10.42.0.65** accesses pod **10.42.1.9** from its own network namespace. According to the routing table in **10.42.0.65** pod's network namespace, data enters the Linux bridge cni0 in the network namespace of **10.42.0.65** pod's host **192.168.205.4**. Let's check the host routing information
```bash
# ip addr |grep 192.168.205.4
    inet 192.168.205.4/24 metric 100 brd 192.168.205.255 scope global dynamic enp0s1

# ip route
10.42.1.0/24 via 10.42.1.0 dev flannel.1 onlink
```
The next-hop IP address for the **10.42.1.0/24** subnet is **10.42.1.0**, sent via the flannel.1 device. The flannel.1 device is created on the host by flannel at startup based on the VXLAN network type. It is a VXLAN device that handles encapsulation and decapsulation of Layer 2 Ethernet packets into UDP packets. The ".1" represents that this VXLAN Layer 2 network has an ID of 1, which also corresponds to the VXLAN network configuration in etcd. At this point, the packet's source IP is **10.42.0.65**, destination IP is **10.42.1.9**, source MAC is the veth device MAC in pod **10.42.0.65**'s network namespace, and destination MAC is the MAC of the next-hop IP **10.42.1.0/32**.

- View VTEP endpoint MAC address and forwarding interface information

View MAC address information: On host **192.168.205.4** of pod **10.42.0.65**, query the ARP table to find that the MAC address of **10.42.1.0/32** is 62:c8:a9:ce:ca:4e
```bash
# ip addr |grep 192.168.205.4
    inet 192.168.205.4/24 metric 100 brd 192.168.205.255 scope global dynamic enp0s1

# ip neighbo |grep 10.42.1.0
10.42.1.0 dev flannel.1 lladdr 62:c8:a9:ce:ca:4e PERMANENT

# ip neighbo show dev flannel.1
10.42.1.0 lladdr 62:c8:a9:ce:ca:4e PERMANENT
10.42.2.0 lladdr ca:cb:1f:99:10:97 PERMANENT
```
View MAC address forwarding information: Since flannel.1 is a VXLAN device, it has forwarding interfaces corresponding to its MAC. Continue querying the flannel.1 device's MAC forwarding interface on host **192.168.205.4** of pod **10.42.0.65**.
```bash
# ip addr |grep 192.168.205.4
    inet 192.168.205.4/24 metric 100 brd 192.168.205.255 scope global dynamic enp0s1

# bridge fdb show |grep 62:c8:a9:ce:ca:4e
62:c8:a9:ce:ca:4e dev flannel.1 dst 192.168.205.3 self permanent

# bridge fdb show dev flannel.1
62:c8:a9:ce:ca:4e dst 192.168.205.3 self permanent
ee:87:b2:4a:fd:62 dst 192.168.205.5 self permanent
```
We can see that the forwarding interface corresponding to flannel.1 device MAC address **62:c8:a9:ce:ca:4e** is **192.168.205.3**, meaning flannel.1 will send the original Layer 2 packet (source IP **10.42.0.65**, destination IP **10.42.1.9**, source MAC is the veth device MAC in pod **10.42.0.65** network namespace, destination MAC is **10.42.1.0/32** MAC) as a UDP payload to port **8472** on **192.168.205.3**. The host of target pod **10.42.1.9** is indeed **192.168.205.3**, and the flannel.1 device on it will also perform UDP decapsulation on data received on port 8472.

- flannel.1 device handling UDP encapsulation and decapsulation
```bash
# ip addr |grep 192.168.205.4
    inet 192.168.205.4/24 metric 100 brd 192.168.205.255 scope global dynamic enp0s1

# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.205.1   0.0.0.0         UG    100    0        0 enp0s1
192.168.205.0   0.0.0.0         255.255.255.0   U     100    0        0 enp0s1
192.168.205.1   0.0.0.0         255.255.255.255 UH    100    0        0 enp0s1
```
flannel.1 device UDP encapsulation: From the routing table of pod **10.42.0.65**'s host **192.168.205.4**, we know that traffic to the **192.168.205.0/24** subnet is a directly connected route, sent using the host's network device enp0s1. Therefore:

   - Outer UDP packet: source IP is **192.168.205.4**, destination IP is **192.168.205.3**, source MAC is **192.168.205.4** MAC, destination MAC is **192.168.205.3** MAC. Destination port is 8472, VXLAN ID is 1.
   - Inner Layer 2 Ethernet packet: source IP is **10.42.0.65**, destination IP is **10.42.1.9**, source MAC is the veth device MAC in pod **10.42.0.65** network namespace, destination MAC is **10.42.1.0/32** MAC
   - After encapsulation is complete, the packet is sent to target node **192.168.205.3** according to the host's routing table

flannel.1 device UDP decapsulation: After host **192.168.205.3** receives the packet

   - After the target node **192.168.205.3** receives the UDP packet on port 8472, it discovers a VXLAN ID of 1 in the packet. Since the Linux kernel supports VXLAN, the protocol stack can determine through the VXLAN ID that this is a VXLAN data packet with VXLAN ID 1. It then finds the VXLAN device with VXLAN ID 1 on the host to process it, which is the flannel.1 device on **192.168.205.3**.
   - After flannel.1 receives the data, it begins decapsulating the VXLAN UDP packet. After removing the UDP packet's IP, port, and MAC information, it obtains the internal payload and discovers it is a Layer 2 packet.
   - The Layer 2 packet is further decapsulated to reveal the source IP **10.42.0.65** and destination IP **10.42.1.9**.
   - According to the routing table on **192.168.205.3**, the data is locally forwarded by the Linux bridge cni0. As a Linux bridge, cni0 uses a veth pair to forward the data to the target pod **10.42.1.9**
```bash
# ip addr |grep 192.168.205.3
    inet 192.168.205.3/24 metric 100 brd 192.168.205.255 scope global dynamic enp0s1

# route -n
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
10.42.1.0       0.0.0.0         255.255.255.0   U     0      0        0 cni0
```

- Writing the host routing table and flannel.1 device MAC forwarding interface table (FDB forwarding)

Because all hosts run the flannel service, and flannel connects to the etcd storage center, each host knows its own subnet CIDR, its own flannel.1 device IP address and MAC address, as well as the subnet CIDRs and flannel.1 device IP addresses and MAC addresses of other hosts. With this information, the routing table and FDB can be populated when flannel starts. Taking host **192.168.205.4** as an example:
```bash
~# ip addr |grep 192.168.205.4
    inet 192.168.205.4/24 metric 100 brd 192.168.205.255 scope global dynamic enp0s1

# bridge fdb show dev flannel.1
62:c8:a9:ce:ca:4e dst 192.168.205.3 self permanent
ee:87:b2:4a:fd:62 dst 192.168.205.5 self permanent

# etcdctl ....
```

**Flannel Overlay (VXLAN mode) Summary**

- Each host has a VXLAN network device named flannel.x that handles UDP encapsulation and decapsulation of VXLAN data. UDP data is processed on the host's port 8472 (port value is configurable).
- Data enters the host's network namespace from the pod's network namespace.
- According to the routing table in the host network namespace, the next-hop IP is the target VXLAN device's IP, and it is sent by the current host's flannel.x device.
- The MAC address of the next-hop IP is found in the ARP table of the host network namespace.
- The forwarding IP corresponding to the next-hop IP's MAC address is found in the FDB of the host network namespace.
- The current host's flannel.x device performs UDP encapsulation based on the forwarding IP corresponding to the next-hop IP's MAC address and the local routing table. At this point:
   - Outer UDP packet: source IP is the current host IP, destination IP is the IP matched in the MAC forwarding table, source MAC is the current host IP's MAC, destination MAC is the MAC of the IP matched in the FDB. Destination port is 8472 (configurable), VXLAN ID is 1 (configurable).
   - Inner Layer 2 Ethernet frame: source IP is the source pod IP, destination IP is the target pod IP, source MAC is the source pod MAC, destination MAC is the MAC of the next-hop IP in the host network namespace's routing table (typically the flannel.x device IP on the target pod's host).
- The packet is routed from the current host to the target node host.
- After the target node host receives the UDP packet on port 8472, it discovers a VXLAN ID in the packet. Then, according to the Linux VXLAN protocol, it finds the VXLAN device on the target host that corresponds to the VXLAN ID in the packet and hands the data to it for processing.
- After the VXLAN device receives the data, it decapsulates the VXLAN UDP packet, removes the UDP packet's IP, port, and MAC information to obtain the internal payload, and discovers it is a Layer 2 packet. It then continues to decapsulate this Layer 2 packet to obtain the source pod IP and destination pod IP.
- According to the routing table on the target node host, data is locally forwarded by the Linux bridge cni0.
- Data is forwarded from the Linux bridge cni0 to the target pod via a veth pair.
- When the flannel service starts on each host, it reads the VXLAN configuration information from etcd and writes the corresponding data into the host's routing table and MAC forwarding interface table (FDB).

### c) Flannel Underlay vs. Overlay Network Comparison

- Both require the host to have IP forwarding enabled (net.ipv4.ip_forward = 1).
- Flannel underlay network has no extra packet encapsulation or decapsulation, so it is more efficient.
- Flannel underlay network requires all worker nodes to be in the same Layer 2 network to complete next-hop routing to the target pod. That is, underlay network worker nodes cannot span subnets.
- Flannel VXLAN overlay network involves encapsulation and decapsulation, with all outer packets being UDP packets. Therefore, worker nodes only need Layer 3 routing reachability, supporting worker nodes across subnets.
- Flannel VXLAN overlay network inner packets are Layer 2 Ethernet packets, based on Linux VXLAN devices.
- In both flannel underlay and flannel VXLAN overlay networks, all packets are processed in the operating system's kernel space, with no user-space application involvement.



> Reference:
> 1. [K8s Cluster Networking](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=MzI0MDE3MjAzMg==&action=getalbum&album_id=2123526506718003213&scene=173&from_msgid=2648393229&from_itemidx=1&count=3&nolastread=1#wechat_redirect)
> 2. [iptables Guide](https://lixiangyun.gitbook.io/iptables_doc_zh_cn/)
> 3. [Docker Network Types](https://developer.aliyun.com/article/974008#slide-4)
> 4. [ipvs Working Mode Principles](https://icloudnative.io/posts/ipvs-how-kubernetes-services-direct-traffic-to-pods/)