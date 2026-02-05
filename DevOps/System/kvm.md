## Introduction

kvm: Kernel module responsible for CPU and memory virtualization, intercepts guest I/O and passes it to QEMU for processing.
QEMU: Implements IO virtualization and device emulation (disk, network card, graphics card, sound card, etc.), interacts with the kvm kernel via IOCTL system calls.
qemu-kvm: Core virtualization software, provides hardware emulation and an interface with the kvm kernel module.
libvirt: Service and daemon (libvirtd) for managing virtualization platforms, provides a common API for managing various virtualization technologies (such as kvm, Xen).
virsh: CLI command-line tool based on libvirt.
virt-install: Command-line tool for creating kvm virtual machines.
virt-manager: Virtual machine UI management tool.
virt-viewer: Tool for connecting to virtual machine display.
virt-clone: Virtual machine cloning tool.
virt-top: Tool for viewing virtual machine load.
virt-v2v: Virtual machine format migration tool.

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