---
description: AWS networking — VPC, security groups, NAT, load balancing
tags:
  - platform/aws
  - networking
---

# Network

## Components

| Component | Purpose |
|-----------|---------|
| **VPC** | Logical network in a region with a CIDR block (e.g., `10.0.0.0/16`) |
| **Subnet** | CIDR partition within a VPC, tied to a single AZ |
| **Route Table** | Per-subnet routing rules |
| **Internet Gateway (IGW)** | Bidirectional internet access for public subnets |
| **NAT Gateway** | Outbound-only internet for private subnets |
| **Security Group** | Stateful firewall at the instance / ENI level |
| **Network ACL** | Stateless firewall at the subnet level |
| **VPC Endpoint** | Private connectivity to AWS services (no internet) |
| **VPC Peering** | Connect two VPCs (same or cross-account / region) |
| **Transit Gateway** | Hub-and-spoke for many VPCs and on-prem networks |
| **ALB / NLB / GWLB** | L7 / L4 / L3 load balancers within a VPC |

## CIDR Planning

- Reserve `10.0.0.0/16` per VPC; subnets typically `/20` or `/24` per AZ.
- Keep production / staging / dev in distinct CIDR ranges to allow future peering.
- AWS reserves 5 addresses per subnet (`.0` network, `.1` router, `.2` DNS, `.3` future, `.255` broadcast).

## CLI

### VPC

```bash
aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=prod-vpc}]'
aws ec2 describe-vpcs
aws ec2 modify-vpc-attribute --vpc-id vpc-xxx --enable-dns-hostnames
aws ec2 delete-vpc --vpc-id vpc-xxx
```

### Subnets

```bash
aws ec2 create-subnet \
  --vpc-id vpc-xxx \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a
aws ec2 describe-subnets --filters Name=vpc-id,Values=vpc-xxx
aws ec2 modify-subnet-attribute --subnet-id subnet-xxx --map-public-ip-on-launch
aws ec2 delete-subnet --subnet-id subnet-xxx
```

### Route Tables

```bash
aws ec2 create-route-table --vpc-id vpc-xxx
aws ec2 describe-route-tables --filters Name=vpc-id,Values=vpc-xxx
aws ec2 create-route \
  --route-table-id rtb-xxx \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id igw-xxx
aws ec2 associate-route-table --route-table-id rtb-xxx --subnet-id subnet-xxx
aws ec2 delete-route --route-table-id rtb-xxx --destination-cidr-block 0.0.0.0/0
```

### Internet Gateway

```bash
aws ec2 create-internet-gateway
aws ec2 attach-internet-gateway --internet-gateway-id igw-xxx --vpc-id vpc-xxx
aws ec2 detach-internet-gateway --internet-gateway-id igw-xxx --vpc-id vpc-xxx
aws ec2 delete-internet-gateway --internet-gateway-id igw-xxx
```

### NAT Gateway

```bash
# Requires an Elastic IP allocated first
aws ec2 allocate-address --domain vpc
aws ec2 create-nat-gateway \
  --subnet-id subnet-xxx \
  --allocation-id eipalloc-xxx
aws ec2 describe-nat-gateways
aws ec2 delete-nat-gateway --nat-gateway-id nat-xxx
```

### Security Groups

```bash
aws ec2 create-security-group \
  --group-name my-sg \
  --description "My security group" \
  --vpc-id vpc-xxx

aws ec2 describe-security-groups

# Ingress rules
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxx \
  --protocol tcp --port 22 --cidr 10.0.0.0/8
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxx \
  --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 revoke-security-group-ingress \
  --group-id sg-xxx \
  --protocol tcp --port 22 --cidr 10.0.0.0/8

# Egress rules
aws ec2 authorize-security-group-egress \
  --group-id sg-xxx \
  --protocol tcp --port 443 --cidr 0.0.0.0/0

aws ec2 delete-security-group --group-id sg-xxx
```

### Network ACLs

```bash
aws ec2 create-network-acl --vpc-id vpc-xxx
aws ec2 describe-network-acls --filters Name=vpc-id,Values=vpc-xxx
aws ec2 create-network-acl-entry \
  --network-acl-id acl-xxx \
  --rule-number 100 \
  --protocol tcp --port-range From=22,To=22 \
  --cidr-block 0.0.0.0/0 --rule-action allow
aws ec2 delete-network-acl --network-acl-id acl-xxx
```

### VPC Endpoints

```bash
# Gateway endpoint (S3 / DynamoDB only)
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxx \
  --service-name com.amazonaws.us-east-1.s3 \
  --route-table-ids rtb-xxx

# Interface endpoint (most services, AWS PrivateLink)
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxx \
  --service-name com.amazonaws.us-east-1.ssm \
  --vpc-endpoint-type Interface \
  --subnet-ids subnet-xxx \
  --security-group-ids sg-xxx
```

### VPC Peering

```bash
aws ec2 create-vpc-peering-connection \
  --vpc-id vpc-xxx \
  --peer-vpc-id vpc-yyy
aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id pcx-xxx
aws ec2 describe-vpc-peering-connections
aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id pcx-xxx
```

### Load Balancers (ALB / NLB)

```bash
# Application Load Balancer (L7)
aws elbv2 create-load-balancer \
  --name my-alb \
  --type application \
  --subnets subnet-xxx subnet-yyy \
  --security-groups sg-xxx

# Network Load Balancer (L4)
aws elbv2 create-load-balancer \
  --name my-nlb \
  --type network \
  --subnets subnet-xxx subnet-yyy

aws elbv2 describe-load-balancers
aws elbv2 delete-load-balancer --load-balancer-arn ARN
```

### Target Groups

```bash
aws elbv2 create-target-group \
  --name my-tg \
  --protocol HTTP \
  --port 80 \
  --vpc-id vpc-xxx \
  --target-type instance \
  --health-check-path /health

aws elbv2 register-targets \
  --target-group-arn TG_ARN \
  --targets Id=i-xxx,Port=80 Id=i-yyy,Port=80

aws elbv2 deregister-targets \
  --target-group-arn TG_ARN \
  --targets Id=i-xxx,Port=80

aws elbv2 describe-target-health --target-group-arn TG_ARN
```

### Listeners

```bash
# HTTP listener
aws elbv2 create-listener \
  --load-balancer-arn LB_ARN \
  --protocol HTTP --port 80 \
  --default-actions Type=forward,TargetGroupArn=TG_ARN

# HTTPS listener with ACM cert
aws elbv2 create-listener \
  --load-balancer-arn LB_ARN \
  --protocol HTTPS --port 443 \
  --certificates CertificateArn=arn:aws:acm:... \
  --default-actions Type=forward,TargetGroupArn=TG_ARN
```

> Reference:
>
> 1. [VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/)
> 2. [Elastic Load Balancing](https://docs.aws.amazon.com/elasticloadbalancing/)
