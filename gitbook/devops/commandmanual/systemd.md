---
description: Systemd service management and system control CLI references
tags:
  - devops/command
---

# Systemd

## bootctl

```bash
bootctl status
bootctl status --esp-path /mnt/lfs/boot/
```

## hostnamectl

```bash
hostnamectl status
hostnamectl set-hostname east-web-x
```

## localectl

```bash
localectl status
localectl list-locales
localectl set-locale LANG=en_US.UTF-8
```

## timedatectl

```bash
timedatectl status
timedatectl list-timezones

# set clock manually
timedatectl set-time YYYY-MM-DD
timedatectl set-time HH:MM:SS

# set timezone
timedatectl set-timezone Asia/Hong_Kong

# enable / disable NTP sync (systemd-timesyncd)
timedatectl set-ntp true
timedatectl set-ntp false
```

## networkctl

```bash
# inspect
networkctl list
networkctl status
networkctl status eth0

# trigger systemd-networkd to re-read configs
networkctl reload
networkctl reconfigure eth0
```

## systemd-analyze

```bash
# overall boot time
systemd-analyze

# slowest units by activation time
systemd-analyze blame

# critical chain leading to default.target
systemd-analyze critical-chain

# verify a unit file's syntax
systemd-analyze verify /etc/systemd/system/myapp.service
```

## loginctl

### Sessions

```bash
loginctl list-sessions
loginctl session-status <session-id>
```

### Users

```bash
loginctl list-users
loginctl user-status <username>
loginctl show-user root
```

## journalctl

### Time Range

```bash
# -S / --since   start time
# -U / --until   end time
journalctl --since "2024-01-01"
journalctl --since "2024-01-01 09:00:00" --until "2024-01-01 09:15:00"
journalctl --since "20 min ago" --until "10 min ago"
```

### Boot & Kernel

```bash
# current boot only
journalctl -b
journalctl -b -0                       # same as -b
journalctl -b -1                       # previous boot

# list all stored boots
journalctl --list-boots

# kernel ring buffer
journalctl -k
journalctl --dmesg
```

### Unit & Priority

```bash
# logs for one or more units
journalctl -u nginx.service
journalctl -u nginx.service -u httpd.service

# filter by syslog priority
journalctl -p err                      # err and above
journalctl -p [debug|info|notice|warning|err|crit|alert|emerg]

# filter by PID / UID / GID / executable
journalctl _PID=123
journalctl _UID=1000
journalctl _EXE=/usr/bin/nginx
```

### Output Format

```bash
# -o short | short-iso | json | json-pretty | cat | verbose
journalctl -u nginx -o json-pretty
journalctl -u nginx -o cat             # message only, no timestamp/host

# add catalog explanations where available
journalctl -xe
```

### Follow & Pager

```bash
# follow (like tail -f)
journalctl -f
journalctl -fu nginx.service

# tail last N lines
journalctl -n 100
journalctl -n 100 -u nginx.service

# jump to end of pager
journalctl -e

# show newest first
journalctl -r
```

### Maintenance

```bash
# disk usage
journalctl --disk-usage

# vacuum by size / time / file count
journalctl --vacuum-size=500M
journalctl --vacuum-time=7d
journalctl --vacuum-files=10

# rotate active journal
journalctl --rotate
```

### Common Recipes

```bash
# tail the last 10 entries of two services, with catalog
journalctl -xe -u nginx.service -u httpd.service -n 10 -f

# everything for a unit since last boot, in JSON
journalctl -u nginx.service -b -o json-pretty
```

## systemctl

### Unit Commands

```bash
systemctl list-units
systemctl list-units --type=service --state=running
systemctl --failed                     # only failed units

systemctl cat|start|stop|reload|restart|kill|is-active nginx.service
systemctl reload-or-restart nginx.service

# dependencies
systemctl list-dependencies nginx.service
systemctl list-dependencies multi-user.target

# switch runlevel target
systemctl isolate multi-user.target
```

### Unit File Commands

```bash
systemctl list-unit-files

# enable / disable autostart
systemctl enable nginx.service
systemctl enable --now nginx.service   # enable + start in one shot
systemctl disable nginx.service
systemctl is-enabled nginx.service

# mask: forbid the unit (stronger than disable)
systemctl mask nginx.service
systemctl unmask nginx.service

# default target (e.g. graphical.target / multi-user.target)
systemctl get-default
systemctl set-default multi-user.target
```

### Edit & Override

```bash
# create or edit a drop-in override (recommended over editing vendor unit)
systemctl edit nginx.service
systemctl edit --full nginx.service    # override the whole unit

# revert overrides
systemctl revert nginx.service
```

### Properties

```bash
# read properties
systemctl show nginx.service
systemctl show -p CPUShares nginx.service

# set a property at runtime (persists across daemon-reload with --runtime drop)
systemctl set-property nginx.service CPUShares=500
systemctl set-property nginx.service MemoryMax=1G
```

### Manager State

```bash
# re-read unit files after editing
systemctl daemon-reload

# re-execute the systemd manager itself
systemctl daemon-reexec

# log verbosity of the manager
systemctl log-level
systemctl log-target
```

### System Commands

```bash
systemctl rescue
systemctl halt
systemctl poweroff
systemctl reboot [ARG]
systemctl suspend
systemctl hibernate
```

### Other

```bash
# nspawn / multi-host
systemctl list-machines

# pending jobs in the queue
systemctl list-jobs

# inspect / modify the manager's environment
systemctl show-environment
systemctl set-environment VARIABLE=VALUE
systemctl unset-environment VARIABLE
```

> Reference:
>
> 1. [systemctl(1)](https://www.freedesktop.org/software/systemd/man/systemctl.html)
> 2. [journalctl(1)](https://www.freedesktop.org/software/systemd/man/journalctl.html)
> 3. [Systemd Beginner's Tutorial](https://ruanyifeng.com/blog/2016/03/systemd-tutorial-commands.html)
