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
cat << "EOF" > cncf.conf
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
        argocd.example.com
        gitlab.example.com
        jenkins.example.com
        harbor.example.com
        rancher.example.com
        # Observability and Analysis
        prometheus.example.com
        grafana.example.com
        kibana.example.com
    ;

    access_log /opt/nginx/logs/access.log main;
    ssl_certificate     "/opt/nginx/keys/example.com.crt";
    ssl_certificate_key "/opt/nginx/keys/example.com.key";

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
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Upgrade $http_upgrade;
    }
}
EOF
```
