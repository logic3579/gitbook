---
description: Aliyun networking — VPC planning, security groups, EIP, NAT, and load balancing
tags:
  - platform/aliyun
  - networking
---

# Network

## CIDR Block Planning Overview

### 1) Purpose of CIDR Block Planning

- Easy to view and manage, similar to IP planning for one or more IDC data centers -- you can immediately identify ownership based on IP addresses.
- Facilitates network and routing determination within the same cluster/VPC, as well as network isolation policies (whitelists).
- Distinguishes multiple VPC/network environments, making it easy to differentiate subnet CIDR blocks when establishing network connectivity.

### 2) Standardized Design Approach

First, distinguish between two categories -- whether there are cluster-type resources such as ACK that require separate planning:

1. If there are no cluster resources (i.e., only conventional resources like RDS, ECS, etc.), simply define the VPC and vSwitches using standard private network CIDR blocks.
2. If there are cluster resources, allocate separate vSwitches for conventional resources and **dedicated vSwitches** for cluster resources.

Since production deployments mostly exist in cluster form on the cloud, we focus on the second approach.

CIDR block design specifications:

- Private CIDR blocks available for VPC: `192.168.0.0/16`, `10.0.0.0/8`, `172.16.0.0/12` and their subnets. Each VPC can only specify one CIDR block.
- CIDR blocks available for vSwitches: must be a subset of (≤) the VPC CIDR block.
- Number of VPCs: Use different CIDR blocks when creating multiple VPCs.
- Number of clusters: Use different CIDR blocks when deploying multiple clusters under the same account.
- ACK cluster network plugin mode:
  - **Without Terway**: three private CIDR blocks needed, e.g., `10.1.0.0/16` (VPC-vswitch), `192.168.0.0/24` (Pods), `192.168.10.0/24` (Services).
  - **With Terway**: two private CIDR blocks needed, e.g., `10.16.0.0/8` (VPC-vswitch + Pod), `192.168.0.0/24` (Services).

### Personal Recommendations

- Under the same account (same environment), use `192.168.0.0/16`, `10.0.0.0/8`, `172.16.0.0/12` to create VPCs.
  - Use sub-vSwitches to separate different clusters and cloud product resources.
  - Use cloud product whitelists or other network plugins for network isolation policies.
- Different accounts (e.g., development, production) can reuse the same CIDR blocks (cross-environment calls generally do not exist).
- Going forward, prefer the Terway plugin.

## Production Case Studies

### Case 1

- VPC: `10.0.0.0/8` (reusing the production VPC)
- vSwitches: Create 4 new vSwitches
  - `test-swc-10_200_0_0_20` (Availability Zone 1)
  - `test-swc-10_200_16_0_20` (Availability Zone 2)
  - `test-swc-10_200_64_0_19` (Availability Zone 1)
  - `test-swc-10_200_96_0_19` (Availability Zone 2)
- Cluster CIDR Planning
  - Node CIDR: `10.200.0.0/20`, `10.200.16.0/20`
  - Pod CIDR: `10.200.64.0/19`, `10.200.96.0/19`
  - Service CIDR: `172.31.0.0/16`

> Notes:
>
> - If high availability across different availability zones is required for Node and Pod vSwitches, each availability zone must have vSwitches available for both Nodes and Pods.
> - The Service CIDR block must not overlap with the VPC CIDR block or CIDR blocks used by existing Kubernetes clusters within the VPC.

### Related Documentation and Tools

