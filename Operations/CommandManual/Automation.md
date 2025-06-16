# Automation

## ansible

### inventory

```bash
# initial: for initalize the system
inventories/initial.host

# test hosts
inventories/test.host

# production hosts
inventories/prod.host
```

### ansible(ad-hoc modules)

```bash
# command usage
# optional arguments
--vault-password-file VAULT_PASSWORD_FILES
-B --backgroud SECONDS
-C --check
-D --diff
-P --poll POLL_INTERVAL
-a --args MODULE_ARGS
-e --extra-vars EXTRA_VARS
-f --forks FORKS
-i --inventory INVENTORY
-m --module-name MODULE_NAME
-t --tree TREE
# Privilege Escalation Options
--become-method BECOME_METHOD
--become-user BECOME_USER
-K --ask-become-pass
-b --become
# Connection Options
--private-key PRIVATE_KEY_FILE
--ssh-extra-args SSH_EXTRA_ARGS
-T --timeout TIMEOUT
-k --ask-pass
-u --user REMOTE_USER
-vvvv --verbose


# check all hosts
ansible all --list-hosts [-i inventories/test.host]
ansible all -m ping
ansible '*' -m ping
# pattern hosts
ansible '192.*' -m ping
ansible 'db*' -m ping
ansible 'web:&db' -m ping
ansible 'web:db' -m ping
ansible 'web:!db' -m ping
ansible "~(web|db).*\.example\.com" –m ping


# Common modules
# shell or script
ansible test -m command -a 'echo test'
ansible test -m shell -a 'chdir=/opt/ ls'
ansible test -m script -a /tmp/t.sh
# file or git transfer
ansible test -m copy -a "src=/tmp.t.sh dest=/tmp/t.sh mode=600 backup=yes"
ansible test -m file -a "dest=/etc/ansible/facts.d/ state=directory"
ansible test -m git -a "repo=git://foo.example.org/repo.git dest=/srv/myapp version=HEAD"
ansible test -m lineinfile
ansible test -m replace
# managing packages
ansible test -m apt -a "name=acme state=present"
ansible test -m yum -a "name=acme state=absent"
ansible test -m package -a "name=ntpdate state=absent"
# users and groups
ansible test -m user -a "name=nobody group=nobody state=present"
# managing services
ansible test -m service -a "name=httpd state=restarted"
ansible web -m systemd -a "name=httpd state=started"
# managing firewall
ansible test -m iptables -a "chain=INPUT destination_port=22 protocol=tcp jump=ACCEPT"
ansible test -m firewalld -a "service=https permanent=yes state=enabled"
# time limited background operations
ansible test -B 300 -P 2 -a "sleep 30"
ansible test -m async_status -a "jid=488359678239.2844"
```

### vars fact template

#### vars

```bash
# how to define
# 1. extra vars
-e "init_hosts=10.0.10.12,10.0.10.13" --check
-e '{"foo":"bar","numbers":["one","two"]}'
-e @variables.yaml
# 2. inventory vars
host1 http_port=80
[webservers:vars]
ntp_server=ntp.example.com
# 3. playbook: vars, include_vars, vars_files, vars_prompt, registered vars
- hosts: webservers
  vars:
    http_port: 80
  tasks:
    include_vars: myvars.yml
  vars_files:
    - /vars/external_vars.yml
  vars_prompt:
    - name: root_password
      prompt: 'Please input the root password:'
      private: yes
---
  tasks:
    - shell: uptime
      register: result
    - name: show uptime
      debug: var=result
# 4. role: roles/x/defaults/main.yml, roles/x/vars/main.yml
http_port: 80
# 5. fact
- host:
  tasks:
    - command: whoami
      register: result
    - set_fact: w={{result.stdout}}
    - debug: var=w

# priority
https://ansible.leops.cn/basic/Variables/#_3

# variable range
https://ansible.leops.cn/basic/Variables/#_4

# how to use
# 1. jinja2: template, vars
- hosts: test
  template: src=foo.cfg.j2 dest={{ remote_install_path }}/foo.cfg
  vars:
    app_path: "{{ base_path }}/22"
# 2. fact
- name: yakir test
  hosts: test
  tasks:
    - name: debug test
#      debug: msg={{ ansible_facts }}
      debug: msg={{ ansible_facts["default_ipv4"]["address"] }}
# 3. Built in variables
https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html
```

