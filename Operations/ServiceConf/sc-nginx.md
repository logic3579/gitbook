### nginx.conf

```bash
user  nobody nobody;
worker_processes  auto;
worker_cpu_affinity auto;
worker_rlimit_nofile 655350;

error_log  logs/error.log;
pid        logs/nginx.pid;

events {
    worker_connections  102400;
}

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
    include       mime.types;
    default_type  application/octet-stream;

    log_format  main  escape=json
'$remote_addr |$ip2location_country_long |$ip2location_region |$ip2location_city |[$time_local] |$host |$request |$status |BodySent:$body_bytes_sent |ReqTime:$request_time |$request_completion |$http_x_forwarded_for |$proxy_host |$upstream_addr |$upstream_status |$upstream_cache_status |UpResTime:$upstream_response_time |UpConnTime:$upstream_connect_time |UpResLen:$upstream_response_length |$hostname-$request_id |$scheme |$request_body |$http_cookie |$http_referer |$http_user_agent';

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

    resolver 8.8.8.8 1.1.1.1 114.114.114.114 valid=5 ipv6=off;
    resolver_timeout 3s;

    sendfile      on;
    server_tokens off;
    proxy_intercept_errors on;

    keepalive_timeout  180;
    client_body_buffer_size  50m;
    client_body_timeout      300;
    client_max_body_size     50m;
    proxy_next_upstream error  timeout  http_502  http_503 http_504;
    proxy_next_upstream_timeout 20;
    proxy_connect_timeout    10;
    proxy_read_timeout       300;
    proxy_send_timeout       300;
    proxy_buffer_size        512k;
    proxy_buffers            4 512k;
    proxy_busy_buffers_size    512k;
    proxy_temp_file_write_size 512k;
    client_header_buffer_size 512k;
    large_client_header_buffers 4 512k;

    server_names_hash_max_size 3072;
    server_names_hash_bucket_size 1024;
    proxy_ignore_client_abort on;

    variables_hash_max_size 2048;
    variables_hash_bucket_size 2048;

    gzip  on;
    gzip_disable "msie6";
    gzip_proxied any;
    gzip_min_length 1k;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/javascript application/octet-stream;

    # ip2location = https://github.com/chrislim2888/IP2Location-C-Library
    ip2location_database /opt/nginx/conf/IPV6-COUNTRY-REGION-CITY.BIN;
    ip2location_proxy_recursive on;
    map $ip2location_country_short $blocked_country {
	    default no;
	    ~*(AU|IN|NG|US)$ yes;
    }

    # geoip2 = https://github.com/leev/ngx_http_geoip2_module
    geoip2 /opt/nginx/conf/GeoLite2-Country.mmdb {
       $geoip2_country_code country iso_code;
       $geoip2_country_name country names en;
    }
    geoip2 /opt/nginx/conf/GeoLite2-City.mmdb {
        $geoip2_city_name city names en;
        $geoip2_subdivisions_name subdivisions 0 names en;
        $geoip2_latitude location latitude;
        $geoip2_longitude location longitude;
    }
    map $geoip2_country_code $allowed_country {
        default no;
        ~*(AU|IN|NG|US)$ yes;
    }

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

    # vhosts dir
    include vhosts/*.conf;
}


include modules.conf;

```

#### modules.conf

```bash
cat > /opt/nginx/conf/modules.conf << EOF
load_module modules/ndk_http_module.so;
load_module modules/ngx_http_array_var_module.so;
load_module modules/ngx_http_echo_module.so;
load_module modules/ngx_http_geoip2_module.so;
load_module modules/ngx_http_headers_more_filter_module.so;
load_module modules/ngx_http_ip2location_module.so;
load_module modules/ngx_http_lua_module.so;
load_module modules/ngx_http_set_misc_module.so;
load_module modules/ngx_stream_geoip2_module.so;
EOF
```

### third iplib

[[IPV6-COUNTRY-REGION-CITY.BIN.gz|ip2location]]

[[GeoLite2-City.mmdb.gz|Geoip2]]

### vhosts/\*.conf

#### default.conf

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

#### real_ip.conf

```bash
real_ip_header X-Forwarded-For;
real_ip_recursive on;
# proxy downstream real ip
set_real_ip_from 192.168.1.1/32;
set_real_ip_from 192.168.1.2/32;
```

#### template.conf

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

        # cache settings
        #if ($request_filename ~ .*\.(htm|html|json)$) {
        #    add_header Cache-Control no-cache;
        #}
        if ($request_filename ~ .*\.(htm|html)$) { add_header Cache-Control "max-age=60, s-maxage=120"; }
        if ($request_filename !~ .*\.(htm|html)$) { add_header Cache-Control "max-age=31536000, s-maxage=86400"; }
            root /usr/share/nginx/html;
            try_files $uri $uri/ /index.html;
        }

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
        # Upgrade get by http header, Connection get by nginx map
        # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Upgrade
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
