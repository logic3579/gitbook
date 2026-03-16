---
description: OpenCost provides visibility into current and historical Kubernetes spend and resource allocation.
---

# OpenCost

## Introduction

OpenCost is a CNCF sandbox project that provides real-time cost visibility and insights for Kubernetes workloads. It enables teams to understand, monitor, and optimize their Kubernetes spending at the namespace, deployment, and pod levels.

OpenCost is the open-source foundation of Kubecost, offering core cost allocation functionality without the enterprise features.

## Key Features

### Cost Monitoring
- Real-time cost tracking at cluster, namespace, deployment, and pod level
- Historical cost data with trend analysis
- Support for AWS, GCP, Azure, and on-premises
- Custom pricing configuration

### Resource Cost Breakdown
- CPU cost allocation
- Memory cost allocation
- GPU cost allocation
- Storage (PVC) cost allocation
- Network egress cost tracking

### Multi-Cluster Support
- Federation across multiple Kubernetes clusters
- Unified cost reporting
- Cluster-level comparison

### Integration
- Prometheus metrics endpoint
- Grafana dashboard integration
- Cloud provider APIs for accurate pricing
- OpenTelemetry support

## Architecture

OpenCost consists of:

- **Cost Model**: Core calculation engine that processes Prometheus metrics
- **Allocation Service**: Distributes costs across namespaces and pods
- **Prometheus Adapter**: Exposes custom metrics for cost data
- **Exporter**: Collects and exports cost metrics

## Installation

### Helm Installation

```bash
# Add OpenCost helm repo
helm repo add opencost https://opencost.github.io/opencost-helm-chart
helm repo update

# Install OpenCost
helm install opencost opencost/opencost -n opencost --create-namespace
```

### kubectl Installation

```bash
# Deploy OpenCost
kubectl apply -f https://raw.githubusercontent.com/opencost/opencost/develop/kubernetes/opencost.yaml
```

## Configuration

### Prometheus Configuration

OpenCost requires Prometheus. Ensure your Prometheus has the following scrape config:

```yaml
- job_name: 'opencost'
  scrape_interval: 1m
  scrape_timeout: 10s
  metrics_path: '/metrics'
  scheme: 'http'
  static_configs:
    - targets: ['opencost.opencost.svc:9003']
```

### Cloud Provider Integration

#### AWS

```yaml
opencost:
  config:
    aws:
      enabled: true
      spotDataEndpoint: "https://spot-data-cloudjoin.s3.amazonaws.com"
      spotDataBucket: "my-spot-data-bucket"
      spotDataPrefix: "spotdata"
```

#### GCP

```yaml
opencost:
  config:
    gcp:
      enabled: true
      projectID: "my-gcp-project"
      billingDataDataset: "my-billing-dataset"
```

#### Azure

```yaml
opencost:
  config:
    azure:
      enabled: true
      subscriptionID: "my-subscription-id"
      tenantID: "my-tenant-id"
      clientID: "my-client-id"
      clientSecret: "my-client-secret"
```

## Accessing OpenCost

```bash
# Port-forward to access UI
kubectl port-forward -n opencost svc/opencost 9090:9090
```

Access the UI at: http://localhost:9090

## Key Metrics

### Namespace Costs

```promql
sum(opencost_namespace_cost) by (namespace)
```

### Pod Costs

```promql
sum(opencost_pod_cost) by (pod, namespace)
```

### Cost by Service

```promql
sum(opencost_service_cost) by (service)
```

### CPU Cost

```promql
sum(opencost_cpu_cost) by (cluster)
```

### Memory Cost

```promql
sum(opencost_memory_cost) by (cluster)
```

### GPU Cost

```promql
sum(opencost_gpu_cost) by (cluster)
```

### Storage Cost

```promql
sum(opencost_pvc_cost) by (cluster, persistentvolume)
```

## Cost Allocation

### By Namespace

OpenCost automatically allocates costs based on:
- Resource requests
- Resource limits
- Actual usage
- PVC usage

### Using Labels

Cost allocation can be customized using Kubernetes labels:

```yaml
metadata:
  labels:
    environment: "production"
    team: "platform"
```

### Shared Costs

