---
description: Nginx
tags:
  - cncf/orchestration
  - service-proxy
---

# Nginx

## Introduction
...

## Deploy By Binary
### Quick Start
```bash
# Ubuntu Package install
https://nginx.org/en/linux_packages.html#Ubuntu

# download and decompress
wget http://nginx.org/download/nginx-1.24.0.tar.gz
tar xf nginx-1.24.0.tar.gz && rm -f nginx-1.24.0.tar.gz
cd nginx-1.24.0 

# get third-party module
https://github.com/happyfish100/fastdfs-nginx-module.git
git clone https://github.com/ip2location/ip2location-nginx.git
git clone https://github.com/leev/ngx_http_geoip2_module
git clone https://github.com/openresty/echo-nginx-module.git
git clone https://github.com/openresty/lua-nginx-module.git
git clone https://github.com/vision5/ngx_devel_kit.git

# compile 
./configure --prefix=/opt/nginx --with-threads --with-file-aio --with-stream --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_addition_module --with-http_geoip_module --with-http_sub_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module --with-compat --with-cc-opt=-O2
# options args
--with-ld-opt=-Wl,-rpath,/usr/local/src/luajit/ 
--with-pcre=/usr/local/src/pcrexx 
--with-zlib=/usr/local/src/zlibxx 
--with-openssl=/usr/local/src/opensslxx
# compile third-party module arg
# upstream check
--add-dynamic-module=/usr/local/src/nginx_upstream_check_module-master
# fastdfs
--add-module=/usr/local/src/fastdfs-nginx-module/src
# rtmp
--add-module=/usr/local/src/nginx-rtmp-module
# iplocation
--add-dynamic-module=/usr/local/src/ip2location-nginx
--add-dynamic-module=/usr/local/src/ngx_http_geoip2_module
# echo for debug
--add-dynamic-module=/usr/local/src/echo-nginx-module
# more headers
--add-dynamic-module=/usr/local/src/headers-more-nginx-module/
# array var
--add-dynamic-module=/usr/local/src/array-var-nginx-module
# set var
--add-dynamic-module=/usr/local/src/set-misc-nginx-module
# devel kit and lua module
--add-dynamic-module=/usr/local/src/ngx_devel_kit
--add-dynamic-module=/usr/local/src/lua-nginx-module


# install
make -j4 && make install
mkdir -p /opt/nginx/conf/keys/
mkdir -p /opt/nginx/conf/vhosts/
cd /opt/nginx
```

### Config and Boot
#### Config

**Main Config** — `/opt/nginx/conf/nginx.conf`

