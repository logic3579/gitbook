## Introduction

kvm：内核模块，负责 CPU 与内存虚拟化，拦截 Guest 客户机的 I/O 交给 QEMU 处理。
QEMU： 实现 IO 虚拟化与各设备模拟（磁盘、网卡、显卡、声卡等），通过 IOCTL 系统调用与 kvm 内核交互。
qemu-kvm： 核心虚拟化软件，提供硬件仿真和与 kvm 内核模块的接口。
libvirt：管理虚拟化平台的服务和守护进程（libvirtd），提供了一个通用的 API 来管理各种虚拟化技术（如 kvm，Xen）。
virsh：基于 libvirt 的 CLI 命令行工具。
virt-install：创建 kvm 虚拟机的命令行工具。
virt-manager：虚拟机 UI 管理工具。
virt-viewer：连接到虚拟机屏幕工具。
virt-clone：虚拟机克隆工具。
virt-top：查看虚拟机负载工具。
virt-v2v：虚拟机格式迁移工具。

## How To Use

```bash
# Check hardware virtualization support
lscpu | grep Virtualization

# Install
dnf install qemu-kvm qemu-img
dnf install libvirt libvirt-python libvirt-client virt-install virt-manager

# Start libvirtd
systemctl start libvirtd
systemctl enable libvirtd
lsmod | grep kvm

# Option: Install bridge-utils
dnf install -y bridge-utils
vim /etc/sysconfig/network-scripts/ifcfg-ens192
vim /etc/sysconfig/network-scripts/ifcfg-br0
systemctl restart network
ip addr show br0

# Create vm
# option1: install initial vm by UI
virt-manager
# option2: install initial vm by iso
osinfo-query os # search os variant
virt-install \
  --name=template-ubuntu-22.04-base \
  --vcpus=2 \
  --ram=4096 \
  --disk path=/var/lib/libvirt/images/template-ubuntu-22.04-base.qcow2,size=20 \
  --cdrom=/tmp/ubuntu-22.04.iso \
  --os-variant=ubuntu22.04 \
  --network network=default \
  --graphics spice
qemu-img convert -O qcow2 -c template-ubuntu-22.04-base.qcow2 template-ubuntu-22.04.qcow2
qemu-img info template-ubuntu-22.04.qcow2
# option3: install vm by qcow2 template
virt-install \
  --name=vm-test \
  --import \
  --vcpus=2 \
  --ram=4096 \
  --disk path=/var/lib/libvirt/images/rockylinux9.5.qcow2 \
  --os-variant=ubuntu22.04 \
  --graphics spice \
  --network network=default \
  --noautoconsole

# Manager
virsh net-list --all
virsh list --all
virsh start vm_name
virsh autostart vm_name
virsh shutdown vm_name
virsh destroy vm_name
virsh undefine vm_name --remove-all-storage
virsh console vm_name
virsh edit vm_name
```