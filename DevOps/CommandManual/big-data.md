---
description: HDFS and HBase CLI references for Hadoop ecosystem
tags:
  - devops/command
  - database
---

# Big Data

## HDFS

### Filesystem Operations

```bash
# list / list recursively
hdfs dfs -ls /
hdfs dfs -ls -R /path/to/dir

# create / remove directories
hdfs dfs -mkdir -p /path/to/dir
hdfs dfs -rm -r /path/to/dir
hdfs dfs -rm -skipTrash /path/to/file
```

### Upload & Download

```bash
# upload (put = copyFromLocal)
hdfs dfs -put localfile /hdfs/path/
hdfs dfs -put -f localfile /hdfs/path/          # overwrite if exists
hdfs dfs -copyFromLocal localfile /hdfs/path/

# download (get = copyToLocal)
hdfs dfs -get /hdfs/path/file localpath
hdfs dfs -copyToLocal /hdfs/path/file localpath
hdfs dfs -getmerge /hdfs/path/dir localfile      # merge files into one
```

### File Operations

```bash
# read
hdfs dfs -cat /path/to/file
hdfs dfs -tail /path/to/file
hdfs dfs -head /path/to/file
hdfs dfs -text /path/to/file                     # display compressed file as text

# copy / move
hdfs dfs -cp /src /dst
hdfs dfs -mv /src /dst

# size and usage
hdfs dfs -du -s -h /path/to/dir                  # directory size summary
hdfs dfs -df -h                                  # filesystem disk usage
hdfs dfs -count -q -h /path/to/dir               # file/directory count with quota

# permission and ownership
hdfs dfs -chmod -R 755 /path/to/dir
hdfs dfs -chown -R user:group /path/to/dir
```

### File Test

```bash
hdfs dfs -test -e /path/to/file                  # exists
hdfs dfs -test -d /path/to/dir                   # is directory
hdfs dfs -test -f /path/to/file                  # is file
hdfs dfs -test -z /path/to/file                  # is zero length
```

### Snapshot

```bash
hdfs dfs -createSnapshot /path snapshot_name
hdfs dfs -deleteSnapshot /path snapshot_name
hdfs dfs -renameSnapshot /path old_name new_name
```

### Admin

```bash
# cluster status report
hdfs dfsadmin -report

# safe mode
hdfs dfsadmin -safemode get
hdfs dfsadmin -safemode enter
hdfs dfsadmin -safemode leave

# refresh datanode list
hdfs dfsadmin -refreshNodes
```

### FSCK

```bash
# full filesystem check
hdfs fsck /

# detailed check for one path (files, blocks, locations)
hdfs fsck /path/to/file -files -blocks -locations

# list corrupt file blocks
hdfs fsck / -list-corruptfileblocks
```

### Balancer & Trash

```bash
# rebalance data across datanodes
hdfs balancer -threshold 10

# empty trash
hdfs dfs -expunge
```

### Quota

```bash
# space quota
hdfs dfsadmin -setSpaceQuota 1T /path/to/dir
hdfs dfsadmin -clrSpaceQuota /path/to/dir

# name (file count) quota
hdfs dfsadmin -setQuota 1000000 /path/to/dir
hdfs dfsadmin -clrQuota /path/to/dir
```

## HBase

### Shell

```bash
hbase shell
```

### Status & Version

```bash
status
status 'simple'
status 'detailed'
version
whoami
```

### Namespace

```bash
list_namespace
create_namespace 'myns'
describe_namespace 'myns'
alter_namespace 'myns', {METHOD => 'set', 'PROPERTY_NAME' => 'PROPERTY_VALUE'}
drop_namespace 'myns'                            # namespace must be empty
```

### Table: List and Describe

```bash
list
list_namespace_tables 'myns'
describe 'myns:mytable'
exists 'myns:mytable'
is_enabled 'myns:mytable'
is_disabled 'myns:mytable'
```

### Table: Create

```bash
# simple
create 'myns:mytable', 'cf1'

# multi-family with versions, TTL, compression
create 'myns:mytable', {NAME => 'cf1', VERSIONS => 3}, {NAME => 'cf2', VERSIONS => 1, TTL => 86400, COMPRESSION => 'SNAPPY'}

# pre-split regions
create 'myns:mytable', {NAME => 'cf1'}, SPLITS => ['10', '20', '30', '40']
```

