---
description: Memory inspection, monitoring, and cache management tools
---

# Memory Tools

## free

```bash
# display memory usage in human-readable format
free -h
free -h -s 3        # refresh every 3 seconds
free -h -c 5         # refresh 5 times then exit

# output example
#               total        used        free      shared  buff/cache   available
# Mem:           15Gi       5.2Gi       2.1Gi       312Mi       8.1Gi       9.6Gi
# Swap:         2.0Gi          0B       2.0Gi
```

## top / htop

```bash
# top - sort by memory usage
top -o %MEM

# inside top keyboard shortcuts
# M    sort by memory usage
# P    sort by CPU usage
# e    toggle memory unit (KB/MB/GB)
# 1    show per-CPU stats
# c    show full command line
# k    kill a process
# q    quit

# htop
htop
htop -u username      # filter by user
htop -p 1234,5678     # monitor specific PIDs
htop -t               # tree view
```

## ps (memory-related)

```bash
# sort processes by memory usage (descending)
ps aux --sort=-%mem | head -20

# show specific process memory details
ps -o pid,user,%mem,rss,vsz,comm -p <PID>

# show all processes sorted by RSS (resident set size)
ps -eo pid,user,rss,comm --sort=-rss | head -20

# RSS: physical memory actually used (KB)
# VSZ: virtual memory allocated (KB)
```

## pmap

```bash
# show memory map of a process
pmap <PID>
pmap -x <PID>         # extended format with details
pmap -X <PID>         # even more details (Linux 4.5+)

# summary only
pmap -d <PID>
```

## vmstat (memory columns)

```bash
# memory related columns
vmstat 1 5
#  swpd: virtual memory used (swap)
#  free: idle memory
#  buff: memory used as buffers
#  cache: memory used as cache
#  si: swap in from disk (KB/s)
#  so: swap out to disk (KB/s)
```

## drop_caches

```bash
# 0: do not release (default)
# 1: release page cache
# 2: release dentries and inodes cache
# 3: release all cache
echo 1 > /proc/sys/vm/drop_caches
echo 0 > /proc/sys/vm/drop_caches

# safe way: sync first to flush dirty pages to disk
sync && echo 3 > /proc/sys/vm/drop_caches
```

## smem

```bash
# show memory usage with shared memory proportionally distributed
smem -r -k            # sorted, human-readable
smem -u               # per-user summary
smem -t               # show totals
smem -p               # show percentages

# USS: Unique Set Size (memory unique to this process)
# PSS: Proportional Set Size (shared memory divided equally among users)
# RSS: Resident Set Size (total physical memory, including shared)
```

> Reference:
>
> 1. [procfs Documentation](https://www.kernel.org/doc/html/latest/filesystems/proc.html)
> 2. [htop Repository](https://github.com/htop-dev/htop)
> 3. [smem Documentation](https://www.selenic.com/smem/)
