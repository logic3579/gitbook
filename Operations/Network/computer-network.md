---
description: Computer Network
---

# Computer Network

## 一、计算机网络概述
### 分类

- 按交换技术：电路交换、报文交换、分组交换
- 按使用者：共用网、专用网
- 按传输介质：有线网路、无线网络
- 按覆盖范围：广域网WAN、城域网MAN、局域网LAN、个域网PAN
- 按拓扑结构：总线型、星型、环型、网状型

### 性能指标

- 速率：数据量单位（bit）

比特单位计算：8bit=1B KB=210B MB=210x210B ...<br />
速率计算：b/s=bps/s Kbps=103bps/s Mbps=103x103bps/s ...

- 带宽：通信线路传输数据能力，单位时间内从某一点到另一点能通过"最高速率"

单位和计算方式 与速率相同

- 吞吐量：单位时间内通过某个网络（信道、接口）的数据量，实际通过网络的数据量，受网络带宽和额定速率影响（小于等于速率）
- 时延：发送时延、传播时延、处理时延 （地理位置相同时，数据较大时发送时延占主导）

发送时延计算：分组长度（b）/ 发送速率（b/s） 发送速率取网卡、信道带宽、接口速率中最小值<br />
传播时延计算：信道长度（m）/ 电磁传播速率（m/s） 自由空间：3x108m/s 铜线：2.3x108  光纤：2x108<br />
处理时延：包含排队时延（路由器存储转发，计算复杂）

