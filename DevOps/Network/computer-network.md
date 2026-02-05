---
description: Computer Network
---

# Computer Network

## 1. Overview of Computer Networks
### Classification

- By switching technology: circuit switching, message switching, packet switching
- By user type: public network, private network
- By transmission medium: wired network, wireless network
- By coverage area: WAN (Wide Area Network), MAN (Metropolitan Area Network), LAN (Local Area Network), PAN (Personal Area Network)
- By topology: bus, star, ring, mesh

### Performance Metrics

- Speed: data unit (bit)

Bit unit calculation: 8bit=1B KB=210B MB=210x210B ...<br />
Speed calculation: b/s=bps/s Kbps=103bps/s Mbps=103x103bps/s ...

- Bandwidth: the data transmission capacity of a communication link, the "maximum rate" that can pass from one point to another per unit of time

Units and calculation methods are the same as speed

- Throughput: the amount of data passing through a network (channel, interface) per unit of time; the actual data volume passing through the network, affected by network bandwidth and rated speed (less than or equal to speed)
- Delay: transmission delay, propagation delay, processing delay (when geographically co-located, transmission delay dominates for large data)

Transmission delay calculation: packet length (b) / transmission rate (b/s); transmission rate takes the minimum of NIC speed, channel bandwidth, and interface rate<br />
Propagation delay calculation: channel length (m) / electromagnetic propagation speed (m/s); free space: 3x108 m/s, copper wire: 2.3x108, optical fiber: 2x108<br />
Processing delay: includes queuing delay (router store-and-forward, computationally complex)

