# README.md

## Prerequisites

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

## kube-state-metrics

```bash
helm upgrade --create-namespace \
    --install \
    kube-state-metrics prometheus-community/kube-state-metrics \
    -n monitoring \
    -f values.yaml
kubectl apply -f virtualservice.yaml
```

## prometheus-mysql-exporter

```bash
helm upgrade --create-namespace \
    --set mysql.host="mysql.database.svc.cluster.local" \
    --set mysql.pass="your_password" \
    --set mysql.user="your_username" \
    --install prometheus-mysql-exporter prometheus-community/prometheus-mysql-exporter \
    -n monitoring \
    -f values.yaml
```

## Grafana

```bash
# Config
vim values.yaml
persistence:
  type: pvc
  enabled: true
  storageClassName: standard-rwo
useStatefulSet: true

# Install
helm upgrade --create-namespace \
    --install grafana grafana/grafana \
    -n monitoring \
    -f values.yaml --version=9.2.4
kubectl apply -f virtualservice.yaml
```

## Nightingale

```bash
# Get helm-charts
git clone http://github.com/flashcatcloud/n9e-helm.git nightingale
cd nightingale

# Configure
vim values.yaml
...

# Fix prometheus issue
vim templates/prometheus/statefulset.yaml
      initContainers:
      - name: fix-permission
        image: busybox
        command: ["sh", "-c", "chown -R 65534:65534 /prometheus"]
        volumeMounts:
        - name: prometheus-data
          mountPath: /prometheus

# Fix mysql issue
vim templates/database/statefulset.yaml
      containers:
      - name: mysql
        args:
        - "--ignore-db-dir=lost+found"
        ...
        env:
          - name: TZ
            value: UTC

# Fix categraf timezone
vim templates/categraf/daemonset.yaml
      containers:
        - env:
            - name: TZ
              value: UTC

# Fix n9e timezone
vim templates/n9e/deployment.yaml
      containers:
        - args:
          env:
            - name: TZ
              value: UTC

# Update categraf
vim categraf/conf/input.prometheus/prometheus.toml
[[instances]]
# kube-state-metrics
urls = ["http://kube-state-metrics:8080/metrics"]
use_tls = false
url_label_key = "instance"
url_label_value = "{{.Host}}"
# if you use dashboards, do not delete this label
labels = {job="categraf"}

[[instances]]
# prometheus-mysql-exporter
urls = ["http://prometheus-mysql-exporter:9104/metrics"]
use_tls = false
url_label_key = "instance"
url_label_value = "{{.Host}}"
# if you use dashboards, do not delete this label
labels = {job="categraf"}


# Install
helm upgrade --create-namespace --install nightingale . -n monitoring -f values.yaml
```