- 时延带宽积：传播时延 x 带宽<br />
![image](https://github.com/yakir3/gitbook/assets/30774576/8a41a05d-3122-4a4f-9b0a-df8b28e7bd84)- 往返时间：单次双向信息交互的时间（RTT）
- 利用率（主干网ISP一般控制信道利用率不超过50%，超过网络时延迅速增大）

信道利用率：表示某信道有百分之机的时间是被利用的（有数据通过）<br />网络利用率：全网络的信道利用率的加权平均

- 丢包率：分组丢失率，指一定时间范围内，丢失的分组数量与总分组数量的比率

丢包原因：传输过程出现误码或分组到达队列已满的交换机、路由器时被丢弃（通信量较大容易造成网络拥塞）

### 计算机网络体系结构
#### 常见的计算机网路体系结构

1. OSI 7层模型（原始学术结构）
> 应用层
> 表示层
> 会话层
> 运输层
> 网络层
> 数据链路层
> 物理层


2. TCP/IP体系结构（商业驱动）
> 应用层（HTTP、SMTP、DNS、RTP）
> 运输层（TCP、UDP）
> 网际层（IP）
> 网络接口层


3. 原理体系结构（教学结构）
> 应用层
> 运输层
> 网络层
> 数据链路层
> 物理层


#### 计算机网络体系结构分层的必要性

- 物理层（使用何种信号来传输比特）
   - 传输介质
   - 物理接口
   - 使用信号表示比特0/1
- 数据链路层（一个网络或一段链路上传输）
   - 如何标识网络中各主机（主机编码问题，如MAC 地址）
   - 如何从信号所表示的一连串比特流区分出地址和数据
   - 如何协调各主机争抢总线
- 网络层（解决分组在多个网路传输路由的问题）
   - 如何标识各网络以及网络中各主机（网络和主机共同编址问题，如IP 地址）
   - 路由器如何转发分组，如何进行路由选择
- 传输层（解决网络之间基于网络通信问题）
   - 如何解决进程之间基于网络的通信问题
   - 出现传输错误如何解决
- 应用层（解决通过应用进程的交互来实现特定网络应用问题）
   - 通过应用进程间交互来完成特定的网络应用

![image](https://github.com/yakir3/gitbook/assets/30774576/5e7b3b9d-962a-4d46-a400-54c6f09dabbf)

#### 专用术语

- 实体：任何可发送或接收信息的硬件或软件进程。对等实体（收发双方想同层次中的实体，如网卡）
- 协议：控制两个对等实体进行逻辑通信的规则集合（HTTP协议、TCP协议、IP协议等）
   - 语法：定义交换信息的格式（如IP 报文头+数据格式）
   - 语义：定义通信双方所要完成的操作（如HTTP GET 请求与HTTP 响应报文）
   - 同步：定义通信双方的时序关系（TCP 三次连接）
- 服务
   - 协议控制下，两个对等实体间的逻辑通信使得本层能够向上一层提供服务
   - 要实现本层协议，还需要使用下一层所提供的服务
   - 协议是"水平的"，服务是"垂直的"
   - 服务访问点：帧、协议字段（IP）、端口号
   - 服务原语：上层使用下层所提供的的服务必须通过与下层交换一些命令
- 协议数据单元PDU（Protocol Data Unit）：对等层次之间传送的数据包
   - 比特流 bit
   - 帧 frame
   - 数据包 packet
   - 数据包 segment（TCP）/datagram（UDP）
   - 数据包：message
- 服务数据单元SDU：同一系统内，层与层之间交换的数据包
- 多个SDU可以合成一个PDU；一个SDU也可划分为几个PDU

时延与传播时长习题计算：<br />
![image](https://github.com/yakir3/gitbook/assets/30774576/e62e4510-0689-4b1c-b86b-6873b0cf5f2a)<br />
![image](https://github.com/yakir3/gitbook/assets/30774576/3f1798fd-d4ea-4cc5-b460-516bf69c79a8)


## 二、TCP/IP 体系
### 物理层
#### 传输媒体

- 导引型
   - 双绞线
   - 同轴电缆
   - 光纤
- 非导引型
   - 无线电波
   - 红外线
   - 微波通信（2~40 GHz）
   - 可见光
#### 物理层协议主要任务

- 机械特性
- 电器特性
- 功能特性
- 过程特性
> 物理层考虑的是怎样才能在各种计算机的传输媒体上传输数据比特流
> 为数据链路层屏蔽各种传输媒体的差异，是数据链路层只需考虑如何完成本层的协议和服务，而不必考虑网络具体传输是什么

#### 传输方式

- 串行传输：计算机网络
- 并行传输：CPU --> 内存 总线并行传输
- 同步传输：收发时钟同步
   - 外同步：收发双方之间添加一条单独的时钟信号线
   - 内同步：发送端将时钟同步信号编码到发送数据中一起传输（如曼彻斯特编码）
- 异步传输
   - 字节之间同步（起始位 结束位）
   - 字节中每个比特仍然同步
- 单工：收音机
- 半双工：对讲机
- 全双工：电话
#### 编码与调制
![image](https://github.com/yakir3/gitbook/assets/30774576/546a4b1e-84e8-4b8c-90b0-ac39c82e0de2)

### 数据链路层
![image](https://github.com/yakir3/gitbook/assets/30774576/10477e15-8292-45ca-ab4f-46ae9b4d284f)

#### 封装成帧
添加帧头与帧尾：MAC帧<br />
![image](https://github.com/yakir3/gitbook/assets/30774576/ba44a080-de9f-4e5c-a2b5-26dbcd6849ce)

#### 差错检测

- 帧尾检错码
- 奇偶校验
- 循环冗余校验CRC
![image](https://github.com/yakir3/gitbook/assets/30774576/89beee93-70b6-4b34-8901-b8c65ff978ed)

#### 可靠传输
![image](https://github.com/yakir3/gitbook/assets/30774576/7ad647e7-061c-4cce-b461-d6ec15b6142e)

- 停止等待协议SW
- 回退N帧协议GBN
- 选择重传协议SR

#### 点对点协议PPP
![image](https://github.com/yakir3/gitbook/assets/30774576/36d62332-24d2-4d71-b742-539fb2c31b37)

#### 媒体接入控制
![image](https://github.com/yakir3/gitbook/assets/30774576/a291367b-8d85-4677-8671-df63444b28b1)<br />
![image](https://github.com/yakir3/gitbook/assets/30774576/e7e867c6-81b6-4f83-ad54-9b3b08efb713)


#### 随机接入

- CSMA/CD协议
- CSMA/CA协议

#### MAC地址、IP地址以及ARP协议
![image](https://github.com/yakir3/gitbook/assets/30774576/61f6a15f-d422-4834-8eff-9a75a6952ebc)

#### 集线器与交换机
![image](https://github.com/yakir3/gitbook/assets/30774576/f68a7c75-b4a6-4bf1-aa85-5896b0c4827f)<br />
![image](https://github.com/yakir3/gitbook/assets/30774576/9261b6c1-48cc-4eb1-9e09-9f4f71e7ce35)<br />
![image](https://github.com/yakir3/gitbook/assets/30774576/adc06b14-704d-4aa9-83b1-289231b1cba1)

#### VLAN技术 
![image](https://github.com/yakir3/gitbook/assets/30774576/edfb6a2f-3d77-437a-a9c9-6210a9ab0990)


### 网络层
#### 概述
![image](https://github.com/yakir3/gitbook/assets/30774576/7f893777-ebf0-4f93-927b-314517bb72c5)

#### IPV4地址

- 分类

![image](https://github.com/yakir3/gitbook/assets/30774576/79eef85b-b285-4f27-be93-8e46a9b2ec06)

- 子网划分（[子网掩码](https://www.bejson.com/convert/subnetmask/)）
- 无分类编址的IPV4地址：CIDR。 如：192.168.10.1/20 的CIDR块为  -->  192.168.0~192.168.15

![image](https://github.com/yakir3/gitbook/assets/30774576/51b62709-cdf2-44fa-b520-6eb48aaa1a2e)

- 定长子网掩码FLSM和变长的子网掩码VLSM
- IP数据报的发送和转发过程
- 路由协议概述
   - 静态路由：人工配置网络路由、默认路由、特定主机路由、黑洞路由
   - 动态路由：通过路由协议自动获取路由信息

<br />

![image](https://github.com/yakir3/gitbook/assets/30774576/921977c6-3b1a-474f-b774-f82ccdcc7dba)<br />
![image](https://github.com/yakir3/gitbook/assets/30774576/c79a1e2a-27a7-4f5f-a318-22c768d567c6)

- 路由信息协议：RIP协议（基于距离向量）

![image](https://github.com/yakir3/gitbook/assets/30774576/4b1f9208-50a1-48e0-b263-26a0f2c21861)<br />
![image](https://github.com/yakir3/gitbook/assets/30774576/04c9f6bb-9f1e-4713-a3e5-ba139325302c)

- 路由信息协议：开放最短路径优先OSPF 基本工作原理（基于链路状态）

![image](https://github.com/yakir3/gitbook/assets/30774576/71ebe717-658c-4435-ba8a-5e068db53c2a)<br />
![image](https://github.com/yakir3/gitbook/assets/30774576/73121ecf-cf0c-43af-8bfa-0f14cc7ff7fb)<br />
![image](https://github.com/yakir3/gitbook/assets/30774576/568987a0-a9b6-47e5-bacd-6b591eeaa1d5)<br />
![image](https://github.com/yakir3/gitbook/assets/30774576/290e7b52-8b55-4f03-a51f-49fa66e576d1)

- 路由信息协议：边界网关协议BGP

![image](https://github.com/yakir3/gitbook/assets/30774576/66e3b7dd-70ba-4019-8e0c-46913df74743)<br />
![image](https://github.com/yakir3/gitbook/assets/30774576/670490a6-be77-4710-a691-bf19a26c4627)


- IPV4数据报首部格式

![image](https://github.com/yakir3/gitbook/assets/30774576/629de9ee-5714-40ed-9e25-1bb0843f00bd)

- 网际控制报文协议ICMP
   - 终点不可达、源点抑制、时间超过、参数问题、改变路由（重定向）

![image](https://github.com/yakir3/gitbook/assets/30774576/eba9619d-49b2-4b42-b4bb-0be497e01967)

   - ping、traceroute

![image](https://github.com/yakir3/gitbook/assets/30774576/0acd3c11-9212-4269-8853-122f395d6bb4)<br />
![image](https://github.com/yakir3/gitbook/assets/30774576/d50cdc96-a462-4180-ba56-b4ed610b5db9)


- 虚拟专用网VPN与网络地址转换NAT

![image](https://github.com/yakir3/gitbook/assets/30774576/f306247d-08c1-4098-8d9e-5fc5695d7e8a)

### 传输层
#### TCP 与UDP 对比
![image](https://github.com/yakir3/gitbook/assets/30774576/3239b70d-f99d-4ad7-821c-cf518fb25350)

#### TCP原理

- 流量控制（滑动窗口）

![image](https://github.com/yakir3/gitbook/assets/30774576/6c6c9224-8d8b-450b-ba41-f26f6f9f878d)

- 拥塞控制
   - Tahoe 版本
      - 慢开始
      - 拥塞避免
   - Reno 版本
      - 快重传（发送方尽快重传，非等待超时计时器）
      - 快恢复

![image](https://github.com/yakir3/gitbook/assets/30774576/74d00c42-8cfc-4a9d-8fc7-fc45f74174ec)<br />
![image](https://github.com/yakir3/gitbook/assets/30774576/639cc3af-c445-410d-a1b6-28540a38e57f)


- 超时重传选择（RTO 重传超时时间取值）
- 可靠传输实现
- 三次握手与四次断开

![image](https://github.com/yakir3/gitbook/assets/30774576/34a6973c-a399-45c8-982f-5d299373cd39)

- 首部格式

![image](https://github.com/yakir3/gitbook/assets/30774576/9661366f-fdee-47c2-aba5-166989aa88e1)

### 应用层
#### C/S方式与P2P方式
![image](https://github.com/yakir3/gitbook/assets/30774576/ee7014ce-d516-4330-9521-509d870615d4)

#### DHCP、DNS、FTP、SMTP、HTTP 等协议