- Delay-bandwidth product: propagation delay x bandwidth<br />
![image](https://github.com/logic3579/gitbook/assets/30774576/8a41a05d-3122-4a4f-9b0a-df8b28e7bd84)- Round-trip time: the time for a single bidirectional information exchange (RTT)
- Utilization (backbone ISPs generally keep channel utilization below 50%; exceeding this causes network delay to increase rapidly)

Channel utilization: indicates what percentage of time a channel is being utilized (data passing through)<br />Network utilization: the weighted average of all channel utilizations across the network

- Packet loss rate: the ratio of lost packets to total packets within a given time period

Causes of packet loss: bit errors during transmission, or packets being dropped when arriving at switches or routers with full queues (high traffic volume easily causes network congestion)

### Computer Network Architecture
#### Common Computer Network Architectures

1. OSI 7-Layer Model (original academic architecture)
> Application Layer
> Presentation Layer
> Session Layer
> Transport Layer
> Network Layer
> Data Link Layer
> Physical Layer


2. TCP/IP Architecture (commercially driven)
> Application Layer (HTTP, SMTP, DNS, RTP)
> Transport Layer (TCP, UDP)
> Internet Layer (IP)
> Network Interface Layer


3. Theoretical Architecture (pedagogical model)
> Application Layer
> Transport Layer
> Network Layer
> Data Link Layer
> Physical Layer


#### The Necessity of Layered Computer Network Architecture

- Physical Layer (what signals are used to transmit bits)
   - Transmission media
   - Physical interfaces
   - Using signals to represent bits 0/1
- Data Link Layer (transmission over a single network or link segment)
   - How to identify hosts in the network (host addressing, e.g., MAC address)
   - How to distinguish addresses and data from a continuous bit stream represented by signals
   - How to coordinate hosts competing for the bus
- Network Layer (solving the problem of packet routing across multiple networks)
   - How to identify each network and hosts within networks (combined network and host addressing, e.g., IP address)
   - How routers forward packets and perform route selection
- Transport Layer (solving network-based communication between processes)
   - How to solve process-to-process communication over the network
   - How to handle transmission errors
- Application Layer (solving specific network application needs through application process interaction)
   - Completing specific network applications through interaction between application processes

![image](https://github.com/logic3579/gitbook/assets/30774576/5e7b3b9d-962a-4d46-a400-54c6f09dabbf)

#### Terminology

- Entity: any hardware or software process capable of sending or receiving information. Peer entities (entities at the same layer on both sending and receiving sides, e.g., network interface cards)
- Protocol: a set of rules controlling logical communication between two peer entities (HTTP protocol, TCP protocol, IP protocol, etc.)
   - Syntax: defines the format of exchanged information (e.g., IP header + data format)
   - Semantics: defines the operations to be performed by both communicating parties (e.g., HTTP GET request and HTTP response message)
   - Synchronization: defines the timing relationship between communicating parties (TCP three-way handshake)
- Service
   - Under protocol control, logical communication between two peer entities enables the current layer to provide services to the layer above
   - To implement the current layer's protocol, services provided by the layer below are also needed
   - Protocols are "horizontal"; services are "vertical"
   - Service access points: frames, protocol fields (IP), port numbers
   - Service primitives: the upper layer must exchange certain commands with the lower layer to use its services
- Protocol Data Unit (PDU): data packets transmitted between peer layers
   - Bit stream (bit)
   - Frame
   - Packet
   - Segment (TCP) / Datagram (UDP)
   - Message
- Service Data Unit (SDU): data packets exchanged between layers within the same system
- Multiple SDUs can be combined into one PDU; one SDU can also be divided into several PDUs

Delay and propagation time exercise calculations:<br />
![image](https://github.com/logic3579/gitbook/assets/30774576/e62e4510-0689-4b1c-b86b-6873b0cf5f2a)<br />
![image](https://github.com/logic3579/gitbook/assets/30774576/3f1798fd-d4ea-4cc5-b460-516bf69c79a8)


## 2. TCP/IP Architecture
### Physical Layer
#### Transmission Media

- Guided media
   - Twisted pair
   - Coaxial cable
   - Optical fiber
- Unguided media
   - Radio waves
   - Infrared
   - Microwave communication (2~40 GHz)
   - Visible light
#### Main Tasks of Physical Layer Protocols

- Mechanical characteristics
- Electrical characteristics
- Functional characteristics
- Procedural characteristics
> The Physical Layer is concerned with how to transmit data bit streams over various computer transmission media
> It shields the Data Link Layer from the differences between various transmission media, so the Data Link Layer only needs to consider how to implement its own protocols and services without worrying about the specific underlying transmission

#### Transmission Modes

- Serial transmission: computer networks
- Parallel transmission: CPU --> memory bus parallel transmission
- Synchronous transmission: sender and receiver clocks synchronized
   - External synchronization: a separate clock signal line added between sender and receiver
   - Internal synchronization: the sender encodes the clock synchronization signal into the transmitted data (e.g., Manchester encoding)
- Asynchronous transmission
   - Synchronization between bytes (start bit, stop bit)
   - Each bit within a byte is still synchronized
- Simplex: radio
- Half-duplex: walkie-talkie
- Full-duplex: telephone
#### Encoding and Modulation
![image](https://github.com/logic3579/gitbook/assets/30774576/546a4b1e-84e8-4b8c-90b0-ac39c82e0de2)

### Data Link Layer
![image](https://github.com/logic3579/gitbook/assets/30774576/10477e15-8292-45ca-ab4f-46ae9b4d284f)

#### Framing
Adding frame header and trailer: MAC frame<br />
![image](https://github.com/logic3579/gitbook/assets/30774576/ba44a080-de9f-4e5c-a2b5-26dbcd6849ce)

#### Error Detection

- Frame trailer error detection code
- Parity check
- Cyclic Redundancy Check (CRC)
![image](https://github.com/logic3579/gitbook/assets/30774576/89beee93-70b6-4b34-8901-b8c65ff978ed)

#### Reliable Transmission
![image](https://github.com/logic3579/gitbook/assets/30774576/7ad647e7-061c-4cce-b461-d6ec15b6142e)

- Stop-and-Wait protocol (SW)
- Go-Back-N protocol (GBN)
- Selective Repeat protocol (SR)

#### Point-to-Point Protocol (PPP)
![image](https://github.com/logic3579/gitbook/assets/30774576/36d62332-24d2-4d71-b742-539fb2c31b37)

#### Media Access Control
![image](https://github.com/logic3579/gitbook/assets/30774576/a291367b-8d85-4677-8671-df63444b28b1)<br />
![image](https://github.com/logic3579/gitbook/assets/30774576/e7e867c6-81b6-4f83-ad54-9b3b08efb713)


#### Random Access

- CSMA/CD protocol
- CSMA/CA protocol

#### MAC Address, IP Address, and ARP Protocol
![image](https://github.com/logic3579/gitbook/assets/30774576/61f6a15f-d422-4834-8eff-9a75a6952ebc)

#### Hubs and Switches
![image](https://github.com/logic3579/gitbook/assets/30774576/f68a7c75-b4a6-4bf1-aa85-5896b0c4827f)<br />
![image](https://github.com/logic3579/gitbook/assets/30774576/9261b6c1-48cc-4eb1-9e09-9f4f71e7ce35)<br />
![image](https://github.com/logic3579/gitbook/assets/30774576/adc06b14-704d-4aa9-83b1-289231b1cba1)

#### VLAN Technology
![image](https://github.com/logic3579/gitbook/assets/30774576/edfb6a2f-3d77-437a-a9c9-6210a9ab0990)


### Network Layer
#### Overview
![image](https://github.com/logic3579/gitbook/assets/30774576/7f893777-ebf0-4f93-927b-314517bb72c5)

#### IPv4 Addresses

- Classification

![image](https://github.com/logic3579/gitbook/assets/30774576/79eef85b-b285-4f27-be93-8e46a9b2ec06)

- Subnetting ([subnet mask](https://www.bejson.com/convert/subnetmask/))
- Classless IPv4 addressing: CIDR. For example: the CIDR block for 192.168.10.1/20 is --> 192.168.0~192.168.15

![image](https://github.com/logic3579/gitbook/assets/30774576/51b62709-cdf2-44fa-b520-6eb48aaa1a2e)

- Fixed-Length Subnet Mask (FLSM) and Variable-Length Subnet Mask (VLSM)
- IP datagram sending and forwarding process
- Routing protocol overview
   - Static routing: manually configured network routes, default routes, host-specific routes, black hole routes
   - Dynamic routing: automatically obtaining routing information through routing protocols

<br />

![image](https://github.com/logic3579/gitbook/assets/30774576/921977c6-3b1a-474f-b774-f82ccdcc7dba)<br />
![image](https://github.com/logic3579/gitbook/assets/30774576/c79a1e2a-27a7-4f5f-a318-22c768d567c6)

- Routing Information Protocol: RIP (distance-vector based)

![image](https://github.com/logic3579/gitbook/assets/30774576/4b1f9208-50a1-48e0-b263-26a0f2c21861)<br />
![image](https://github.com/logic3579/gitbook/assets/30774576/04c9f6bb-9f1e-4713-a3e5-ba139325302c)

- Routing protocol: Open Shortest Path First (OSPF) basic working principle (link-state based)

![image](https://github.com/logic3579/gitbook/assets/30774576/71ebe717-658c-4435-ba8a-5e068db53c2a)<br />
![image](https://github.com/logic3579/gitbook/assets/30774576/73121ecf-cf0c-43af-8bfa-0f14cc7ff7fb)<br />
![image](https://github.com/logic3579/gitbook/assets/30774576/568987a0-a9b6-47e5-bacd-6b591eeaa1d5)<br />
![image](https://github.com/logic3579/gitbook/assets/30774576/290e7b52-8b55-4f03-a51f-49fa66e576d1)

- Routing protocol: Border Gateway Protocol (BGP)

![image](https://github.com/logic3579/gitbook/assets/30774576/66e3b7dd-70ba-4019-8e0c-46913df74743)<br />
![image](https://github.com/logic3579/gitbook/assets/30774576/670490a6-be77-4710-a691-bf19a26c4627)


- IPv4 datagram header format

![image](https://github.com/logic3579/gitbook/assets/30774576/629de9ee-5714-40ed-9e25-1bb0843f00bd)

- Internet Control Message Protocol (ICMP)
   - Destination unreachable, source quench, time exceeded, parameter problem, redirect

![image](https://github.com/logic3579/gitbook/assets/30774576/eba9619d-49b2-4b42-b4bb-0be497e01967)

   - ping、traceroute

![image](https://github.com/logic3579/gitbook/assets/30774576/0acd3c11-9212-4269-8853-122f395d6bb4)<br />
![image](https://github.com/logic3579/gitbook/assets/30774576/d50cdc96-a462-4180-ba56-b4ed610b5db9)


- Virtual Private Network (VPN) and Network Address Translation (NAT)

![image](https://github.com/logic3579/gitbook/assets/30774576/f306247d-08c1-4098-8d9e-5fc5695d7e8a)

### Transport Layer
#### TCP vs. UDP Comparison
![image](https://github.com/logic3579/gitbook/assets/30774576/3239b70d-f99d-4ad7-821c-cf518fb25350)

#### TCP Principles

- Flow control (sliding window)

![image](https://github.com/logic3579/gitbook/assets/30774576/6c6c9224-8d8b-450b-ba41-f26f6f9f878d)

- Congestion control
   - Tahoe version
      - Slow start
      - Congestion avoidance
   - Reno version
      - Fast retransmit (sender retransmits as soon as possible, without waiting for timeout timer)
      - Fast recovery

![image](https://github.com/logic3579/gitbook/assets/30774576/74d00c42-8cfc-4a9d-8fc7-fc45f74174ec)<br />
![image](https://github.com/logic3579/gitbook/assets/30774576/639cc3af-c445-410d-a1b6-28540a38e57f)


- Retransmission timeout selection (RTO retransmission timeout value)
- Reliable transmission implementation
- Three-way handshake and four-way teardown

![image](https://github.com/logic3579/gitbook/assets/30774576/34a6973c-a399-45c8-982f-5d299373cd39)

- Header format

![image](https://github.com/logic3579/gitbook/assets/30774576/9661366f-fdee-47c2-aba5-166989aa88e1)

### Application Layer
#### Client/Server Model and P2P Model
![image](https://github.com/logic3579/gitbook/assets/30774576/ee7014ce-d516-4330-9521-509d870615d4)

#### DHCP, DNS, FTP, SMTP, HTTP and Other Protocols

