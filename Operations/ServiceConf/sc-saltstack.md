/etc/salt/master
```bash
default_include: master.d/*.conf
gather_job_timeout: 10  # salt job
timeout: 5  # salt command and api
#show_jid: False
worker_threads: 10
auto_accept: True
publisher_acl:
  saltstack:
    - test.ping
    - state.sls
fileserver_backend:
  - roots
  - gitfs
file_roots:
  base:
    - /srv/salt/base
  dev:
    - /srv/salt/dev
  prod:
    - /srv/salt/prod
hash_type: sha256
#gitfs_remotes:
#  - git://github.com/saltstack/salt-states.git
pillar_roots:
  base:
    - /srv/salt/pillar
log_file: /var/log/salt/master
key_logfile: /var/log/salt/key
log_level: info
log_level_logfile: info
```


/etc/salt/minion
```bash
id: minion_hostname
user: root
master:
 - 1.1.1.1
 - 8.8.8.8
master_port: 4506
backup_mode: minion
output: nested
acceptance_wait_time: 10
acceptance_wait_time_max: 0
random_reauth_delay: 60
hash_type: sha256
environment: base
```

