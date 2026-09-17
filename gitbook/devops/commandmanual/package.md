---
description: Package manager CLI references for apt, dpkg, dnf, rpm, and pacman
tags:
  - devops/command
---

# Package

## apt (Debian / Ubuntu)

### Repo Cache

```bash
apt update
```

### Search

```bash
apt search dig | grep bin

# apt-file: search by file path inside packages (not yet installed)
apt install apt-file
apt-file update
apt-file search dig | grep bin
```

### Install

```bash
apt install zsh git svn telnet wget curl make cmake
apt install containerd.io
```

### Remove

```bash
apt remove xxx
apt purge xxx                          # also remove config files
apt autoremove                         # remove orphaned dependencies
```

### Upgrade

```bash
apt upgrade                            # upgrade installed packages
apt upgrade xxx                        # upgrade one package
apt full-upgrade                       # may remove packages to satisfy deps
```

### Info

```bash
apt list
apt list --installed
apt show bind9-dnsutils
```

### Versions & Pinning

```bash
# all available versions across enabled repos
apt policy
apt policy firefox

# install a specific version
apt install firefox=59.0.2+build1-0ubuntu1
```

## dpkg (Debian / Ubuntu)

### List Installed

```bash
dpkg -l
dpkg -l | grep nginx
```

### Find Owner of File

```bash
dpkg -S /usr/bin/lsb_release
dpkg -S /lib/libmultipath.so
```

### List Files of a Package

```bash
dpkg -L lsb-release
```

### Local File Install / Remove

```bash
dpkg -i elasticsearch-8.8.2-amd64.deb
dpkg -r mysql-common                   # remove (keep config)
dpkg -P mysql-common                   # purge (remove config)
```

## dnf (RHEL / Fedora)

### Repo Cache & Management

```bash
dnf repolist

# enable / disable a repo
dnf config-manager --set-enabled crb
dnf config-manager --set-disabled crb

# refresh metadata
dnf update                             # also upgrades; use `dnf check-update` for read-only
dnf clean all
```

### Search

```bash
dnf search gtk | grep theme
dnf search shell-theme
```

### Install

```bash
dnf install zsh git svn telnet wget curl make cmake
dnf install containerd
```

### Remove

```bash
dnf remove xxx
dnf autoremove                         # remove orphaned dependencies
```

### Upgrade

```bash
dnf upgrade                            # upgrade all (alias of `dnf update`)
dnf upgrade xxx                        # upgrade one package
```

### Info

```bash
dnf list installed
dnf info bind-utils
```

### Versions & Pinning

```bash
# show all available versions across enabled repos
dnf list --showduplicates gcc
dnf search --showduplicates gcc

# install a specific version
dnf install gcc-11.4.1-3.el9
```

### Modules (AppStream)

```bash
dnf module list
dnf module enable nodejs:18
dnf module disable <module>:<stream>
dnf module reset <module>
```

## rpm (RHEL / Fedora)

### List Installed

```bash
rpm -qa
rpm -qa | grep nginx
```

### Find Owner of File

```bash
rpm -qf /bin/ls
```

### List Files of a Package

```bash
rpm -ql nginx
```

### Local File Install / Remove

```bash
rpm -ivh xxx.rpm                       # install verbose with progress
rpm -Uvh xxx.rpm                       # upgrade (install if not present)
rpm -e xxx                             # remove
```

### Verify

```bash
rpm -V nginx                           # verify package integrity
rpm -qip xxx.rpm                       # info about a .rpm file
```

## pacman (Arch)

### Repo Cache

```bash
pacman -Sy                             # refresh package database
pacman -Syu                            # refresh + upgrade everything
```

### Search

```bash
pacman -Ss nginx                       # search remote repos
pacman -Qs nginx                       # search installed packages
```

### Install

```bash
pacman -S zsh git curl make cmake
```

### Remove

```bash
pacman -R nginx
pacman -Rs nginx                       # also remove unused dependencies
pacman -Rns nginx                      # also remove config files
```

### Upgrade

```bash
pacman -Syu                            # upgrade all
pacman -S nginx                        # upgrading by re-installing
```

### Info

```bash
pacman -Q                              # list installed packages
pacman -Qi nginx                       # info about installed package
pacman -Si nginx                       # info about remote package
```

### Find Owner of File

```bash
pacman -Qo /usr/bin/nginx
```

### List Files of a Package

```bash
pacman -Ql nginx
```

### Local File Install

```bash
pacman -U ./pkgname-1.0-1-x86_64.pkg.tar.zst
```

> Reference:
>
> 1. [apt Documentation](https://manpages.debian.org/bullseye/apt/apt.8.en.html)
> 2. [dpkg Documentation](https://manpages.debian.org/bullseye/dpkg/dpkg.1.en.html)
> 3. [dnf Documentation](https://dnf.readthedocs.io/)
> 4. [rpm Documentation](https://rpm-software-management.github.io/rpm/manual/)
> 5. [pacman Wiki](https://wiki.archlinux.org/title/Pacman)
