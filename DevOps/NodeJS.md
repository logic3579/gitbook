---
icon: code
description: Node.js record
---

# Node.js

## 1. Development Environment

### Install

```bash
# ubuntu
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs

# macOS
brew install node

# Verify
node -v
npm -v
```

### nvm

Node Version Manager. A tool for managing multiple Node.js versions per user.

#### Install

```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Add to shell profile (auto-added by installer)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Verify
nvm --version
```

#### Node Version Management

```bash
# List available remote versions
nvm ls-remote
nvm ls-remote --lts

# Install a specific version
nvm install 22
nvm install 20.18.0
nvm install --lts                    # latest LTS

# Use a version
nvm use 22
nvm use --lts

# Set default version
nvm alias default 22

# Show current version
nvm current

# List installed versions
nvm ls

# Uninstall a version
nvm uninstall 20.18.0

# Run a command with a specific version (without switching)
nvm exec 20 node app.js
nvm run 20 app.js

# Pin project version (writes .nvmrc)
echo "22" > .nvmrc
nvm use                              # reads .nvmrc
```

### fnm

Fast Node Manager, written in Rust. A faster alternative to nvm with `.nvmrc` / `.node-version` support.

#### Install

```bash
# macOS
brew install fnm

# Linux
curl -fsSL https://fnm.vercel.app/install | bash

# Add to shell profile
eval "$(fnm env --use-on-cd)"
```

#### Node Version Management

```bash
# Install and use
fnm install 22
fnm use 22
fnm default 22

# List versions
fnm ls
fnm ls-remote

# Auto-switch on cd (reads .nvmrc / .node-version)
fnm env --use-on-cd
```

## 2. ProjectManage

### npm

The default package manager bundled with Node.js. It uses `package.json` for dependency declaration and `package-lock.json` for lockfile.

#### Project Management

```bash
# Initialize a new project
npm init
npm init -y                          # skip prompts

# Install dependencies
npm install
npm install express
npm install 'axios@^1.7'
npm install --save-dev jest eslint   # dev dependencies

# Uninstall
npm uninstall express

# Update dependencies
npm update
npm outdated                         # check for outdated packages

# Show dependency tree
npm ls
npm ls --depth=0                     # top-level only

# Run scripts defined in package.json
npm run build
npm run dev
npm test
npm start

# Execute a package binary (npx)
npx create-react-app my-app
npx eslint .
npx --yes degit user/repo my-project

# Global install
npm install -g pm2
npm ls -g --depth=0
```

#### Configuration

```bash
# Registry
npm config get registry
npm config set registry https://registry.npmmirror.com

# Cache
npm cache clean --force
npm cache verify
```

### Bun

An all-in-one JavaScript runtime and toolkit. It includes a bundler, test runner, and npm-compatible package manager — all significantly faster than Node.js equivalents.

#### Install

```bash
# Standalone installer (recommend)
curl -fsSL https://bun.sh/install | bash

# macOS
brew install oven-sh/bun/bun

# npm
npm install -g bun

# Upgrade
bun upgrade
```

#### Project Management

```bash
# Initialize a new project
bun init

# Install dependencies (reads package.json, writes bun.lock)
bun install
bun add express
bun add 'axios@^1.7'
bun add --dev jest eslint            # dev dependencies

# Remove
bun remove express

# Update dependencies
bun update
bun outdated

# Run scripts defined in package.json
bun run build
bun run dev
bun test

# Run a file directly (uses Bun runtime)
bun run app.ts                       # TypeScript supported natively
bun run app.js

# Execute a package binary (like npx)
bunx create-next-app my-app
bunx eslint .

# Build and bundle
bun build ./src/index.ts --outdir ./dist
```

### pnpm

A fast, disk-efficient package manager. It uses a content-addressable store and hard links to save disk space.

#### Install

```bash
# Via corepack (recommend)
corepack enable
corepack prepare pnpm@latest --activate

# Standalone
curl -fsSL https://get.pnpm.io/install.sh | sh

# Via npm
npm install -g pnpm

# Verify
pnpm -v
```

#### Project Management

```bash
# Initialize a new project
pnpm init

# Install dependencies
pnpm install
pnpm add express
pnpm add 'axios@^1.7'
pnpm add --save-dev jest eslint     # dev dependencies

# Remove
pnpm remove express

# Update dependencies
pnpm update
pnpm outdated

# Run scripts
pnpm run build
pnpm dev
pnpm test

# Execute a package binary
pnpm dlx create-react-app my-app

# Manage the content-addressable store
pnpm store status
pnpm store prune                     # remove unreferenced packages
```

> Reference:
>
> 1. [Official Website](https://nodejs.org/)
> 2. [Repository](https://github.com/nodejs/node)
> 3. [npm](https://www.npmjs.com/)
> 4. [nvm](https://github.com/nvm-sh/nvm)
> 5. [fnm](https://github.com/Schniz/fnm)
> 6. [Bun](https://bun.sh/)
> 7. [pnpm](https://pnpm.io/)
