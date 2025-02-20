---
description: >-
  Cloud Native Computing Foundation
  Cloud Native Interactive Landscape
icon: bullseye-arrow
---

# CNCF

## Table of contents

<!-- toc -->

- [CNAI](#)
- [AppDefinitionDevelopment](#)
- [ObservabilityAnalysis](#)
- [OrchestrationManagement](#)
- [Provisioning](#)
- [Runtime](#)
- [Serverless](#)

<!-- tocstop -->


## Nginx config
```bash
cat << "EOF" > cncf-nginx.conf 
upstream cluster_ingress {
  server 1.1.1.1;
  server 2.2.2.2;
  server 3.3.3.3;
}
upstream cluster_ingress_tls {
  server 1.1.1.1:443;
  server 2.2.2.2:443;
  server 3.3.3.3:443;
}
server {
    listen 80;
    listen 443;

    server_name
        # AppDefinition and Development
        argocd.yakir.top
        gitlab.yakir.top
        jenkins.yakir.top
        harbor.yakir.top
        rancher.yakir.top
        # Observability and Analysis
        prometheus.yakir.top
        grafana.yakir.top
    ;

    access_log logs/yakir_access.log main;
    ssl_certificate     "keys/yakir.top.crt";
    ssl_certificate_key "keys/yakir.top.key";

    allow 127.0.0.1;
    deny all;

    location / {
        proxy_pass http://cluster_ingress;
        proxy_ignore_client_abort on;
        proxy_redirect   off;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
        # websocket
        proxy_http_version 1.1;
        proxy_set_header Connection $connection_upgrade; # upgrade
        proxy_set_header Upgrade $http_upgrade; # websocket
    }
}
EOF
```
