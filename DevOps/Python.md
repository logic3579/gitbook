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

A dependency management and packaging tool for Python. It allows declaring project libraries and their constraints via `pyproject.toml` and manages virtual environments automatically.

#### Install

```bash
# Standalone installer (recommend)
curl -sSL https://install.python-poetry.org | python -
poetry self update

# pipx
pipx install poetry
pipx upgrade poetry
```

#### Project Management

```bash
# Create a new project
poetry new my-project

# Initialize an existing project
cd my-project
poetry init

# Build and publish to PyPI
poetry build
poetry publish
```

#### Dependency Management

```bash
# Add dependencies
poetry add flask
poetry add 'requests>=2.31'
poetry add --group dev pytest ruff   # dev dependencies

# Add from requirements.txt
poetry add $(cat requirements.txt)

# Install from pyproject.toml
poetry install

# Remove a dependency
poetry remove flask

# Show all dependencies
poetry show
poetry show --tree                   # dependency tree

# Update dependencies
poetry update
```

#### Virtual Environment

```bash
# Use a specific Python version
poetry env use /usr/bin/python3.10
poetry env use 3.12

# Show environment info
poetry env info
poetry env list                      # list all environments

# Remove an environment
poetry env remove <env_name>

# Activate the environment shell
poetry shell
```

#### Running Commands

```bash
# Run a command inside the virtualenv
poetry run python -V
poetry run python app.py
poetry run pytest
```

#### Configuration

```bash
# List all configuration
poetry config --list

# Set config (append --local for project-level)
poetry config virtualenvs.create true
poetry config virtualenvs.in-project true --local
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

#### Scripts

```bash
# Run a script with inline dependencies declared in the script (PEP 723)
uv run --with requests script.py
uv run --with flask --with jinja2 app.py
```

#### Tools (uvx / uv tool)

`uvx` is an alias for `uv tool run`. It runs a CLI tool in a **temporary isolated environment** — no global install needed. Use `--from` when the package name differs from the command name.

```bash
# Run a tool directly (fetched on demand, not permanently installed)
uvx ruff check .
uvx black .

# --from <package>: explicitly specify the package that provides the command
uvx --from httpie http https://httpbin.org/get
uvx --from httpie http POST https://httpbin.org/post name=uv
uvx --from cowsay cowsay -t "Hello uv"

# Pin a specific version
uvx --from 'ruff==0.4.0' ruff check .

# uv tool: manage persistent global CLI tools (installed to ~/.local/bin)
uv tool install ruff             # install a tool globally
uv tool install httpie           # provides the `http` command
uv tool list                     # list all installed tools
uv tool uninstall ruff           # uninstall a tool
uv tool upgrade ruff             # upgrade a specific tool
uv tool upgrade --all            # upgrade all installed tools
```

> Reference:
>
> 1. [Official Website](https://www.python.org/)
> 2. [Repository](https://github.com/python/cpython)
> 3. [PyPI](https://pypi.org/)
> 4. [Poetry](https://python-poetry.org/)
> 5. [uv](https://docs.astral.sh/uv/)
> 6. [toml.io](https://toml.io/cn/)
