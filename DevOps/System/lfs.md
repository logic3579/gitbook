---
description: Linux From Scratch 12.1 for systemd
---

# Linux From Scratch 12.1

## Introduction
...

## Preparing for the Build
### Preparing the Host System
#### Creating a New Partition
```bash
su - root

# legacy
# partitioning
parted /dev/sdb -- unit mib 
parted /dev/sdb -- mklabel gpt
parted /dev/sdb -- mkpart primary 1 3
parted /dev/sdb -- mkpart primary ext4 3 515
parted /dev/sdb -- mkpart root ext4 515 -1
parted /dev/sdb -- set 1 bios_grub on
# formating
mkfs.ext4 -v /dev/sdb2
mkfs.ext4 -v /dev/sdb3


# UEFI
# partitioning
parted /dev/sdb -- unit mib 
parted /dev/sdb -- mklabel gpt
parted /dev/sdb -- mkpart primary 1 3
parted /dev/sdb -- mkpart ESP fat32 3 515
parted /dev/sdb -- mkpart root ext4 515 -1
parted /dev/sdb -- set 1 bios_grub on
parted /dev/sdb -- set 2 esp on
# formating
mkfs.fat -F 32 -n boot /dev/sdb2
mkfs.ext4 -v /dev/sdb3
```

#### Setting The $LFS Variable
```bash
cat >> /root/.bashrc << EOF
export LFS=/mnt/lfs
EOF
source /root/.bashrc
```

#### Mounting the New Partition
```bash
# legacy
mkdir -pv $LFS
mount -v -t ext4 /dev/sdb3 $LFS
mkdir -v $LFS/boot
mount -v -t ext4 /dev/sdb2 $LFS/boot/

# UEFI
mkdir -pv $LFS
mount -v -t ext4 /dev/sdb3 $LFS
mkdir -pv $LFS/boot/efi
mount -t vfat -o codepage=437,iocharset=iso8859-1 /dev/sda2 /boot/efi


# option: temp persistence mount
cat >> /etc/fstab
# legacy
UUID="638d219e-f1a0-401c-b4cf-de79860a0445" /mnt/lfs ext4 defaults 1 1
PARTUUID="d47b7e0a-61fe-4c96-a387-13c07b53ddb7" /mnt/lfs/boot ext4 defaults 1 1
# UEFI
UUID="638d219e-f1a0-401c-b4cf-de79860a0445" /mnt/lfs ext4 defaults 0 1
PARTUUID="d47b7e0a-61fe-4c96-a387-13c07b53ddb7" /mnt/lfs/boot/efi vfat codepage=437,iocharset=iso8859-1 0 1
```

### Packages and Patches
```bash
mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources

# get source packages and patch
wget https://lfs.xry111.site/zh_CN/12.1-systemd/wget-list-systemd
#cat wget-list-systemd |awk -F'/' '{print "https://repo.jing.rocks/lfs/lfs-packages/12.1/"$NF}' |tee wget-list-systemd
wget --input-file=wget-list-systemd --continue --directory-prefix=$LFS/sources

# option: check md5sum
wget https://lfs.xry111.site/zh_CN/12.1-systemd/md5sums
pushd $LFS/sources
  md5sum -c md5sums
popd

chown root:root $LFS/sources/*
```

### Final Preparations
#### Creating a Limited Directory Layout in the LFS Filesystem
```bash
# Create the required directory layout by issuing the following commands as root
mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}

for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done

case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac

# cross-compiler directory
mkdir -pv $LFS/tools
```

#### Adding the LFS User
```bash
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
echo "lfs:lfs123" | chpasswd

chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -v lfs $LFS/lib64 ;;
esac

# change to user lfs
su - lfs
```

#### Setting Up the Environment
```bash
# setup bash_profile
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

# setup bashrc
cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
# make -jx parallel number
export MAKEFLAGS=-j$(nproc)
EOF

# rename /etc/bash.bashrc
[ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE

source ~/.bash_profile
```

## Building the LFS Cross Toolchain and Temporary Tools
### Compiling a Cross-Toolchain
#### Binutils-2.42 - Pass 1
```bash
cd $LFS/sources
tar xf binutils-2.42.tar.xz && cd binutils-2.42
mkdir -v build && cd build

../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror    \
             --enable-default-hash-style=gnu

make && make install

cd $LFS/sources && rm -rf binutils-2.42
```

#### GCC-13.2.0 - Pass 1
```bash
tar xf gcc-13.2.0.tar.xz && cd gcc-13.2.0

tar -xf ../mpfr-4.2.1.tar.xz
mv -v mpfr-4.2.1 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
 ;;
esac

mkdir -v build && cd build

../configure                  \
    --target=$LFS_TGT         \
    --prefix=$LFS/tools       \
    --with-glibc-version=2.39 \
    --with-sysroot=$LFS       \
    --with-newlib             \
    --without-headers         \
    --enable-default-pie      \
    --enable-default-ssp      \
    --disable-nls             \
    --disable-shared          \
    --disable-multilib        \
    --disable-threads         \
    --disable-libatomic       \
    --disable-libgomp         \
    --disable-libquadmath     \
    --disable-libssp          \
    --disable-libvtv          \
    --disable-libstdcxx       \
    --enable-languages=c,c++

make && make install 

cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h

cd $LFS/sources && rm -rf gcc-13.2.0
```

#### Linux-6.7.4 API Headers
```bash
tar xf linux-6.7.4.tar.xz && cd linux-6.7.4

make mrproper

make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr

cd $LFS/sources && rm -rf linux-6.7.4
```

#### Glibc-2.39
```bash
tar xf glibc-2.39.tar.xz && cd glibc-2.39

case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
    ;;
esac

patch -Np1 -i ../glibc-2.39-fhs-1.patch

mkdir -v build && cd build

echo "rootsbindir=/usr/sbin" > configparms

../configure                             \
      --prefix=/usr                      \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=4.19               \
      --with-headers=$LFS/usr/include    \
      --disable-nscd                     \
      libc_cv_slibdir=/usr/lib

make && make DESTDIR=$LFS install

sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd

# check
echo 'int main(){}' | $LFS_TGT-gcc -xc -
readelf -l a.out | grep ld-linux
[Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]
rm -v a.out

cd $LFS/sources && rm -rf glibc-2.39
```

#### Libstdc++ from GCC-13.2.0
```bash
tar xf gcc-13.2.0.tar.xz && cd gcc-13.2.0

mkdir -v build && cd build

../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --build=$(../config.guess)      \
    --prefix=/usr                   \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/13.2.0

make && make DESTDIR=$LFS install

rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la

cd $LFS/sources && rm -rf gcc-13.2.0
```

### Cross Compiling Temporary Tools
#### M4-1.4.19
```bash
tar xf m4-1.4.19.tar.xz && cd m4-1.4.19

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make && make DESTDIR=$LFS install

cd $LFS/sources && rm -rf m4-1.4.19
```

#### Ncurses-6.4-20230520
```bash
tar xf ncurses-6.4-20230520.tar.xz && cd ncurses-6.4-20230520

sed -i s/mawk// configure

mkdir build
pushd build
  ../configure
  make -C include
  make -C progs tic
popd

./configure --prefix=/usr                \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-normal             \
            --with-cxx-shared            \
            --without-debug              \
            --without-ada                \
            --disable-stripping          \
            --enable-widec

make && make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i $LFS/usr/include/curses.h

cd $LFS/sources && rm -rf ncurses-6.4-20230520
```

#### Bash-5.2.21
```bash
tar xf bash-5.2.21.tar.gz && cd bash-5.2.21

./configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc

make && make DESTDIR=$LFS install

ln -sv bash $LFS/bin/sh

cd $LFS/sources && rm -rf bash-5.2.21
```

