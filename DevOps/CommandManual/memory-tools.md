---
description: Memory inspection, monitoring, cache management, swap, and OOM investigation
tags:
  - devops/command
---

# Memory Tools

## Overview

### free

```bash
# display memory usage in human-readable format
free -h
free -h -s 3                              # refresh every 3 seconds
free -h -c 5                              # refresh 5 times then exit

# output example
#               total        used        free      shared  buff/cache   available
# Mem:           15Gi       5.2Gi       2.1Gi       312Mi       8.1Gi       9.6Gi
# Swap:         2.0Gi          0B       2.0Gi
```

### /proc/meminfo

```bash
# raw kernel view (single source of truth that free / top / vmstat all derive from)
cat /proc/meminfo

# key fields
# MemTotal:        total RAM
# MemAvailable:    realistic free (used by `free` "available")
# Buffers/Cached:  page cache
# SReclaimable:    slab reclaimable (part of "available")
# AnonPages:       anonymous (process heap/stack)
# Shmem:           tmpfs + shared memory
# SwapTotal/Free:  swap

# quick filter
grep -E '^(MemTotal|MemAvailable|Buffers|Cached|SwapTotal|SwapFree|AnonPages|Shmem):' /proc/meminfo
```

## Process Memory

### ps

```bash
# sort processes by %MEM (descending)
ps aux --sort=-%mem | head -20

# show specific process memory details
ps -o pid,user,%mem,rss,vsz,comm -p <PID>

# all processes sorted by RSS
ps -eo pid,user,rss,comm --sort=-rss | head -20

# RSS: physical memory actually used (KB)
# VSZ: virtual memory allocated (KB) — includes mmap / swapped-out / shared
```

### top && htop

```bash
# top sorted by memory
top -o %MEM

# inside top keyboard shortcuts
# M    sort by memory
# P    sort by CPU
# e    toggle memory unit (KB/MB/GB)
# 1    show per-CPU stats
# c    show full command line
# k    kill a process
# q    quit

# htop
htop
htop -u username                          # filter by user
htop -p 1234,5678                         # monitor specific PIDs
htop -t                                   # tree view
```

### pmap

```bash
# memory map of a process
pmap <PID>
pmap -x <PID>                             # extended (RSS, dirty)
pmap -X <PID>                             # very detailed (Linux 4.5+)
pmap -d <PID>                             # device summary

# find the biggest anonymous mappings
pmap -x <PID> | sort -k3 -n | tail -20
```

### smem

```bash
# shared memory accounted proportionally — closer to "real" footprint
smem -r -k                                # sorted, human-readable
smem -u                                   # per-user summary
smem -t                                   # totals
smem -p                                   # percentages

# USS: Unique Set Size (memory unique to this process)
# PSS: Proportional Set Size (shared memory divided among users)
# RSS: Resident Set Size (total physical, including shared — overcounts)
```

### /proc/\<pid\>/status

```bash
# per-process memory fields, no extra tooling required
grep -E '^(Vm|Rss)' /proc/<PID>/status

# VmPeak / VmSize     virtual memory peak / current
# VmRSS / RssAnon / RssFile / RssShmem
# VmSwap              swapped out anonymous pages
```

## Slab & Kernel Cache

### slabtop

```bash
# live view of slab caches (kernel object caches: dentry, inode, kmalloc-*, etc.)
slabtop
slabtop -o                                # one-shot, sorted by size
slabtop -s c                              # sort by cache size
slabtop -s u                              # sort by usage
```

### /proc/slabinfo

```bash
# raw slab data (needs root)
sudo head -3 /proc/slabinfo
# fields: name <active_objs> <num_objs> <objsize> ...
```

### drop_caches

```bash
# 0: do not release (default)
# 1: release page cache
# 2: release dentries and inodes
# 3: release all
echo 1 > /proc/sys/vm/drop_caches
echo 0 > /proc/sys/vm/drop_caches

# safe: flush dirty pages first
sync && echo 3 > /proc/sys/vm/drop_caches
```

## Swap

### swapon

```bash
# show active swap devices / files
swapon --show
cat /proc/swaps

# create a swap file
dd if=/dev/zero of=/swapfile bs=1M count=2048
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# disable
swapoff /swapfile
swapoff -a                                # disable all
```

### Swap Pressure

```bash
# swap in / out rate (KB/s) — non-zero means pressure
vmstat 1 5
# si / so columns

# per-process swap usage (sorted desc)
for f in /proc/[0-9]*/status; do
  awk '/^Name|^VmSwap/ {printf "%s ", $2} END {print ""}' "$f"
done | sort -k2 -hr | head -20
```

### swappiness

```bash
# 0..100 — kernel preference for swapping anon pages vs reclaiming cache
cat /proc/sys/vm/swappiness                       # default usually 60
sysctl vm.swappiness=10                           # less aggressive swap
echo 'vm.swappiness=10' >> /etc/sysctl.d/99-mem.conf
```

## vmstat (Memory)

### Usage

```bash
# install
apt install procps

# basic usage
vmstat [options] [delay [count]]
vmstat 2                                  # every 2s, uninterrupted
vmstat 1 10                               # 10 samples, 1s

# event counters and memory stats summary
vmstat -s

# memory-related columns of `vmstat 1 5`
#  swpd:  virtual memory used (swap)
#  free:  idle memory
#  buff:  buffers
#  cache: page cache
#  si:    swap in from disk (KB/s)
#  so:    swap out to disk (KB/s)
```

### Active / Inactive

```bash
# active / inactive memory accounting (LRU state)
vmstat -a 1 5
```

## sar (Memory)

```bash
# install
apt install sysstat

# memory utilization
sar -r 1 10

# swap utilization
sar -S 1 10

# swap in/out rate
sar -W 1 10
```

## NUMA

### numactl

```bash
# show NUMA topology and policies
numactl --hardware
numactl --show

# pin a workload to a node (CPU + memory)
numactl --cpunodebind=0 --membind=0 ./my-app

# interleave memory across nodes
numactl --interleave=all ./my-app
```

### numastat

```bash
# per-node allocation hits / misses
numastat

# per-process NUMA memory usage
numastat -p <PID>
numastat -m                               # node-level meminfo
```

## OOM Investigation

### dmesg && journalctl

```bash
# kernel OOM killer messages
dmesg -T | grep -i -E 'oom|killed process'
journalctl -k --since '1 hour ago' | grep -i oom

# in the trace look for:
#   "invoked oom-killer"     — who triggered reclaim
#   "Memory cgroup out of memory" — container OOM (vs. host OOM)
#   "Killed process <pid> (<name>)" — victim
```

### Cgroup Memory

```bash
# cgroup v2: per-container memory accounting
cat /sys/fs/cgroup/<path>/memory.current
cat /sys/fs/cgroup/<path>/memory.max
cat /sys/fs/cgroup/<path>/memory.stat
cat /sys/fs/cgroup/<path>/memory.events       # oom / oom_kill counters

# cgroup v1 (legacy)
cat /sys/fs/cgroup/memory/<path>/memory.usage_in_bytes
cat /sys/fs/cgroup/memory/<path>/memory.oom_control
```

> Reference:
>
> 1. [procfs Documentation](https://www.kernel.org/doc/html/latest/filesystems/proc.html)
> 2. [htop Repository](https://github.com/htop-dev/htop)
> 3. [smem Documentation](https://www.selenic.com/smem/)
> 4. [sysstat (sar/vmstat)](https://github.com/sysstat/sysstat)
> 5. [numactl](https://github.com/numactl/numactl)
