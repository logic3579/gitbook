/opt/pgsql/data/postgresql.conf
```bash
# PostgreSQL configuration file
# DB Version: 15
# OS Type: linux
# DB Type: web
# Total Memory (RAM): 4 GB
# CPUs num: 8
# Data Storage: ssd

max_connections = 200
shared_buffers = 1GB
effective_cache_size = 3GB
maintenance_work_mem = 256MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 1310kB
min_wal_size = 1GB
max_wal_size = 4GB
max_worker_processes = 8
max_parallel_workers_per_gather = 4
max_parallel_workers = 8
max_parallel_maintenance_workers = 4

#------------------------------------------------------------------------------
# FILE LOCATIONS
#------------------------------------------------------------------------------
# Data directory
data_directory = '/opt/pgsql/data'
# HBA file
hba_file = '/opt/pgsql/data/pg_hba.conf'
# Ident file
ident_file = '/opt/pgsql/data/pg_ident.conf'

```