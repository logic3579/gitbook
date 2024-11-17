---
description: Nginx
---

# Nginx

## Introduction
...

## Deploy With Binary
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
#### [[sc-nginx|Config]]

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

## Deploy With Container
### Run in Docker
```bash
docker run xxx
```

### Run in Kubernetes
> k8s 集群建议使用 ingress-nginx-controller
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
> 1. [Official Website](https://nginx.org/en/docs/)
> 2. [Openrestry Repository](https://github.com/openresty)
> 3. [Luajit Download](https://luajit.org/download.html)
> 4. [ingress-nginx controller](https://kubernetes.github.io/ingress-nginx/deploy/)
> 5. [nginx-ingress controller](https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/)
