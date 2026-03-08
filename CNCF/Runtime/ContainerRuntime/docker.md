---
description: Docker
---

# Docker

## Introduction

### Linux Namespace

#### Overview

Linux Namespace is a kernel-level environment isolation mechanism provided by Linux. Unix has a system call called chroot (which jails users into a specific directory by modifying the root directory). chroot provides a simple isolation model: the filesystem inside chroot cannot access external content. Linux Namespace builds on this concept, providing isolation mechanisms for UTS, IPC, mount, PID, network, and User.

The super parent process PID in Linux is 1. Similar to chroot, if we can jail a user process space into a certain process branch and make the processes underneath see the super parent PID as 1, we achieve resource isolation (processes in different PID namespaces cannot see each other).

Three main system calls:

- **`clone()`** – Creates a new process with isolation by setting namespace parameters.
- **`unshare()`** – Detaches a process from a namespace.
- **`setns()`** – Attaches a process to an existing namespace.

[Linux Namespace Types](https://lwn.net/Articles/531114/)

| Type                   | System Call Flag | Kernel Version                                                            |
| ---------------------- | ---------------- | --------------------------------------------------------------------------------- |
| **Mount namespaces**   | CLONE_NEWNS   | [Linux 2.4.19](http://lwn.net/2001/0301/a/namespaces.php3)              |
| **UTS namespaces**     | CLONE_NEWUTS  | [Linux 2.6.19](http://lwn.net/Articles/179345/)                         |
| **IPC namespaces**     | CLONE_NEWIPC  | [Linux 2.6.19](http://lwn.net/Articles/187274/)                         |
| **PID namespaces**     | CLONE_NEWPID  | [Linux 2.6.24](http://lwn.net/Articles/259217/)                         |
| **Network namespaces** | CLONE_NEWNET     | [Started in Linux 2.6.24, completed in Linux 2.6.29](http://lwn.net/Articles/219794/) |
| **User namespaces**    | CLONE_NEWUSER    | [Started in Linux 2.6.23, completed in Linux 3.8](http://lwn.net/Articles/528078/)  |

#### clone() System Call

```c
#define _GNU_SOURCE
#include <sys/types.h>
#include <sys/wait.h>
#include <stdio.h>
#include <sched.h>
#include <signal.h>
#include <unistd.h>

/* Define a 1MB stack for clone */
#define STACK_SIZE (1024 * 1024)
static char container_stack[STACK_SIZE];

char* const container_args[] = {
    "/bin/bash",
    NULL
};

int container_main(void* arg)
{
    printf("Container - inside the container!\n");
    /* Execute a shell to observe whether resources are isolated */
    execv(container_args[0], container_args);
    printf("Something's wrong!\n");
    return 1;
}

int main()
{
    printf("Parent - start a container!\n");
    /* Call clone with a function and stack space (tail pointer because the stack grows downward) */
    int container_pid = clone(container_main, container_stack+STACK_SIZE, SIGCHLD, NULL);
    /* Wait for child process to finish */
    waitpid(container_pid, NULL, 0);
    printf("Parent - container stopped!\n");
    return 0;
}
```

Compile and run to verify

```bash
$ gcc -o ns ns.c
$ ./ns
Parent - start a container!
Container - inside the container!

$ ls /tmp
```

#### UTS Namespace

```bash
int container_main(void* arg)
{
    printf("Container - inside the container!\n");
    sethostname("container",10); /* set hostname */
    execv(container_args[0], container_args);
    printf("Something's wrong!\n");
    return 1;
}

int main()
{
    printf("Parent - start a container!\n");
    int container_pid = clone(container_main, container_stack+STACK_SIZE,
            CLONE_NEWUTS | SIGCHLD, NULL); /* Enable CLONE_NEWUTS Namespace isolation */
    waitpid(container_pid, NULL, 0);
    printf("Parent - container stopped!\n");
    return 0;
}
```

After running the program, the child process hostname becomes container

```bash
ubuntu@ubuntu:~$ sudo ./uts
Parent - start a container!
Container - inside the container!
root@container:~# hostname
container
root@container:~# uname -n
container
```

#### IPC Namespace

IPC (Inter-Process Communication) is a communication method between processes in Unix/Linux, including shared memory, semaphores, and message queues. To achieve isolation, IPC must be isolated so that only processes within the same Namespace can communicate. IPC requires a global ID, and Namespace must isolate this ID from other Namespaces.

To enable IPC isolation, add the CLONE_NEWIPC flag when calling clone

```c
int container_pid = clone(container_main, container_stack+STACK_SIZE,
            CLONE_NEWUTS | CLONE_NEWIPC | SIGCHLD, NULL);
```

First create an IPC Queue with global Queue ID 0

```bash
ubuntu@ubuntu:~$ ipcmk -Q
Message queue id: 0

ubuntu@ubuntu:~$ ipcs -q
------ Message Queues --------
key        msqid      owner      perms      used-bytes   messages
0xd0d56eb2 0          ubuntu      644        0            0
```

Run the program to verify IPC Queue isolation

```bash
# Without CLONE_NEWIPC, the child process can still see the global IPC Queue
ubuntu@ubuntu:~$ sudo ./uts
Parent - start a container!
Container - inside the container!

root@container:~# ipcs -q
------ Message Queues --------
key        msqid      owner      perms      used-bytes   messages
0xd0d56eb2 0          ubuntu      644        0            0

# With CLONE_NEWIPC enabled, IPC is now isolated
root@ubuntu:~$ ./ipc
Parent - start a container!
Container - inside the container!

root@container:~/linux_namespace# ipcs -q

------ Message Queues --------
key        msqid      owner      perms      used-bytes   messages
```

#### PID Namespace

```c
int container_main(void* arg)
{
    /* Check the child process PID - it will output pid 1 */
    printf("Container [%5d] - inside the container!\n", getpid());
    sethostname("container",10);
    execv(container_args[0], container_args);
    printf("Something's wrong!\n");
    return 1;
}

int main()
{
    printf("Parent [%5d] - start a container!\n", getpid());
    /* Enable PID namespace - CLONE_NEWPID */
    int container_pid = clone(container_main, container_stack+STACK_SIZE,
            CLONE_NEWUTS | CLONE_NEWPID | SIGCHLD, NULL);
    waitpid(container_pid, NULL, 0);
    printf("Parent - container stopped!\n");
    return 0;
}
```

Run the program to verify

```bash
ubuntu@ubuntu:~$ sudo ./pid
Parent [ 3474] - start a container!
Container [ 1] - inside the container!
root@container:~# echo $$
1
```

Role of PID 1: The process with PID 1 is init, which has a special role. As the parent of all processes, it has many privileges (e.g., signal masking) and monitors all process states. If a child process is orphaned (parent didn't wait for it), init reclaims resources and terminates it. To achieve process space isolation, we need to create a process with PID 1, ideally making the child process PID appear as 1 inside the container.

However, running ps, top, etc. in the child shell still shows all processes, indicating incomplete isolation. This is because commands like ps and top read from the /proc filesystem, which is shared between parent and child processes. **Therefore, filesystem isolation is also needed.**

#### Mount Namespace

Enable mount namespace and remount /proc filesystem in the child process

```c
int container_main(void* arg)
{
    printf("Container [%5d] - inside the container!\n", getpid());
    sethostname("container",10);
    /* Remount proc filesystem to /proc */
    //option1
    //mount("none", "/tmp", "tmpfs", 0, "");
    //option2
    system("mount -t proc proc /proc");
    execv(container_args[0], container_args);
    printf("Something's wrong!\n");
    return 1;
}

int main()
{
    printf("Parent [%5d] - start a container!\n", getpid());
    /* Enable Mount Namespace - add CLONE_NEWNS flag */
    int container_pid = clone(container_main, container_stack+STACK_SIZE,
            CLONE_NEWUTS | CLONE_NEWPID | CLONE_NEWNS | SIGCHLD, NULL);
    waitpid(container_pid, NULL, 0);
    printf("Parent - container stopped!\n");
    return 0;
}
```

Run the program to verify

```bash
ubuntu@ubuntu:~$ sudo ./pid.mnt
Parent [ 3502] - start a container!
Container [    1] - inside the container!

root@container:~# ps -elf
F S UID        PID  PPID  C PRI  NI ADDR SZ WCHAN  STIME TTY          TIME CMD
4 S root         1     0  0  80   0 -  6917 wait   19:55 pts/2    00:00:00 /bin/bash
0 R root        14     1  0  80   0 -  5671 -      19:56 pts/2    00:00:00 ps -elf

root@container:~# ls /proc
...
root@container:~# top
...
```

#### User Namespace

User Namespace uses the CLONE_NEWUSER flag. After enabling it, the internal UID and GID differ from external ones, defaulting to 65534 because the container cannot find its real UID and falls back to the maximum UID (defined in /proc/sys/kernel/overflowuid).

To map container UIDs to real system UIDs, modify /proc/pid/uid_map and /proc/pid/gid_map. The format of these files is:

```bash
ID-inside-ns ID-outside-ns length
```

Where:

- The first field ID-inside-ns represents the UID or GID displayed inside the container,
- The second field ID-outside-ns represents the real UID or GID mapped outside the container.
- The third field represents the mapping range, typically 1 for one-to-one mapping.
  For example, mapping real uid=1000 to container uid=0

```bash
$ cat /proc/2465/uid_map
         0       1000          1
```

Another example: mapping uid starting from 0 inside the namespace to uid starting from 0 outside, with the maximum range of unsigned 32-bit integer

```bash
$ cat /proc/$$/uid_map
         0          0          4294967295
```

Notes:

- The process writing these files needs CAP_SETUID (CAP_SETGID) capability in this namespace (see [Capabilities](http://man7.org/linux/man-pages/man7/capabilities.7.html))
- The writing process must be in a parent or child user namespace of this user namespace.
- Additionally, one of the following conditions must be met: 1) The parent maps its effective uid/gid to the child user namespace, 2) If the parent has CAP_SETUID/CAP_SETGID, it can map to any uid/gid in the parent process.

```c
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/mount.h>
#include <sys/capability.h>
#include <stdio.h>
#include <sched.h>
#include <signal.h>
#include <unistd.h>

#define STACK_SIZE (1024 * 1024)

static char container_stack[STACK_SIZE];
char* const container_args[] = {
    "/bin/bash",
    NULL
};

int pipefd[2];

void set_map(char* file, int inside_id, int outside_id, int len) {
    FILE* mapfd = fopen(file, "w");
    if (NULL == mapfd) {
        perror("open file error");
        return;
    }
    fprintf(mapfd, "%d %d %d", inside_id, outside_id, len);
    fclose(mapfd);
}

void set_uid_map(pid_t pid, int inside_id, int outside_id, int len) {
    char file[256];
    sprintf(file, "/proc/%d/uid_map", pid);
    set_map(file, inside_id, outside_id, len);
}

void set_gid_map(pid_t pid, int inside_id, int outside_id, int len) {
    char file[256];
    sprintf(file, "/proc/%d/gid_map", pid);
    set_map(file, inside_id, outside_id, len);
}

int container_main(void* arg)
{

    printf("Container [%5d] - inside the container!\n", getpid());

    printf("Container: eUID = %ld;  eGID = %ld, UID=%ld, GID=%ld\n",
            (long) geteuid(), (long) getegid(), (long) getuid(), (long) getgid());

    /* Wait for parent process notification before proceeding (inter-process sync) */
    char ch;
    close(pipefd[1]);
    read(pipefd[0], &ch, 1);

    printf("Container [%5d] - setup hostname!\n", getpid());
    //set hostname
    sethostname("container",10);

    //remount "/proc" to make sure the "top" and "ps" show container's information
    mount("proc", "/proc", "proc", 0, NULL);

    execv(container_args[0], container_args);
    printf("Something's wrong!\n");
    return 1;
}

int main()
{
    const int gid=getgid(), uid=getuid();

    printf("Parent: eUID = %ld;  eGID = %ld, UID=%ld, GID=%ld\n",
            (long) geteuid(), (long) getegid(), (long) getuid(), (long) getgid());

    pipe(pipefd);

    printf("Parent [%5d] - start a container!\n", getpid());

    int container_pid = clone(container_main, container_stack+STACK_SIZE,
            CLONE_NEWUTS | CLONE_NEWPID | CLONE_NEWNS | CLONE_NEWUSER | SIGCHLD, NULL);


    printf("Parent [%5d] - Container [%5d]!\n", getpid(), container_pid);

    //To map the uid/gid,
    //   we need edit the /proc/PID/uid_map (or /proc/PID/gid_map) in parent
    //The file format is
    //   ID-inside-ns   ID-outside-ns   length
    //if no mapping,
    //   the uid will be taken from /proc/sys/kernel/overflowuid
    //   the gid will be taken from /proc/sys/kernel/overflowgid
    set_uid_map(container_pid, 0, uid, 1);
    set_gid_map(container_pid, 0, gid, 1);

    printf("Parent [%5d] - user/group mapping done!\n", getpid());

    /* Notify child process */
    close(pipefd[1]);

    waitpid(container_pid, NULL, 0);
    printf("Parent - container stopped!\n");
    return 0;
}
```

The program above uses a pipe to synchronize parent and child processes. This is necessary because the child process calls execv, which replaces the entire process space. We need to complete the user namespace uid/gid mapping before execv, so that /bin/bash launched by execv will show the # prompt due to the inside-uid being set to 0.

Run the program

```bash
ubuntu@ubuntu:~$ id
uid=1000(ubuntu) gid=1000(ubuntu) groups=1000(ubuntu)

ubuntu@ubuntu:~$ ./user #<-- run as ubuntu user
Parent: eUID = 1000;  eGID = 1000, UID=1000, GID=1000
Parent [ 3262] - start a container!
Parent [ 3262] - Container [ 3263]!
Parent [ 3262] - user/group mapping done!
Container [    1] - inside the container!
Container: eUID = 0;  eGID = 0, UID=0, GID=0 #<--- UID/GID inside container are now 0
Container [    1] - setup hostname!

root@container:~# id #<---- user and prompt inside container are now root
uid=0(root) gid=0(root) groups=0(root),65534(nogroup)
```

Although the container shows root, the /bin/bash process actually runs as a regular ubuntu user, improving container security.
User Namespace runs as a regular user, but other Namespaces require root privileges. To use multiple Namespaces simultaneously, first create a User Namespace as a regular user, map that user to root, then create other Namespaces as root inside the container.

#### Network Namespace

Network Namespaces are typically created using the ip command.
Note: The host may be a VM, and the physical NIC may be a virtual NIC capable of routing IPs.
<!-- Image removed: Pasted image 20240213223106.png (file not found) -->

In a Docker container, use ip link show or ip addr show to view the host network

```bash
ubuntu@ubuntu:~$ ip link show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state ...
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc ...
    link/ether 00:0c:29:b7:67:7d brd ff:ff:ff:ff:ff:ff
3: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 ...
    link/ether 56:84:7a:fe:97:99 brd ff:ff:ff:ff:ff:ff
5: veth22a38e6: <BROADCAST,UP,LOWER_UP> mtu 1500 qdisc ...
    link/ether 8e:30:2a:ac:8c:d1 brd ff:ff:ff:ff:ff:ff
```

How to simulate the above scenario:

```bash
## First, add a bridge lxcbr0, simulating docker0
brctl addbr lxcbr0
brctl stp lxcbr0 off
ifconfig lxcbr0 192.168.10.1/24 up # assign IP address to bridge

## Next, create a network namespace - ns1

# Add a namespace named ns1 (using ip netns add)
ip netns add ns1

# Activate the loopback (127.0.0.1) in the namespace (using ip netns exec ns1)
ip netns exec ns1   ip link set dev lo up

## Then, add a pair of virtual network interfaces

# Add a veth pair; one end will be placed inside the container
ip link add veth-ns1 type veth peer name lxcbr0.1

# Move veth-ns1 into namespace ns1, giving the container a new NIC
ip link set veth-ns1 netns ns1

# Rename veth-ns1 to eth0 inside the container (avoids name conflict)
ip netns exec ns1  ip link set dev veth-ns1 name eth0

# Assign an IP address to the container NIC and activate it
ip netns exec ns1 ifconfig eth0 192.168.10.11/24 up


# Add lxcbr0.1 to the bridge
brctl addif lxcbr0 lxcbr0.1

# Add a route rule so the container can access external networks
ip netns exec ns1     ip route add default via 192.168.10.1

# Create a directory for network namespace ns1 under /etc/netns,
# then set resolv.conf for this namespace, enabling DNS resolution inside the container
mkdir -p /etc/netns/ns1
echo "nameserver 8.8.8.8" > /etc/netns/ns1/resolv.conf
```

Docker networking differs from the above in two ways:

- Docker resolv.conf uses [Mount Namespace](#mount-namespace) instead of the above method
- Docker uses the process PID as the Network Namespace name.

Add a new NIC to a running Docker container, e.g., add an eth1 NIC with a static externally-accessible IP address.

```bash
ip link add peerA type veth peer name peerB
brctl addif docker0 peerA
ip link set peerA up
ip link set peerB netns ${container-pid}
ip netns exec ${container-pid} ip link set dev peerB name eth1
ip netns exec ${container-pid} ip link set eth1 up ;
ip netns exec ${container-pid} ip addr add ${ROUTEABLE_IP} dev eth1 ;
```

The external "physical NIC" must be set to promiscuous mode so that eth1 can broadcast its MAC address via ARP. The external switch then forwards packets for this IP to the "physical NIC". In promiscuous mode, eth1 receives the relevant data, enabling Docker container network connectivity with the external network.

### Linux Cgroup

Linux CGroup (Linux Control Group) is a Linux kernel feature for limiting, controlling, and isolating resource usage (CPU, memory, disk I/O, etc.) of process groups.

Linux CGroup allows you to allocate resources — such as CPU time, system memory, network bandwidth, or combinations thereof — to user-defined groups of tasks (processes). You can monitor configured cgroups, deny cgroups access to certain resources, and dynamically reconfigure cgroups on a running system.
Main features:

- **Resource limitation**: Limit resource usage, such as memory caps and filesystem cache limits.
- **Prioritization**: Priority control for CPU utilization and disk I/O throughput.
- **Accounting**: Auditing and statistics, primarily for billing purposes.
- **Control**: Suspend and resume processes.

Using cgroups, system administrators can more precisely control the allocation, prioritization, denial, management, and monitoring of system resources, improving overall efficiency by better distributing hardware resources based on tasks and users.

- Isolate a set of processes (e.g., all nginx processes) and limit their resource consumption, such as CPU core binding.
- Allocate sufficient memory for the process group
- Allocate appropriate network bandwidth and disk storage limits for the process group
- Restrict access to certain devices (via device whitelisting)

View cgroup mount in Ubuntu

```bash
ubuntu@ubuntu:~$ mount -t cgroup
cgroup on /sys/fs/cgroup/cpuset type cgroup (rw,relatime,cpuset)
cgroup on /sys/fs/cgroup/cpu type cgroup (rw,relatime,cpu)
cgroup on /sys/fs/cgroup/cpuacct type cgroup (rw,relatime,cpuacct)
cgroup on /sys/fs/cgroup/memory type cgroup (rw,relatime,memory)
cgroup on /sys/fs/cgroup/devices type cgroup (rw,relatime,devices)
cgroup on /sys/fs/cgroup/freezer type cgroup (rw,relatime,freezer)
cgroup on /sys/fs/cgroup/blkio type cgroup (rw,relatime,blkio)
cgroup on /sys/fs/cgroup/net_prio type cgroup (rw,net_prio)
cgroup on /sys/fs/cgroup/net_cls type cgroup (rw,net_cls)
cgroup on /sys/fs/cgroup/perf_event type cgroup (rw,relatime,perf_event)
cgroup on /sys/fs/cgroup/hugetlb type cgroup (rw,relatime,hugetlb)
```

Or use the lssubsys command

```bash
$ lssubsys  -m
cpuset /sys/fs/cgroup/cpuset
cpu /sys/fs/cgroup/cpu
cpuacct /sys/fs/cgroup/cpuacct
memory /sys/fs/cgroup/memory
devices /sys/fs/cgroup/devices
freezer /sys/fs/cgroup/freezer
blkio /sys/fs/cgroup/blkio
net_cls /sys/fs/cgroup/net_cls
net_prio /sys/fs/cgroup/net_prio
perf_event /sys/fs/cgroup/perf_event
hugetlb /sys/fs/cgroup/hugetlb
```

If not available, mount manually

```bash
mkdir cgroup
mount -t tmpfs cgroup_root ./cgroup
mkdir cgroup/cpuset
mount -t cgroup -ocpuset cpuset ./cgroup/cpuset/
mkdir cgroup/cpu
mount -t cgroup -ocpu cpu ./cgroup/cpu/
mkdir cgroup/memory
mount -t cgroup -omemory memory ./cgroup/memory/

# After successful mount, cpu and cpuset subsystems are visible
ubuntu@ubuntu:~$ ls /sys/fs/cgroup/cpu /sys/fs/cgroup/cpuset/
/sys/fs/cgroup/cpu:
cgroup.clone_children  cgroup.sane_behavior  cpu.shares         release_agent
cgroup.event_control   cpu.cfs_period_us     cpu.stat           tasks
cgroup.procs           cpu.cfs_quota_us      notify_on_release  user

/sys/fs/cgroup/cpuset/:
cgroup.clone_children  cpuset.mem_hardwall             cpuset.sched_load_balance
cgroup.event_control   cpuset.memory_migrate           cpuset.sched_relax_domain_level
cgroup.procs           cpuset.memory_pressure          notify_on_release
cgroup.sane_behavior   cpuset.memory_pressure_enabled  release_agent
cpuset.cpu_exclusive   cpuset.memory_spread_page       tasks
cpuset.cpus            cpuset.memory_spread_slab       user
cpuset.mem_exclusive   cpuset.mems
```

Create directories under /sys/fs/cgroup subdirectories

```bash
ubuntu@ubuntu:/sys/fs/cgroup/cpu$ sudo mkdir testdir

ubuntu@ubuntu:/sys/fs/cgroup/cpu$ ls ./testdir
cgroup.clone_children  cgroup.procs       cpu.cfs_quota_us  cpu.stat           tasks
cgroup.event_control   cpu.cfs_period_us  cpu.shares        notify_on_release
```

#### CPU Limit

Simulate a CPU-intensive program

```bash
tee > deadloop.c << "EOF"
int main(void)
{
    int i = 0;
    for(;;) i++;
    return 0;
}
EOF

gcc deadloop.c -o deadlooop
./deadloop
```

Limit CPU for a custom cgroup

```bash
ubuntu@ubuntu:~# cat /sys/fs/cgroup/cpu/testdir/cpu.cfs_quota_us
-1
# 20% CPU usage
root@ubuntu:~# echo 20000 > /sys/fs/cgroup/cpu/testdir/cpu.cfs_quota_us

# Get the pid of the above program and add it to this cgroup
ps -ef |grep deadloop
echo [pid] >> /sys/fs/cgroup/cpu/testdir/tasks
```

Thread code example

```c
#define _GNU_SOURCE         /* See feature_test_macros(7) */

#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/syscall.h>


const int NUM_THREADS = 5;

void *thread_main(void *threadid)
{
    /* Add self to cgroup (syscall(SYS_gettid) gets the thread system tid) */
    char cmd[128];
    sprintf(cmd, "echo %ld >> /sys/fs/cgroup/cpu/haoel/tasks", syscall(SYS_gettid));
    system(cmd);
    sprintf(cmd, "echo %ld >> /sys/fs/cgroup/cpuset/haoel/tasks", syscall(SYS_gettid));
    system(cmd);

    long tid;
    tid = (long)threadid;
    printf("Hello World! It's me, thread #%ld, pid #%ld!\n", tid, syscall(SYS_gettid));

    int a=0;
    while(1) {
        a++;
    }
    pthread_exit(NULL);
}
int main (int argc, char *argv[])
{
    int num_threads;
    if (argc > 1){
        num_threads = atoi(argv[1]);
    }
    if (num_threads<=0 || num_threads>=100){
        num_threads = NUM_THREADS;
    }

    /* Set CPU utilization to 50% */
    mkdir("/sys/fs/cgroup/cpu/haoel", 755);
    system("echo 50000 > /sys/fs/cgroup/cpu/haoel/cpu.cfs_quota_us");

    mkdir("/sys/fs/cgroup/cpuset/haoel", 755);
    /* Limit CPU to cores #2 and #3 only */
    system("echo \"2,3\" > /sys/fs/cgroup/cpuset/haoel/cpuset.cpus");

    pthread_t* threads = (pthread_t*) malloc (sizeof(pthread_t)*num_threads);
    int rc;
    long t;
    for(t=0; t<num_threads; t++){
        printf("In main: creating thread %ld\n", t);
        rc = pthread_create(&threads[t], NULL, thread_main, (void *)t);
        if (rc){
            printf("ERROR; return code from pthread_create() is %d\n", rc);
            exit(-1);
        }
    }

    /* Last thing that main() should do */
    pthread_exit(NULL);
    free(threads);
}
```

#### Memory Limit

Simulate a memory-intensive program (allocating 512 bytes each time, sleeping 1 second between allocations)

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>

int main(void)
{
    int size = 0;
    int chunk_size = 512;
    void *p = NULL;

    while(1) {

        if ((p = malloc(p, chunk_size)) == NULL) {
            printf("out of memory!!\n");
            break;
        }
        memset(p, 1, chunk_size);
        size += chunk_size;
        printf("[%d] - memory is allocated [%8d] bytes \n", getpid(), size);
        sleep(1);
    }
    return 0;
}
```

Limit memory

```bash
# Create a memory cgroup
$ mkdir /sys/fs/cgroup/memory/testdir
$ echo 64k > /sys/fs/cgroup/memory/testdir/memory.limit_in_bytes

# Add the pid of the above process to this cgroup
$ echo [pid] > /sys/fs/cgroup/memory/haoel/tasks
```

#### IO Limit

Test simulated I/O speed

```bash
# dd command for read/write I/O
dd if=/dev/sda1 of=/dev/null

# Check I/O speed
iotop
  TID  PRIO  USER     DISK READ  DISK WRITE  SWAPIN     IO>    COMMAND
 8128 be/4 root       55.74 M/s    0.00 B/s  0.00 % 85.65 % dd if=/de~=/dev/null...
```

Create a blkio (block device I/O) cgroup

```bash
mkdir /sys/fs/cgroup/blkio/testdir
```

Limit process I/O speed

```bash
# Note: 8:0 is the device number, obtained via ls -l /dev/sda1
root@ubuntu:~# echo '8:0 1048576'  > /sys/fs/cgroup/blkio/testdir/blkio.throttle.read_bps_device
# Add the dd command pid to the cgroup
root@ubuntu:~# echo [pid] > /sys/fs/cgroup/blkio/testdir/tasks

# Check I/O speed
iotop
  TID  PRIO  USER     DISK READ  DISK WRITE  SWAPIN     IO>    COMMAND
 8128 be/4 root      973.20 K/s    0.00 B/s  0.00 % 94.41 % dd if=/de~=/dev/null...
```

#### Cgroup Subsystem

- blkio — Sets I/O limits for block devices such as physical devices (disk, SSD, USB, etc.).
- cpu — Uses the scheduler to provide cgroup task access to CPU.
- cpuacct — Generates automatic reports on CPU usage by tasks in a cgroup.
- cpuset — Assigns dedicated CPUs (on multi-core systems) and memory nodes to cgroup tasks.
- devices — Allows or denies access to devices for tasks in a cgroup.
- freezer — Suspends or resumes tasks in a cgroup.
- memory — Sets memory limits for tasks in a cgroup and generates memory usage reports.
- net_cls — Tags network packets with a class identifier (classid), allowing the Linux traffic controller (tc) to identify packets from specific cgroups.
- net_prio — Sets network traffic priority
- hugetlb — Limits HugeTLB (huge page filesystem) usage.

#### Cgroup Terminology

- **Tasks**: A system process.
- **Control Group**: A group of processes classified by certain criteria. Resource control in cgroups is implemented per control group. A process can join a control group, and resource limits are defined on the group. Simply put, a cgroup is represented as a directory with a set of configurable files.
- **Hierarchy**: Control groups can be organized hierarchically as a tree (directory structure). Child nodes inherit attributes from parent nodes. Simply put, a hierarchy is a cgroups directory tree on one or more subsystems.
- **Subsystem**: A resource controller, e.g., the CPU subsystem controls CPU time allocation. A subsystem must be attached to a hierarchy to take effect. Once attached, all control groups in that hierarchy are governed by the subsystem.

## Docker Engine

### Install

```bash
# install docker engine
https://docs.docker.com/engine/install/debian/

```

### Storage

#### Overview

```bash
# show docker volume info
docker volume ls
DRIVER    VOLUME NAME
local     jenkins_home
local     test-volume


# how to use
# default volume, directory = /var/lib/docker/volumes/
-v test-volume:/container-app/my-app
--volume test-volume:/container-app/my-app
--mount
# bind mounts
-v /local_path/app.conf:/container-app/app.conf
--volume /local_path/app.conf:/container-app/app.conf
--mount
# memory volume
--tmpfs

```

#### Volumes

```bash
# create volume
docker volume create test-volume


# start container with volume
docker run -d --name test \
###
# option1
-v test-volume:/app \
--volume test-volume:/app \
# anonymous mode
--volume /app
# option2
--mount source=test-volume,target=/app \
# readonly mode
--mount source=test-volume,destination=/usr/share/nginx/html,readonly \
--mount 'type=volume,source=nfsvolume,target=/app,volume-driver=local,volume-opt=type=nfs,volume-opt=device=:/var/docker-nfs,volume-opt=o=addr=10.0.0.10' \
###
nginx:latest


# use a volume with docker-ompose
services:
  frontend:
    image: node:lts
    volumes:
      - test-volume:/home/node/app
volumes:
  test-volume:
     # external: true


# show and remove volume
docker inspect volume test-volume
docker stop test
docker volume rm test-volume

```

#### Bind mounts

```bash
# start container with bind mounts
docker run -d --name test \
###
# option1
-v /opt/app.conf:/app/app.conf \
# option2
--mount type=bind,source="$(pwd)"/target,target=/app/ \
--mount type=bind,source="$(pwd)"/target,target=/app/,readonly \
# bind propagation
--mount type=bind,source="$(pwd)"/target,target=/app2,readonly,bind-propagation=rslave \
###
nginx:latest


# use bind mounts with docker-compose
services:
  frontend:
    image: node:lts
    volumes:
      - type: bind
        source: ./static
        target: /opt/app/static
volumes:
  myapp:


# show and remove container
docker inspect test --format '{{ json .Mounts }}'
docker stop test
docker rm test

```

#### tmpfs mounts

```bash
# start container with tmpfs
docker run -it --name tmptest \
###
# option1
--tmpfs /app
# option2
--mount type=tmpfs,target=/app \
# specify tmpfs options
--mount type=tmpfs,destination=/app,tmpfs-mode=1770,tmpfs-size=104857600 \
###
nginx:latest


# show and remove container
docker inspect tmptest --format '{{ json .Mounts }}'
docker stop tmptest
docker rm tmptest

```

#### Storage drivers

##### Btrfs

```bash
# stop docker
systemctl stop docker.service

# backup and empty contents
cp -au /var/lib/docker/ /var/lib/docker.bk
rm -rf /var/lib/docker/*

# format block device as a btrfs filesystem
mkfs.btrfs -f /dev/xvdf

# mount the btrfs filesystem on /var/lib/docker mount point
mount -t btrfs /dev/xvdf /var/lib/docker
cp -au /var/lib/docker.bk/* /var/lib/docker/

# configure Docker to use the btrfs storage driver
vim /etc/docker/daemon.json
{
  "storage-driver": "btrfs"
}
systemctl start docker.service

# verify
docker info --format '{{ json .Driver }}'
"btrfs"
```

##### OverlayFS

```bash
# stop docker
systemctl stop docker.service

# backup and empty contents
cp -au /var/lib/docker/ /var/lib/docker.bk
rm -rf /var/lib/docker/*

# options: separate backing filesystem, mount into /var/lib/docker and make sure to add mount to /etc/fstab to make it.

# configure Docker to use the btrfs storage driver
vim /etc/docker/daemon.json
{
  "storage-driver": "overlay2"
}
systemctl start docker.service

# verify
docker info --format '{{ json .Driver }}'
"overlay2"
mount |grep overlay |grep docker
```

##### ZFS

```bash
# stop docker
systemctl stop docker.service

# backup and empty contents
cp -auR /var/lib/docker/ /var/lib/docker.bk
rm -rf /var/lib/docker/*

# create a new zpool on block device and mount into /var/lib/docker
zpool create -f zpool-docker -m /var/lib/docker /dev/xvdf
# add zpoll
zpool add zpool-docker /dev/xvdh
# verify zpool
zfs list
NAME           USED  AVAIL  REFER  MOUNTPOINT
zpool-docker    55K  96.4G    19K  /var/lib/docker

# configure Docker to use the btrfs storage driver
vim /etc/docker/daemon.json
{
  "storage-driver": "zfs"
}
systemctl start docker.service

# verify
docker info --format '{{ json .Driver }}'
"zfs"
```

##### containerd snapshotters

```bash
# configure Docker to use the btrfs storage driver
vim /etc/docker/daemon.json
{
  "features": {
    "containerd-snapshotter": true
  }
}
systemctl restart docker.service

# verify
docker info -f '{{ .DriverStatus }}'
[[driver-type io.containerd.snapshotter.v1]]

```

### Networking

#### Overview

```bash
# show docker network info
docker network ls
NETWORK ID     NAME      DRIVER    SCOPE
b2adc1fcf214   bridge    bridge    local
2ed9fbc8db3e   host      host      local
f1b2d749ed2c   none      null      local

# how to use
# bridge
--net bridge
# host
--net host
# none
--net none
# container
--net container:container_name|container_id

```

#### Networking drivers

##### Bridge

```bash
# bridge
Each container has its own network stack with individual IP assignment. Containers are connected to a virtual bridge (default: docker0).

# 1. Create a container namespace on the host
xxx

# 2. The daemon creates a veth pair on the host. Traffic from one end flows to the other.
# One interface is placed on the docker0 bridge and named vethxxx
# View bridge info
brctl show
bridge name     bridge id               STP enabled     interfaces
docker0         8000.0242db01d347       no              vethccab668
# View host vethxxx interface
ip addr |grep vethccab668
# The other interface is placed in the container namespace and named eth0
docker run --rm -dit busybox sh ip addr

# 3. The daemon assigns an IP address and subnet from docker0's private address space and sets docker0 IP as the default gateway
docker inspect test |grep Gateway
            "Gateway": "172.17.0.1",

```

##### Overlay

```bash
# Multi-host networking, used with docker swarm
```

##### Host

```bash
# host
Uses the host IP and ports, sharing the host network stack.

# test
docker run --rm -dit --net host busybox ip addr
```

##### IPvlan

```bash
# ipvlan
ipvlan_mode: l2, l3(default), l3s
ipvlan_flag: bridge(default), private, vepa
parent: eth0

# l2 mode: uses host network segment
docker network create -d ipvlan \
     --subnet=192.168.1.0/24 \
     --gateway=192.168.1.1 \
     -o ipvlan_mode=l2 \
     -o parent=eth0 test_l2_net
# test
docker run --net=test_l2_net --name=ipv1 -dit alpine /bin/sh
docker run --net=test_l2_net --name=ipv2 -it --rm alpine /bin/sh
ping -c 4 ipv1

# l3 mode
docker network create -d ipvlan \
     --subnet=192.168.1.0/24 \
     --subnet=10.10.1.0/24 \
     -o ipvlan_mode=l3 test_l3_net
# test
docker run --net=test_l3_net --ip=192.168.1.10 -dit busybox /bin/sh
docker run --net=test_l3_net --ip=10.10.1.10 -dit busybox /bin/sh

docker run --net=test_l3_net --ip=192.168.1.9 -it --rm busybox ping -c 2 10.10.1.10
docker run --net=test_l3_net --ip=10.10.1.9 -it --rm busybox ping -c 2 192.168.1.10

```

##### Macvlan

```bash
# macvlan

# bridge mode
docker network create -d macvlan \
  --subnet=172.16.86.0/24 \
  --gateway=172.16.86.1 \
  -o parent=eth0 pub_net


# 802.1Q trunk bridge mode
docker network create -d macvlan \
    --subnet=192.168.50.0/24 \
    --gateway=192.168.50.1 \
    -o parent=eth0.50 macvlan50

docker network create -d macvlan \
    --subnet=192.168.60.0/24 \
    --gateway=192.168.60.1 \
    -o parent=eth0.60 macvlan60

# https://zhuanlan.zhihu.com/p/616504632
```

##### None

```bash
# none
Each container has its own network stack but without network configuration such as veth pair and bridge connections.

# verify
docker run --rm -dit --net none busybox ip addr
```

##### Container

```bash
# container
Shares the network stack with a specified existing container, using the same IP, ports, etc.

# verify
docker run -dit --name test --rm busybox sh
docker run -it --name c1 --net container:test --rm busybox ip addr
docker run -it --name c2 --net container:test --rm busybox ip addr
```

##### Custom Network Mode

```bash
# user-defined
The default docker0 bridge cannot communicate via container name. Custom networks use the daemon embedded DNS server, allowing direct communication via --name specified container names.

# Create a custom network
docker network create test-network
# View new virtual NIC on the host
ip addr
    inet 172.19.0.1/16 brd 172.19.255.255 scope global br-8cb8260a95cf
brctl show
br-8cb8260a95cf         8000.024272aa9d38       no              veth556b81b
# verify
docker run -dit --name test1 --net test-network --rm busybox sh
docker run -it --name test2 --net test-network --rm busybox ping -c 4 test1

# Connect to an existing network
docker run -dit --name test3 --net test-network --rm busybox sh
docker network connect test-network test3
docker exec -it test3 ip addr
531: eth0@if532: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
533: eth1@if534: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue
    link/ether 02:42:ac:13:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.19.0.2/16 brd 172.19.255.255 scope global eth1
       valid_lft forever preferred_lft forever

```

#### Daemon

```bash
# configuration file
/etc/docker/daemon.json
~/.config/docker/daemon.json
# configuration using flags
dockerd --debug \
  --tls=true \
  --tlscert=/var/docker/server.pem \
  --tlskey=/var/docker/serverkey.pem \
  --host tcp://192.168.10.1:2376


# default data directory
/var/lib/docker


# systemd
cat /lib/systemd/system/docker.service
```

### Docker Build

#### Build images

#### Multi-stage builds

Use multi-stage builds

```dockerfile
# syntax=docker/dockerfile:1
FROM golang:1.21
WORKDIR /src
COPY <<EOF ./main.go
package main

import "fmt"

func main() {
  fmt.Println("hello, world")
}
EOF
RUN go build -o /bin/hello ./main.go

FROM scratch
COPY --from=0 /bin/hello /bin/hello
CMD ["/bin/hello"]
```

Name build stages

```dockerfile
# syntax=docker/dockerfile:1
FROM golang:1.21 as build
WORKDIR /src
COPY <<EOF /src/main.go
package main

import "fmt"

func main() {
  fmt.Println("hello, world")
}
EOF
RUN go build -o /bin/hello ./main.go

FROM scratch
COPY --from=build /bin/hello /bin/hello
CMD ["/bin/hello"]
```

```bash
# build
docker built -t hello .

# stop at a specific build stage
docker build --target build -t hello .
```

### Dockerfile

#### Example

```dockerfile
# Dockerfile syntax
# syntax=docker/dockerfile:1

# Base image
FROM ubuntu:22.04

# install app dependencies
RUN apt-get update && apt-get install -y python3 python3-pip
RUN pip install flask==3.0.*

# install app
COPY hello.py /

# final configuration
ENV FLASK_APP=hello
EXPOSE 8000
CMD ["flask", "run", "--host", "0.0.0.0", "--port", "8000"]
```

#### others

```Dockerfile
""" Best Practices
1. Use a unified base image.
2. Separate static and dynamic layers (stable content at the bottom).
3. Minimize image size (only include what is necessary).
4. Single responsibility (one function per image, interact via network, modular management).
5. Use fewer layers and reduce content per layer.
6. Do not modify file permissions separately (combine with COPY or in entrypoint).
7. Leverage build cache to speed up builds.
8. Use version control and automated builds (store in git, automate image builds, document build args).
9. Use .dockerignore files (exclude files and directories).
"""

# ENTRYPOINT directive:
# exec form: directly starts the program process, pid=1
ENTRYPOINT ["node", "app.js"]
# shell form: forks a shell subprocess which then starts the program
ENTRYPOINT "node" "app.js"

# Pod template fields corresponding to Dockerfile
spec.contianers[n].command = ENTRYPOINT
spec.contianers[n].args = CMD
```

### Docker Compose

Archery Docker Compose

> Reference:
>
> 1. [Official Website](https://docs.docker.com/)
> 2. [Docker network-drivers](https://docs.docker.com/network/drivers/)
> 3. [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
> 4. [COOLSHELL-Docker Fundamentals: Linux NAMESPACE](https://coolshell.cn/articles/17010.html)
