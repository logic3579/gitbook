---
description: Build tool CLI references for Maven, Gradle, and Make
---

# Build Tools

## Maven

```bash
# determine file location
mvn -X clean | grep "settings"

# determini effective settings
mvn help:effective-settings

# override the default location
mvn clean --settings /tmp/my-settings.xml --global-settings /tmp/global-settings.xml

# package
mvn clean package -U -DskipTests

# deploy
mvn clean package deploy -U -DskipTests

# dependency tree
mvn dependency:tree
mvn dependency:tree -Dincludes=groupId:artifactId

# run specific test
mvn test -Dtest=MyTestClass
mvn test -Dtest=MyTestClass#testMethod

# install local jar
mvn install:install-file -Dfile=lib.jar -DgroupId=com.example -DartifactId=lib -Dversion=1.0 -Dpackaging=jar

# check for dependency updates
mvn versions:display-dependency-updates
mvn versions:display-plugin-updates
```

## Gradle

```bash
# build
gradle build
gradle build -x test          # skip tests
gradle clean build

# tasks
gradle tasks                   # list available tasks
gradle tasks --all             # list all tasks including sub-project tasks

# dependencies
gradle dependencies
gradle dependencies --configuration implementation
gradle dependencyInsight --dependency commons-lang3

# run specific test
gradle test --tests "com.example.MyTest"
gradle test --tests "*MyTest.testMethod"

# wrapper
gradle wrapper --gradle-version=8.5
./gradlew build                # use wrapper

# properties
gradle properties
gradle build -Penv=prod        # pass project property
gradle build -Dorg.gradle.debug=true

# publish
gradle publish
gradle publishToMavenLocal
```

## Make

```bash
# basic usage
make                           # run default target
make target_name               # run specific target
make -j$(nproc)                # parallel build
make -n                        # dry run (show commands without executing)
make -B                        # force rebuild all targets

# variables
make CC=gcc CFLAGS="-O2 -Wall"
make PREFIX=/usr/local install

# common targets
make clean                     # clean build artifacts
make install                   # install to system
make uninstall                 # remove from system
make test                      # run tests
make dist                      # create distribution archive

# debug
make --debug                   # show debug info
make -p                        # print database (all rules and variables)
```

> Reference:
>
> 1. [Maven Documentation](https://maven.apache.org/guides/)
> 2. [Gradle Documentation](https://docs.gradle.org/)
> 3. [GNU Make Manual](https://www.gnu.org/software/make/manual/)
