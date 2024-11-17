---
description: Docker
---

# Docker

## Introduction
### Linux Namespace
#### 简介
Linux Namespace 是 Linux 提供的一种内核级别环境隔离的方法。Unix 中有一个叫chroot 的系统调用（通过修改根目录把用户 jai l到一个特定目录下），chroot 提供了一种简单的隔离模式：chroot 内部的文件系统无法访问外部的内容。Linux Namespace 在此基础上，提供了对 UTS、IPC、mount、PID、network、User 等的隔离机制。

Linux 下的超级父亲进程的 PID 是1，所以，同 chroot 一样，如果我们可以把用户的进程空间 jail 到某个进程分支下，并像 chroot 那样让其下面的进程 看到的那个超级父进程的 PID为1，于是就可以达到资源隔离的效果了（不同的 PID namespace 中的进程无法看到彼此）

主要是三个系统调用
- **`clone`****() – 实现线程的系统调用，用来创建一个新的进程，并可以通过设计上述参数达到隔离。
- **`unshare`****() – 使某进程脱离某个 namespace
- **`setns`****() – 把某进程加入到某个 namespace

[Linux Namespace 种类](https://lwn.net/Articles/531114/)

|分类|系统调用参数|相关内核版本|
|---|---|---|
|**Mount namespaces**|CLONE_NEWNS|[Linux 2.4.19](http://lwn.net/2001/0301/a/namespaces.php3)|
|**UTS namespaces**|CLONE_NEWUTS|[Linux 2.6.19](http://lwn.net/Articles/179345/)|
|**IPC namespaces**|CLONE_NEWIPC|[Linux 2.6.19](http://lwn.net/Articles/187274/)|
|**PID namespaces**|CLONE_NEWPID|[Linux 2.6.24](http://lwn.net/Articles/259217/)|
|**Network namespaces**|CLONE_NEWNET|[始于Linux 2.6.24 完成于 Linux 2.6.29](http://lwn.net/Articles/219794/)|
|**User namespaces**|CLONE_NEWUSER|[始于 Linux 2.6.23 完成于 Linux 3.8)](http://lwn.net/Articles/528078/)|

#### clone() 系统调用
```c
#define _GNU_SOURCE
#include <sys/types.h>
#include <sys/wait.h>
#include <stdio.h>
#include <sched.h>
#include <signal.h>
#include <unistd.h>

/* 定义一个给 clone 用的栈，栈大小1M */
#define STACK_SIZE (1024 * 1024)
static char container_stack[STACK_SIZE];

char* const container_args[] = {
    "/bin/bash",
    NULL
};

int container_main(void* arg)
{
    printf("Container - inside the container!\n");
    /* 直接执行一个shell，以便我们观察这个进程空间里的资源是否被隔离了 */
    execv(container_args[0], container_args); 
    printf("Something's wrong!\n");
    return 1;
}

int main()
{
    printf("Parent - start a container!\n");
    /* 调用clone函数，其中传出一个函数，还有一个栈空间的（为什么传尾指针，因为栈是反着的） */
    int container_pid = clone(container_main, container_stack+STACK_SIZE, SIGCHLD, NULL);
    /* 等待子进程结束 */
    waitpid(container_pid, NULL, 0);
    printf("Parent - container stopped!\n");
    return 0;
}
```
编译运行程序验证
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
    sethostname("container",10); /* 设置hostname */
    execv(container_args[0], container_args);
    printf("Something's wrong!\n");
    return 1;
}

int main()
{
    printf("Parent - start a container!\n");
    int container_pid = clone(container_main, container_stack+STACK_SIZE, 
            CLONE_NEWUTS | SIGCHLD, NULL); /*启用CLONE_NEWUTS Namespace隔离 */
    waitpid(container_pid, NULL, 0);
    printf("Parent - container stopped!\n");
    return 0;
}
```
运行程序，子进程的 hostname 变成了 container
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
IPC全称 Inter-Process Communication，是 Unix/Linux 下进程间通信的一种方式，IPC 有共享内存、信号量、消息队列等方法。所以为了隔离，需要把 IPC 给隔离开来，这样只有在同一个 Namespace 下的进程才能相互通信。IPC 需要有一个全局的 ID，Namespace 需要对这个 ID 隔离，不能让别的 Namespace 的进程看到。

启动 IPC 隔离,需要在调用 clone 时加上 CLONE_NEWIPC 参数
```c
int container_pid = clone(container_main, container_stack+STACK_SIZE, 
            CLONE_NEWUTS | CLONE_NEWIPC | SIGCHLD, NULL);
```
先创建一个 IPC 的 Queue,全局 Queue ID 是0
```bash
ubuntu@ubuntu:~$ ipcmk -Q 
Message queue id: 0

ubuntu@ubuntu:~$ ipcs -q
------ Message Queues --------
key        msqid      owner      perms      used-bytes   messages    
0xd0d56eb2 0          ubuntu      644        0            0
```
运行程序验证 IPC Queue 是否隔离
```bash
# 如果运行没有 CLONE_NEWIPC 的程序,在子进程中还是能看到这个全启的IPC Queue
ubuntu@ubuntu:~$ sudo ./uts 
Parent - start a container!
Container - inside the container!

root@container:~# ipcs -q
------ Message Queues --------
key        msqid      owner      perms      used-bytes   messages    
0xd0d56eb2 0          ubuntu      644        0            0

# 如果我们运行加上了 CLONE_NEWIPC 的程序，IPC 已被隔离
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
    /* 查看子进程的PID，我们可以看到其输出子进程的 pid 为 1 */
    printf("Container [%5d] - inside the container!\n", getpid());
    sethostname("container",10);
    execv(container_args[0], container_args);
    printf("Something's wrong!\n");
    return 1;
}

int main()
{
    printf("Parent [%5d] - start a container!\n", getpid());
    /*启用PID namespace - CLONE_NEWPID*/
    int container_pid = clone(container_main, container_stack+STACK_SIZE, 
            CLONE_NEWUTS | CLONE_NEWPID | SIGCHLD, NULL); 
    waitpid(container_pid, NULL, 0);
    printf("Parent - container stopped!\n");
    return 0;
}
```
运行程序验证
```bash
ubuntu@ubuntu:~$ sudo ./pid
Parent [ 3474] - start a container!
Container [ 1] - inside the container!
root@container:~# echo $$
1
```
PID 为1的作用: PID 为1的进程是 init，地位非常特殊。作为所有进程的父进程，有很多特权（比如：屏蔽信号等），还会为检查所有进程的状态.如果某个子进程脱离了父进程（父进程没有wait它），那么 init 就会负责回收资源并结束这个子进程，所以要做到进程空间的隔离，首先要创建出 PID 为1的进程，最好就像 chroot 那样，把子进程的PID在容器内变成1.

但是在子进程的 shell 里输入 ps,top 等命令，上述程序还是可以看得到所有进程。说明并没有完全隔离。这是因为，像 ps, top 这些命令会去读 /proc 文件系统，因为 /proc 文件系统在父进程和子进程都是一样的，所以这些命令显示的东西都是一样的。**因此,还需要对文件系统进行隔离.**

#### Mount Namespace
启用 mount namespace 并在子进程中重新 mount /proc 文件系统
```c
int container_main(void* arg)
{
    printf("Container [%5d] - inside the container!\n", getpid());
    sethostname("container",10);
    /* 重新mount proc文件系统到 /proc下 */
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
    /* 启用Mount Namespace - 增加CLONE_NEWNS参数 */
    int container_pid = clone(container_main, container_stack+STACK_SIZE, 
            CLONE_NEWUTS | CLONE_NEWPID | CLONE_NEWNS | SIGCHLD, NULL);
    waitpid(container_pid, NULL, 0);
    printf("Parent - container stopped!\n");
    return 0;
}
```
运行程序验证
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
User Namespace 主要是用了 CLONE_NEWUSER 的参数。使用了这个参数后，内部看到的  UID 和 GID 已经与外部不同了，默认显示为65534。那是因为容器找不到其真正的 UID,所以设置上了最大的 UID（其设置定义在 /proc/sys/kernel/overflowuid）。

要把容器中的 uid 和真实系统的 uid 给映射在一起，需要修改 /proc/pid/uid_map 和 /proc/pid/gid_map 这两个文件。这两个文件的格式为：
```bash
ID-inside-ns ID-outside-ns length
```
其中：
+ 第一个字段 ID-inside-ns 表示在容器显示的 UID 或 GID，
+ 第二个字段 ID-outside-ns 表示容器外映射的真实的 UID 或 GID。
+ 第三个字段表示映射的范围，一般填1，表示一一对应。
比如，把真实的 uid=1000映射成容器内的 uid=0
```bash
$ cat /proc/2465/uid_map
         0       1000          1
```
再比如下面的示例：表示把 namespace 内部从0开始的 uid 映射到外部从0开始的 uid，其最大范围是无符号32位整形
```bash
$ cat /proc/$$/uid_map
         0          0          4294967295
```

需要注意的是： 
- 写这两个文件的进程需要这个 namespace 中的 CAP_SETUID (CAP_SETGID)权限（可参看[Capabilities](http://man7.org/linux/man-pages/man7/capabilities.7.html)）
- 写入的进程必须是此 user namespace 的父或子的 user namespace 进程。
- 另外需要满如下条件之一：1）父进程将 effective uid/gid 映射到子进程的 user namespace 中，2）父进程如果有 CAP_SETUID/CAP_SETGID 权限，那么它将可以映射到父进程中的任一 uid/gid。

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

    /* 等待父进程通知后再往下执行（进程间的同步） */
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

    /* 通知子进程 */
    close(pipefd[1]);

    waitpid(container_pid, NULL, 0);
    printf("Parent - container stopped!\n");
    return 0;
}
```
上面的程序，用了一个 pipe 来对父子进程进行同步，为什么要这样做？因为子进程中有一个execv 的系统调用，这个系统调用会把当前子进程的进程空间给全部覆盖掉，我们希望在 execv 之前就做好 user namespace 的 uid/gid 的映射，这样，execv 运行的 /bin/bash 就会因为我们设置了 uid 为0的 inside-uid 而变成#号的提示符。

运行程序
```bash
ubuntu@ubuntu:~$ id
uid=1000(ubuntu) gid=1000(ubuntu) groups=1000(ubuntu)

ubuntu@ubuntu:~$ ./user #<--以 ubuntu 用户运行
Parent: eUID = 1000;  eGID = 1000, UID=1000, GID=1000 
Parent [ 3262] - start a container!
Parent [ 3262] - Container [ 3263]!
Parent [ 3262] - user/group mapping done!
Container [    1] - inside the container!
Container: eUID = 0;  eGID = 0, UID=0, GID=0 #<---Container里的UID/GID都为0了
Container [    1] - setup hostname!

root@container:~# id #<----我们可以看到容器里的用户和命令行提示符是root用户了
uid=0(root) gid=0(root) groups=0(root),65534(nogroup)
```
虽然容器内是 root 用户,但其实容器的 /bin/bash 进程是以一个普通用户 ubuntu 运行的,容器的安全性得到提高.
User Namespace 是以普通用户运行，但是别的 Namespace 需要 root 权限，那么，如果我要同时使用多个 Namespace 时，先用一般用户创建 User Namespace，然后把这个一般用户映射成 root，在容器内用 root 来创建其它的 Naemespace。

#### Network Namespace
一般用 ip 命令创建 Network Namespace.
注意: 宿主机可能是 VM 主机,物理网卡可能是一个可以路由 IP 的虚拟网卡.
![[Pasted image 20240213223106.png]]

docker 容器中,使用 ip link show 或 ip addr show 查看当前宿主机的网络情况
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

如何模拟以上情况:
```bash
## 首先，我们先增加一个网桥lxcbr0，模仿docker0
brctl addbr lxcbr0
brctl stp lxcbr0 off
ifconfig lxcbr0 192.168.10.1/24 up #为网桥设置IP地址

## 接下来，我们要创建一个network namespace - ns1

# 增加一个namesapce 命令为 ns1 （使用ip netns add命令）
ip netns add ns1 

# 激活namespace中的loopback，即127.0.0.1（使用ip netns exec ns1来操作ns1中的命令）
ip netns exec ns1   ip link set dev lo up 

## 然后，我们需要增加一对虚拟网卡

# 增加一个pair虚拟网卡，注意其中的veth类型，其中一个网卡要按进容器中
ip link add veth-ns1 type veth peer name lxcbr0.1

# 把 veth-ns1 按到namespace ns1中，这样容器中就会有一个新的网卡了
ip link set veth-ns1 netns ns1

# 把容器里的 veth-ns1改名为 eth0 （容器外会冲突，容器内就不会了）
ip netns exec ns1  ip link set dev veth-ns1 name eth0 

# 为容器中的网卡分配一个IP地址，并激活它
ip netns exec ns1 ifconfig eth0 192.168.10.11/24 up


# 上面我们把veth-ns1这个网卡按到了容器中，然后我们要把lxcbr0.1添加上网桥上
brctl addif lxcbr0 lxcbr0.1

# 为容器增加一个路由规则，让容器可以访问外面的网络
ip netns exec ns1     ip route add default via 192.168.10.1

# 在/etc/netns下创建network namespce名称为ns1的目录，
# 然后为这个namespace设置resolv.conf，这样，容器内就可以访问域名了
mkdir -p /etc/netns/ns1
echo "nameserver 8.8.8.8" > /etc/netns/ns1/resolv.conf
```
docker 网络原理与以上方式有两点区别:
- Docker 的 resolv.conf 没有用这样的方式，而是用了 [[Docker#Mount Namespace|Mount Namespace]]
- 另外，docker 是用进程的 PID 来做 Network Namespace 的名称的。

为运行的 docker 容器新增网卡,比如为正在运行的docker容器，增加一个 eth1的网卡，并给了一个静态的可被外部访问到的 IP 地址。
```bash
ip link add peerA type veth peer name peerB 
brctl addif docker0 peerA 
ip link set peerA up 
ip link set peerB netns ${container-pid} 
ip netns exec ${container-pid} ip link set dev peerB name eth1 
ip netns exec ${container-pid} ip link set eth1 up ; 
ip netns exec ${container-pid} ip addr add ${ROUTEABLE_IP} dev eth1 ;
```
需要把外部的“物理网卡”配置成混杂模式，这样这个 eth1 网卡就会向外通过 ARP 协议发送自己的 Mac 地址，然后外部的交换机就会把到这个 IP 地址的包转到“物理网卡”上，因为是混杂模式，所以 eth1就能收到相关的数据，一看包是发给自己的那么就收到。这样，Docker容器的网络就和外部通了。

### Linux Cgroup
Linux CGroup 全称 Linux Control Group， 是 Linux 内核的一个功能，用来限制、 控制与分离一个进程组群的资源（如 CPU、内存、磁盘输入输出等）。

Linux CGroupCgroup 可​​​让​​​您​​​为​​​系​​​统​​​中​​​所​​​运​​​行​​​任​​​务​​​（进​​​程​​​）的​​​用​​​户​​​定​​​义​​​组​​​群​​​分​​​配​​​资​​​源​​​ — 比​​​如​​​ CPU 时​​​间​​​、​​​系​​​统​​​内​​​存​​​、​​​网​​​络​​​带​​​宽​​​或​​​者​​​这​​​些​​​资​​​源​​​的​​​组​​​合​​​。​​​您​​​可​​​以​​​监​​​控​​​您​​​配​​​置​​​的​​​ cgroup，拒​​​绝​​​ cgroup 访​​​问​​​某​​​些​​​资​​​源​​​，甚​​​至​​​在​​​运​​​行​​​的​​​系​​​统​​​中​​​动​​​态​​​配​​​置​​​您​​​的​​​ cgroup。
主要提供以下功能:
- **Resource limitation**: 限制资源使用，比如内存使用上限以及文件系统的缓存限制。
- **Prioritization**: 优先级控制，比如：CPU 利用和磁盘 IO 吞吐。
- **Accounting**: 一些审计或一些统计，主要目的是为了计费。
- **Control**: 挂起进程，恢复执行进程。

使​​​用​​​ cgroup，系​​​统​​​管​​​理​​​员​​​可​​​更​​​具​​​体​​​地​​​控​​​制​​​对​​​系​​​统​​​资​​​源​​​的​​​分​​​配​​​、​​​优​​​先​​​顺​​​序​​​、​​​拒​​​绝​​​、​​​管​​​理​​​和​​​监​​​控​​​。​​​可​​​更​​​好​​​地​​​根​​​据​​​任​​​务​​​和​​​用​​​户​​​分​​​配​​​硬​​​件​​​资​​​源​​​，提​​​高​​​总​​​体​​​效​​​率​​​.
- 隔离一个进程集合（比如：nginx 的所有进程），并限制他们所消费的资源，比如绑定 CPU的核。
- 为这组进程分配其足够使用的内存
- 为这组进程分配相应的网络带宽和磁盘存储限制
- 限制访问某些设备（通过设置设备的白名单）

Ubuntu 中查看 cgroup mount
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
或者使用 lssubsys 命令
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

如果没有可自己 mount 
```bash
mkdir cgroup
mount -t tmpfs cgroup_root ./cgroup
mkdir cgroup/cpuset
mount -t cgroup -ocpuset cpuset ./cgroup/cpuset/
mkdir cgroup/cpu
mount -t cgroup -ocpu cpu ./cgroup/cpu/
mkdir cgroup/memory
mount -t cgroup -omemory memory ./cgroup/memory/

# mount 成功,可看到 cpu 和 cpuset 的子系统
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
在 /sys/fs/cgroup 各个子目录 make dir
```bash
ubuntu@ubuntu:/sys/fs/cgroup/cpu$ sudo mkdir yakir

ubuntu@ubuntu:/sys/fs/cgroup/cpu$ ls ./yakir
cgroup.clone_children  cgroup.procs       cpu.cfs_quota_us  cpu.stat           tasks
cgroup.event_control   cpu.cfs_period_us  cpu.shares        notify_on_release
```

#### CPU Limit
模拟非常吃 CPU 的程序
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
限制自定义 group 的 CPU
```bash
ubuntu@ubuntu:~# cat /sys/fs/cgroup/cpu/yakir/cpu.cfs_quota_us 
-1
# 20% CPU 使用率
root@ubuntu:~# echo 20000 > /sys/fs/cgroup/cpu/yakir/cpu.cfs_quota_us

# 查看上面程序的 pid,加入这个 cgroup 中
ps -ef |grep deadloop
echo [pid] >> /sys/fs/cgroup/cpu/yakir/tasks
```

线程代码示例
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
    /* 把自己加入cgroup中（syscall(SYS_gettid)为得到线程的系统tid） */
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

    /* 设置CPU利用率为50% */
    mkdir("/sys/fs/cgroup/cpu/haoel", 755);
    system("echo 50000 > /sys/fs/cgroup/cpu/haoel/cpu.cfs_quota_us");

    mkdir("/sys/fs/cgroup/cpuset/haoel", 755);
    /* 限制CPU只能使用#2核和#3核 */
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
模拟耗内存程序(不断的分配内存，每次512个字节，每次休息一秒)
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

限制内存
```bash
# 创建memory cgroup
$ mkdir /sys/fs/cgroup/memory/yakir
$ echo 64k > /sys/fs/cgroup/memory/yakir/memory.limit_in_bytes

# 把上面的进程的pid加入这个cgroup
$ echo [pid] > /sys/fs/cgroup/memory/haoel/tasks
```

#### IO Limit
测试模拟 IO 速度
```bash
# dd 命令读写 IO
dd if=/dev/sda1 of=/dev/null

# 查看 IO 速度
iotop
  TID  PRIO  USER     DISK READ  DISK WRITE  SWAPIN     IO>    COMMAND
 8128 be/4 root       55.74 M/s    0.00 B/s  0.00 % 85.65 % dd if=/de~=/dev/null...
```

创建一个 blkio(块设备IO) 的 cgroup
```bash
mkdir /sys/fs/cgroup/blkio/yakir
```
限制进程 IO 速度
```bash
# 注：8:0 是设备号，通过 ls -l /dev/sda1 获得
root@ubuntu:~# echo '8:0 1048576'  > /sys/fs/cgroup/blkio/yakir/blkio.throttle.read_bps_device
# 将 dd 命令的 pid 放入 cgroup
root@ubuntu:~# echo [pid] > /sys/fs/cgroup/blkio/yakir/tasks

# 查看 IO 速度
iotop
  TID  PRIO  USER     DISK READ  DISK WRITE  SWAPIN     IO>    COMMAND
 8128 be/4 root      973.20 K/s    0.00 B/s  0.00 % 94.41 % dd if=/de~=/dev/null...
```

#### Cgroup Subsystem
- blkio — 这​​​个​​​子​​​系​​​统​​​为​​​块​​​设​​​备​​​设​​​定​​​输​​​入​​​/输​​​出​​​限​​​制​​​，比​​​如​​​物​​​理​​​设​​​备​​​（磁​​​盘​​​，固​​​态​​​硬​​​盘​​​，USB 等​​​等​​​）。
- cpu — 这​​​个​​​子​​​系​​​统​​​使​​​用​​​调​​​度​​​程​​​序​​​提​​​供​​​对​​​ CPU 的​​​ cgroup 任​​​务​​​访​​​问​​​。​​​
- cpuacct — 这​​​个​​​子​​​系​​​统​​​自​​​动​​​生​​​成​​​ cgroup 中​​​任​​​务​​​所​​​使​​​用​​​的​​​ CPU 报​​​告​​​。​​​
- cpuset — 这​​​个​​​子​​​系​​​统​​​为​​​ cgroup 中​​​的​​​任​​​务​​​分​​​配​​​独​​​立​​​ CPU（在​​​多​​​核​​​系​​​统​​​）和​​​内​​​存​​​节​​​点​​​。​​​
- devices — 这​​​个​​​子​​​系​​​统​​​可​​​允​​​许​​​或​​​者​​​拒​​​绝​​​ cgroup 中​​​的​​​任​​​务​​​访​​​问​​​设​​​备​​​。​​​
- freezer — 这​​​个​​​子​​​系​​​统​​​挂​​​起​​​或​​​者​​​恢​​​复​​​ cgroup 中​​​的​​​任​​​务​​​。​​​
- memory — 这​​​个​​​子​​​系​​​统​​​设​​​定​​​ cgroup 中​​​任​​​务​​​使​​​用​​​的​​​内​​​存​​​限​​​制​​​，并​​​自​​​动​​​生​​​成​​​​​内​​​存​​​资​​​源使用​​​报​​​告​​​。​​​
- net_cls — 这​​​个​​​子​​​系​​​统​​​使​​​用​​​等​​​级​​​识​​​别​​​符​​​（classid）标​​​记​​​网​​​络​​​数​​​据​​​包​​​，可​​​允​​​许​​​ Linux 流​​​量​​​控​​​制​​​程​​​序​​​（tc）识​​​别​​​从​​​具​​​体​​​ cgroup 中​​​生​​​成​​​的​​​数​​​据​​​包​​​。​​​
- net_prio — 这个子系统用来设计网络流量的优先级
- hugetlb — 这个子系统主要针对于HugeTLB系统进行限制，这是一个大页文件系统。

#### Cgroup 相关术语
- **任务（Tasks）**：就是系统的一个进程。
- **控制组（Control Group）**：一组按照某种标准划分的进程，比如官方文档中的Professor和Student，或是WWW和System之类的，其表示了某进程组。Cgroups中的资源控制都是以控制组为单位实现。一个进程可以加入到某个控制组。而资源的限制是定义在这个组上，就像上面示例中我用的haoel一样。简单点说，cgroup的呈现就是一个目录带一系列的可配置文件。
- **层级（Hierarchy）**：控制组可以组织成hierarchical的形式，既一颗控制组的树（目录结构）。控制组树上的子节点继承父结点的属性。简单点说，hierarchy就是在一个或多个子系统上的cgroups目录树。
- **子系统（Subsystem）**：一个子系统就是一个资源控制器，比如CPU子系统就是控制CPU时间分配的一个控制器。子系统必须附加到一个层级上才能起作用，一个子系统附加到某个层级以后，这个层级上的所有控制族群都受到这个子系统的控制。Cgroup的子系统可以有很多，也在不断增加中。

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
local     yakir-test


# how to use
# default volume, directory = /var/lib/docker/volumes/
-v yakir-test:/container-app/my-app
--volume yakir-test:/container-app/my-app
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
docker volume create yakir-test


# start container with volume
docker run -d --name test \
### 
# option1
-v yakir-test:/app \
--volume yakir-test:/app \
# anonymous mode
--volume /app
# option2
--mount source=yakir-test,target=/app \
# readonly mode
--mount source=yakir-test,destination=/usr/share/nginx/html,readonly \
--mount 'type=volume,source=nfsvolume,target=/app,volume-driver=local,volume-opt=type=nfs,volume-opt=device=:/var/docker-nfs,volume-opt=o=addr=10.0.0.10' \
###
nginx:latest


# use a volume with docker-ompose
services:
  frontend:
    image: node:lts
    volumes:
      - yakir-test:/home/node/app
volumes:
  yakir-test:
     # external: true


# show and remove volume
docker inspect volume yakir-test
docker stop test
docker volume rm yakir-test

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
每个容器拥有独立网络协议栈，为每一个容器分配、设置 IP 等。将容器连接到虚拟网桥（默认为 docker0 网桥）。

# 1.在宿主机上创建 container namespace
xxx

# 2.daemon 进程利用 veth pair 技术，在宿主机上创建一对对等虚拟网络接口设备。veth pair 特性是一端流量会流向另一端。
# 一个接口放在宿主机的 docker0 虚拟网桥上并命名为 vethxxx
# 查看网桥信息
brctl show
bridge name     bridge id               STP enabled     interfaces
docker0         8000.0242db01d347       no              vethccab668
# 查看宿主机 vethxxx 接口
ip addr |grep vethccab668
# 另外一个接口放进 container 所属的 namespace 下并命名为 eth0 接口
docker run --rm -dit busybox sh ip addr

# 3.daemon 进程还会从网桥 docker0 的私有地址空间中分配一个 IP 地址和子网给该容器，并设置 docker0 的 IP 地址为容器的默认网关
docker inspect test |grep Gateway
            "Gateway": "172.17.0.1",

```

##### Overlay
```bash
# 多 docker 主机组建网络，配合 docker swarm 使用
```

##### Host
```bash
# host
使用宿主机的 IP 和端口，共享宿主机网络协议栈。

# test
docker run --rm -dit --net host busybox ip addr
```

##### IPvlan
```bash
# ipvlan
ipvlan_mode: l2, l3(default), l3s
ipvlan_flag: bridge(default), private, vepa
parent: eth0

# l2 mode: 使用宿主机的望断
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
每个容器拥有独立网络协议栈，但没有网络设置，如分配 veth pair 和网桥连接等。

# verify
docker run --rm -dit --net none busybox ip addr
```

##### Container
```bash
# container
和一个指定已有的容器共享网络协议栈，使用共有的 IP、端口等。

# verify
docker run -dit --name test --rm busybox sh
docker run -it --name c1 --net container:test --rm busybox ip addr
docker run -it --name c2 --net container:test --rm busybox ip addr
```

##### 自定义网络模式
```bash
# user-defined 
默认 docker0 网桥无法通过 container name host 通信，自定义网络默认使用 daemon 进程内嵌的 DNS server，可以直接通过 --name 指定的 container name 进行通信

# 创建自定义网络
docker network create yakir-test
# 宿主机查看新增虚拟网卡
ip addr
    inet 172.19.0.1/16 brd 172.19.255.255 scope global br-8cb8260a95cf
brctl show
br-8cb8260a95cf         8000.024272aa9d38       no              veth556b81b
# verify
docker run -dit --name test1 --net yakir-test --rm busybox sh
docker run -it --name test2 --net yakir-test --rm busybox ping -c 4 test1

# 连接已有的网络
docker run -dit --name test3 --net yakir-test --rm busybox sh
docker network connect yakir-test test3 
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
""" 编写规范
1. 使用统一的 base 镜像。
2. 动静分离（基础稳定内容放在底层）。
3. 最小原则（镜像只打包必需的东西）。
4. 一个原则（每个镜像只有一个功能，交互通过网络，模块化管理）。
5. 使用更少的层，减少每层的内容。
6. 不要在 Dockerfile 单独修改文件权限（entrypoint / 拷贝+修改权限同时操作）。
7. 利用 cache 加快构建速度。
8. 版本控制和自动构建（放入 git 版本控制中，自动构建镜像，构建参数/变量给予文档说明）。
9. 使用 .dockerignore 文件（排除文件和目录）
"""

# ENTRYPOINT 指令:
# exec 形式，直接启动程序进程，pid=1
ENTRYPOINT ["node", "app.js"]
# shell 形式，fork 一个 shell 子进程，shell 子进程启动程序
ENTRYPOINT "node" "app.js"

# Pod template 对应 Dockerfile 字段
spec.contianers[n].command = ENTRYPOINT
spec.contianers[n].args = CMD
```

### Docker Compose
[[docker-compose.yml|Archery Docker Compose]]



> Reference:
> 1. [Official Website](https://docs.docker.com/)
> 2. [Docker network-drivers](https://docs.docker.com/network/drivers/)
> 3. [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
> 4. [COOLSHELL-DOCKER基础技术:Linux NAMESPACE](https://coolshell.cn/articles/17010.html)