```bash
user  nobody nobody;
worker_processes  auto;
worker_cpu_affinity auto;
pid        logs/nginx.pid;
error_log  logs/error.log;
include /opt/nginx/modules-enabled/*.conf;
worker_rlimit_nofile 655350;

events {
    worker_connections  102400;
	# multi_accept on;
}

##
# TCP Stream Settings
##
stream{
    log_format tcp_log '$remote_addr [$time_local]'
         '$protocol $status $bytes_sent $bytes_received $session_time'
         '"$upstream_addr" "$upstream_bytes_sent" "$upstream_bytes_received" "$upstream_connect_time"';
    access_log /opt/nginx/logs/tcp-access.log tcp_log;

    upstream tcp_backend_server {
        hash $remote_addr consistent; #IP hash
        server 1.1.1.1:9999;
        server 2.2.2.2:9999;
        server 3.3.3.3:9999;
    }
    server {
      listen 9999;
      proxy_pass tcp_backend_server;
    }
}

http {
    ###
    # Basic Settings
    ##

    sendfile on;
	tcp_nopush on;
	types_hash_max_size 2048;
    server_tokens off;
    server_names_hash_max_size 3072;
    server_names_hash_bucket_size 1024;

    include       mime.types;
    default_type  application/octet-stream;

    ##
    # SSL Settings
    ##
    #ssl_protocols SSLv3 TLSv1.0 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    ##
    # Logging Settings
    ##
    log_format main '$remote_addr $remote_user $ip2location_country_long $ip2location_region $ip2location_city '
                    '[$time_local] Host:$host Request:$request Status:$status RequestLength:$request_length BodyBytesSent:$body_bytes_sent RequestTime:$request_time '
                    'UpstreamAddr:$upstream_addr UpstreamStatus:$upstream_status UpstreamConnTime:$upstream_connect_time UpstreamResTime:$upstream_response_time '
                    'Scheme:$scheme Referer:$http_referer Cookie:$http_cookie UA:$http_user_agent XFF:$http_x_forwarded_for'
    log_format main_json escape=json '{"time_local":"$time_local",'
'"server_addr":"$server_addr",'
'"country":"$ip2location_country_long",'
'"state":"$ip2location_region",'
'"city":"$ip2location_city",'
'"http_x_forward":"$http_x_forwarded_for",'
'"remote_addr":"$remote_addr",'
'"request_method":"$request_method",'
'"uri":"$uri",'
'"scheme":"$scheme",'
'"domain":"$server_name",'
'"referer":"$http_referer",'
'"server_name":"$host",'
'"request":"$request_uri",'
'"http_user_agent":"$http_user_agent",'
'"args":"$args",'
'"body":"$request_body",'
'"cookie":"$http_cookie",'
'"request_length":"$request_length",'
'"size":$body_bytes_sent,'
'"request_completion":"$request_completion",'
'"status": "$status",'
'"proxy_host":"$proxy_host",'
'"response_time":$request_time,'
'"upstream_time":"$upstream_response_time",'
'"upstream_status":"$upstream_status",'
'"upstream_addr":"$upstream_addr",'
'"upstream_cache_status":"$upstream_cache_status",'
'"upstream_connect_time":"$upstream_connect_time",'
'"upstream_response_length":"$upstream_response_length",'
'"https":"$https",'
'"request_id":"$hostname-$request_id"'
'}';
    access_log /opt/nginx/logs/access.log main;

    ##
    # Gzip Settings
    ##
    gzip  on;
    gzip_disable "msie6";
    gzip_proxied any;
    gzip_min_length 1k;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/javascript application/octet-stream;


    resolver 8.8.8.8 1.1.1.1 114.114.114.114 valid=5 ipv6=off;
    resolver_timeout 3s;

    keepalive_timeout 180;
    client_body_buffer_size 50m;
    client_body_timeout 300;
    client_max_body_size 50m;
    proxy_intercept_errors on;
    proxy_ignore_client_abort on;
    proxy_next_upstream error timeout http_502 http_503 http_504;
    proxy_next_upstream_timeout 20;
    proxy_connect_timeout 10;
    proxy_read_timeout 300;
    proxy_send_timeout 300;
    proxy_buffer_size 512k;
    proxy_buffers 4 512k;
    proxy_busy_buffers_size 512k;
    proxy_temp_file_write_size 512k;
    client_header_buffer_size 512k;
    large_client_header_buffers 4 512k;

    variables_hash_max_size 2048;
    variables_hash_bucket_size 2048;


    ##
    # Map Settings
    ##
    # ip2location = https://github.com/chrislim2888/IP2Location-C-Library
    ip2location_database /opt/nginx/conf/IPV6-COUNTRY-REGION-CITY.BIN;
    ip2location_proxy_recursive on;
    map $ip2location_country_short $blocked_country {
	    default no;
	    ~*(AU|IN|NG|US)$ yes;
    }
    ## geoip2 = https://github.com/leev/ngx_http_geoip2_module
    #geoip2 /opt/nginx/conf/GeoLite2-Country.mmdb {
    #   $geoip2_country_code country iso_code;
    #   $geoip2_country_name country names en;
    #}
    #geoip2 /opt/nginx/conf/GeoLite2-City.mmdb {
    #    $geoip2_city_name city names en;
    #    $geoip2_subdivisions_name subdivisions 0 names en;
    #    $geoip2_latitude location latitude;
    #    $geoip2_longitude location longitude;
    #}
    #map $geoip2_country_code $allowed_country {
    #    default no;
    #    ~*(AU|IN|NG|US)$ yes;
    #}

    # websocket connection keepalive
    map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
    }

    # domain ssl dir
    map $ssl_server_name $domainCert {
       default /opt/nginx/conf/keys/default.crt;
       ~*^(.+\.)*([^\.]+\.[^\.]+)$ /opt/nginx/conf/keys/$2.crt;
    }
    map $ssl_server_name $domainKey {
       default /opt/nginx/conf/keys/default.key;
       ~*^(.+\.)*([^\.]+\.[^\.]+)$ /opt/nginx/conf/keys/$2.key;
    }

    ##
    # Virtual Host Configs
    ##
    include vhosts/*.conf;
}


include modules.conf;

```

**Modules Config** — `/opt/nginx/conf/modules.conf`

```bash
load_module modules/ndk_http_module.so;
load_module modules/ngx_http_array_var_module.so;
load_module modules/ngx_http_echo_module.so;
load_module modules/ngx_http_geoip2_module.so;
load_module modules/ngx_http_headers_more_filter_module.so;
load_module modules/ngx_http_ip2location_module.so;
load_module modules/ngx_http_lua_module.so;
load_module modules/ngx_http_set_misc_module.so;
load_module modules/ngx_stream_geoip2_module.so;
```

**Virtual Host** — `/opt/nginx/conf/vhosts/default.conf`