#### fact

```bash
# ansible setup info
ansible test -m setup
ansible test -m setup -a 'filter=ansible_eth*'


# custom fact
cat > playbooks/fact_test.yml << "EOF"
- name: facts test
  hosts: test
  tasks:
     - name: create directory for ansible custom facts
       file: state=directory recurse=yes path=/opt/ansible/facts.d
     - name: install custom test fact
       copy:
         content: |
           [forbid]
           foor=bar
         dest: /opt/ansible/facts.d/forbidden.fact
     - name: re-read facts after adding custom fact
       setup: filter=ansible_local
     - name: ansible_local vars
       debug: msg={{ansible_local}}
       # debug: var=ansible_local
EOF
ansible-playbook playbooks/fact_test.yml


# third cache: ansible.cfg
fact_caching_connection = localhost:6379:0:admin
fact_caching_connection = localhost:11211


# flush cache
ansible-playbook --flush-cache playbooks/example.yml
```

#### template

```bash
# jinja2 template
ansible test -m debug -a "msg={{ now(utc='True',fmt='%H-%m-%d %T') }}"

# use jinja2
vars:
  motd_value: "{{ lookup('file', '/etc/motd') }}"
tasks:
  - debug:
      msg: "motd value is {{ motd_value }}"
tasks:
  - shell: cat /some/path/to/file.json
    register: result
  - set_fact:
      myvar: "{{ result.stdout | from_json }}"
```

### ansible-console

```bash
ansible-console test

root@all (1)[f:5]$ ping
10.0.0.1 | SUCCESS => {
    "changed": false,
    "ping": "pong"

}
```

### ansible-doc

```bash
# List available plugins
ansible-doc --list

# show infomation
ansible-doc file
ansible-doc -t become -l
ansible-doc -j ping
ansible-doc -s ping
```

### ansible-galaxy

```bash
# collections
ansible-galaxy collection


# roles

# manual init template role and define tasks
ansible-galaxy role search nginx
ansible-galaxy role install nginx
ansible-galaxy role info nginx
ansible-galaxy role init /opt/ansible/roles/nginx

# online role
ansible-galaxy list
ansible-galaxy install geerlingguy.redis
ansible-galaxy remove geerlingguy.redis
```

### ansible-lint

```bash
# install
pip install ansible-lint

# use
ansible-lint playbooks/example.yml
```

### ansible-playbook

```bash
# execute example playbook
ansible-playbook playbooks/example.yml
# execute playbook use extra vars hosts
ansible-playbook -i inventories/initial.hosts playbooks/initial.yml -e "init_hosts=10.0.10.12,10.0.10.13" --check


# optional arguments
--ask-vault-pass
--flush-cache
--list-hosts
--list-tags
--list-tasks
--start-at-task START_AT_TASK
--step
--syntax-check
-C --check
-D --diff
-i --inventory INVENTORY
# Privilege Escalation Options
--become-method BECOME_METHOD
--become-user BECOME_USER
-K --ask-become-pass
-b --become
# Connection Options
--private-key PRIVATE_KEY_FILE
--ssh-extra-args SSH_EXTRA_ARGS
-T --timeout TIMEOUT
-k --ask-pass
-u --user REMOTE_USER
-vvvv --verbose


# import
# roles/example/tasks/main.yml
- name: added in 2.4, previously you used 'include'
  import_tasks: redhat.yml
  when: ansible_facts['os_family']|lower == 'redhat'
- import_tasks: debian.yml
  when: ansible_facts['os_family']|lower == 'debian'
# roles/example/tasks/redhat.yml
- yum:
    name: "httpd"
    state: present
# roles/example/tasks/debian.yml
- apt:
    name: "apache2"
    state: present

# include
- hosts: test
  tasks:
    - include_tasks: "{{inventory_hostname}}.yml"
    - include_tasks: other.yml param={{item}}
      loop: "{{ items | flatten(levels=1) }}"
    - include_role:
        name: example

- name: include vars
  include_vars: "{{ lookup('first_found', possible_files) }}"
  vars:
    possible_files:
      - "{{ ansible_distribution }}.yaml"
      - "{{ ansible_os_family }}.yaml"
      - default.yaml


# become


# asynchronous


# debuger


# step task
ansible-playbook playbooks/example.yml --start-at-task="install packages"
ansible-playbook playbooks/example.yml --step


```