#### Coreutils-9.4
```bash
tar xf coreutils-9.4.tar.xz && cd coreutils-9.4

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime

make && make DESTDIR=$LFS install

mv -v $LFS/usr/bin/chroot $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' $LFS/usr/share/man/man8/chroot.8

cd $LFS/sources && rm -rf coreutils-9.4
```

#### Diffutils-3.10
```bash
tar xf diffutils-3.10.tar.xz && cd diffutils-3.10

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)

make && make DESTDIR=$LFS install

cd $LFS/sources && rm -rf diffutils-3.10
```

#### File-5.45
```bash
tar xf file-5.45.tar.gz && cd file-5.45

mkdir build
pushd build
  ../configure --disable-bzlib      \
               --disable-libseccomp \
               --disable-xzlib      \
               --disable-zlib
  make
popd

./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)

make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install

rm -v $LFS/usr/lib/libmagic.la

cd $LFS/sources && rm -rf file-5.45
```

#### Findutils-4.9.0
```bash
tar xf findutils-4.9.0.tar.xz && cd findutils-4.9.0

./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)

make && make DESTDIR=$LFS install

cd $LFS/sources && rm -rf findutils-4.9.0
```

#### Gawk-5.3.0
```bash
tar xf gawk-5.3.0.tar.xz && cd gawk-5.3.0

sed -i 's/extras//' Makefile.in

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make && make DESTDIR=$LFS install

cd $LFS/sources && rm -rf gawk-5.3.0
```

#### Grep-3.11
```bash
tar xf grep-3.11.tar.xz && cd grep-3.11

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)

make && make DESTDIR=$LFS install

cd $LFS/sources && rm -rf grep-3.11
```

#### Gzip-1.13
```bash
tar xf gzip-1.13.tar.xz && cd gzip-1.13

./configure --prefix=/usr --host=$LFS_TGT

make && make DESTDIR=$LFS install

cd $LFS/sources && rm -rf gzip-1.13
```

#### Make-4.4.1
```bash
tar xf make-4.4.1.tar.gz && cd make-4.4.1

./configure --prefix=/usr   \
            --without-guile \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make && make DESTDIR=$LFS install

cd $LFS/sources && rm -rf make-4.4.1
```

#### Patch-2.7.6
```bash
tar xf patch-2.7.6.tar.xz && cd patch-2.7.6

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make && make DESTDIR=$LFS install

cd $LFS/sources && rm -rf patch-2.7.6
```

#### Sed-4.9
```bash
tar xf sed-4.9.tar.xz && cd sed-4.9

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)

make && make DESTDIR=$LFS install

cd $LFS/sources && rm -rf sed-4.9
```

#### Tar-1.35
```bash
tar xf tar-1.35.tar.xz && cd tar-1.35

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess)

make && make DESTDIR=$LFS install

cd $LFS/sources && rm -rf tar-1.35
```

#### Xz-5.4.6
```bash
tar xf xz-5.4.6.tar.xz && cd xz-5.4.6

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.4.6

make && make DESTDIR=$LFS install

rm -v $LFS/usr/lib/liblzma.la

cd $LFS/sources && rm -rf xz-5.4.6
```

#### Binutils-2.42 - Pass 2
```bash
cd $LFS/sources
tar xf binutils-2.42.tar.xz && cd binutils-2.42

sed '6009s/$add_dir//' -i ltmain.sh

mkdir -v build && cd build

../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd        \
    --enable-default-hash-style=gnu

make && make DESTDIR=$LFS install

rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

cd $LFS/sources && rm -rf binutils-2.42
```

#### GCC-13.2.0 - Pass 2
```bash
tar xf gcc-13.2.0.tar.xz && cd gcc-13.2.0

tar -xf ../mpfr-4.2.1.tar.xz
mv -v mpfr-4.2.1 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

mkdir -v build && cd build

../configure                                       \
    --build=$(../config.guess)                     \
    --host=$LFS_TGT                                \
    --target=$LFS_TGT                              \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc      \
    --prefix=/usr                                  \
    --with-build-sysroot=$LFS                      \
    --enable-default-pie                           \
    --enable-default-ssp                           \
    --disable-nls                                  \
    --disable-multilib                             \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libsanitizer                         \
    --disable-libssp                               \
    --disable-libvtv                               \
    --enable-languages=c,c++

make && make DESTDIR=$LFS install

ln -sv gcc $LFS/usr/bin/cc

cd $LFS/sources && rm -rf gcc-13.2.0
```

### Entering Chroot and Building Additional Temporary Tools
#### Prerequisite
```bash
# Introduction
su - root
export LFS=/mnt/lfs


# Changing Ownership
chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -R root:root $LFS/lib64 ;;
esac


# Preparing Virtual Kernel File Systems
mkdir -pv $LFS/{dev,proc,sys,run}

mount -v --bind /dev $LFS/dev
mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
  install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
  mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi


# Entering the Chroot Environment
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j$(nproc)"      \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login


# Creating Directories
mkdir -pv /{boot,home,mnt,opt,srv}
mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp


# Creating Essential Files and Symlinks
ln -sv /proc/self/mounts /etc/mtab

cat > /etc/hosts << "EOF"
127.0.0.1  localhost $(hostname)
::1        localhost
EOF

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF

echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd
echo "tester:x:101:" >> /etc/group
install -o tester -d /home/tester

exec /usr/bin/bash --login

touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp
```

#### Gettext-0.22.4
```bash
cd /sources/
tar xf gettext-0.22.4.tar.xz && cd gettext-0.22.4

./configure --disable-shared

make && cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

cd /sources/ && rm -rf gettext-0.22.4
```

#### Bison-3.8.2
```bash
tar xf bison-3.8.2.tar.xz && cd bison-3.8.2

./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.8.2

make && make install

cd /sources/ && rm -rf bison-3.8.2
```

#### Perl-5.38.2
```bash
tar xf perl-5.38.2.tar.xz && cd perl-5.38.2

sh Configure -des                                        \
             -Dprefix=/usr                               \
             -Dvendorprefix=/usr                         \
             -Duseshrplib                                \
             -Dprivlib=/usr/lib/perl5/5.38/core_perl     \
             -Darchlib=/usr/lib/perl5/5.38/core_perl     \
             -Dsitelib=/usr/lib/perl5/5.38/site_perl     \
             -Dsitearch=/usr/lib/perl5/5.38/site_perl    \
             -Dvendorlib=/usr/lib/perl5/5.38/vendor_perl \
             -Dvendorarch=/usr/lib/perl5/5.38/vendor_perl

make && make install

cd /sources/ && rm -rf perl-5.38.2
```

#### Python-3.12.2
```bash
tar xf Python-3.12.2.tar.xz && cd Python-3.12.2

./configure --prefix=/usr   \
            --enable-shared \
            --without-ensurepip

make && make install

cd /sources/ && rm -rf Python-3.12.2
```

#### Texinfo-7.1
```bash
tar xf texinfo-7.1.tar.xz && cd texinfo-7.1

./configure --prefix=/usr

make && make install

cd /sources/ && rm -rf texinfo-7.1
```

#### Util-linux-2.39.3
```bash
tar xf util-linux-2.39.3.tar.xz && cd util-linux-2.39.3

mkdir -pv /var/lib/hwclock

./configure --libdir=/usr/lib    \
            --runstatedir=/run   \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python     \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.39.3

make && make install

cd /sources/ && rm -rf util-linux-2.39.3
```

#### Cleaning up and Saving the Temporary System
```bash
# cleaning
rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,libexec} -name \*.la -delete
rm -rf /tools


# backup
exit
su - root
export LFS=/mnt/lfs

mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
umount $LFS/dev/pts
umount $LFS/{sys,proc,run,dev}

cd $LFS
tar -cJpf $HOME/lfs-temp-tools-12.1.tar.xz .


# restore
export LFS=/mnt/lfs && cd $LFS
rm -rf ./*
tar -xpf $HOME/lfs-temp-tools-12.1.tar.xz
```

