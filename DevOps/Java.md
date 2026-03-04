---
icon: code
description: Java record
---

# Java

## 1. Development Environment

### Install

```bash
# ubuntu
apt install default-jdk
apt install openjdk-17-jdk

# macOS
brew install openjdk@21

# Manual install (Temurin / Adoptium)
wget https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21/OpenJDK21U-jdk_x64_linux_hotspot.tar.gz
tar xf OpenJDK21U-jdk_x64_linux_hotspot.tar.gz -C /usr/local/
export JAVA_HOME=/usr/local/jdk-21
export PATH=$JAVA_HOME/bin:$PATH

# Verify
java -version
javac -version
```

### SDKMAN

A version manager for JDK and JVM-based tools (Maven, Gradle, etc.).

#### Install

```bash
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk version
```

#### Usage

```bash
# List available JDK distributions
sdk list java

# Install a specific JDK
sdk install java 21.0.3-tem
sdk install java 17.0.11-zulu

# Use a JDK version
sdk use java 21.0.3-tem              # current shell only
sdk default java 21.0.3-tem          # set as default

# Show current version
sdk current java

# Install other tools
sdk install maven
sdk install gradle

# Upgrade
sdk upgrade java
```

### IntelliJ IDEA

```bash
# Plugins
gradianto          # themes
rainbow brackets   # bracket colorizer
```

## 2. ProjectManage

### Maven

Apache Maven is a build automation and dependency management tool for Java. It uses `pom.xml` to declare dependencies, plugins, and build lifecycle.

#### Install

```bash
# SDKMAN (recommend)
sdk install maven

# macOS
brew install maven

# Manual
wget https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz
tar xf apache-maven-3.9.9-bin.tar.gz -C /usr/local/
export M2_HOME=/usr/local/apache-maven-3.9.9
export PATH=$M2_HOME/bin:$PATH

# Verify
mvn -version
```

#### Project Management

```bash
# Create a new project from archetype
mvn archetype:generate \
    -DgroupId=com.example \
    -DartifactId=my-app \
    -DarchetypeArtifactId=maven-archetype-quickstart

# Build lifecycle
mvn clean                         # clean target/
mvn compile                       # compile source code
mvn test                          # run unit tests
mvn package                       # build JAR/WAR
mvn install                       # install to local repository
mvn deploy                        # deploy to remote repository

# Common options
mvn clean package -DskipTests     # skip tests during build
mvn clean package -P production   # activate a profile
mvn dependency:tree               # show dependency tree
mvn dependency:resolve            # resolve and download dependencies
mvn versions:display-dependency-updates
```

#### Configuration

```xml
<!-- ~/.m2/settings.xml — mirror example -->
<settings>
  <mirrors>
    <mirror>
      <id>aliyun</id>
      <mirrorOf>central</mirrorOf>
      <url>https://maven.aliyun.com/repository/central</url>
    </mirror>
  </mirrors>
</settings>
```

### Gradle

A build automation tool using Groovy/Kotlin DSL. It uses `build.gradle` (or `build.gradle.kts`) for project configuration.

#### Install

```bash
# SDKMAN (recommend)
sdk install gradle

# macOS
brew install gradle

# Verify
gradle -version
```

#### Project Management

```bash
# Initialize a new project
gradle init --type java-application

# Build lifecycle
./gradlew clean                   # clean build/
./gradlew build                   # compile, test, and package
./gradlew test                    # run tests
./gradlew bootRun                 # run Spring Boot application
./gradlew jar                     # build JAR

# Common options
./gradlew build -x test           # skip tests
./gradlew dependencies            # show dependency tree
./gradlew tasks                   # list available tasks

# Wrapper (generate or update)
gradle wrapper --gradle-version 8.10
```

## 3. JVM Settings

### Common

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
> 3. [SDKMAN](https://sdkman.io/)
> 4. [Maven](https://maven.apache.org/)
> 5. [Gradle](https://gradle.org/)
> 6. [AliCloud Serverless](https://help.aliyun.com/zh/sae/use-cases/best-practices-for-jvm-heap-size-configuration)
