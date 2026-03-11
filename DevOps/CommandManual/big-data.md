---
description: HDFS and HBase CLI references for Hadoop ecosystem
---

# Big Data

## HDFS

```bash
# filesystem operations
hdfs dfs -ls /
hdfs dfs -ls -R /path/to/dir
hdfs dfs -mkdir -p /path/to/dir
hdfs dfs -rm -r /path/to/dir
hdfs dfs -rm -skipTrash /path/to/file

# upload and download
hdfs dfs -put localfile /hdfs/path/
hdfs dfs -put -f localfile /hdfs/path/          # overwrite if exists
hdfs dfs -copyFromLocal localfile /hdfs/path/
hdfs dfs -get /hdfs/path/file localpath
hdfs dfs -copyToLocal /hdfs/path/file localpath
hdfs dfs -getmerge /hdfs/path/dir localfile      # merge files into one

# file operations
hdfs dfs -cat /path/to/file
hdfs dfs -tail /path/to/file
hdfs dfs -head /path/to/file
hdfs dfs -text /path/to/file                     # display compressed file as text
hdfs dfs -cp /src /dst
hdfs dfs -mv /src /dst
hdfs dfs -du -s -h /path/to/dir                  # directory size summary
hdfs dfs -df -h                                  # filesystem disk usage
hdfs dfs -count -q -h /path/to/dir               # file/directory count with quota
hdfs dfs -chmod -R 755 /path/to/dir
hdfs dfs -chown -R user:group /path/to/dir

# file test
hdfs dfs -test -e /path/to/file                  # exists
hdfs dfs -test -d /path/to/dir                   # is directory
hdfs dfs -test -f /path/to/file                  # is file
hdfs dfs -test -z /path/to/file                  # is zero length

# snapshot
hdfs dfs -createSnapshot /path snapshot_name
hdfs dfs -deleteSnapshot /path snapshot_name
hdfs dfs -renameSnapshot /path old_name new_name

# admin operations
hdfs dfsadmin -report                            # cluster status report
hdfs dfsadmin -safemode get                      # check safe mode
hdfs dfsadmin -safemode enter
hdfs dfsadmin -safemode leave
hdfs dfsadmin -refreshNodes                      # refresh datanode list

# block and file check
hdfs fsck /                                      # full filesystem check
hdfs fsck /path/to/file -files -blocks -locations
hdfs fsck / -list-corruptfileblocks

# balancer
hdfs balancer -threshold 10                      # rebalance data across datanodes

# trash
hdfs dfs -expunge                                # empty trash

# quota
hdfs dfsadmin -setSpaceQuota 1T /path/to/dir
hdfs dfsadmin -clrSpaceQuota /path/to/dir
hdfs dfsadmin -setQuota 1000000 /path/to/dir     # set name (file count) quota
hdfs dfsadmin -clrQuota /path/to/dir
```

## HBase

```bash
# hbase shell
hbase shell

# status and version
status
status 'simple'
status 'detailed'
version
whoami

# namespace
list_namespace
create_namespace 'myns'
describe_namespace 'myns'
alter_namespace 'myns', {METHOD => 'set', 'PROPERTY_NAME' => 'PROPERTY_VALUE'}
drop_namespace 'myns'                            # namespace must be empty

# table
## list and describe
list
list_namespace_tables 'myns'
describe 'myns:mytable'
exists 'myns:mytable'
is_enabled 'myns:mytable'
is_disabled 'myns:mytable'
## create table
create 'myns:mytable', 'cf1'
create 'myns:mytable', {NAME => 'cf1', VERSIONS => 3}, {NAME => 'cf2', VERSIONS => 1, TTL => 86400, COMPRESSION => 'SNAPPY'}
create 'myns:mytable', {NAME => 'cf1'}, SPLITS => ['10', '20', '30', '40']
## alter table
alter 'myns:mytable', {NAME => 'cf1', VERSIONS => 5}
alter 'myns:mytable', {NAME => 'cf3', VERSIONS => 1}                   # add column family
alter 'myns:mytable', 'delete' => 'cf3'                                # delete column family
alter 'myns:mytable', {NAME => 'cf1', TTL => 604800}
alter 'myns:mytable', MAX_FILESIZE => '134217728'                      # 128MB region split size
## enable and disable
disable 'myns:mytable'
enable 'myns:mytable'
## drop (must disable first)
disable 'myns:mytable'
drop 'myns:mytable'
## truncate (disable + drop + recreate)
truncate 'myns:mytable'

# CRUD
## put (insert/update)
put 'myns:mytable', 'row1', 'cf1:name', 'value1'
put 'myns:mytable', 'row1', 'cf1:age', '25'
## get
get 'myns:mytable', 'row1'
get 'myns:mytable', 'row1', 'cf1:name'
get 'myns:mytable', 'row1', {COLUMN => 'cf1:name', VERSIONS => 3}
get 'myns:mytable', 'row1', {COLUMN => 'cf1:name', TIMESTAMP => 1234567890}
## scan
scan 'myns:mytable'
scan 'myns:mytable', {LIMIT => 10}
scan 'myns:mytable', {STARTROW => 'row1', STOPROW => 'row5'}
scan 'myns:mytable', {COLUMNS => ['cf1:name', 'cf1:age']}
scan 'myns:mytable', {FILTER => "SingleColumnValueFilter('cf1', 'name', =, 'binary:value1')"}
scan 'myns:mytable', {FILTER => "PrefixFilter('row')"}
scan 'myns:mytable', {ROWPREFIXFILTER => 'row', LIMIT => 100}
scan 'myns:mytable', {TIMERANGE => [1234567890, 1234567900]}
## count
count 'myns:mytable'
count 'myns:mytable', INTERVAL => 100000
## delete
delete 'myns:mytable', 'row1', 'cf1:name'
deleteall 'myns:mytable', 'row1'
## increment counter
incr 'myns:mytable', 'row1', 'cf1:counter', 1
get_counter 'myns:mytable', 'row1', 'cf1:counter'

# snapshot
snapshot 'myns:mytable', 'mytable_snapshot'
list_snapshots
clone_snapshot 'mytable_snapshot', 'myns:mytable_clone'
restore_snapshot 'mytable_snapshot'              # table must be disabled
delete_snapshot 'mytable_snapshot'
## export snapshot to another cluster
hbase org.apache.hadoop.hbase.snapshot.ExportSnapshot \
  -snapshot mytable_snapshot \
  -copy-to hdfs://remote-cluster:8020/hbase \
  -mappers 16

# region management
list_regions 'myns:mytable'
move 'encoded_regionname', 'dest_server'
split 'myns:mytable', 'split_key'
merge_region 'encoded_region_a', 'encoded_region_b'
compact 'myns:mytable'
major_compact 'myns:mytable'
flush 'myns:mytable'
balance_switch true                              # enable auto balancer
balancer                                         # trigger balancer run

# bulk load
## generate HFiles
hbase org.apache.hadoop.hbase.tool.BulkLoadHFilesTool \
  hdfs:///path/to/hfiles 'myns:mytable'

# table permission (if ACL enabled)
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
