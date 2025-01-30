# Package

## Arch
### pacman
```bash
#
```

## Debian
### apt
```bash
# update repo
apt update

# list packages
apt list
apt list --installed

# search package
apt search dig |grep bin

# show package detail
apt show bind9-dnsutils

# install
apt install zsh git svn telnet wget curl make cmake
apt install containerd.io

# remove
apt remove xxx

# upgrade
apt upgrade xxx

# show all repo and install special version
apt policy
apt policy firefox
apt install firefox=59.0.2+build1-0ubuntu1 



# apt-file
apt install apt-file
apt-file update
apt-file search dig |grep bin
```

### dpkg
```bash
# list packages concisely
dpkg -l

# find which package owning binary or library file
dpkg -S /usr/bin/lsb_release
dpkg -S /lib/libmultipath.so

# List files 'owned' by package
dpkg -L lsb-release

# manually install or remove a .deb file package
dpkg -i elasticsearch-8.8.2-amd64.deb
dpkg -r mysql-common && dpkg -P mysql-common
```

## RedHat
### dnf
```bash
# update repo
dnf update


# install package
dnf install zsh git svn telnet wget curl make cmake
dnf install containerd


# search
dnf search gtk | grep theme
dnf search shell-theme
dnf search icon-theme
dnf search cursor-theme

# show duplicates, in repos, in list/search commands
dnf list --showduplicates gcc
dnf search --showduplicates gcc

# Fedora
# install extensions
dnf install gnome-shell-extension-user-theme
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
# install chrome
dnf install fedora-workstation-repositories
dnf config-manager --set-enabled google-chrome
dnf update
dnf install google-chrome-stable
# install theme tools
dnf install gnome-shell-theme-yaru
dnf install gnome-tweak-tool
```

### rpm
```bash
# list packages concisely
rpm -qa

# find which package owning binary or library file
rpm -qf /bin/ls

# manually install or remove a .rpm file package
rpm -ivh xxx.rpm
```