### Table: Alter

```bash
# change family attributes
alter 'myns:mytable', {NAME => 'cf1', VERSIONS => 5}
alter 'myns:mytable', {NAME => 'cf1', TTL => 604800}

# add / delete column family
alter 'myns:mytable', {NAME => 'cf3', VERSIONS => 1}
alter 'myns:mytable', 'delete' => 'cf3'

# 128MB region split size
alter 'myns:mytable', MAX_FILESIZE => '134217728'
```

### Table: Enable / Disable

```bash
disable 'myns:mytable'
enable 'myns:mytable'
```

### Table: Drop and Truncate

```bash
# drop (must disable first)
disable 'myns:mytable'
drop 'myns:mytable'

# truncate (disable + drop + recreate)
truncate 'myns:mytable'
```

### CRUD: Put

```bash
put 'myns:mytable', 'row1', 'cf1:name', 'value1'
put 'myns:mytable', 'row1', 'cf1:age', '25'
```

### CRUD: Get

```bash
get 'myns:mytable', 'row1'
get 'myns:mytable', 'row1', 'cf1:name'
get 'myns:mytable', 'row1', {COLUMN => 'cf1:name', VERSIONS => 3}
get 'myns:mytable', 'row1', {COLUMN => 'cf1:name', TIMESTAMP => 1234567890}
```

### CRUD: Scan

```bash
scan 'myns:mytable'
scan 'myns:mytable', {LIMIT => 10}
scan 'myns:mytable', {STARTROW => 'row1', STOPROW => 'row5'}
scan 'myns:mytable', {COLUMNS => ['cf1:name', 'cf1:age']}
scan 'myns:mytable', {FILTER => "SingleColumnValueFilter('cf1', 'name', =, 'binary:value1')"}
scan 'myns:mytable', {FILTER => "PrefixFilter('row')"}
scan 'myns:mytable', {ROWPREFIXFILTER => 'row', LIMIT => 100}
scan 'myns:mytable', {TIMERANGE => [1234567890, 1234567900]}
```

### CRUD: Count

```bash
count 'myns:mytable'
count 'myns:mytable', INTERVAL => 100000
```

### CRUD: Delete

```bash
delete 'myns:mytable', 'row1', 'cf1:name'
deleteall 'myns:mytable', 'row1'
```

### CRUD: Increment Counter

```bash
incr 'myns:mytable', 'row1', 'cf1:counter', 1
get_counter 'myns:mytable', 'row1', 'cf1:counter'
```

### Snapshot

```bash
snapshot 'myns:mytable', 'mytable_snapshot'
list_snapshots
clone_snapshot 'mytable_snapshot', 'myns:mytable_clone'
restore_snapshot 'mytable_snapshot'              # table must be disabled
delete_snapshot 'mytable_snapshot'

# export snapshot to another cluster
hbase org.apache.hadoop.hbase.snapshot.ExportSnapshot \
  -snapshot mytable_snapshot \
  -copy-to hdfs://remote-cluster:8020/hbase \
  -mappers 16
```

### Region Management

```bash
list_regions 'myns:mytable'
move 'encoded_regionname', 'dest_server'
split 'myns:mytable', 'split_key'
merge_region 'encoded_region_a', 'encoded_region_b'
compact 'myns:mytable'
major_compact 'myns:mytable'
flush 'myns:mytable'
balance_switch true                              # enable auto balancer
balancer                                         # trigger balancer run
```

### Bulk Load

```bash
# generate HFiles into the table
hbase org.apache.hadoop.hbase.tool.BulkLoadHFilesTool \
  hdfs:///path/to/hfiles 'myns:mytable'
```

### Permission (ACL Enabled)

```bash
grant 'user', 'RWXCA', 'myns:mytable'
revoke 'user', 'myns:mytable'
user_permission 'myns:mytable'
```

> Reference:
>
> 1. [HDFS Commands Guide](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-hdfs/HDFSCommands.html)
> 2. [HDFS FileSystem Shell](https://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/FileSystemShell.html)
> 3. [HBase Shell Reference](https://hbase.apache.org/book.html#shell)
> 4. [HBase Documentation](https://hbase.apache.org/book.html)