## Building the LFS System
### Installing Basic System Software
#### [[Linux From Scratch 12.1#Prerequisite|Prerequisite]]
1. `findmnt | grep $LFS`
2. Preparing Virtual Kernel File Systems
3. Entering the Chroot Environment

#### Man-pages-6.06
```bash
cd /sources/
tar xf man-pages-6.06.tar.xz && cd man-pages-6.06

rm -v man3/crypt*

make prefix=/usr install

cd /sources/ && rm -rf man-pages-6.06
```

#### Iana-Etc-20240125
```bash
tar xf iana-etc-20240125.tar.gz && cd iana-etc-20240125

cp services protocols /etc

cd /sources/ && rm -rf iana-etc-20240125
```

#### Glibc-2.39
```bash
# install
tar xf glibc-2.39.tar.xz && cd glibc-2.39

patch -Np1 -i ../glibc-2.39-fhs-1.patch

mkdir -v build && cd build

echo "rootsbindir=/usr/sbin" > configparms

../configure --prefix=/usr                            \
             --disable-werror                         \
             --enable-kernel=4.19                     \
             --enable-stack-protector=strong          \
             --disable-nscd                           \
             libc_cv_slibdir=/usr/lib

make
make check

### option: if make check command have errors 
touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
###

make install
sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd

mkdir -pv /usr/lib/locale
localedef -i C -f UTF-8 C.UTF-8
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f ISO-8859-1 en_GB
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_ES -f ISO-8859-15 es_ES@euro
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i is_IS -f ISO-8859-1 is_IS
localedef -i is_IS -f UTF-8 is_IS.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f ISO-8859-15 it_IT@euro
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i se_NO -f UTF-8 se_NO.UTF-8
localedef -i ta_IN -f UTF-8 ta_IN.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
localedef -i zh_TW -f UTF-8 zh_TW.UTF-8

make localedata/install-locales

localedef -i C -f UTF-8 C.UTF-8
localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true



# config
cat > /etc/nsswitch.conf << "EOF"
passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files
EOF


tar -xf ../../tzdata2024a.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO

tzselect 
#ln -sfv /usr/share/zoneinfo/<xxx> /etc/localtime
ln -sfv /usr/share/zoneinfo/Asia/Hong_Kong /etc/localtime

cat > /etc/ld.so.conf << "EOF"
/usr/local/lib
/opt/lib
include /etc/ld.so.conf.d/*.conf
EOF
mkdir -pv /etc/ld.so.conf.d

cd /sources/ && rm -rf glibc-2.39
```

#### Zlib-1.3.1
```bash
tar xf zlib-1.3.1.tar.gz && cd zlib-1.3.1

./configure --prefix=/usr

make
make check
make install

rm -fv /usr/lib/libz.a

cd /sources/ && rm -rf zlib-1.3.1
```

#### Bzip2-1.0.8
```bash
tar xf bzip2-1.0.8.tar.gz && cd bzip2-1.0.8

patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch

sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile

make -f Makefile-libbz2_so
make clean

make
make PREFIX=/usr install

cp -av libbz2.so.* /usr/lib
ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so

cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done

rm -fv /usr/lib/libbz2.a

cd /sources/ && rm -rf bzip2-1.0.8
```

#### Xz-5.4.6
```bash
tar xf xz-5.4.6.tar.xz && cd xz-5.4.6

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.4.6

make
make check
make install

cd /sources/ && rm -rf xz-5.4.6
```

#### Zstd-1.5.5
```bash
tar xf zstd-1.5.5.tar.gz && cd zstd-1.5.5

make prefix=/usr
make check
make prefix=/usr install

rm -v /usr/lib/libzstd.a

cd /sources/ && rm -rf zstd-1.5.5
```

#### File-5.45
```bash
tar xf file-5.45.tar.gz && cd file-5.45

./configure --prefix=/usr

make
make check
make install

cd /sources/ && rm -rf file-5.45
```

#### Readline-8.2
```bash
tar xf readline-8.2.tar.gz && cd readline-8.2

sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install

patch -Np1 -i ../readline-8.2-upstream_fixes-3.patch

./configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/readline-8.2

make SHLIB_LIBS="-lncursesw"
make SHLIB_LIBS="-lncursesw" install
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.2

cd /sources/ && rm -rf readline-8.2
```

#### M4-1.4.19
```bash
tar xf m4-1.4.19.tar.xz && cd m4-1.4.19

./configure --prefix=/usr

make
make check
make install

cd /sources/ && rm -rf m4-1.4.19
```

#### Bc-6.7.5
```bash
tar xf bc-6.7.5.tar.xz && cd bc-6.7.5

CC=gcc ./configure --prefix=/usr -G -O3 -r

make
make test
make install

cd /sources/ && rm -rf bc-6.7.5
```

#### Flex-2.6.4
```bash
tar xf flex-2.6.4.tar.gz && cd flex-2.6.4

./configure --prefix=/usr \
            --docdir=/usr/share/doc/flex-2.6.4 \
            --disable-static

make
make check
make install

ln -sv flex   /usr/bin/lex
ln -sv flex.1 /usr/share/man/man1/lex.1

cd /sources/ && rm -rf flex-2.6.4
```

#### Tcl-8.6.13
```bash
tar xf tcl8.6.13-src.tar.gz && cd tcl8.6.13

SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr           \
            --mandir=/usr/share/man

make

sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.5|/usr/lib/tdbc1.1.5|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5/library|/usr/lib/tcl8.6|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.5|/usr/include|"            \
    -i pkgs/tdbc1.1.5/tdbcConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.3|/usr/lib/itcl4.2.3|" \
    -e "s|$SRCDIR/pkgs/itcl4.2.3/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.2.3|/usr/include|"            \
    -i pkgs/itcl4.2.3/itclConfig.sh

unset SRCDIR

make test
make install

chmod -v u+w /usr/lib/libtcl8.6.so
make install-private-headers
ln -sfv tclsh8.6 /usr/bin/tclsh
mv /usr/share/man/man3/{Thread,Tcl_Thread}.3

cd ..
tar -xf ../tcl8.6.13-html.tar.gz --strip-components=1
mkdir -v -p /usr/share/doc/tcl-8.6.13
cp -v -r  ./html/* /usr/share/doc/tcl-8.6.13

cd /sources/ && rm -rf tcl8.6.13
```

#### Expect-5.45.4
```bash
tar xf expect5.45.4.tar.gz && cd expect5.45.4

python3 -c 'from pty import spawn; spawn(["echo", "ok"])'

./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include

make
make test
make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib

cd /sources/ && rm -rf expect5.45.4
```

#### DejaGNU-1.6.3
```bash
tar xf dejagnu-1.6.3.tar.gz && cd dejagnu-1.6.3

mkdir build && cd build

../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi

make check
make install
install -v -dm755  /usr/share/doc/dejagnu-1.6.3
install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3

cd /sources/ && rm -rf dejagnu-1.6.3
```

#### Pkgconf-2.1.1
```bash
tar xf pkgconf-2.1.1.tar.xz && cd pkgconf-2.1.1

./configure --prefix=/usr              \
            --disable-static           \
            --docdir=/usr/share/doc/pkgconf-2.1.1

make
make install
ln -sv pkgconf   /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1

cd /sources/ && rm -rf pkgconf-2.1.1
```

#### Binutils-2.42
```bash
tar xf binutils-2.42.tar.xz && cd binutils-2.42

mkdir build && cd build

../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --enable-gold       \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --with-system-zlib  \
             --enable-default-hash-style=gnu

make tooldir=/usr
make -k check
make tooldir=/usr install
rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a

cd /sources/ && rm -rf binutils-2.42
```

#### GMP-6.3.0
```bash
tar xf gmp-6.3.0.tar.xz && cd gmp-6.3.0

./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.3.0

make
make html
make check 2>&1 | tee gmp-check-log
awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log
make install
make install-html

cd /sources/ && rm -rf gmp-6.3.0
```

