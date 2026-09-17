---
description: Disk I/O benchmarking, monitoring, filesystem, partitioning, and syscall tracing
tags:
  - devops/command
---

# IO Tools

## Disk Usage

### df && du

```bash
# filesystem-level free space
df -h
df -hT                                   # include filesystem type
df -ih                                   # inode usage (often what runs out first)

# directory-level usage
du -sh /var/log                          # summary, human-readable
du -sh /var/* | sort -h                  # top-level breakdown sorted
du -h --max-depth=1 /var | sort -h
du -ah /var | sort -h | tail -20         # top 20 largest files/dirs
```

### ncdu

```bash
# interactive disk usage analyzer (apt install ncdu)
ncdu /
ncdu -x /                                # stay on one filesystem
```

### lsof (Disk Hogs)

```bash
# find what is holding a deleted file (common cause of "df says full, du says not")
lsof +L1 | grep -v "^COMMAND"

# files open under a path
lsof +D /var/log
```

## Block Devices

### blkid && lsblk

```bash
# show all block device info
blkid
lsblk -f /dev/sda
lsblk -o UUID,PARTUUID,PATH,MOUNTPOINT /dev/sdb
lsblk -d -o NAME,ROTA,SIZE,MODEL          # ROTA=0 for SSD, 1 for HDD
```

### SCSI Bus Rescan

```bash
# detect newly added disks without rebooting
for host in $(ls /sys/class/scsi_host); do
  echo "- - -" > /sys/class/scsi_host/$host/scan
done
```

## Partitioning

```bash
# MBR: fdisk, parted
# GPT: gdisk, parted

# show disk partition info
fdisk -l /dev/sda
gdisk -l /dev/sda
parted -l /dev/sda
```

### fdisk (MBR)

```bash
fdisk /dev/sda
```

### gdisk (GPT)

```bash
gdisk /dev/sda
```

### parted

```bash
# MBR (Legacy Boot) layout
parted /dev/sda -- mklabel msdos
parted /dev/sda -- mkpart primary 1MB -2GB
parted /dev/sda -- set 1 boot on
parted /dev/sda -- mkpart primary linux-swap -2GB 100%

# GPT (UEFI) layout
parted /dev/sdb -- unit mib
parted /dev/sdb -- mklabel gpt
parted /dev/sdb -- mkpart primary 1 3
parted /dev/sdb -- mkpart ESP fat32 3 515
parted /dev/sdb -- mkpart root ext4 515 -1
parted /dev/sdb -- set 1 bios_grub on
parted /dev/sdb -- set 2 esp on
```

### partprobe && growpart

```bash
# reread partition table without reboot
partprobe

# grow a partition to fill available space (cloud-utils-growpart)
growpart /dev/sda 1
```

## Filesystem

### mkfs

```bash
# ext4
mkfs.ext4 /dev/sda1

# xfs
mkfs.xfs /dev/sda1

# mount and persist
mount /dev/sda1 /data
echo 'UUID=<uuid> /data ext4 defaults 0 2' >> /etc/fstab
```

### Resize

```bash
# resize after growpart (ext2/3/4)
resize2fs /data

# resize xfs (must be mounted)
xfs_growfs -d /data
```

### tune2fs && xfs_info

```bash
# ext4: show / tune filesystem parameters
tune2fs -l /dev/sda1
tune2fs -m 1 /dev/sda1                   # reduce reserved-for-root from 5% to 1%
tune2fs -c 0 -i 0 /dev/sda1              # disable fsck mount-count / time check

# xfs: show geometry
xfs_info /data
```

## Mount & Swap

### mount && findmnt

```bash
# show mounted filesystems
mount | column -t
findmnt
findmnt -T /var/log                      # which mount serves a path
findmnt --verify                         # validate /etc/fstab

# mount / remount
mount /dev/sda1 /data
mount -o remount,rw /                    # flip readonly root to rw
```

### Swap

```bash
# show swap usage
swapon --show
cat /proc/swaps
free -h

# enable / disable
swapon /swapfile
swapoff -a

# create a swap file
dd if=/dev/zero of=/swapfile bs=1M count=2048
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
```