- [Cloud Enterprise Network (CEN) Working Principles and Operations](https://help.aliyun.com/document_detail/189596.html)
- VPN Gateway:
  - [IPSec VPN Technical Principles](https://cloud.tencent.com/developer/article/1824924)
  - [Aliyun Official Operations](https://help.aliyun.com/document_detail/65072.html)
- [Subnet Calculator Online Tool](https://www.bejson.com/convert/subnetmask/)

## CLI

### VPC

```bash
aliyun vpc CreateVpc \
  --RegionId cn-hangzhou \
  --CidrBlock 10.0.0.0/16 \
  --VpcName test-vpc
aliyun vpc DescribeVpcs --RegionId cn-hangzhou
aliyun vpc DescribeVpcAttribute --VpcId vpc-xxx --RegionId cn-hangzhou
aliyun vpc ModifyVpcAttribute --VpcId vpc-xxx --VpcName new-name --RegionId cn-hangzhou
aliyun vpc DeleteVpc --VpcId vpc-xxx --RegionId cn-hangzhou
```

### vSwitch

```bash
aliyun vpc CreateVSwitch \
  --RegionId cn-hangzhou \
  --VpcId vpc-xxx \
  --ZoneId cn-hangzhou-h \
  --CidrBlock 10.0.1.0/24 \
  --VSwitchName test-vsw
aliyun vpc DescribeVSwitches --RegionId cn-hangzhou --VpcId vpc-xxx
aliyun vpc DeleteVSwitch --VSwitchId vsw-xxx --RegionId cn-hangzhou
```

### EIP

```bash
aliyun vpc AllocateEipAddress \
  --RegionId cn-hangzhou \
  --Bandwidth 5 \
  --InternetChargeType PayByTraffic
aliyun vpc DescribeEipAddresses --RegionId cn-hangzhou
aliyun vpc AssociateEipAddress \
  --AllocationId eip-xxx --InstanceId i-xxx --RegionId cn-hangzhou
aliyun vpc UnassociateEipAddress \
  --AllocationId eip-xxx --InstanceId i-xxx --RegionId cn-hangzhou
aliyun vpc ReleaseEipAddress --AllocationId eip-xxx --RegionId cn-hangzhou
```

### Route Tables

```bash
aliyun vpc DescribeRouteTables --RegionId cn-hangzhou --VpcId vpc-xxx
aliyun vpc CreateRouteEntry \
  --RouteTableId vtb-xxx \
  --DestinationCidrBlock 0.0.0.0/0 \
  --NextHopId i-xxx \
  --NextHopType Instance
aliyun vpc DeleteRouteEntry --RouteEntryId rte-xxx
```

### Security Groups

```bash
aliyun ecs CreateSecurityGroup \
  --RegionId cn-hangzhou \
  --VpcId vpc-xxx \
  --SecurityGroupName test-sg
aliyun ecs DescribeSecurityGroups --RegionId cn-hangzhou
aliyun ecs DescribeSecurityGroupAttribute --SecurityGroupId sg-xxx --RegionId cn-hangzhou
aliyun ecs AuthorizeSecurityGroup \
  --RegionId cn-hangzhou \
  --SecurityGroupId sg-xxx \
  --IpProtocol tcp \
  --PortRange 22/22 \
  --SourceCidrIp 0.0.0.0/0
aliyun ecs RevokeSecurityGroup \
  --RegionId cn-hangzhou \
  --SecurityGroupId sg-xxx \
  --IpProtocol tcp \
  --PortRange 22/22 \
  --SourceCidrIp 0.0.0.0/0
aliyun ecs DeleteSecurityGroup --SecurityGroupId sg-xxx --RegionId cn-hangzhou
```

### NAT Gateway

```bash
aliyun vpc CreateNatGateway \
  --RegionId cn-hangzhou \
  --VpcId vpc-xxx \
  --NatGatewayName test-nat \
  --NatType Enhanced \
  --VSwitchId vsw-xxx
aliyun vpc DescribeNatGateways --RegionId cn-hangzhou
aliyun vpc DeleteNatGateway --NatGatewayId ngw-xxx --RegionId cn-hangzhou

# SNAT entries
aliyun vpc CreateSnatEntry \
  --RegionId cn-hangzhou \
  --SnatTableId stb-xxx \
  --SourceVSwitchId vsw-xxx \
  --SnatIp 1.2.3.4
```

### SLB (Classic Load Balancer)

```bash
aliyun slb CreateLoadBalancer \
  --RegionId cn-hangzhou \
  --LoadBalancerName test-slb \
  --AddressType internet \
  --LoadBalancerSpec slb.s2.small
aliyun slb DescribeLoadBalancers --RegionId cn-hangzhou
aliyun slb DeleteLoadBalancer --LoadBalancerId lb-xxx

# Backend servers
aliyun slb AddBackendServers \
  --LoadBalancerId lb-xxx \
  --BackendServers '[{"ServerId":"i-xxx","Weight":100}]'
aliyun slb RemoveBackendServers \
  --LoadBalancerId lb-xxx \
  --BackendServers '[{"ServerId":"i-xxx"}]'

# Listeners
aliyun slb CreateLoadBalancerHTTPListener \
  --LoadBalancerId lb-xxx \
  --ListenerPort 80 \
  --BackendServerPort 8080 \
  --Bandwidth -1
aliyun slb StartLoadBalancerListener --LoadBalancerId lb-xxx --ListenerPort 80
```

### ALB (Application Load Balancer)

```bash
aliyun alb CreateLoadBalancer \
  --VpcId vpc-xxx \
  --AddressType Internet \
  --LoadBalancerName test-alb \
  --LoadBalancerEdition Standard \
  --ZoneMappings.1.ZoneId cn-hangzhou-h \
  --ZoneMappings.1.VSwitchId vsw-xxx \
  --ZoneMappings.2.ZoneId cn-hangzhou-i \
  --ZoneMappings.2.VSwitchId vsw-yyy
aliyun alb ListLoadBalancers --RegionId cn-hangzhou
aliyun alb DeleteLoadBalancer --LoadBalancerId alb-xxx

# Server groups
aliyun alb CreateServerGroup --ServerGroupName test-sg --VpcId vpc-xxx
aliyun alb AddServersToServerGroup \
  --ServerGroupId sgp-xxx \
  --Servers.1.ServerId i-xxx \
  --Servers.1.ServerType Ecs \
  --Servers.1.Port 80 \
  --Servers.1.Weight 100

# Listeners
aliyun alb CreateListener \
  --LoadBalancerId alb-xxx \
  --ListenerProtocol HTTP \
  --ListenerPort 80 \
  --DefaultActions.1.Type ForwardGroup \
  --DefaultActions.1.ForwardGroupConfig.ServerGroupTuples.1.ServerGroupId sgp-xxx
```

> Reference:
>
> 1. [VPC Documentation](https://help.aliyun.com/product/27706.html)
> 2. [Terway Network Plugin](https://help.aliyun.com/document_detail/97467.html)
> 3. [SLB Documentation](https://help.aliyun.com/product/27537.html)
> 4. [ALB Documentation](https://help.aliyun.com/product/197553.html)
