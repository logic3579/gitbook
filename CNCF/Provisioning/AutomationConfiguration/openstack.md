---
description: OpenStack is an open-source cloud computing platform for building and managing public and private clouds.
tags:
  - cncf/provisioning
  - configuration
---

# OpenStack

## Introduction

OpenStack is a set of open-source software components that provide a framework for creating and managing cloud computing platforms. It allows organizations to deploy and manage compute, storage, and networking resources in a scalable, on-demand infrastructure.

### Core Services

| Service      | Project Name | Description                                    |
| ------------ | ------------ | ---------------------------------------------- |
| Compute      | Nova         | Manages virtual machines and bare metal servers |
| Networking   | Neutron      | Provides networking-as-a-service (SDN)         |
| Block Storage| Cinder       | Persistent block storage for instances         |
| Object Storage| Swift       | Distributed, eventually consistent object store|
| Identity     | Keystone     | Authentication, authorization, and service catalog |
| Image        | Glance       | Stores and retrieves virtual machine images    |
| Dashboard    | Horizon      | Web-based UI for managing OpenStack services   |
| Orchestration| Heat         | Template-based infrastructure orchestration    |

### Architecture

```text
┌─────────────────────────────────────────────────┐
│                    Horizon (Dashboard)           │
├─────────────────────────────────────────────────┤
│  Keystone │  Nova  │ Neutron │ Cinder │ Glance  │
│ (Identity)│(Compute)│(Network)│(Block) │(Image)  │
├─────────────────────────────────────────────────┤
│            Message Queue (RabbitMQ)              │
├─────────────────────────────────────────────────┤
│            Database (MySQL/MariaDB)              │
├─────────────────────────────────────────────────┤
│        Hypervisor (KVM / Xen / VMware)          │
└─────────────────────────────────────────────────┘
```

## Deploy

### DevStack (Development)

[DevStack](https://docs.openstack.org/devstack/) is the quickest way to get a development environment running:

```bash
# Create stack user
sudo useradd -s /bin/bash -d /opt/stack -m stack
echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack
sudo su - stack

# Clone DevStack
git clone https://opendev.org/openstack/devstack
cd devstack

# Create local.conf
cat > local.conf << 'EOF'
[[local|localrc]]
ADMIN_PASSWORD=secret
DATABASE_PASSWORD=$ADMIN_PASSWORD
RABBIT_PASSWORD=$ADMIN_PASSWORD
SERVICE_PASSWORD=$ADMIN_PASSWORD
HOST_IP=10.0.0.1
EOF

# Run the installer
./stack.sh
# Horizon dashboard available at http://HOST_IP/dashboard
```

### CLI Operations

```bash
# Install OpenStack CLI
pip install python-openstackclient

# Source credentials
source openrc admin admin

# Compute operations
openstack server list
openstack server create --flavor m1.small --image ubuntu-22.04 \
  --network private --key-name mykey my-instance

# Network operations
openstack network create my-network
openstack subnet create --network my-network --subnet-range 10.0.0.0/24 my-subnet
openstack router create my-router

# Image operations
openstack image list
openstack image create --file ubuntu-22.04.qcow2 --disk-format qcow2 ubuntu-22.04

# Volume operations
openstack volume create --size 10 my-volume
openstack server add volume my-instance my-volume
```

> Reference:
>
> 1. [Official Website](https://docs.openstack.org/)
> 2. [Repository](https://github.com/openstack/openstack)
> 3. [DevStack](https://docs.openstack.org/devstack/)