## I/O Benchmark

### dd

```bash
# CPU baseline (no disk involved)
dd if=/dev/zero of=/dev/null

# sequential write throughput (direct I/O, bypass page cache)
time dd if=/dev/zero of=test.file bs=1G count=2 oflag=direct
```

### fio

```bash
# sequential read
fio -filename=/tmp/test.file -direct=1 -iodepth 1 -thread -rw=read \
    -ioengine=psync -bs=16k -size=2G -numjobs=10 -runtime=60 \
    -group_reporting -name=test_r

# sequential write
fio -filename=/tmp/test.file -direct=1 -iodepth 1 -thread -rw=write \
    -ioengine=psync -bs=16k -size=2G -numjobs=10 -runtime=60 \
    -group_reporting -name=test_w

# random write
fio -filename=/tmp/test.file -direct=1 -iodepth 1 -thread -rw=randwrite \
    -ioengine=psync -bs=16k -size=2G -numjobs=10 -runtime=60 \
    -group_reporting -name=test_randw

# mixed random read/write (70% read, noop scheduler)
fio -filename=/var/test.file -direct=1 -iodepth 1 -thread -rw=randrw -rwmixread=70 \
    -ioengine=psync -bs=16k -size=2G -numjobs=10 -runtime=60 \
    -group_reporting -name=test_r_w -ioscheduler=noop
```

## I/O Monitoring

### iostat

```bash
# install
apt install sysstat

# usage
iostat [options] [delay [count]]
iostat 2                                 # uninterrupted, every 2s
iostat 1 10                              # 10 samples, 1s interval

# common flags
-c     CPU utilization
-d     device utilization
-h     human-readable
-x     extended statistics
-t     timestamp

# example: extended stats for sda and sdb, every 1s, 10 samples
iostat -dhx sda sdb 1 10
```

### iotop

```bash
# common flags
-o, --only            only show processes/threads doing I/O
-b, --batch           non-interactive mode
-n NUM                number of iterations
-d SEC                delay between iterations [1s]
-p PID                processes to monitor
-u USER               users to monitor
-P                    only processes (not threads)
-a, --accumulated     accumulated I/O instead of bandwidth
-k                    kilobytes instead of human-friendly
-t                    timestamp per line (implies --batch)

# accumulated, process-level, only active I/O
iotop -oPa
```

### pidstat

```bash
# per-process I/O, 1s interval
pidstat -d 1

# per-process CPU and I/O, 5 samples
pidstat -du 1 5
```

### sar (Disk I/O)

```bash
# overall I/O transfer rate
sar -b 1 10

# per-block-device activity (pretty-print names)
sar -d -p 1 10
```

### vmstat (Disk)

```bash
# disk statistics with timestamps
vmstat -d -t

# event counters and memory stats
vmstat -s

# number of forks since boot
vmstat -f
```

## Syscall & File Tracing

### strace

```bash
# install
apt install strace

# top-of-time syscall summary (great first look)
strace -c ls

# trace only file-related syscalls
strace -e trace=file -p <PID>
strace -e trace=openat,read,write -p <PID>

# follow forks
strace -f -p <PID>

# write trace to file
strace -o /tmp/strace.out -f -tt -p <PID>
```

### lsof (Open Files)

```bash
# all open files for a process
lsof -p <PID>

# who has this file open
lsof /var/log/syslog

# files opened by a user
lsof -u username

# all open files of a process tree
lsof -R -p <PID>
```

> Reference:
>
> 1. [fio Documentation](https://fio.readthedocs.io/)
> 2. [sysstat (iostat/pidstat/sar)](https://github.com/sysstat/sysstat)
> 3. [iotop](https://repo.or.cz/iotop.git)
> 4. [util-linux (lsblk/blkid/fdisk)](https://github.com/util-linux/util-linux)
> 5. [GNU parted](https://www.gnu.org/software/parted/)
> 6. [strace](https://strace.io/)
> 7. [lsof](https://github.com/lsof-org/lsof)
