# Memory Tools

## free vm memory

```bash
# 0：do not release (default)
# 1：release page cache
# 2：release dentries and inodes cache
# 3：release all cache
echo int > /proc/sys/vm/drop_caches
echo 0 > /proc/sys/vm/drop_caches
```