#### MPFR-4.2.1
```bash
tar xf mpfr-4.2.1.tar.xz && cd mpfr-4.2.1

./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.2.1

make
make html
make check
make install
make install-html

cd /sources/ && rm -rf mpfr-4.2.1
```

#### MPC-1.3.1
```bash
tar xf mpc-1.3.1.tar.gz && cd mpc-1.3.1

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.3.1

make
make html
make check
make install
make install-html

cd /sources/ && rm -rf mpc-1.3.1
```

#### Attr-2.5.2
```bash
tar xf attr-2.5.2.tar.gz && cd attr-2.5.2

./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.5.2

make
make check
make install

cd /sources/ && rm -rf attr-2.5.2
```

#### Acl-2.3.2
```bash
tar xf acl-2.3.2.tar.xz && cd acl-2.3.2

./configure --prefix=/usr         \
            --disable-static      \
            --docdir=/usr/share/doc/acl-2.3.2

make
make install

cd /sources/ && rm -rf acl-2.3.2
```

#### Libcap-2.69
```bash
tar xf libcap-2.69.tar.xz && cd libcap-2.69

sed -i '/install -m.*STA/d' libcap/Makefile

make prefix=/usr lib=lib
make test
make prefix=/usr lib=lib install

cd /sources/ && rm -rf libcap-2.69
```

#### Libxcrypt-4.4.36
```bash
tar xf libxcrypt-4.4.36.tar.xz && cd libxcrypt-4.4.36

./configure --prefix=/usr                \
            --enable-hashes=strong,glibc \
            --enable-obsolete-api=no     \
            --disable-static             \
            --disable-failure-tokens

make
make check
make install

### option
make distclean
./configure --prefix=/usr                \
            --enable-hashes=strong,glibc \
            --enable-obsolete-api=glibc  \
            --disable-static             \
            --disable-failure-tokens
make
cp -av --remove-destination .libs/libcrypt.so.1* /usr/lib
###

cd /sources/ && rm -rf libxcrypt-4.4.36
```

#### Shadow-4.14.5
```bash
tar xf shadow-4.14.5.tar.xz && cd shadow-4.14.5

sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;

sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
    -e 's:/var/spool/mail:/var/mail:'                   \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                  \
    -i etc/login.defs

touch /usr/bin/passwd
./configure --sysconfdir=/etc   \
            --disable-static    \
            --with-{b,yes}crypt \
            --without-libbsd    \
            --with-group-name-max-length=32

make
make exec_prefix=/usr install
make -C man install-man

pwconv
grpconv
mkdir -p /etc/default
useradd -D --gid 999
passwd root

cd /sources/ && rm -rf shadow-4.14.5
```

#### GCC-13.2.0
```bash
tar xf gcc-13.2.0.tar.xz && cd gcc-13.2.0

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

mkdir build && cd build

../configure --prefix=/usr            \
             LD=ld                    \
             --enable-languages=c,c++ \
             --enable-default-pie     \
             --enable-default-ssp     \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-fixincludes    \
             --with-system-zlib

make 
ulimit -s 32768
chown -R tester .
su tester -c "PATH=$PATH make -k check"
../contrib/test_summary
make install

chown -v -R root:root \
    /usr/lib/gcc/$(gcc -dumpmachine)/13.2.0/include{,-fixed}
ln -svr /usr/bin/cpp /usr/lib
ln -sv gcc.1 /usr/share/man/man1/cc.1
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/13.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/

echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'
[Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]

grep -E -o '/usr/lib.*/S?crt[1in].*succeeded' dummy.log
/usr/lib/gcc/x86_64-pc-linux-gnu/13.2.0/../../../../lib/Scrt1.o succeeded
/usr/lib/gcc/x86_64-pc-linux-gnu/13.2.0/../../../../lib/crti.o succeeded
/usr/lib/gcc/x86_64-pc-linux-gnu/13.2.0/../../../../lib/crtn.o succeeded

grep -B4 '^ /usr/include' dummy.log
#include <...> search starts here:
 /usr/lib/gcc/x86_64-pc-linux-gnu/13.2.0/include
 /usr/local/include
 /usr/lib/gcc/x86_64-pc-linux-gnu/13.2.0/include-fixed
 /usr/include

grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
SEARCH_DIR("/usr/x86_64-lfs-linux-gnu/lib64")
SEARCH_DIR("/usr/local/lib64")
SEARCH_DIR("/lib64")
SEARCH_DIR("/usr/lib64")
SEARCH_DIR("/usr/x86_64-lfs-linux-gnu/lib")
SEARCH_DIR("/usr/local/lib")
SEARCH_DIR("/lib")
SEARCH_DIR("/usr/lib");

grep "/lib.*/libc.so.6 " dummy.log
attempt to open /usr/lib/libc.so.6 succeeded

grep found dummy.log
found ld-linux-x86-64.so.2 at /usr/lib/ld-linux-x86-64.so.2

mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

rm -v dummy.c a.out dummy.log
cd /sources/ && rm -rf gcc-13.2.0
```

#### Ncurses-6.4-20230520
```bash
tar xf ncurses-6.4-20230520.tar.xz && cd ncurses-6.4-20230520

./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --with-cxx-shared       \
            --enable-pc-files       \
            --enable-widec          \
            --with-pkg-config-libdir=/usr/lib/pkgconfig

make
make DESTDIR=$PWD/dest install
install -vm755 dest/usr/lib/libncursesw.so.6.4 /usr/lib
rm -v  dest/usr/lib/libncursesw.so.6.4
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i dest/usr/include/curses.h
cp -av dest/* /

for lib in ncurses form panel menu ; do
    ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc    /usr/lib/pkgconfig/${lib}.pc
done

ln -sfv libncursesw.so /usr/lib/libcurses.so
cp -v -R doc -T /usr/share/doc/ncurses-6.4-20230520

cd /sources/ && rm -rf ncurses-6.4-20230520
```

#### Sed-4.9
```bash
tar xf sed-4.9.tar.xz && cd sed-4.9

./configure --prefix=/usr

make
make html

chown -R tester .
su tester -c "PATH=$PATH make check"

make install
install -d -m755           /usr/share/doc/sed-4.9
install -m644 doc/sed.html /usr/share/doc/sed-4.9

cd /sources/ && rm -rf sed-4.9
```

#### Psmisc-23.6
```bash
tar xf psmisc-23.6.tar.xz && cd psmisc-23.6

./configure --prefix=/usr

make
make check
make install

cd /sources/ && rm -rf psmisc-23.6
```

#### Gettext-0.22.4
```bash
tar xf gettext-0.22.4.tar.xz && cd gettext-0.22.4

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.22.4

make
make check
make install
chmod -v 0755 /usr/lib/preloadable_libintl.so

cd /sources/ && rm -rf gettext-0.22.4
```

#### Bison-3.8.2
```bash
tar xf bison-3.8.2.tar.xz && cd bison-3.8.2

./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2

make
make check
make install

cd /sources/ && rm -rf bison-3.8.2
```

#### Grep-3.11
```bash
tar xf grep-3.11.tar.xz && cd grep-3.11

sed -i "s/echo/#echo/" src/egrep.sh

./configure --prefix=/usr

make
make check
make install

cd /sources/ && rm -rf grep-3.11
```

#### Bash-5.2.21
```bash
tar xf bash-5.2.21.tar.gz && cd bash-5.2.21

patch -Np1 -i ../bash-5.2.21-upstream_fixes-1.patch

./configure --prefix=/usr             \
            --without-bash-malloc     \
            --with-installed-readline \
            --docdir=/usr/share/doc/bash-5.2.21

make
chown -R tester .
su -s /usr/bin/expect tester << "EOF"
set timeout -1
spawn make tests
expect eof
lassign [wait] _ _ _ value
exit $value
EOF

make install
exec /usr/bin/bash --login

cd /sources/ && rm -rf bash-5.2.21
```

