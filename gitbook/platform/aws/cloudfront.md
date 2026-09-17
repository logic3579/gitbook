---
description: Amazon CloudFront is a global CDN service that accelerates delivery of websites, APIs, and content with low latency and high transfer speeds.
tags:
  - platform/aws
  - networking
---

# CloudFront

Amazon CloudFront is a CDN service that distributes content to end users with low latency through a worldwide network of edge locations. It integrates natively with S3, EC2, ALB, API Gateway, and Lambda@Edge.

## Key Features

- **Global Edge Network** — 600+ points of presence (PoPs) across 90+ cities and 40+ countries.
- **Origin Types** — S3 buckets, EC2 instances, ALB/ELB, API Gateway, or any custom HTTP origin.
- **HTTPS/TLS** — Free TLS certificates via ACM, TLS 1.3 support, and SNI.
- **Cache Behaviors** — Path-based routing with configurable TTL, headers, query strings, and cookies.
- **Lambda@Edge / CloudFront Functions** — Run code at edge locations for request/response manipulation.
- **Origin Shield** — Additional caching layer to reduce load on origins.

## Architecture

```text
┌──────┐    ┌────────────────┐    ┌──────────────────┐    ┌──────────┐
│ User │───▶│ Edge Location  │───▶│ Regional Edge    │───▶│  Origin  │
│      │    │ (cache + TLS)  │    │ Cache (optional) │    │ (S3/ALB) │
└──────┘    └────────────────┘    └──────────────────┘    └──────────┘
```

## Cache Behaviors

| Setting              | Description                                           |
| -------------------- | ----------------------------------------------------- |
| Path Pattern         | URL path to match (e.g., `/api/*`, `/static/*`)       |
| TTL (min/max/default)| Cache duration at the edge                            |
| Compress             | Auto gzip/brotli compression for supported content    |
| Viewer Protocol      | HTTP only, HTTPS only, or redirect HTTP to HTTPS      |
| Allowed Methods      | Which HTTP methods to forward to origin               |

## CLI

### Distributions

```bash
# Create an S3 origin distribution
aws cloudfront create-distribution \
  --origin-domain-name my-bucket.s3.amazonaws.com \
  --default-root-object index.html

# List distributions
aws cloudfront list-distributions \
  --query 'DistributionList.Items[*].{Id:Id,Domain:DomainName,Status:Status}'

aws cloudfront get-distribution --id E1234567890
aws cloudfront update-distribution --id E1234567890 --distribution-config file://config.json --if-match ETAG
aws cloudfront delete-distribution --id E1234567890 --if-match ETAG
```

### Cache Invalidation

```bash
aws cloudfront create-invalidation \
  --distribution-id E1234567890 \
  --paths "/*"

aws cloudfront list-invalidations --distribution-id E1234567890
aws cloudfront get-invalidation --distribution-id E1234567890 --id I2J3K4L5
```

> Reference:
>
> 1. [Official Website](https://aws.amazon.com/cloudfront/)
> 2. [CloudFront Developer Guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/)
> 3. [CloudFront Pricing](https://aws.amazon.com/cloudfront/pricing/)
