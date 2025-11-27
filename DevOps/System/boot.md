# Boot

## BIOS vs UEFI

### BIOS

**Legacy 启动模式**: 检查所有连接设备的 MBR,如果找不到引导加载程序,Legacy 会切换列表中下一个设备并重复此过程,直到找到加载程序,否则返回错误

基本输入输出系统: Basic Input/Output System

1. 开机加电硬件自检, POST(Power-On Self-Test)
   该过程主要对计算机各种硬件设备进行检测，如 CPU、内存、主板、硬盘、CMOS 芯片等，如果出现致命故障则停机，并且由于初始化过程还没完成，所以不会出现任何提示信号；如果出现一般故障则会发出蜂鸣；若未出现故障，加电自检完成(枚举本地硬件设备初始化).
2. 按 Boot Sequence 查找**可用的存储设备**, 找到后从该设备第一个扇区读取 MBR 或 GPT(Linux 系统) 引导启动操作系统.

- [[boot#MBR|MBR]]
- [[boot#GPT|GPT]]

### UEFI

**UEFI 启动模式**: 引导数据存储在 .efi 文件中. UEFI 启动模式包含一个特殊 EFI 分区,用于存储 .efi 文件并用于引导过程和引导加载程序.

统一可扩展固件接口: Unified Extensible Firmware Interface

1. 开机加电硬件之间, POST(Power-On Self-Test)
2. 从该设备第一个扇区读取 GPT 方式引导操作系统.

- [[boot#GPT|GPT]]

## MBR vs GPT

> 1.  LBA(Logical Block Address 逻辑块地址): 默认已 512B 进行规划, LBA 从0开始.
> 2.  Sector(硬盘扇区): 目前为单个 512B (部分新磁盘为4096B).

### MBR

主引导记录: Master Boot Record

- LBA0: 保存 MBR 信息.

| 起始字节 | 字节长度 | 说明                                                                                             |
| -------- | -------- | ------------------------------------------------------------------------------------------------ |
| 1        | 446B     | Boot loader: 主引导加载程序,加载内核到内存中运行.                                                |
| 447      | 64B      | Disk Partition Table: 分区表,记录每个分区信息(大小,起始扇区和大小等).每个分区16B,最多四个主分区. |
| 511      | 2B       | Boot Flag: 分区表标记,表示设备是否可启动.                                                        |

- 分区表: 最多4个主分区. 或3个主分区+1个扩展分区+多个逻辑分区.扩展分区可以分成两个逻辑分区,第二个逻辑分区可以继续分逻辑分区,直到找到分区表本身(只有一个分区项)
- Boot loader: Linux 中为 grub 或 grub2

### GPT

GUID 分区表: GUID Partition Table

- LBA0: 第一部分前446B 保留 MBR Boot loader,第二部分保存 GPT 磁盘分区格式标识.
- LBA1: GPT HDR 分区表头记录.记录分区表本身位置与大小,同时记录备份用 GPT 分区位置(磁盘最后的34个 LBA), 通过放置的分区表校验码(CRC32)错误时从备份 GPT 中恢复运行.

| 起始字节 | 字节长度 | 说明                         |
| -------- | -------- | ---------------------------- |
| 0        | 8B       | 分区表头签名                 |
| 8        | 4B       | 版本号                       |
| 12       | 4B       | 分区表头大小                 |
| 16       | 4B       | GPT 头 CRC 校验和            |
| 20       | 4B       | 保留,必须为0                 |
| 24       | 8B       | 当前 LBA(这个分区表头的位置) |
| 32       | 8B       |                              |
| ...      | ...      | ...                          |

- LBA2~LBA33: GPT 分区表信息.每个 LBA 提供4组分区记录,默认情况下有4x32=128个分区.

| 起始字节 | 字节长度 | 说明                                                                        |
| -------- | -------- | --------------------------------------------------------------------------- |
| 0        | 16B      | 分区类型, 如{C12A7328-F81F-11D2-BA4B-00A0C93EC93B}代表 EFI 系统分区         |
| 16       | 16B      | 分区 GUID                                                                   |
| 32       | 8B       | 分区起始 LBA(小端序)                                                        |
| 40       | 8B       | 分区末尾 LBA                                                                |
| 48       | 8B       | 分区属性标签(0:系统分区, 1:EFI隐藏分区, 2:传统BIOS可引导分区, 60:只读, ...) |
| 56       | 72B      | 分区名(可以包括36个UTF-16(小端序)字符)                                      |

- LBA34~LBA-34: GPT 实际分区内容
- LBA-33~LBA-2: GPT 分区表的备份,对 LBA2~LBA33 的备份
- LBA-1: GPT 表头记录备份,对 LBA1 的备份

![[/DevOps/System/attachements/boot-1.png]]

## Kernel

1. 内核初始化硬件
2. 加载驱动
3. 初始化内存管理,进程管理
4. 挂载根文件系统
5. 切换 rootfs
6. 运行 init 程序(systemd)
7. systemd: 系统初始化与服务启动

## Systemd

/etc/rcX.d/
/etc/init.d/

> Reference:
>
> 1. [BIOS vs UEFI](https://zhuanlan.zhihu.com/p/26098509)
> 2. [MBR vs GPT](https://www.easeus.com/partition-master/mbr-vs-gpt.html)
> 3. [计算机是如何启动的?](https://www.ruanyifeng.com/blog/2013/02/booting.html)
> 4. [GPT WIKI](https://zh.wikipedia.org/zh-hans/GUID%E7%A3%81%E7%A2%9F%E5%88%86%E5%89%B2%E8%A1%A8)
