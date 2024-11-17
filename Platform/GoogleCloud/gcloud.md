---
description: gcloud client tool
---

# gcloud

## GCE
```bash
# get info
gcloud compute instances list --format="value(name,zone)"

# update 
gcloud compute instances update $name --zone $zone --deletion-protection
```



> Reference:
> 1. [Official Website](https://cloud.google.com/sdk/gcloud/reference/)
