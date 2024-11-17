---
description: CDN
---

# CDN

## nginx

1. chrome's Disable cache: local disk, local memory cache
2. HTTP no-cache header
3. CDN Response header


Resquest Header
-H 'Accept-Encoding: br, gzip, deflate'
curl https://xxx.com --resolve xxx.com.com:443:1.1.1.1

Response Header
content-encoding: br
content-type: text/css


> Reference:
> 1. [Official Website]()
> 2. [Repository]()