#### Libtool-2.4.7
```bash
tar xf libtool-2.4.7.tar.xz && cd libtool-2.4.7

./configure --prefix=/usr

make
make -k check
make install
rm -fv /usr/lib/libltdl.a

cd /sources/ && rm -rf libtool-2.4.7
```

#### GDBM-1.23
```bash
tar xf gdbm-1.23.tar.gz && cd gdbm-1.23

./configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat

make
make check
make install

cd /sources/ && rm -rf gdbm-1.23
```

#### Gperf-3.1
```bash
tar xf gperf-3.1.tar.gz && cd gperf-3.1

./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1

make
make -j1 check
make install

cd /sources/ && rm -rf gperf-3.1
```

#### Expat-2.6.0
```bash
tar xf expat-2.6.0.tar.xz && cd expat-2.6.0

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.6.0

make
make check
make install
install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.6.0

cd /sources/ && rm -rf expat-2.6.0
```

#### Inetutils-2.5
```bash
tar xf inetutils-2.5.tar.xz && cd inetutils-2.5

./configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers

make
make check
make install
mv -v /usr/{,s}bin/ifconfig

cd /sources/ && rm -rf inetutils-2.5
```

#### Less-643
```bash
tar xf less-643.tar.gz && cd less-643

./configure --prefix=/usr --sysconfdir=/etc

make
make check
make install

cd /sources/ && rm -rf less-643
```

#### Perl-5.38.2
```bash
tar xf perl-5.38.2.tar.xz && cd perl-5.38.2

export BUILD_ZLIB=False
export BUILD_BZIP2=0

sh Configure -des                                         \
             -Dprefix=/usr                                \
             -Dvendorprefix=/usr                          \
             -Dprivlib=/usr/lib/perl5/5.38/core_perl      \
             -Darchlib=/usr/lib/perl5/5.38/core_perl      \
             -Dsitelib=/usr/lib/perl5/5.38/site_perl      \
             -Dsitearch=/usr/lib/perl5/5.38/site_perl     \
             -Dvendorlib=/usr/lib/perl5/5.38/vendor_perl  \
             -Dvendorarch=/usr/lib/perl5/5.38/vendor_perl \
             -Dman1dir=/usr/share/man/man1                \
             -Dman3dir=/usr/share/man/man3                \
             -Dpager="/usr/bin/less -isR"                 \
             -Duseshrplib                                 \
             -Dusethreads

make
TEST_JOBS=$(nproc) make test_harness
make install
unset BUILD_ZLIB BUILD_BZIP2

cd /sources/ && rm -rf perl-5.38.2
```

#### XML::Parser-2.47
```bash
tar xf XML-Parser-2.47.tar.gz && cd XML-Parser-2.47

perl Makefile.PL

make
make test
make install

cd /sources/ && rm -rf XML-Parser-2.47
```

#### Intltool-0.51.0
```bash
tar xf intltool-0.51.0.tar.gz && cd intltool-0.51.0

sed -i 's:\\\${:\\\$\\{:' intltool-update.in

./configure --prefix=/usr

make
make check
make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO

cd /sources/ && rm -rf intltool-0.51.0
```

#### Autoconf-2.72
```bash
tar xf autoconf-2.72.tar.xz && cd autoconf-2.72

./configure --prefix=/usr

make
make check
make install

cd /sources/ && rm -rf autoconf-2.72
```

#### Automake-1.16.5
```bash
tar xf automake-1.16.5.tar.xz && cd automake-1.16.5

./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.5

make
make -j$(($(nproc)>4?$(nproc):4)) check
make install

cd /sources/ && rm -rf automake-1.16.5
```

#### OpenSSL-3.2.1
```bash
tar xf openssl-3.2.1.tar.gz && cd openssl-3.2.1

./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic

make
HARNESS_JOBS=$(nproc) make test
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install

mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.2.1
cp -vfr doc/* /usr/share/doc/openssl-3.2.1

cd /sources/ && rm -rf openssl-3.2.1
```

#### Kmod-31
```bash
tar xf kmod-31.tar.xz && cd kmod-31

./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --with-openssl         \
            --with-xz              \
            --with-zstd            \
            --with-zlib

make
make install

for target in depmod insmod modinfo modprobe rmmod; do
  ln -sfv ../bin/kmod /usr/sbin/$target
done
ln -sfv kmod /usr/bin/lsmod

cd /sources/ && rm -rf kmod-31
```

#### Libelf from Elfutils-0.190
```bash
tar xf elfutils-0.190.tar.bz2 && cd elfutils-0.190

./configure --prefix=/usr                \
            --disable-debuginfod         \
            --enable-libdebuginfod=dummy

make
make check
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a

cd /sources/ && rm -rf elfutils-0.190
```

#### Libffi-3.4.4
```bash
tar xf libffi-3.4.4.tar.gz && cd libffi-3.4.4

./configure --prefix=/usr          \
            --disable-static       \
            --with-gcc-arch=native

make
make check
make install

cd /sources/ && rm -rf libffi-3.4.4
```

#### Python-3.12.2
```bash
tar xf Python-3.12.2.tar.xz && cd Python-3.12.2

./configure --prefix=/usr        \
            --enable-shared      \
            --with-system-expat  \
            --enable-optimizations

make
make install

cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF

install -v -dm755 /usr/share/doc/python-3.12.2/html
tar --no-same-owner -xvf ../python-3.12.2-docs-html.tar.bz2
cp -R --no-preserve=mode python-3.12.2-docs-html/* \
    /usr/share/doc/python-3.12.2/html

cd /sources/ && rm -rf Python-3.12.2
```

#### Flit-Core-3.9.0
```bash
tar xf flit_core-3.9.0.tar.gz && cd flit_core-3.9.0

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --no-user --find-links dist flit_core

cd /sources/ && rm -rf flit_core-3.9.0
```

#### Wheel-0.42.0
```bash
tar xf wheel-0.42.0.tar.gz && cd wheel-0.42.0

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links=dist wheel

cd /sources/ && rm -rf wheel-0.42.0
```

#### Setuptools-69.1.0
```bash
tar xf setuptools-69.1.0.tar.gz && cd setuptools-69.1.0

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist setuptools

cd /sources/ && rm -rf setuptools-69.1.0
```

#### Ninja-1.11.1
```bash
tar xf ninja-1.11.1.tar.gz && cd ninja-1.11.1

export NINJAJOBS=$(nproc)

sed -i '/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc
python3 configure.py --bootstrap

./ninja ninja_test
./ninja_test --gtest_filter=-SubprocessTest.SetWithLots
install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja

cd /sources/ && rm -rf ninja-1.11.1
```

#### Meson-1.3.2
```bash
tar xf meson-1.3.2.tar.gz && cd meson-1.3.2

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist meson

install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson

cd /sources/ && rm -rf meson-1.3.2
```

#### Coreutils-9.4
```bash
tar xf coreutils-9.4.tar.xz && cd coreutils-9.4

patch -Np1 -i ../coreutils-9.4-i18n-1.patch

sed -e '/n_out += n_hold/,+4 s|.*bufsize.*|//&|' -i src/split.c
autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime

make
make NON_ROOT_USERNAME=tester check-root

groupadd -g 102 dummy -U tester
chown -R tester . 
su tester -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check"
groupdel dummy
make install

mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8

cd /sources/ && rm -rf coreutils-9.4
```

#### Check-0.15.2
```bash
tar xf check-0.15.2.tar.gz && cd check-0.15.2

./configure --prefix=/usr --disable-static

make
make check
make docdir=/usr/share/doc/check-0.15.2 install

cd /sources/ && rm -rf check-0.15.2
```

