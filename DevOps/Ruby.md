---
icon: code
description: Ruby record
---

# Ruby

## 1. Development Environment

### Install
```bash
# centos
yum install -y make gcc zlib-devel bzip2-devel openssl-devel ncurses-devel libffi-devel

# ubuntu
apt install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget libbz2-dev

# build install openssl
wget https://github.com/openssl/openssl/releases/download/openssl-3.0.15/openssl-3.0.15.tar.gz
tar xf openssl-3.0.15.tar.gz && rm -f openssl-3.0.15.tar.gz && cd openssl-3.0.15
./config --prefix=/usr/local/openssl3.0.15
make && make install

# build
wget https://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.6.tar.gz
tar xf ruby-3.3.6.tar.gz && rm -f ruby-3.3.6.tar.gz && cd ruby-3.3.6
./configure --prefix=/usr/local/ruby3.3.6/ --with-openssl-include=/usr/local/openssl3.0.15/include --with-openssl-lib=/usr/local/openssl3.0.15/lib

# install
make && make install
```


## 2. ProjectManage

### gem

```bash
gem install
gem uninstall
gem list --local
gem build
```

### bundler

```bash
bundler install
```

### rvm

```bash
rvm install 3.3.6
rvm use system
```



> Reference:
> 1. [Official Website](https://ruby-lang.org/)
> 2. [Repository](https://github.com/ruby/ruby)
> 3. [RVM](https://rvm.io/rvm)
