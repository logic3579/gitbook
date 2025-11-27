---
icon: code
description: Java record
---

# Java

## 1. Development Environment

### Install

```bash
# centos

# ubuntu
#apt install openjdk-17-jdk
apt install default-jdk

# build && install

```

### IntelliJ IDEA

```bash
# active
cat ideaActive/ja-netfilter-all/ja-netfilter/readme.txt

# settings
# 1. Python Intergrated Tools -> Docstring format: Google

# Plugins
gradianto # themes
rainbow brackets # json
```

## 2. ProjectManage

### [maven](../../Operations/CommandManual/BuildTools.md#maven)

### gradle

```bash

```

## 3. JVM Settings

### common

```bash
JAVA_OPTS="\
-Dcatalina.base=${PWD} \
-Dfile.encoding=utf-8 \
-Dlog.file.path=/app/logs
"

JAVA_ARGS="\
--server.port=${SERVER_PORT-8080}
"

java $JAVA_OPTS \
-XX:InitialRAMPercentage=50.0 \
-XX:MinRAMPercentage=50.0 \
-XX:MaxRAMPercentage=75.0 \
-Xlog:gc:${PWD}/logs/gc.log:time,level,tags \
-XX:+HeapDumpOnOutOfMemoryError \
-XX:HeapDumpPath=${PWD}/logs/heapdump.hprof \
-jar app.jar \
$JAVA_ARGS

```

### jvm 容器参数

| 参数                                                                 | 说明                                                                                                                                                                                                                  |
| -------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| -XX:+UseContainerSupport                                             | <p>设置JVM检测所处容器的内存大小和处理器数量，而不是检测整个操作系统的。<br><br>JVM会使用上述检测到的信息进行资源分配，例如：-XX:InitialRAMPercentage和-XX:MaxRAMPercentage所设置的百分比就是基于此信息进行计算的</p> |
| -XX:InitialRAMPercentage                                             | 设置JVM使用容器内存的初始百分比。建议与-XX:MaxRAMPercentage保持一致，推荐设置为70.0，代表JVM初始使用容器内存的70%                                                                                                     |
| -XX:MaxRAMPercentage                                                 | 设置JVM使用容器内存的最大百分比。由于存在系统组件开销，建议最大不超过75.0，推荐设置为70.0，代表JVM最大使用容器内存的70%                                                                                               |
| -XX:+PrintGCDetails                                                  | 输出GC详细信息                                                                                                                                                                                                        |
| -XX:+PrintGCDateStamps                                               | 输出GC时间戳。日期形式，例如2019-12-24T21:53:59.234+0800                                                                                                                                                              |
| -Xloggc:/home/admin/nas/gc-${POD\_IP}-$(date '+%s').log              | GC日志文件路径。需保证Log文件所在容器路径已存在，建议您将该容器路径挂载到NAS目录或收集到SLS，以便自动创建目录以及实现日志的持久化存储                                                                                 |
| -XX:+HeapDumpOnOutOfMemoryError                                      | JVM发生OOM时，自动生成Dump文件。                                                                                                                                                                                      |
| -XX:HeapDumpPath=/home/admin/nas/dump-${POD\_IP}-$(date '+%s').hprof | Dump文件路径。需保证Dump文件所在容器路径已存在，建议您将该容器路径挂载到NAS目录，以便自动创建目录以及实现日志的持久化存储                                                                                             |

> \[!NOTE] 注意 Contents 使用-XX:+UseContainerSupport参数需JDK 8u191+、JDK 10及以上版本。 -XX:+UseContainerSupport参数仅在部分操作系统上支持，具体支持情况请查阅您所使用的Java版本的官方文档。 在JDK 11及之后的版本中，日志相关的参数-XX:+PrintGCDetails、-XX:+PrintGCDateStamps、-Xloggc:$LOG\_PATH/gc.log已被废弃，请使用参数-Xlog:gc:$LOG_PATH/gc.log代替。 Dragonwell 11不支持${POD_IP}变量。 如果您没有将/home/admin/nas容器路径挂载到NAS目录，则必须保证该目录在应用启动前已存在，否则将不会产生日志文件。

### jvm 堆参数

| 参数                                                                 | 说明                                                                                                                                      |
| -------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| -Xms                                                                 | 设置JVM初始内存大小。建议与-Xmx相同，避免每次垃圾回收完成后JVM重新分配内存                                                                |
| -Xmx                                                                 | 设置JVM最大可用内存大小。为避免容器OOM，请为系统预留足够的内存大小。                                                                      |
| -XX:+PrintGCDetails                                                  | 输出GC详细信息                                                                                                                            |
| -XX:+PrintGCDateStamps                                               | 输出GC时间戳。日期形式，例如2019-12-24T21:53:59.234+0800                                                                                  |
| -Xloggc:/home/admin/nas/gc-${POD\_IP}-$(date '+%s').log              | GC日志文件路径。需保证Log文件所在容器路径已存在，建议您将该容器路径挂载到NFS\&NAS目录&收集到SLS，以便自动创建目录以及实现日志的持久化存储 |
| -XX:+HeapDumpOnOutOfMemoryError                                      | JVM发生OOM时，自动生成Dump文件                                                                                                            |
| -XX:HeapDumpPath=/home/admin/nas/dump-${POD\_IP}-$(date '+%s').hprof | Dump文件路径。需保证Dump文件所在容器路径已存在，建议您将该容器路径挂载到NAS目录，以便自动创建目录以及实现日志的持久化存储                 |

| 内存规格大小 | JVM堆大小 |
| ------------ | --------- |
| 1GB          | 600 MB    |
| 2GB          | 1434 MB   |
| 3GB          | 2867 MB   |
| 4GB          | 5734 MB   |

> \[!NOTE] 内存规格参数说明 在JDK 11及之后的版本中，日志相关的参数-XX:+PrintGCDetails、-XX:+PrintGCDateStamps、-Xloggc:$LOG\_PATH/gc.log已被废弃，请使用参数-Xlog:gc:$LOG_PATH/gc.log代替。 Dragonwell 11不支持${POD_IP}变量。 如果您没有将/home/admin/nas容器路径挂载到NAS目录，则必须保证该目录在应用启动前已存在，否则将不会产生日志文件。

> Reference:
>
> 1. [Official Website](https://openjdk.org/projects/jdk/)
> 2. [Repository](https://github.com/openjdk/jdk)
> 3. [AliCloud Serverless](https://help.aliyun.com/zh/sae/use-cases/best-practices-for-jvm-heap-size-configuration)
