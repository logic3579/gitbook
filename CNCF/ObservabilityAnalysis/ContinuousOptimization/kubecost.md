---
description: Kubecost provides real-time cost visibility and insights for Kubernetes clusters.
---

# Kubecost

## Introduction

Kubecost is a cloud-native cost management tool designed to provide real-time visibility and insights into Kubernetes cluster costs. It helps teams understand, monitor, and optimize their Kubernetes spending across namespaces, deployments, and services.

## Key Features

### Cost Monitoring
- Real-time cost tracking at cluster, namespace, and pod level
- Historical cost data with trend analysis
- Multi-cluster cost aggregation
- Support for AWS, GCP, Azure, and on-premises

### Resource Optimization
- Idle resource detection
- Right-sizing recommendations
- Waste identification (unattached volumes, oversized PVCs)
- Container resource request optimization

### Budgets & Alerts
- Custom budget definitions
- Cost anomaly alerts
- Daily/weekly/monthly spend reports
- Team-based cost allocation (chargeback/showback)

### Integration
- Prometheus integration for metrics
- Grafana dashboards
- Cloud provider APIs for accurate pricing
- Helm-based deployment

## Architecture

Kubecost consists of:
- **Kubecost Core**: Cost calculation engine
- **Prometheus**: Metrics storage
- **Cost Model**: ETL pipeline for pricing data
- **Frontend**: Web UI for visualization

## Installation

### Helm Installation

```bash
# Add Kubecost helm repo
helm repo add kubecost https://kubecost.github.io/cost-analyzer-helm-chart
helm repo update

# Install Kubecost
helm install kubecost kubecost/cost-analyzer -n kubecost --create-namespace
```

### kubectl Installation

```bash
# Deploy Kubecost
kubectl apply -f https://github.com/kubecost/cost-analyzer-helm-chart/releases/latest/download/kubecost.yaml
```

## Configuration

### Common Values

```yaml
# values.yaml
global:
  prometheus:
    enabled: true
  grafana:
    enabled: true

kubecostProductConfigs:
  clusterName: "prod-cluster"
  currencyCode: "USD"
```

### AWS Spot Data

```yaml
kubecostProductConfigs:
  awsSpotDataRegion: "us-east-1"
  awsSpotDataBucket: "kubecost-spot-data"
  awsSpotDataPrefix: "spotdata"
```

### Azure Configuration

```yaml
kubecostProductConfigs:
  azureSubscriptionID: "subscription-id"
  azureTenantID: "tenant-id"
  azureClientID: "client-id"
  azureClientSecret: "client-secret"
```

## Accessing Kubecost

```bash
# Port-forward to access UI
kubectl port-forward -n kubecost svc/kubecost-cost-analyzer 9090:9090
```

Access the UI at: http://localhost:9090

## Key Metrics

### Namespace Costs
```promql
sum(kube_namespace_annotations_cost{annotation_kubecost_com_namespace!=""}) by (annotation_kubecost_com_namespace)
```

### Pod Costs
```promql
container_memory_allocation_bytes * on(cluster_id, container, pod, namespace) group_right() kubecost_savings_container_memory_price
```

### CPU Cost
```promql
container_cpu_allocation * on(cluster_id, container, pod, namespace) group_right() kubecost_savings_container_cpu_price
```

## Cost Allocation

### By Namespace
Kubecost automatically allocates costs based on:
- Resource requests
- Resource limits
- Actual usage
- PVC usage

### By Label/Annotation
```yaml
metadata:
  labels:
    kubecost.com/team: "platform"
    kubecost.com/product: "backend"
```

## Savings

### Cluster Right-sizing
Kubecost analyzes historical CPU/memory usage and recommends:
- Optimal node pool sizes
- Node count adjustments
- Spot instance opportunities

### Unused Resources Detection
- Detects unattached PVCs
- Identifies idle pods
- Finds oversized containers

## Alerts

### Example Alert Rules

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kubecost-alerts
  namespace: kubecost
data:
  alerts.yaml: |
    - name: Daily Budget
      description: "Daily spend > $100"
      threshold: 100
      schedule: "0 0 * * *"
      emit_at: "00:00"
```

## Enterprise Features

- Multi-cluster federation
- SAML/SSO integration
- Custom pricing APIs
- Role-based access control (RBAC)
- Advanced reporting

## Best Practices

1. **Start with default settings** - Kubecost works well out of the box
2. **Configure cloud integration** - Accurate pricing requires provider API access
3. **Set budgets early** - Establish cost guardrails from day one
4. **Use labels consistently** - Enable team-based cost allocation
5. **Review weekly** - Make cost reviews part of your sprint cadence

## Comparison with OpenCost

| Feature | Kubecost | OpenCost |
|---------|----------|----------|
| Pricing Model | Freemium (Enterprise paid) | Open source (CNCF) |
| UI | Full-featured web UI | Basic UI |
| Enterprise Support | Yes | Community only |
| Cloud Integrations | Native | Limited |

> Reference:
>
> 1. [Official Website](https://kubecost.com/)
> 2. [Repository](https://github.com/kubecost/cost-analyzer-helm-chart)
> 3. [Documentation](https://docs.kubecost.com/)
