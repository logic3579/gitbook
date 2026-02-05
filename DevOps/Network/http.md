---
description: HTTP protocol
---

# HTTP

## HTTP Request Process
Each HTTP request goes through these stages: Client initiates request --> DNS resolution --> TCP connection --> SSL/TLS handshake --> Server processing --> Content transfer --> Complete


## curl Command Manual
Refer to the curl command manual. The curl command supports timing statistics for the following stages:
- time_namelookup: Time from request start to DNS resolution completion
- time_connect: Time from request start to TCP three-way handshake completion
- time_appconnect: Time from request start to TLS handshake completion
- time_pretransfer: Time from request start to just before sending the first GET request to the server
- time_redirect: Redirect time, including DNS resolution, TCP connection, and content transfer time before the final content transfer
- time_starttransfer: Time from request start to content transfer completion
- time_total: Total time from request start to completion


## Key HTTP Performance Metrics
- DNS request time: DNS resolution speed of the domain's NS and local DNS
- TCP establishment time: Speed at the server's network layer
- SSL handshake time: Speed of the server handling HTTPS and similar protocols
- Server request processing time: Speed of the server processing the HTTP request
- TTFB: Time from when the client sends the first byte to receiving the response (Time To First Byte)
- Server response time: Time from receiving the first byte of the response to completion of full transfer (content transfer time)
- Total request completion time

> Note: If you want to analyze HTTP performance bottlenecks, it is not recommended to use requests with redirects for analysis. Redirects result in multiple TCP connections or multiple HTTP requests, and the data from multiple requests gets mixed together, making the data less intuitive. Therefore, time_redirect has limited practical significance for actual analysis.<br />The arithmetic relationships are:

- DNS request time = time_namelookup
- TCP three-way handshake time = time_connect - time_namelookup
- SSL handshake time = time_appconnect - time_connect
- TTFB time = time_starttransfer - time_appconnect
- Server request processing time = time_starttransfer - time_pretransfer
- Server transfer time = time_total - time_starttransfer
- Total time = time_total
