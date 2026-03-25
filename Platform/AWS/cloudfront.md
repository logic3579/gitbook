---
description: Amazon CloudFront is a global CDN service that accelerates delivery of websites, APIs, and content with low latency and high transfer speeds.
tags:
  - platform/aws
  - networking
---

# CloudFront

## Introduction

Amazon CloudFront is a Content Delivery Network (CDN) service that distributes content to end users with low latency and high transfer speeds through a worldwide network of edge locations. It integrates natively with other AWS services such as S3, EC2, ALB, and Lambda@Edge.

### Key Features

- **Global Edge Network** — 600+ points of presence (PoPs) across 90+ cities and 40+ countries.
- **Origin Types** — S3 buckets, EC2 instances, ALB/ELB, API Gateway, or any custom HTTP origin.
- **HTTPS/TLS** — Free TLS certificates via ACM, TLS 1.3 support, and SNI.
- **Cache Behaviors** — Path-based routing with configurable TTL, headers, query strings, and cookies.
- **Lambda@Edge / CloudFront Functions** — Run code at edge locations for request/response manipulation.
- **Origin Shield** — Additional caching layer to reduce load on origins.

### Architecture

```text
┌──────┐    ┌────────────────┐    ┌──────────────────┐    ┌──────────┐
│ User │───▶│ Edge Location  │───▶│ Regional Edge    │───▶│  Origin  │
│      │    │ (cache + TLS)  │    │ Cache (optional) │    │ (S3/ALB) │
└──────┘    └────────────────┘    └──────────────────┘    └──────────┘
```

## Configuration

### Create Distribution (AWS CLI)

```bash
# Create an S3 origin distribution
aws cloudfront create-distribution \
  --origin-domain-name my-bucket.s3.amazonaws.com \
  --default-root-object index.html

# List distributions
aws cloudfront list-distributions \
  --query 'DistributionList.Items[*].{Id:Id,Domain:DomainName,Status:Status}'

# Create cache invalidation
aws cloudfront create-invalidation \
  --distribution-id E1234567890 \
  --paths "/*"
```

### Distribution Config (Terraform)

```hcl
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = ["cdn.example.com"]
  price_class         = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cors_s3.id
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
```

### Cache Behaviors

| Setting              | Description                                           |
| -------------------- | ----------------------------------------------------- |
| Path Pattern         | URL path to match (e.g., `/api/*`, `/static/*`)       |
| TTL (min/max/default)| Cache duration at the edge                            |
| Compress             | Auto gzip/brotli compression for supported content    |
| Viewer Protocol      | HTTP only, HTTPS only, or redirect HTTP to HTTPS      |
| Allowed Methods      | Which HTTP methods to forward to origin               |

> Reference:
>
> 1. [Official Website](https://aws.amazon.com/cloudfront/)
> 2. [CloudFront Developer Guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/)
> 3. [CloudFront Pricing](https://aws.amazon.com/cloudfront/pricing/)
