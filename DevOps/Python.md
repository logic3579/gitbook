---
icon: code
description: Python record
---

# Python

## 1. Development Environment

### Install

```bash
# centos
yum install -y make gcc zlib-devel bzip2-devel openssl-devel ncurses-devel libffi-devel

# ubuntu
apt install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget libbz2-dev libsqlite3-dev

# build
./configure --prefix=/usr/local/python3_11_1 --enable-loadable-sqlite-extensions --enable-shared --enable-optimizations
# Common build parameters
--enable-shared                         # Enable shared library support, allowing other programs to link against the Python library
--enable-optimizations                  # Enable build optimizations
--enable-ipv6                           # Enable IPv6 support
--enable-loadable-sqlite-extensions     # Allow dynamically loading SQLite extensions
--with-system-expat                     # Use the system expat library
--with-system-ffi                       # Use the system ffi library
--with-openssl=/usr/local/openssl1.11u  # Specify the path to the OpenSSL library
--with-zlib=/usr/local/zlib             # Specify the path to the zlib library
--with-bz2=/usr/local/bz2               # Specify the path to the bzip2 library
--with-tcltk=/usr/local/tcltk           # Specify the path to the Tcl/Tk library

# install
make && make install
```

### Pycharm

```bash
# active
cat ./ideaActive/ja-netfilter-all/ja-netfilter/readme.txt

# settings
# 1. Python Intergrated Tools -> Docstring format: Google

# Plugins
gradianto # themes
rainbow brackets # json
```

## 2. ProjectManage

### pip

```bash
# Install
...

# Create Virtualenv
python -m venv .venv

# Output installed packages in requirements format
pip freeze > requirements.txt

# Install dependencies
pip install Django==4.1.3
pip install -r requirements.txt
```

### Poetry

#### Install

```bash
# Option 1(recommend)
curl -sSL https://install.python-poetry.org | python -
poetry self update


# Option 2
pip3 install pipx
# Install shared tool poetry to /root/.local/bin/poetry
/usr/local/bin/pipx install poetry
export PATH=$PATH:/root/.local/bin
# Upgrade
pipx upgrade poetry
```

#### How to use

```bash
# New project
poetry new poetry-project

# Init existed project
cd my-project
poetry init


# Create Virtualenv with system Python
poetry env use /usr/bin/python3.10
poetry env info
poetry env list <--full-path>

# Add and install dependencies
poetry add <package_name==version>
# Add requirements.txt depencies
poetry add $(cat requirements.txt)
# Add depency for only dev
poetry add --dev pytest

# Add dependencies by manual
vim pyproject.toml
poetry install

# show all depencies
poetry show

# Update dependencies by manual
poetry update

# Remove Virtualenv
poetry env remove <env_name>

# Run On poetry Virtualenv
poetry run python -V
poetry run python <your_script.py>

# Active Virtualenv python shell
poetry shell

# Build and publish to PyPI
poetry build
poetry publish

# Config poetry
poetry config --list
poetry config virtualenvs.create true <--local>
```

### uv

An extremely fast Python package and project manager, written in Rust. It is a drop-in replacement for pip, pip-tools, pipx, poetry, pyenv, and virtualenv — all in a single tool.

#### Install

```bash
# Standalone installer (recommend)
curl -LsSf https://astral.sh/uv/install.sh | sh

# pip
pip install uv

# Homebrew
brew install uv

# Upgrade
uv self update
```

#### Python Management

```bash
# Install a specific Python version
uv python install 3.12

# List available Python versions
uv python list

# Pin project Python version (writes .python-version)
uv python pin 3.12
```

#### Project Management

```bash
# Create a new project
uv init my-project
uv init --lib my-lib       # library project (src layout)

# Add and remove dependencies
uv add flask
uv add 'requests>=2.31'
uv add --dev pytest ruff    # dev dependencies
uv remove flask

# Sync environment from pyproject.toml / uv.lock
uv sync

# Run a command in the project environment
uv run python app.py
uv run pytest

# Build and publish
uv build
uv publish
```

#### Virtualenv Management

```bash
# Create a virtualenv (auto-detects Python or specify version)
uv venv
uv venv --python 3.12
uv venv .venv

# Activate
source .venv/bin/activate
```

#### pip-Compatible Interface

```bash
# Install packages (pip-compatible)
uv pip install flask
uv pip install -r requirements.txt

# Uninstall
uv pip uninstall flask

# Freeze current environment
uv pip freeze > requirements.txt

# Compile a locked requirements file from requirements.in
uv pip compile requirements.in -o requirements.txt
```

#### Run Single-File Scripts & CLI Tools

```bash
# Run a script with inline dependencies (PEP 723)
uv run --with requests script.py

# Run CLI tools without installing (like pipx)
uvx ruff check .
uvx black .

# Install a global CLI tool
uv tool install ruff
uv tool list
```

> Reference:
>
> 1. [Official Website](https://www.python.org/)
> 2. [Repository](https://github.com/python/cpython)
> 3. [PyPI](https://pypi.org/)
> 4. [Poetry](https://python-poetry.org/)
> 5. [uv](https://docs.astral.sh/uv/)
> 6. [toml.io](https://toml.io/cn/)