```bash
server {
  listen 80 default;
  listen 443 ssl http2 default_server;
  server_name _;

  ssl_certificate     /opt/nginx/conf/keys/default.crt;
  ssl_certificate_key /opt/nginx/conf/keys/default.key;

  location / {
     return 403;
  }

  location /check_status.txt {
     return 200 '2f83232835a24a45ecbae42bbf44deb2';
     access_log  off;
    }
}

# global settings for lua
lua_load_resty_core off;
lua_shared_dict limit 50m;
init_by_lua_file "/opt/nginx/conf/waf/init.lua";
lua_socket_log_errors off;

# global settings for ssl
ssl_protocols               TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
ssl_ecdh_curve              X25519:P-256:P-384:P-224:P-521;
ssl_ciphers                 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-CHACHA20-POLY1305:ECDHE+AES128:RSA+AES128:ECDHE+AES256:RSA+AES256:ECDHE+3DES:RSA+3DES';
ssl_prefer_server_ciphers on;
ssl_session_timeout  4h;
ssl_session_cache shared:SSL:30m;
ssl_session_tickets off;
```

**Virtual Host Template** — `/opt/nginx/conf/vhosts/template.conf`

```bash
upstream backend_server {
    server 1.1.1.1:8080;
    server 2.2.2.2:8080;
    server 3.3.3.3:8080;
}

server {
    listen 80;
    listen 443 ssl http2;
    server_name
        example.com
        *.example.com
    ;
    ssl_certificate     $domainCert;
    ssl_certificate_key $domainKey;
    access_log logs/example_access.log main;

    # frontend project
    location / {
        root /app/frontend-project;
        try_files $uri $uri/ /index.html;

        # cache settings
        if ($request_filename ~ .*\.(htm|html)$) { add_header Cache-Control "max-age=60, s-maxage=120"; }
        if ($request_filename !~ .*\.(htm|html)$) { add_header Cache-Control "max-age=31536000, s-maxage=86400"; }

        # Cross-Origin Resource Sharing
        add_header Access-Control-Allow-Origin '*';
        add_header Access-Control-Allow-Methods 'GET, POST, OPTIONS';
        add_header Access-Control-Allow-Headers 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization';

        proxy_intercept_errors on;
        error_page 404 = /;
        error_page 401   /401;
        error_page 403   /403;
        error_page 500   /500;
        error_page 502   /502;
        error_page 503   /503;
    }

    # backend project
    location /api/ {
        proxy_pass http://backend_server;
    }

    # websocket request
    location /socket {
        proxy_pass http://backend_server;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
   }

    # geoip
    location /geoip2 {
        if ( $allowed_country = no ) {
            return 444;
        }
        return 200 '{
            "remote_addr": "$remote_addr",
            "x_forwarded_for": "$http_x_forwarded_for",
            "countryCode": "$geoip2_country_code",
            "countryName": "$geoip2_country_name",
            "cityName": "$geoip2_city_name",
            "citySubdivisions": "$geoip2_subdivisions_name",
            "latitude": "$geoip2_latitude",
            "longitude": "$geoip2_longitude",
            "allowed_country": "$allowed_country"
            }';
    }

    # ip2location
    location /ip2location {
        if ( $blocked_country = yes ) {
            return 444;
        }
        return 200 '{
            "remote_addr": "$remote_addr",
            "x_forwarded_for": "$http_x_forwarded_for",
            "countryCode": "$ip2location_country_short",
            "countryName": "$ip2location_country_long",
            "cityRegion": "$ip2location_region",
            "cityName": "$ip2location_city",
            "locationIsp": "$ip2location_isp",
            "latitude": "$ip2location_latitude",
            "longitude": "$ip2location_longitude",
            "blocked_country": "$blocked_country"
            }';
    }
}
```

**Real IP Config** — `/opt/nginx/conf/vhosts/real_ip.conf`

```bash
real_ip_header X-Forwarded-For;
real_ip_recursive on;
# proxy downstream real ip
set_real_ip_from 192.168.1.1/32;
set_real_ip_from 192.168.1.2/32;
```

#### Boot(systemd)
```bash
cat > /etc/systemd/system/nginx.service << EOF
[Unit]
Description=Nginx-1.x.x
Documentation=https://nginx.org
Wants=network-online.target
After=network-online.target

[Service]
#Type=simple
#ExecStartPre=/opt/nginx/sbin/nginx -q -g 'daemon on; master_process on;' -t
#ExecStart=/opt/nginx/sbin/nginx -g 'daemon on; master_process on;'
#ExecReload=/opt/nginx/sbin/nginx -g 'daemon on; master_process on;' -s reload
#ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile $PIDFile
Type=forking
PIDFile=/opt/nginx/logs/nginx.pid
ExecStartPre=/opt/nginx/sbin/nginx -t
ExecStart=/opt/nginx/sbin/nginx
ExecReload=/opt/nginx/sbin/nginx -s reload
ExecStop=/opt/nginx/sbin/nginx -s stop
PrivateTmp=true
KillSignal=SIGTERM
KillMode=mixed
SendSIGKILL=no
SuccessExitStatus=143
TimeoutStartSec=60
TimeoutStopSec=5
Restart=on-failure
RestartSec=10s
LimitNOFILE=655350
LimitNPROC=655350

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start nginx.service
systemctl enable nginx.service
```