### ansible-vault

```bash
# playbook operation
ansible-vault create playbooks/new.yml
ansible-vault edit playbooks/new.yml
ansible-vault view playbooks/example.yml
ansible-vault encrypt playbooks/example.yml
ansible-vault decrypt playbooks/example.yml


# option1: --ask-vault-pass or --vault-id
# --ask-vault-pass
ansible-vault encrypt_string pwd123 --name root_password
ansible-playbook playbooks/example.yml --start-at-task "Vault task" --ask-vault-pass
# --vault-id (recommend)
ansible-vault encrypt_string pwd123 --name root_password --vault-id prompt
#ansible-vault encrypt_string pwd123 --name root_password --vault-id example@prompt
ansible-playbook playbooks/example.yml --vault-id prompt


# option2: --vault-password-file or --vault-id
# --vault-password-file
ansible-vault encrypt playbooks/example.yml
echo "your_vault_pwd" > pwd.vault
ansible-playbook playbooks/example.yml --vault-password-file pwd.vault
# --vault-id (recommend)
ansible-vault encrypt playbooks/example.yml --vault-id pwd.vault
#ansible-vault encrypt playbooks/example.yml --vault-id example@pwd.vault
echo "your_vault_pwd" > pwd.vault
ansible-playbook playbooks/example.yml --vault-id pwd.vault
```

## saltstack

### minion keys

```bash
# select all keys
salt-key -L

# accept key
salt-key -a db1
salt-key -A

# delete key
salt-key -d web1
salt-key -d 'web*'
salt-key -D

# verify
salt '*' test.version
salt '*' test.ping

```

### match minion

```bash
# regular
salt '*' test.ping
salt 'web0[3-7]' test.ping

# regex pcre
salt -E 'web*|db*' test.ping

# list
salt -L 'node1,node2' test.ping

# grains
salt -G 'os:Ubuntu' test.version

# grains pcre
salt -P 'os:Arch.*' test.ping

# custom groups
cat /etc/salt/master.d/nodegroups.conf
nodegroups:
   FRONTEND: L@frontend1,frontend2,frontend3
   BACKEND: L@backend1,backend2,backend3
salt -N FRONTEND test.ping

# compound
salt -C 'G@roles:apps or I@myname:yakir' test.ping

# pillar
salt -I 'myname:yakir' test.ping

# CIDR
salt -S '192.168.1.0/24' test.ping
```

### module

```bash
# doc
salt 'node1' sys.doc
salt 'node1' sys.doc saltutil
salt 'node1' sys.doc pkg[.install]

# pkg
salt 'node1' pkg.install wget

# cmd
salt 'node1' cmd.run "ls /opt"

# cp
salt 'node1' cp.get_file salt://tmp/files/1.conf /tmp/1.conf
salt 'node1' cp.get_file salt://{{grains.os}}/vimrc /etc/vimrc template=jinja
salt 'node1' cp.get_dir salt://tmp/dir /tmp/dir

# custom module
mkdir /srv/salt/base/_modules
tee > /srv/salt/base/_modules/mydisk.py << "EOF"
def df():
    return __salt__['cmd.run']('df -h')
EOF
salt '*' saltutil.sync_modules
salt 'node1' mydisk.df
```

### state structure

