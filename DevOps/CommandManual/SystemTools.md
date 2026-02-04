# System Tools

## sar

```bash
# install
apt install sysstat

# example
sar [options] [delay [count]]
sar -r 1 10

# cpu
-u     Report CPU utilization
-q     Report queue length and load averages
-P (cpu_list|ALL)    Report per-processor statistics for the specified processor or processors
-w     Report task creation and system switching activity

# memory
-r     Report memory utilization statistics
-S     Report swap space utilization statistics
-W     Report swapping statistics

# network
-n (DEV|ICMP|IP|SOCK|TCP|UDP)   Report network statistics

# I/O statistics
-b     Report I/O and transfer rate statistics
-d     Report activity for each block device
-p     Pretty-print device names

# others
-v     Report status of inode, file and other kernel tables
-y     Report TTY devices activity
-o | -f [filename]

```

## strace

```bash
# install
apt install strace

# trace system calls
strace -c ls

```

## systemtap

```bash
# install
apt install systemtap

# example
tee helloword.stp << "EOF"
probe begin
{
  print ("hello world\n")
  exit ()
}
EOF
stap hellword.stp

# network monitor
tee tcp.stp << "EOF"
#!/usr/bin/env stap
probe syscall.connect {
if(uaddr_ip_port=="443"){
    printf("ip: %s port: %s cmd: %s pid: %d ppid: %d\n", uaddr_ip, uaddr_ip_port, execname(), pid(), ppid())
}

if(uaddr_ip_port=="1521"){
    printf("Time:%s remote_ip:%s remote_port:%s local_cmd:%s pid:%d local_pcmd:%s ppid:%d euid:%d egid:%d env_PWD:%s  \n",
       tz_ctime(gettimeofday_s()),uaddr_ip, uaddr_ip_port,execname(),pid(),pexecname(),ppid(),euid(),egid(),env_var("PWD"))
}

}
EOF
stap -v tcp.stp


# get container pid info
tee sg.stp << "EOF"
global target_pid = 7942
probe signal.send{
  if (sig_pid == target_pid) {
    printf("%s(%d) send %s to %s(%d)\n", execname(), pid(), sig_name, pid_name, sig_pid);
    printf("parent of sender: %s(%d)\n", pexecname(), ppid())
    printf("task_ancestry:%s\n", task_ancestry(pid2task(pid()), 1));
  }
}
EOF
stap -v sg.stp

```

## trap

```bash
# catch ctrl+c signal and execute command, only effective in the current shell session
trap "exit" SIGINT
trap "echo 'Received SIGINT signal'" SIGINT

# ignore signal
trap "" SIGINT

# restore default signal handling
trap - SIGINT


```

## vmstat

```bash
# install
apt install procps
# use
vmstat [options] [delay [count]]


# probe uninterrupted every 2 seconds
vmstat 2
# probe 10 times per second
vmstat 1 10


# Displays a table of various event counters and memory statistics
vmstat -s
# The -f switch displays the number of forks since boot
vmstat -f
# Report disk statistics
vmstat -d -t

#
vmstat -ant 1
```

## watch

```bash
# monitor system soft interrupt rate
watch -d cat /proc/softirqs
```

> Reference:
>
> 1. [Official systemtap Doc](https://sourceware.org/systemtap/documentation.html)
> 2. [Ubuntu Install systemtap](https://wiki.ubuntu.com/Kernel/Systemtap#Systemtap_Installation)
> 3. [IBM Documentation](https://www.ibm.com/docs/zh/power9/9080-M9S?topic=commands-vmstat-command)