#### Diffutils-3.10
```bash
tar xf diffutils-3.10.tar.xz && cd diffutils-3.10

./configure --prefix=/usr

make
make check
make install

cd /sources/ && rm -rf diffutils-3.10
```

#### Gawk-5.3.0
```bash
tar xf gawk-5.3.0.tar.xz && cd gawk-5.3.0

sed -i 's/extras//' Makefile.in

./configure --prefix=/usr

make
chown -R tester .
su tester -c "PATH=$PATH make check"
rm -f /usr/bin/gawk-5.3.0
make install

ln -sv gawk.1 /usr/share/man/man1/awk.1
mkdir -pv /usr/share/doc/gawk-5.3.0
cp -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-5.3.0

cd /sources/ && rm -rf gawk-5.3.0
```

#### Findutils-4.9.0
```bash
tar xf findutils-4.9.0.tar.xz && cd findutils-4.9.0

./configure --prefix=/usr --localstatedir=/var/lib/locate

make
chown -R tester .
su tester -c "PATH=$PATH make check"
make install

cd /sources/ && rm -rf findutils-4.9.0
```

#### Groff-1.23.0
```bash
tar xf groff-1.23.0.tar.gz && cd groff-1.23.0

PAGE=A4 ./configure --prefix=/usr

make
make check
make install

cd /sources/ && rm -rf groff-1.23.0
```

#### GRUB-2.12
```bash
# no need if use UEFI
tar xf grub-2.12.tar.xz && cd grub-2.12

unset {C,CPP,CXX,LD}FLAGS

echo depends bli part_gpt > grub-core/extra_deps.lst

./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --disable-efiemu       \
            --disable-werror

make
make install
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions

cd /sources/ && rm -rf grub-2.12
```

#### GRUB-2.12 for UEFI
```bash
# Dependencies
wget https://github.com/rhboot/efivar/archive/39/efivar-39.tar.gz
wget http://ftp.rpm.org/popt/releases/popt-1.x/popt-1.19.tar.gz
wget https://github.com/rhboot/efibootmgr/archive/18/efibootmgr-18.tar.gz

tar xf efivar-39.tar.gz && cd efivar-39
make ENABLE_DOCS=0 && make install LIBDIR=/usr/lib ENABLE_DOCS=0
cd .. && rm -rf efivar-39

tar xf popt-1.19.tar.gz && cd popt-1.19
./configure --prefix=/usr --disable-static && make && make install
cd .. && rm -rf popt-1.19

tar xf efibootmgr-18.tar.gz && cd efibootmgr-18
make EFIDIR=LFS EFI_LOADER=grubx64.efi
make install EFIDIR=LFS
cd .. && rm -rf efibootmgr-18


# install
wget https://ftp.gnu.org/gnu/grub/grub-2.12.tar.xz
wget https://unifoundry.com/pub/unifont/unifont-15.1.04/font-builds/unifont-15.1.04.pcf.gz

tar xf grub-2.12.tar.xz && cd grub-2.12
mkdir -pv /usr/share/fonts/unifont &&
gunzip -c ../unifont-15.1.04.pcf.gz > /usr/share/fonts/unifont/unifont.pcf

unset {C,CPP,CXX,LD}FLAGS

echo depends bli part_gpt > grub-core/extra_deps.lst

case $(uname -m) in i?86 )
    tar xf ../gcc-13.2.0.tar.xz
    mkdir gcc-13.2.0/build
    pushd gcc-13.2.0/build
        ../configure --prefix=$PWD/../../x86_64-gcc \
                     --target=x86_64-linux-gnu      \
                     --with-system-zlib             \
                     --enable-languages=c,c++       \
                     --with-ld=/usr/bin/ld
        make all-gcc
        make install-gcc
    popd
    export TARGET_CC=$PWD/x86_64-gcc/bin/x86_64-linux-gnu-gcc
esac

            #--enable-grub-mkfont \
./configure --prefix=/usr        \
            --sysconfdir=/etc    \
            --disable-efiemu     \
            --with-platform=efi  \
            --target=x86_64      \
            --disable-werror     &&
unset TARGET_CC && make

make install && mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions

cd /sources/ && rm -rf grub-2.12 
```

#### Gzip-1.13
```bash
tar xf gzip-1.13.tar.xz && cd gzip-1.13

./configure --prefix=/usr

make
make check
make install

cd /sources/ && rm -rf gzip-1.13
```

#### IPRoute2-6.7.0
```bash
tar xf iproute2-6.7.0.tar.xz && cd iproute2-6.7.0

sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8

make NETNS_RUN_DIR=/run/netns
make SBINDIR=/usr/sbin install

mkdir -pv /usr/share/doc/iproute2-6.7.0
cp -v COPYING README* /usr/share/doc/iproute2-6.7.0

cd /sources/ && rm -rf iproute2-6.7.0
```

#### Kbd-2.6.4
```bash
tar xf kbd-2.6.4.tar.xz && cd kbd-2.6.4

patch -Np1 -i ../kbd-2.6.4-backspace-1.patch

sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in

./configure --prefix=/usr --disable-vlock

make
make check
make install
cp -R -v docs/doc -T /usr/share/doc/kbd-2.6.4

cd /sources/ && rm -rf kbd-2.6.4
```

#### Libpipeline-1.5.7
```bash
tar xf libpipeline-1.5.7.tar.gz && cd libpipeline-1.5.7

./configure --prefix=/usr

make
make check
make install

cd /sources/ && rm -rf libpipeline-1.5.7
```

#### Make-4.4.1
```bash
tar xf make-4.4.1.tar.gz && cd make-4.4.1

./configure --prefix=/usr

make
chown -R tester .
su tester -c "PATH=$PATH make check"
make install

cd /sources/ && rm -rf make-4.4.1
```

#### Patch-2.7.6
```bash
tar xf patch-2.7.6.tar.xz && cd patch-2.7.6

./configure --prefix=/usr

make
make check
make install

cd /sources/ && rm -rf patch-2.7.6
```

#### Tar-1.35
```bash
tar xf tar-1.35.tar.xz && cd tar-1.35

FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr

make
make check
make install
make -C doc install-html docdir=/usr/share/doc/tar-1.35

cd /sources/ && rm -rf tar-1.35
```

#### Texinfo-7.1
```bash
tar xf texinfo-7.1.tar.xz && cd texinfo-7.1

./configure --prefix=/usr

make
make check
make install
make TEXMF=/usr/share/texmf install-tex

pushd /usr/share/info
  rm -v dir
  for f in *
    do install-info $f dir 2>/dev/null
  done
popd

cd /sources/ && rm -rf texinfo-7.1
```

#### Vim-9.1.0041
```bash
tar xf vim-9.1.0041.tar.gz && cd vim-9.1.0041

echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h

./configure --prefix=/usr

make
chown -R tester .
su tester -c "TERM=xterm-256color LANG=en_US.UTF-8 make -j1 test" &> vim-test.log
make install

ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done

ln -sv ../vim/vim91/doc /usr/share/doc/vim-9.1.0041

cat > /etc/vimrc << "EOF"
" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif
EOF

vim -c ':options'

cd /sources/ && rm -rf vim-9.1.0041
```

#### MarkupSafe-2.1.5
```bash
tar xf MarkupSafe-2.1.5.tar.gz && cd MarkupSafe-2.1.5

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --no-user --find-links dist Markupsafe

cd /sources/ && rm -rf MarkupSafe-2.1.5
```

#### Jinja2-3.1.3
```bash
tar xf Jinja2-3.1.3.tar.gz && cd Jinja2-3.1.3

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --no-user --find-links dist Jinja2

cd /sources/ && rm -rf Jinja2-3.1.3
```