```bash
# state sls files
tee > /srv/salt/base/package/tree.sls << "EOF"
install_tree_now:
  pkg.installed:
    - pkgs:
      - tree
EOF
tee > /srv/salt/base/package/nginx.sls << "EOF"
install_tree_now:
  pkg.installed:
    - pkgs:
      - nginx
EOF
tee > /srv/salt/base/tmp/init.sls << "EOF"
apache:
  pkg.installed:
    - pkgs:
      - httpd
  file.managed:
    - name: /etc/httpd/conf/httpd.conf
    - source: salt://tmp/files/httpd.conf
  service.running:
    - name: httpd
    - reload: true
    - enable: truej
    - watch:
      - file: apache
EOF


# show state sls
salt 'node1' state.show_highstate [saltenv=dev]
salt 'node1' state.show_sls template [saltenv=dev]
salt 'node1' cp.list_states [saltenv=dev]


# execute top high state sls
tee > /srv/salt/base/top.sls << "EOF"
base:
  'node1':
    - package.tree
    - package.nginx
  'node2':
    - tmp
  'frontend'
    - match: nodegroup
    - nginx
  'os:Ubuntu':
    - match: grain
    - apache
dev:
  'webserver*dev*':
    - webserver
  'db*dev*':
    - db
EOF
salt 'node1' state.highstate [--batch 10%|10] [test=True]


# execute regular state sls
salt '*' state.sls tmp[.init] [saltenv=dev] [test=True]
salt '*' state.sls package.nginx [saltenv=dev] [test=True]
```

### grains

```bash
salt '*' saltutil.refresh_grains [saltenv=base|dev|prod]
salt '*' saltutil.sync_grains
salt '*' grains.ls
salt '*' grains.items
salt '*' grains.item username


# default cache dir
/var/cache/salt/master/minions/node1/data.p

# listening grains
salt '*' grains.ls
    - os
    - username
    ...
salt '*' grains.items
    os:
        Ubuntu
    osrelease:
        20.04
    ...

# target with grains
salt -G 'os:Ubuntu' test.version
salt -G 'host:node1' grains.item os
salt -G 'ip_interfaces:ens160:172.22.3.*' test.ping


# defining custom grains:
# in master
# option1 (save to minion /etc/salt/grains)
salt minion01 grains.setval roles "['web','app1','dev']"
# option2 (save to minion /var/cache/salt/minion/extmods/grains)
mkdir /srv/salt/base/_grains
tee > /srv/salt/base/_grains/mem.py << "EOF"
def my_grains():
    grains = {}
    grains['my_bool'] = True
    grains['my_str'] = 'str_test'
    return grains
EOF
salt minion01 saltutil.sync_grains

# in minion
# option1
tee > /etc/salt/minion.d/grains.conf << "EOF"
grains:
  roles: app1
  project: frontend
EOF
systemctl restart salt-minion
# option2
tee > /etc/salt/grains << "EOF"
roles: app1
project: frontend
EOF
salt minion01 saltutil.sync_grains

# test
salt minion01 grains.item roles project
salt minion01 grains.item my_bool my_str
salt -G 'roles:app1' test.ping


# use state sls with grains
{{ salt['grains.get']('os') }}
{{ salt['grains.get']('os', ‘Debian’) }}

```

### pillar

```bash
salt '*' saltutil.refresh_pillar [pillarenv=base|dev|prod]
salt '*' pillar.ls
salt '*' pillar.items
salt '*' pillar.item mysql

# pillar_roots
tee > /srv/salt/pillar/mypillar.sls << "EOF"
{% if grains['fqdn'] == 'node1' %}
myname: yakir
{% elif grains['fqdn'] == 'node2' %}
myname: andy
{% endif %}
port: 80
EOF

tee > /srv/salt/pillar/top.sls << "EOF"
base:
  '*':
    - mypillar
dev:
  'os:Debian':
    - match: grain
    - vim
test:
  '* and not G@os: Debian':
    - match: compound
    - emacs
EOF

salt '*' pillar.items
salt '*' saltutil.refresh_pillar
salt '*' pillar.item myname port

# use pillar by sls file
tee > /srv/salt/base/tmp/init.sls << "EOF"
apache:
  pkg.installed:
    - pkgs:
      - {{ pillar['myname'] }}
  service.running:
    - name: httpd
    - reload: true
    - enable: true
    - watch:
      - file: /etc/httpd/conf/httpd.conf

/etc/httpd/conf/httpd.conf:
  file.managed:
    - source: salt://apache/httpd.conf
EOF

salt '*' state.sls tmp.init
```

