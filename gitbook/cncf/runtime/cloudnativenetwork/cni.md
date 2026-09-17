---
description: Container Network Interface (CNI) is a specification and libraries for configuring network interfaces in Linux containers.
tags:
  - cncf/runtime
  - networking
  - kubernetes
---

# CNI

## Introduction

Container Network Interface (CNI) is a CNCF project that defines a specification and libraries for writing plugins to configure network interfaces in Linux containers. It focuses on network connectivity of containers and removing allocated resources when containers are deleted.

### How CNI Works

When a container runtime (containerd, CRI-O) creates or deletes a pod, it calls the CNI plugin to set up or tear down the network:

```text
┌──────────────┐    CNI API    ┌────────────┐    ┌─────────────┐
│  Container   │──────────────▶│ CNI Plugin │───▶│ Network     │
│  Runtime     │  ADD / DEL    │ (binary)   │    │ (veth, vxlan│
│  (CRI)       │◀──────────────│            │    │  bridge...) │
└──────────────┘   Result      └────────────┘    └─────────────┘
```

1. **ADD** — Called when a pod is created. The plugin sets up the network interface and returns IP address info.
2. **DEL** — Called when a pod is deleted. The plugin tears down the network interface.
3. **CHECK** — Called to verify an existing container's networking is correct.

### CNI Configuration

CNI configuration files are stored in `/etc/cni/net.d/` and CNI plugin binaries in `/opt/cni/bin/`.

```json
{
  "cniVersion": "1.0.0",
  "name": "my-network",
  "type": "bridge",
  "bridge": "cni0",
  "isGateway": true,
  "ipMasq": true,
  "ipam": {
    "type": "host-local",
    "subnet": "10.244.0.0/16",
    "routes": [
      { "dst": "0.0.0.0/0" }
    ]
  }
}
```

### Plugin Types

**Interface plugins** — Create network interfaces:

| Plugin    | Description                                      |
| --------- | ------------------------------------------------ |
| bridge    | Creates a bridge and adds host/container to it   |
| macvlan   | Creates a new MAC address and forwards traffic   |
| ipvlan    | Adds addresses sharing the parent's MAC          |
| ptp       | Creates a veth pair                              |
| vlan      | Allocates a VLAN device                          |
| host-device | Moves an existing device into a container      |

**IPAM plugins** — Manage IP address allocation:

| Plugin     | Description                                  |
| ---------- | -------------------------------------------- |
| host-local | Maintains a local database of allocated IPs  |
| dhcp       | Runs a daemon to make DHCP requests           |
| static     | Assigns a static IPv4/IPv6 address            |

**Meta plugins** — Chain with other plugins for additional functionality:

| Plugin     | Description                                  |
| ---------- | -------------------------------------------- |
| tuning     | Tweaks sysctl parameters of existing interfaces |
| portmap    | Maps ports from host's address space to container |
| bandwidth  | Allows bandwidth-limiting through traffic control |
| firewall   | Uses iptables or firewalld to add rules      |

### CNI Implementations

Major CNI plugins used in production Kubernetes clusters:

- [**Cilium**](cilium.md) — eBPF-based networking with L7 policy enforcement
- **Calico** — L3 networking with BGP and network policy
- **Flannel** — Simple overlay network using VXLAN
- **Weave Net** — Mesh overlay network with encryption support

> Reference:
>
> 1. [Official Website](https://www.cni.dev/)
> 2. [Repository](https://github.com/containernetworking/cni)
> 3. [CNI Plugins](https://github.com/containernetworking/plugins)
