---
description: HTTP protocol
---

# HTTP

## HTTP 请求过程
每次http请求经过这些过程： 客户端发起请求-->DNS解析-->TCP连接-->SSL等协议握手-->服务器处理-->内容传输-->完成


## curl 命令手册
查看curl 命令的手册，curl命令支持以下阶段的时间统计：
- time_namelookup : 从请求开始到DNS解析完成的耗时
- time_connect : 从请求开始到TCP三次握手完成耗时
- time_appconnect : 从请求开始到TLS握手完成的耗时
- time_pretransfer : 从请求开始到向服务器发送第一个GET请求开始之前的耗时
- time_redirect : 重定向时间，包括到内容传输前的重定向的DNS解析、TCP连接、内容传输等时间
- time_starttransfer : 从请求开始到内容传输完成的时间
- time_total : 从请求开始到完成的总耗时


## 主要的 HTTP 性能指标
- DNS请求耗时 ： 域名的NS及本地使用DNS的解析速度
- TCP建立耗时 ： 服务器网络层面的速度
- SSL握手耗时 ： 服务器处理HTTPS等协议的速度
- 服务器处理请求时间 ： 服务器处理HTTP请求的速度
- TTFB ： 客户端发出第一个字节到收到请求的时间（Time to first bytes）
- 服务器响应耗时 ：服务器响应第一个字节到全部传输完成耗时（内容传输时间）
- 请求完成总耗时

> 注意： 如果想分析HTTP性能的瓶颈，不建议使用带有重定向的请求进行分析，重定向会导致建立多次TCP连接或多次HTTP请求，多次请求的数据混在一起，数据不够直观，因此 time_redirect 对实际分析意义不大。<br />其中的运算关系：

- DNS请求耗时 = time_namelookup
- TCP三次握手耗时 = time_connect - time_namelookup
- SSL握手耗时 = time_appconnect - time_connect
- TTFB耗时 = time_starttransfer - time_appconnect
- 服务器处理请求耗时 = time_starttransfer - time_pretransfer
- 服务器传输耗时 = time_total - time_starttransfer
- 总耗时 = time_total
