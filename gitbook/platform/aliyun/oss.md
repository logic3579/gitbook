---
description: Aliyun Object Storage Service
tags:
  - platform/aliyun
  - storage
---

# OSS

Aliyun Object Storage Service (OSS) provides massively scalable object storage. Day-to-day operations use `ossutil` (the dedicated CLI); `aliyun oss` is also supported via OpenAPI.

## Storage Classes

| Class | Use Case | Minimum Storage |
|-------|----------|-----------------|
| **Standard** | Hot data, frequent access | None |
| **Infrequent Access (IA)** | Cool data, occasional access | 30 days |
| **Archive** | Cold data, rare access | 60 days |
| **Cold Archive** | Coldest, very rarely accessed | 180 days |
| **Deep Cold Archive** | Long-term retention | 180 days |

## CLI

### Buckets

```bash
ossutil mb oss://BUCKET_NAME --storage-class Standard --acl private
ossutil ls oss://
ossutil stat oss://BUCKET_NAME
ossutil rb oss://BUCKET_NAME
ossutil rb oss://BUCKET_NAME -r -f                # delete recursively

# Bucket policy / ACL
ossutil bucket-policy --method put oss://BUCKET_NAME policy.json
ossutil bucket-policy --method get oss://BUCKET_NAME
ossutil set-acl oss://BUCKET_NAME public-read --bucket
```

### Objects

```bash
ossutil cp LOCAL_FILE oss://BUCKET_NAME/PREFIX/
ossutil cp oss://BUCKET_NAME/KEY ./
ossutil cp -r LOCAL_DIR oss://BUCKET_NAME/PREFIX/  # recursive upload
ossutil cp -r oss://SRC/ oss://DST/                # copy between buckets

ossutil ls oss://BUCKET_NAME/PREFIX/
ossutil stat oss://BUCKET_NAME/KEY
ossutil rm oss://BUCKET_NAME/KEY
ossutil rm -r -f oss://BUCKET_NAME/PREFIX/         # bulk delete
```

### Sync

```bash
ossutil sync LOCAL_DIR oss://BUCKET_NAME/PREFIX/
ossutil sync oss://BUCKET_NAME/PREFIX/ LOCAL_DIR
ossutil sync --delete LOCAL_DIR oss://BUCKET_NAME/PREFIX/   # mirror, deletes extras
```

### Multipart Upload

```bash
# Large files split automatically; tune part size and concurrency
ossutil cp BIG_FILE oss://BUCKET_NAME/ --part-size 16777216 --parallel 8

# Inspect / resume / abort uncommitted uploads
ossutil ls oss://BUCKET_NAME/ -m
ossutil rm oss://BUCKET_NAME/ -m -r -f             # abort all incomplete
```

### Signed URLs

```bash
ossutil sign oss://BUCKET_NAME/KEY --timeout 3600  # presigned GET, 1 hour
```

### Lifecycle Rules

```bash
ossutil lifecycle --method put oss://BUCKET_NAME lifecycle.json
ossutil lifecycle --method get oss://BUCKET_NAME
ossutil lifecycle --method delete oss://BUCKET_NAME
```

> Reference:
>
> 1. [Official Website](https://www.alibabacloud.com/product/oss)
> 2. [ossutil Documentation](https://www.alibabacloud.com/help/en/oss/developer-reference/ossutil-overview)