### Verify
```bash
# syntax check
/opt/nginx/sbin/nginx -t                 
nginx: the configuration file /opt/nginx/conf/nginx.conf syntax is ok
nginx: configuration file /opt/nginx/conf/nginx.conf test is successful
```


### Troubleshooting
```bash
# pcre zlib openssl ...
apt install libpcre3-dev zlib1g zlib1g-dev openssl


# ./configure: error: the geoip2 module requires the maxminddb library.
apt install libmaxminddb-dev


# ./configure: error: unsupported LuaJIT version; ngx_http_lua_module requires LuaJIT 2.x.
# solution 1 by apt
apt install luajit libluajit-5.1-2 libluajit-5.1-dev
export LUAJIT_LIB=/usr/lib/x86_64-linux-gnu/
export LUAJIT_INC=/usr/include/luajit-2.1/
# solution 2 by compile luajit2 source
git clone https://github.com/openresty/luajit2.git
make PREFIX=/usr/local/luajit2
make install PREFIX=/usr/local/luajit2
export LUAJIT_LIB=/usr/local/luajit2/lib/
export LUAJIT_INC=/usr/local/luajit2/include/luajit-2.1/


# ./configure: error: the GeoIP module requires the GeoIP library. You can either do not enable the module or install the library.
apt install libgeoip-dev


# /usr/local/src/ip2location-nginx/ngx_http_ip2location_module.c:12:10: fatal error: IP2Location.h: No such file or directory
git clone https://github.com/chrislim2888/IP2Location-C-Library.git
autoreconf -i -v --force
./configure
make
make install
cd data
perl ip-country.pl
cp IPV6-COUNTRY.BIN /opt/nginx/conf/


# nginx: [emerg] dlopen() "/opt/nginx/modules/ngx_http_ip2location_module.so" failed (libIP2Location.so.3: cannot open shared object file: No such file or directory) in /opt/nginx/conf/modules.conf:5
ldconfig
ldconfig |grep IP
libIP2Location.so.3 (libc6,x86-64) => /usr/local/lib/libIP2Location.so.3
libIP2Location.so (libc6,x86-64) => /usr/local/lib/libIP2Location.so
libGeoIP.so.1 (libc6,x86-64) => /lib/x86_64-linux-gnu/libGeoIP.so.1
libGeoIP.so (libc6,x86-64) => /lib/x86_64-linux-gnu/libGeoIP.so


# nginx: [alert] failed to load the 'resty.core' module (https://github.com/openresty/lua-resty-core); ensure you are using an OpenResty release from https://openresty.org/en/download.html (reason: module 'resty.core' not found:
git clone https://github.com/openresty/lua-resty-core.git
git clone https://github.com/openresty/lua-resty-lrucache.git
mkdir -p /usr/local/luajit2/lib/lua/5.1/resty/
cp -ar lua-resty-core/lib/resty/* /usr/local/luajit2/lib/lua/5.1/resty/ 
cp -ar lua-resty-lrucache/lib/resty/* /usr/local/luajit2/lib/lua/5.1/resty/
mkdir -p /usr/local/luajit2/share/luajit-2.1.0-beta3/resty/
cp -ar lua-resty-core/lib/resty/* /usr/local/luajit2/share/luajit-2.1.0-beta3/resty/
cp -ar lua-resty-lrucache/lib/resty/* /usr/local/luajit2/share/luajit-2.1.0-beta3/resty/
```

## Deploy By Container
### Run On Docker
```bash
docker run xxx
```

### Run On Kubernetes
> For Kubernetes clusters, it is recommended to use ingress-nginx-controller
```bash
### for Nginx
# add and update repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm update

# get charts package
helm pull bitnami/nginx --untar
cd nginx

# configure and run
vim values.yaml
helm -n nginx install ingress-nginx .
###


### for ingress
# add and update repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm update

# get charts package
helm pull ingress-nginx/ingress-nginx --untar
cd ingress-nginx

# configure and run
vim values.yaml
...

helm -n ingress-nginx install ingress-nginx .
```


> Reference:
>
> 1. [Official Website](https://nginx.org/en/docs/)
> 2. [Openrestry Repository](https://github.com/openresty)
> 3. [Luajit Download](https://luajit.org/download.html)
> 4. [ingress-nginx controller](https://kubernetes.github.io/ingress-nginx/deploy/)
> 5. [nginx-ingress controller](https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/)
