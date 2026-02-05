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

### [maven](./CommandManual/BuildTools.md#maven)

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

### JVM Container Parameters

| Parameter                                                            | Description                                                                                                                                                                                                           |
| -------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| -XX:+UseContainerSupport                                             | <p>Configures the JVM to detect the memory size and number of processors of the container it runs in, rather than detecting those of the entire operating system.<br><br>The JVM uses the detected information for resource allocation. For example, the percentages set by -XX:InitialRAMPercentage and -XX:MaxRAMPercentage are calculated based on this information.</p> |
| -XX:InitialRAMPercentage                                             | Sets the initial percentage of container memory used by the JVM. It is recommended to keep this consistent with -XX:MaxRAMPercentage. The recommended value is 70.0, meaning the JVM initially uses 70% of container memory. |
| -XX:MaxRAMPercentage                                                 | Sets the maximum percentage of container memory used by the JVM. Due to system component overhead, it is recommended not to exceed 75.0. The recommended value is 70.0, meaning the JVM uses at most 70% of container memory. |
| -XX:+PrintGCDetails                                                  | Outputs detailed GC information.                                                                                                                                                                                      |
| -XX:+PrintGCDateStamps                                               | Outputs GC timestamps in date format, e.g., 2019-12-24T21:53:59.234+0800.                                                                                                                                            |
| -Xloggc:/home/admin/nas/gc-${POD\_IP}-$(date '+%s').log              | GC log file path. Ensure the container path where the log file resides already exists. It is recommended to mount this container path to a NAS directory or collect logs to SLS, to enable automatic directory creation and persistent log storage. |
| -XX:+HeapDumpOnOutOfMemoryError                                      | Automatically generates a dump file when the JVM encounters an OOM error.                                                                                                                                             |
| -XX:HeapDumpPath=/home/admin/nas/dump-${POD\_IP}-$(date '+%s').hprof | Dump file path. Ensure the container path where the dump file resides already exists. It is recommended to mount this container path to a NAS directory, to enable automatic directory creation and persistent log storage. |

> \[!NOTE] Note: Using the -XX:+UseContainerSupport parameter requires JDK 8u191+, JDK 10, or later versions. The -XX:+UseContainerSupport parameter is only supported on certain operating systems; please refer to the official documentation of your Java version for specific support details. In JDK 11 and later versions, the logging-related parameters -XX:+PrintGCDetails, -XX:+PrintGCDateStamps, and -Xloggc:$LOG\_PATH/gc.log have been deprecated. Please use -Xlog:gc:$LOG_PATH/gc.log instead. Dragonwell 11 does not support the ${POD_IP} variable. If you have not mounted the /home/admin/nas container path to a NAS directory, you must ensure that the directory exists before the application starts; otherwise, no log files will be generated.

### JVM Heap Parameters

| Parameter                                                            | Description                                                                                                                               |
| -------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| -Xms                                                                 | Sets the initial JVM memory size. It is recommended to set this the same as -Xmx to avoid JVM memory reallocation after each garbage collection. |
| -Xmx                                                                 | Sets the maximum available JVM memory size. To avoid container OOM, reserve sufficient memory for the system.                             |
| -XX:+PrintGCDetails                                                  | Outputs detailed GC information.                                                                                                          |
| -XX:+PrintGCDateStamps                                               | Outputs GC timestamps in date format, e.g., 2019-12-24T21:53:59.234+0800.                                                                |
| -Xloggc:/home/admin/nas/gc-${POD\_IP}-$(date '+%s').log              | GC log file path. Ensure the container path where the log file resides already exists. It is recommended to mount this container path to an NFS/NAS directory and collect logs to SLS, to enable automatic directory creation and persistent log storage. |
| -XX:+HeapDumpOnOutOfMemoryError                                      | Automatically generates a dump file when the JVM encounters an OOM error.                                                                 |
| -XX:HeapDumpPath=/home/admin/nas/dump-${POD\_IP}-$(date '+%s').hprof | Dump file path. Ensure the container path where the dump file resides already exists. It is recommended to mount this container path to a NAS directory, to enable automatic directory creation and persistent log storage. |

| Memory Specification | JVM Heap Size |
| -------------------- | ------------- |
| 1GB                  | 600 MB        |
| 2GB                  | 1434 MB       |
| 3GB                  | 2867 MB       |
| 4GB                  | 5734 MB       |

> \[!NOTE] Memory specification parameter notes: In JDK 11 and later versions, the logging-related parameters -XX:+PrintGCDetails, -XX:+PrintGCDateStamps, and -Xloggc:$LOG\_PATH/gc.log have been deprecated. Please use -Xlog:gc:$LOG_PATH/gc.log instead. Dragonwell 11 does not support the ${POD_IP} variable. If you have not mounted the /home/admin/nas container path to a NAS directory, you must ensure that the directory exists before the application starts; otherwise, no log files will be generated.

> Reference:
>
> 1. [Official Website](https://openjdk.org/projects/jdk/)
> 2. [Repository](https://github.com/openjdk/jdk)
> 3. [AliCloud Serverless](https://help.aliyun.com/zh/sae/use-cases/best-practices-for-jvm-heap-size-configuration)