#### Systemd-255
```bash
tar xf systemd-255.tar.gz && cd systemd-255

sed -i -e 's/GROUP="render"/GROUP="video"/' \
       -e 's/GROUP="sgx", //' rules.d/50-udev-default.rules.in

patch -Np1 -i ../systemd-255-upstream_fixes-1.patch

mkdir -p build && cd build

meson setup \
      --prefix=/usr                 \
      --buildtype=release           \
      -Ddefault-dnssec=no           \
      -Dfirstboot=false             \
      -Dinstall-tests=false         \
      -Dldconfig=false              \
      -Dsysusers=false              \
      -Drpmmacrosdir=no             \
      -Dhomed=disabled              \
      -Duserdb=false                \
      -Dman=disabled                \
      -Dmode=release                \
      -Dpamconfdir=no               \
      -Ddev-kvm-mode=0660           \
      -Dnobody-group=nogroup        \
      -Dsysupdate=disabled          \
      -Dukify=disabled              \
      -Ddocdir=/usr/share/doc/systemd-255 \
      ..

ninja
ninja install

tar -xf ../../systemd-man-pages-255.tar.xz \
    --no-same-owner --strip-components=1   \
    -C /usr/share/man

systemd-machine-id-setup

cd /sources/ && rm -rf systemd-255
```

#### D-Bus-1.14.10
```bash
tar xf dbus-1.14.10.tar.xz && cd dbus-1.14.10

./configure --prefix=/usr                        \
            --sysconfdir=/etc                    \
            --localstatedir=/var                 \
            --runstatedir=/run                   \
            --enable-user-session                \
            --disable-static                     \
            --disable-doxygen-docs               \
            --disable-xml-docs                   \
            --docdir=/usr/share/doc/dbus-1.14.10 \
            --with-system-socket=/run/dbus/system_bus_socket

make
make check
make install
ln -sfv /etc/machine-id /var/lib/dbus

cd /sources/ && rm -rf dbus-1.14.10
```

#### Man-DB-2.12.0
```bash
tar xf man-db-2.12.0.tar.xz && cd man-db-2.12.0

./configure --prefix=/usr                         \
            --docdir=/usr/share/doc/man-db-2.12.0 \
            --sysconfdir=/etc                     \
            --disable-setuid                      \
            --enable-cache-owner=bin              \
            --with-browser=/usr/bin/lynx          \
            --with-vgrind=/usr/bin/vgrind         \
            --with-grap=/usr/bin/grap             \
            --with-systemdtmpfilesdir=            \
            --with-systemdsystemunitdir=

make
make check
make install

cd /sources/ && rm -rf man-db-2.12.0
```

#### Procps-ng-4.0.4
```bash
tar xf procps-ng-4.0.4.tar.xz && cd procps-ng-4.0.4

./configure --prefix=/usr                           \
            --docdir=/usr/share/doc/procps-ng-4.0.4 \
            --disable-static                        \
            --disable-kill

make
make -k check
make install

cd /sources/ && rm -rf procps-ng-4.0.4
```

#### Util-linux-2.39.3
```bash
tar xf util-linux-2.39.3.tar.xz && cd util-linux-2.39.3

sed -i '/test_mkfds/s/^/#/' tests/helpers/Makemodule.am

./configure --bindir=/usr/bin    \
            --libdir=/usr/lib    \
            --runstatedir=/run   \
            --sbindir=/usr/sbin  \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python     \
            --without-systemd    \
            --without-systemdsystemunitdir        \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.39.3

chown -R tester .
su tester -c "make -k check"
make install

cd /sources/ && rm -rf util-linux-2.39.3
```

#### E2fsprogs-1.47.0
```bash
tar xf e2fsprogs-1.47.0.tar.gz && cd e2fsprogs-1.47.0

mkdir build && cd build

../configure --prefix=/usr           \
             --sysconfdir=/etc       \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck

make
make check
make install
rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a

gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info

makeinfo -o doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info

sed 's/metadata_csum_seed,//' -i /etc/mke2fs.conf

cd /sources/ && rm -rf e2fsprogs-1.47.0
```

#### Stripping
```bash
save_usrlib="$(cd /usr/lib; ls ld-linux*[^g])
             libc.so.6
             libthread_db.so.1
             libquadmath.so.0.0.0
             libstdc++.so.6.0.32
             libitm.so.1.0.0
             libatomic.so.1.2.0"

cd /usr/lib

for LIB in $save_usrlib; do
    objcopy --only-keep-debug --compress-debug-sections=zlib $LIB $LIB.dbg
    cp $LIB /tmp/$LIB
    strip --strip-unneeded /tmp/$LIB
    objcopy --add-gnu-debuglink=$LIB.dbg /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done

online_usrbin="bash find strip"
online_usrlib="libbfd-2.42.so
               libsframe.so.1.0.0
               libhistory.so.8.2
               libncursesw.so.6.4-20230520
               libm.so.6
               libreadline.so.8.2
               libz.so.1.3.1
               libzstd.so.1.5.5
               $(cd /usr/lib; find libnss*.so* -type f)"

for BIN in $online_usrbin; do
    cp /usr/bin/$BIN /tmp/$BIN
    strip --strip-unneeded /tmp/$BIN
    install -vm755 /tmp/$BIN /usr/bin
    rm /tmp/$BIN
done

for LIB in $online_usrlib; do
    cp /usr/lib/$LIB /tmp/$LIB
    strip --strip-unneeded /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done

for i in $(find /usr/lib -type f -name \*.so* ! -name \*dbg) \
         $(find /usr/lib -type f -name \*.a)                 \
         $(find /usr/{bin,sbin,libexec} -type f); do
    case "$online_usrbin $online_usrlib $save_usrlib" in
        *$(basename $i)* )
            ;;
        * ) strip --strip-unneeded $i
            ;;
    esac
done

unset BIN LIB save_usrlib online_usrbin online_usrlib
```

#### Cleaning Up
```bash
rm -rf /tmp/*
find /usr/lib /usr/libexec -name \*.la -delete
find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf
userdel -r tester
```

### System Configuration
#### General Network Configuration
```bash
# Network Device Naming 
# by udev
ip link
# by manual
# option1
ln -s /dev/null /etc/systemd/network/99-default.link
# option2
cat > /etc/systemd/network/10-ether0.link << "EOF"
[Match]
MACAddress=00:00:00:00:00:00
[Link]
Name=ether0
EOF
# option3: set /boot/grub/grub.cfg
net.ifnames=0


# Static IP Configuration
cat > /etc/systemd/network/10-eth-static.network << "EOF"
[Match]
Name=<network-device-name>

[Network]
Address=192.168.0.2/24
Gateway=192.168.0.1
DNS=8.8.8.8
DNS=4.4.4.4
Domains=localhost
EOF


# DHCP Configuration
cat > /etc/systemd/network/10-eth-dhcp.network << "EOF"
[Match]
Name=<network-device-name>

[Network]
DHCP=ipv4

[DHCPv4]
UseDomains=true
EOF


# Static resolv.conf Configuration
cat > /etc/resolv.conf << "EOF"
nameserver 8.8.8.8
nameserver 4.4.4.4
search  ns.local
EOF


# Configuration hostname
echo "<lfs>" > /etc/hostname


# Customizing the /etc/hosts File
cat > /etc/hosts << "EOF"
<192.168.0.2> <FQDN> [alias1] [alias2] ...
::1       ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters
EOF
```

#### Managing Devices
```bash
# option
udevadm info -a -p /sys/class/block/sda
cat > /etc/udev/rules.d/83-duplicate_devs.rules << "EOF"
...
EOF
```

#### Configuring the system clock
```bash
cat > /etc/adjtime << "EOF"
0.0 0 0.0
0
LOCAL
EOF

# After systemd timedatectl start
timedatectl set-local-rtc 1
timedatectl set-time YYYY-MM-DD HH:MM:SS

systemctl disable systemd-timesyncd
```

#### Configuring the Linux Locale
```bash
# option
cat > /etc/vconsole.conf << "EOF"
KEYMAP=
FONT=Lat2-Terminus16
EOF

# After systemd localectl start
localectl set-keymap MAP
```

