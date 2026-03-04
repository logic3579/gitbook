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
./configure --prefix=/usr/local/ruby3.3.6/ \
    --with-openssl-include=/usr/local/openssl3.0.15/include \
    --with-openssl-lib=/usr/local/openssl3.0.15/lib

# install
make && make install
```

## 2. ProjectManage

### gem

Ruby's built-in package manager for installing and managing libraries (gems).

```bash
# Install a gem
gem install rails
gem install rails -v 7.1.0

# Uninstall
gem uninstall rails

# List installed gems
gem list --local

# Search for gems
gem search ^rails

# Show gem info
gem info rails

# Update gems
gem update
gem update --system              # update RubyGems itself

# Build and publish a gem
gem build my_gem.gemspec
gem push my_gem-1.0.0.gem

# Environment info
gem environment
gem which rails
```

### Bundler

A dependency manager for Ruby projects. It reads `Gemfile` and ensures consistent gem versions across environments via `Gemfile.lock`.

#### Install

```bash
gem install bundler
```

#### Project Management

```bash
# Initialize a new Gemfile in the current directory
bundle init

# Install dependencies from Gemfile
bundle install
bundle install --path vendor/bundle   # install to project-local path

# Update dependencies
bundle update
bundle update rails                    # update a specific gem

# Show installed gems
bundle list
bundle show rails                      # show install path of a gem

# Run a command in the bundle context
bundle exec rails server
bundle exec rspec
bundle exec rake db:migrate

# Check for outdated gems
bundle outdated

# Add a gem to Gemfile and install
bundle add devise
bundle add rspec --group development
```

#### Configuration

```bash
# List all configuration
bundle config list

# Set config
bundle config set --local path vendor/bundle
bundle config set --local without production
```

### rbenv

A lightweight Ruby version manager. It manages per-project Ruby versions via `.ruby-version` file.

#### Install

```bash
# macOS
brew install rbenv ruby-build

# Linux (git clone)
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
```

#### Ruby Version Management

```bash
# List available Ruby versions
rbenv install -l

# Install a specific Ruby version
rbenv install 3.3.6

# Set global Ruby version
rbenv global 3.3.6

# Set project-local Ruby version (writes .ruby-version)
rbenv local 3.3.6

# Show current Ruby version
rbenv version

# List all installed versions
rbenv versions

# Uninstall a version
rbenv uninstall 3.3.6

# Rehash shims (after installing new gems with executables)
rbenv rehash
```

### rvm

Ruby Version Manager. A more full-featured alternative to rbenv, manages Ruby installations and gemsets.

#### Install

```bash
# Install rvm
curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
```

#### Ruby Version Management

```bash
# List available Ruby versions
rvm list known

# Install a specific Ruby version
rvm install 3.3.6

# Use a Ruby version
rvm use 3.3.6
rvm use 3.3.6 --default           # set as default
rvm use system                     # use system Ruby

# List installed versions
rvm list

# Uninstall
rvm uninstall 3.3.6
```

#### Gemsets

```bash
# Create a gemset
rvm gemset create my_project

# Use a gemset
rvm use 3.3.6@my_project
rvm use 3.3.6@my_project --default

# List gemsets
rvm gemset list

# Delete a gemset
rvm gemset delete my_project
```

> Reference:
>
> 1. [Official Website](https://ruby-lang.org/)
> 2. [Repository](https://github.com/ruby/ruby)
> 3. [RubyGems](https://rubygems.org/)
> 4. [Bundler](https://bundler.io/)
> 5. [rbenv](https://github.com/rbenv/rbenv)
> 6. [RVM](https://rvm.io/)