Configure shared costs for cluster-level resources:

```yaml
opencost:
  config:
    # Cluster management costs to distribute
    clusterManagementCost: "50.00"
    # Percentage of shared costs to allocate
    sharedCosts:
      - name: "load-balancer"
        cost: "100.00"
```

## Prometheus Queries

### Daily Cost by Namespace

```promql
sum(increase(opencost_namespace_cost_total[24h])) by (namespace)
```

### Monthly Cost Trend

```promql
sum(increase(opencost_cluster_cost_total[30d])) by (cluster)
```

### Cost Efficiency Ratio

```promql
sum(opencost_pod_cost) / sum(opencost_pod_efficiency)
```

## Grafana Integration

### Import Dashboard

Import the official OpenCost Grafana dashboard from:
https://grafana.com/dashboards/14191

### Custom Queries

```promql
# Total Daily Cost
sum(increase(opencost_cluster_cost_total[24h]))

# Top 10 Most Expensive Namespaces
topk(10, sum(opencost_namespace_cost) by (namespace))

# CPU vs Memory Cost Split
sum(opencost_cpu_cost) by (namespace)
sum(opencost_memory_cost) by (namespace)
```

## Alerting

### Prometheus Alert Rules

```yaml
groups:
  - name: opencost.alerts
    rules:
      - alert: HighNamespaceCost
        expr: sum(opencost_namespace_cost) > 1000
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "High cost detected for namespace {{ $labels.namespace }}"
          description: "Namespace {{ $labels.namespace }} cost is above $1000/day"

      - alert: CostAnomaly
        expr: rate(opencost_cluster_cost_total[1h]) > 1.5 * rate(opencost_cluster_cost_total[24h])
        for: 30m
        labels:
          severity: critical
        annotations:
          summary: "Cost anomaly detected"
          description: "Cluster cost is growing faster than normal"
```

## ETL Pipeline

OpenCost uses an ETL (Extract, Transform, Load) pipeline for cost data:

1. **Extract**: Collects data from Prometheus and cloud APIs
2. **Transform**: Applies pricing models and allocations
3. **Load**: Stores processed data for querying

### Build ETL Pipeline

```bash
# Build ETL pipeline manually
curl -g -X POST http://opencost/opencost-backend/etl/build
```

### Update ETL Data

```bash
# Force update ETL with latest data
curl -g -X POST http://opencost/opencost-backend/etl/forceUpdate
```

## Troubleshooting

### Common Issues

#### Missing Metrics

If metrics are missing, check:
- Prometheus is correctly configured to scrape OpenCost
- Prometheus has the correct role permissions
- Network policies allow communication

```bash
# Check OpenCost metrics endpoint
kubectl exec -n opencost deploy/opencost -- curl localhost:9003/metrics
```

#### Incorrect Pricing

If pricing seems wrong:
- Verify cloud provider credentials
- Check custom pricing configuration
- Ensure spot data is configured (if using spot instances)

#### High Memory Usage

OpenCost stores historical data in Prometheus:
- Adjust retention period
- Configure resource limits
- Enable downsampling for historical data

## Comparison with Kubecost

| Feature | OpenCost | Kubecost |
|---------|----------|----------|
| Pricing Model | Open source (CNCF) | Freemium (Enterprise paid) |
| UI | Basic UI | Full-featured web UI |
| Enterprise Support | Community only | Yes |
| Cloud Integrations | Limited | Native |
| SAML/SSO | No | Yes |
| Multi-cluster Federation | Basic | Advanced |
| Custom Reporting | No | Yes |

## Best Practices

1. **Configure cloud integration early** - Accurate pricing requires cloud provider API access
2. **Use consistent labels** - Enable detailed cost allocation across teams
3. **Set up alerting** - Catch cost anomalies early
4. **Review regularly** - Weekly cost reviews help identify optimization opportunities
5. **Combine with right-sizing** - Use cost data to right-size resources

> Reference:
>
> 1. [Official Website](https://opencost.io/)
> 2. [Repository](https://github.com/opencost/opencost)
> 3. [Documentation](https://docs.opencost.io/)
> 4. [CNCF Project](https://www.cncf.io/projects/opencost/)
