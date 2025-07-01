#=============================================================
# Author: Logic
# Created Time: Wed Sep 18 18:09:09 2024
#=============================================================
#!/bin/bash

set -e
trap 'echo "Backup failed"; exit 1' ERR

backup_dir="/backup"
timestamp=$(date +%Y%m%d%H%M%S)
backup_file="${backup_dir}/backup_${timestamp}.tar.gz"

# Create a backup
tar -czf "$backup_file" /important_data

echo "Backup completed: $backup_file"
