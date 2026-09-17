---
icon: code
description: Rust record
tags:
  - devops/language
---

# Rust

## 1. Development Environment

### Install

```bash
# Unix-like systems (Linux, macOS)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# macOS (using Homebrew)
brew install rustup

# Linux (using package manager, e.g., Ubuntu)
# Note: The package manager versions might be outdated, so rustup is recommended.
# sudo apt install rustup   # for Ubuntu/Debian

# Verify
rustc --version
cargo --version
```

### rustup

The Rust toolchain installer and version manager.

```bash
# Update rustup and toolchains
rustup update

# List installed toolchains
rustup toolchain list

# Install a specific toolchain (e.g., nightly)
rustup install nightly

# Set default toolchain
rustup default stable
rustup default nightly

# Add a target for cross-compilation
rustup target add wasm32-unknown-unknown

# Show current toolchain
rustup show

# Uninstall a toolchain
rustup uninstall nightly
```

### cargo

Rust's package manager and build tool, installed with rustup.

```bash
# Create a new binary project
cargo new my-project
cd my-project

# Create a new library project
cargo new --lib my-library

# Build the project
cargo build
cargo build --release   # optimized build

# Run the project
cargo run
cargo run --release

# Check for compilation errors without producing an executable
cargo check

# Run tests
cargo test
cargo test --release

# Generate documentation
cargo doc
cargo doc --open

# Manage dependencies
cargo add serde               # add a dependency
cargo add --dev rayon         # add a dev-dependency
cargo remove serde            # remove a dependency
cargo update                  # update all dependencies
cargo update -p serde         # update a specific package

# Install a binary from crates.io
cargo install ripgrep

# List installed binaries
cargo install --list

# Uninstall a binary
cargo uninstall ripgrep

# Login to crates.io for publishing
cargo login

# Publish a package
cargo publish
```

## 2. ProjectManage

### cargo

The central tool for managing Rust projects.

```bash
# Initialize a new project (same as cargo new)
cargo init

# Run a specific binary example (if the project has examples)
cargo run --example my_example

# Run tests for a specific module
cargo test my_module

# Benchmarking (requires nightly feature)
cargo bench   # only works with #![feature(test)] and nightly

# Cleaning build artifacts
cargo clean

# Checking for outdated dependencies (via cargo-update plugin, but we can show the manual way?)
# Note: cargo itself doesn't have a direct outdated command, but we can use:
cargo update --dry-run   # shows what would be updated without updating

# Or install the cargo-update plugin:
# cargo install cargo-update
# cargo outdated
# cargo upgrade
```

> Reference:
>
> 1. [Official Website](https://www.rust-lang.org/)
> 2. [Repository](https://github.com/rust-lang/rust)
> 3. [Documentation](https://doc.rust-lang.org/book/)
> 4. [crates.io](https://crates.io/)
> 5. [rustup](https://github.com/rust-lang/rustup)
> 6. [cargo](https://github.com/rust-lang/cargo)