#### Configuring the System Locale
```bash
# check
LC_ALL=en_US.utf8 locale language
LC_ALL=en_US.utf8 locale charmap
LC_ALL=en_US.utf8 locale int_curr_symbol
LC_ALL=en_US.utf8 locale int_prefix

# option
cat > /etc/locale.conf << "EOF"
LANG=<ll>_<CC>.<charmap><@modifiers>
EOF

cat > /etc/profile << "EOF"
for i in $(locale); do
  unset ${i%=*}
done

if [[ "$TERM" = linux ]]; then
  export LANG=C.UTF-8
else
  export LANG=en_US.utf8
fi
EOF

# After systemd localectl start
localectl set-locale LANG="en_US.UTF-8" LC_CTYPE="en_US"
```

#### Creating the /etc/inputrc and /etc/shells File
```bash
cat > /etc/inputrc << "EOF"
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8-bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line
EOF


cat > /etc/shells << "EOF"
/bin/sh
/bin/bash
EOF
```

#### Systemd Usage and Configuration
```bash
# Disabling Screen Clearing at Boot Time
mkdir -pv /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/noclear.conf << EOF
[Service]
TTYVTDisallocate=no
EOF

# Disabling tmpfs for /tmp
ln -sfv /dev/null /etc/systemd/system/tmp.mount

# Configuring Automatic File Creation and Deletion

# Overriding Default Services Behavior

# Working with the Systemd Journal

# Working with Core Dumps

# Long Running Processes
# option1
loginctl enable-linger lfs
loginctl show-user lfs
# option2: global
cat /etc/systemd/logind.conf
KillUserProcesses=No
```

### Making the LFS System Bootable
#### Creating the /etc/fstab File
```bash
cat > /etc/fstab << "EOF"
# <file system> <mount point>   <type>  <options>       <dump>  <pass>

# legacy
PARTUUID="9f37c469-a678-4d16-a266-73c208344f03" / ext4 defaults 0 1
PARTUUID="d47b7e0a-61fe-4c96-a387-13c07b53ddb7" /boot ext4 defaults 0 1

# UEFI
PARTUUID="9f37c469-a678-4d16-a266-73c208344f03" / ext4 defaults 0 1
PARTUUID="d47b7e0a-61fe-4c96-a387-13c07b53ddb7" /boot/efi vfat codepage=437,iocharset=iso8859-1 0 1

EOF

mount -a
```

#### Linux-6.7.4
```bash
# install
cd /sources && tar xf linux-6.7.4.tar.xz && cd linux-6.7.4

make mrproper

make menuconfig
...

# If need support UEFI
# https://www.linuxfromscratch.org/blfs/view/stable-systemd/postlfs/grub-setup.html#uefi-kernel

make
make modules_install

cp -iv arch/x86/boot/bzImage /boot/vmlinuz-6.7.4-lfs-12.1-systemd
cp -iv System.map /boot/System.map-6.7.4
cp -iv .config /boot/config-6.7.4
cp -r Documentation -T /usr/share/doc/linux-6.7.4

#cd /sources/ && rm -rf linux-6.7.4
chown 0:0 /sources/linux-6.7.4


# Configuring Linux Module Load Order
install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true
EOF
```

#### Using GRUB to Set Up the Boot Process
#### Rescue(option)
```bash
# install depends
cd /sources/
wget https://files.libburnia-project.org/releases/libburn-1.5.6.tar.gz
wget https://files.libburnia-project.org/releases/libisofs-1.5.6.tar.gz
wget https://files.libburnia-project.org/releases/libisoburn-1.5.6.tar.gz

tar xf libburn-1.5.6.tar.gz && cd libburn-1.5.6
./configure --prefix=/usr --disable-static && make
make install
tar xf libisofs-1.5.6.tar.gz && cd libisofs-1.5.6
./configure --prefix=/usr --disable-static && make
make install
tar xf libisoburn-1.5.6.tar.gz && cd libisoburn-1.5.6
./configure --prefix=/usr              \
            --disable-static           \
            --enable-pkg-check-modules && make
make install
cd /sources/ && rm -rf libburn-1.5.6 libisofs-1.5.6 libisoburn-1.5.6

wget ftp://ftp.gnu.org/gnu/mtools/mtools-4.0.18.tar.gz
tar xf mtools-4.0.18.tar.gz && cd mtools-4.0.18
./configure --prefix=/usr && make && make install
cd /sources/ && rm -rf mtools-4.0.18


# backup emergency boot disk
cd /tmp
grub-mkrescue --output=grub-img.iso
xorriso -as cdrecord -v dev=/dev/cdrw blank=as_needed grub-img.iso
```
#### Config
**legacy boot**
```bash
grub-install /dev/sdb

cat > /boot/grub/grub.cfg << "EOF"
set default=0
set timeout=5

insmod part_gpt
insmod ext2

#set root=(hd0,2)
search --set=root --fs-uuid d67ed2c2-3a2d-4440-81f2-c5491f90641b

menuentry "GNU/Linux, Linux 6.7.4-lfs-12.1" {
        #linux /boot/vmlinuz-6.7.4-lfs-12.1-systemd root=/dev/sda2 ro
        linux /vmlinuz-6.7.4-lfs-12.1-systemd root=PARTUUID=9f37c469-a678-4d16-a266-73c208344f03 ro
}
EOF
```

**UEFI boot**
```bash
# Kernel Configuration for UEFI support

# Create an Emergency Boot Disk

# Find or Create the EFI System Partition
fdisk -l /dev/sdb

# Minimal Boot Configuration with GRUB and EFI
# /boot/efi/EFI/BOOT/BOOTX64.EFI
grub-install --target=x86_64-efi --removable

# Mount the EFI Variable File System
mountpoint /sys/firmware/efi/efivars || mount -v -t efivarfs efivarfs /sys/firmware/efi/efivars

# Setting Up the Configuration
grub-install --bootloader-id=LFS --recheck
efibootmgr

# Creating the GRUB Configuration File
cat > /boot/grub/grub.cfg << EOF
set default=0
set timeout=5

insmod part_gpt
insmod ext2

#set root=(hd0,2)
search --set=root --fs-uuid d67ed2c2-3a2d-4440-81f2-c5491f90641b

insmod all_video
if loadfont /boot/grub/fonts/unicode.pf2; then
  terminal_output gfxterm
fi

menuentry "GNU/Linux, Linux 6.7.4-lfs-12.1"  {
  #linux /boot/vmlinuz-6.7.4-lfs-12.1-systemd root=/dev/sda2 ro
  linux /vmlinuz-6.7.4-lfs-12.1-systemd root=PARTUUID=9f37c469-a678-4d16-a266-73c208344f03 ro
}

menuentry "Firmware Setup" {
  fwsetup
}
EOF

```

### The End
```bash
# the end
echo 12.1-systemd > /etc/lfs-release

cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="12.1-systemd"
DISTRIB_CODENAME="july"
DISTRIB_DESCRIPTION="Linux From Scratch"
EOF

cat > /etc/os-release << "EOF"
NAME="Linux From Scratch"
VERSION="12.1-systemd"
ID=lfs
PRETTY_NAME="Linux From Scratch 12.1"
VERSION_CODENAME="july"
HOME_URL="https://www.linuxfromscratch.org/lfs/"
EOF


# reboot system
logout

umount -v $LFS/dev/pts
mountpoint -q $LFS/dev/shm && umount -v $LFS/dev/shm
umount -v $LFS/dev
umount -v $LFS/run
umount -v $LFS/proc
umount -v $LFS/sys

umount -v $LFS/boot
umount -v $LFS

reboot
```

### Appendices
...



> Reference:
> 1. [LFS Official Manual](https://linuxfromscratch.org/)
> 2. [LFS 12.1 中文文档](https://lfs.xry111.site/zh_CN/12.1/index.html)
