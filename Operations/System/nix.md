# Nix

## Install

### Nix package manager

#### Linux

```bash
# Install Nix via the recommended multi-user installation:
sh <(curl -L https://nixos.org/nix/install) --daemon

# Single-user installation
sh <(curl -L https://nixos.org/nix/install) --no-daemon
```

#### Docker

```bash
# Start a Docker shell with Nix
docker run -it nixos/nix
# Or start a Docker shell with Nix exposing a workdir directory
mkdir workdir
docker run -it -v $(pwd)/workdir:/workdir nixos/nix
# The workdir example from above can be also used to start hacking on nixpkgs
git clone --depth=1 https://github.com/NixOS/nixpkgs.git
docker run -it -v $(pwd)/nixpkgs:/nixpkgs nixos/nix
docker> nix-build -I nixpkgs=/nixpkgs -A hello
docker> find ./result # this symlink points to the build package


# Start a Docker shell with NixOS
docker run -it --name nix-flakes -d --rm nixpkgs/nix-flakes
docker exec -it nix-flakes bash
bash-5.2# nix run github:helix-editor/helix/master
```

### NixOS

#### [1. Obtaining NixOS](https://nixos.org/download/#nixos-iso)

#### 2. Manual Installation

##### Partitioning

```bash
# UEFI(GPT)
# Create a GPT partition table
parted /dev/sda -- mklabel gpt
# Add the boot partition.
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
# Add the root partition.
parted /dev/sda -- mkpart root ext4 512MB 100%
# NixOS by default uses the ESP (EFI system partition) as its /boot partition. It uses the initially reserved 512MiB at the start of the disk.
parted /dev/sda -- set 1 esp on


# Legacy Boot(MBR)
# Create a MBR partition table.
parted /dev/sda -- mklabel msdos
parted /dev/sda -- mkpart primary 1MB -2GB
parted /dev/sda -- set 1 boot on
parted /dev/sda -- mkpart primary linux-swap -2GB 100%
```

![[/Operations/System/attachements/Pasted image 20240321172907.png]]

##### Formatting

```bash
# Format
mkfs.fat -F 32 -n boot /dev/sda1
mkfs.ext4 -L nixos /dev/sda2


## Examples
# For initialising Ext4 partitions: mkfs.ext4. It is recommended that you assign a unique symbolic label to the file system using the option -L label, since this makes the file system configuration independent from device changes. For example:
mkfs.ext4 -L nixos /dev/sda1

# For creating swap partitions: mkswap. Again it’s recommended to assign a label to the swap partition: -L label. For example:
mkswap -L swap /dev/sda2

# UEFI systems
# For creating boot partitions: mkfs.fat. Again it’s recommended to assign a label to the boot partition: -n label. For example:
mkfs.fat -F 32 -n boot /dev/sda3

# For creating LVM volumes, the LVM commands, e.g., pvcreate, vgcreate, and lvcreate.

# For creating software RAID devices, use mdadm.
```

##### Installing

```bash
# Mount the target file system on which NixOS should be installed on /mnt, e.g.
mount /dev/sda2/ /mnt

# UEFI systems
# Mount the boot file system on /mnt/boot
mkdir -p /mnt/boot
mount /dev/sda1/ /mnt/boot

# Generate and edit config
nixos-generate-config --root /mnt
cat >> /mnt/etc/nixos/configuration.nix << "EOF"
{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # (for BIOS systems only)
  # boot.loader.grub.device = "/dev/sda";
  # (for UEFI systems only)
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "logic-nixos"; # Define your hostname.

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.logic = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    openssh.authorizedKeys.keys = [
      # replace with your own public key
      "ssh-rsa <public-key> logic@nixos"
    ];
    packages = with pkgs; [
      tree
    ];
  };

  # Enable experimental-features Flakes and nix-command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    # inputs.helix.packages."${pkgs.system}".helix
  ];
  environment.variables.EDITOR = "vim";

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
    openFirewall = true;
  }

  system.stateVersion = "23.11"; # Did you read the comment?
}
EOF

# Install NixOS
nixos-install
# set root password and reboot
```

#### 3. Upgrading

```bash
# switch channel
nix-channel --list
nixos https://nixos.org/channels/nixos-23.11
# add new channel
nix-channel --add https://channels.nixos.org/nixos-23.11 nixos
nix-channel --add https://channels.nixos.org/nixos-23.11-small nixos

# upgrade
nixos-rebuild switch --upgrade
```

## NixCommand

### nixos-rebuild

```bash
# build new configuration and try to realise the configuration in the running system
nixos-rebuild switch

# to build the configuration and switch the running system to it, but without making it the boot default.(so it will get back to a working configuration after the next reboot).
nixos-rebuild test

# to build the configuration and make it the boot default, but not switch to it now (so it will only take effect after the next reboot).
nixos-rebuild boot

# You can make your configuration show up in a different submenu of the GRUB 2 boot screen by giving it a different profile name
nixos-rebuild switch -p test

# to build the configuration but nothing more. can check syntax
nixos-rebuild build

# rollback
nixos-rebuild switch --rollback

# verbose argument
--show-trace --print-build-logs --verbose
```

### nix-channel

```bash
# list
nix-channel list

# add new
nix-channel --add https://channels.nixos.org/channel-name nixos
```

### nix-shell

```bash
# nodejs env
bash-5.2# nix-shell -p nodejs
[nix-shell:/]# node -e "console.log(1+1)"

# nix-shell
cat > /default.nix << "EOF"
{ pkgs ? import <nixpkgs> {}
}:
pkgs.mkShell {
  name = "logic-test";
  buildInputs = [
    pkgs.nodejs
  ];
  shellHook = ''
    echo "Start developing..."
  '';
}
EOF
bash-5.2# nix-shell
[nix-shell:/]# node -e "console.log(1+1)"
```

### nix-build

```bash
# create normal redis nix file
cat > ./docker-redis.nix << "EOF"
{ pkgs ? import <nixpkgs> { system = "x86_64-linux";}
}:
pkgs.dockerTools.buildLayeredImage {
  name = "nix-redis";
  tag = "latest";
  contents = [ pkgs.redis ];
}
EOF
# build a normal docker image
nix-build docker-redis.nix -o ./result
docker load -i ./result
docker images


# create redis-minimal.nix
cat > ./redis-minimal.nix << "EOF"
{ pkgs ? import <nixpkgs> {}
}:
pkgs.redis.overrideAttrs (old: {
  makeFlags = old.makeFlags ++ ["USE_SYSTEMD=no"];
  preBuild = ''
    makeFlagsArray=(PREFIX="$out"
                    CC="${pkgs.musl.dev}/bin/musl-gcc -static"
                    CFLAGS="-I{pkgs.musl.dev/include}"
                    LDFLAGS="-L{pkgs.musl.dev/lib}");
  '';
  postInstall = "rm -f $out/bin/redis-{benchmark,check-*,cli}";
})
EOF
# create minimal redis nix file
cat > ./docker-redis.nix << "EOF"
{ pkgs ? import <nixpkgs> { system = "x86_64-linux";}
}:
let
  redisMinimal = import ./redis-minimal.nix { inherit pkgs; };
in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-redis-minimal";
  tag = "latest";
  contents = [ redisMinimal ];
}
EOF
# build a minimal docker image
nix-build redis-minimal.nix -o ./result
docker load -i ./result
docker images
```

## Flakes

### nix flake

#### enable experimental features

```bash
cat /etc/nixos/configuration.nix
{ config, pkgs, inputs, ... }:
{
  # ...
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
  ];
  # ...
}
```

#### init flake.nix

```bash
# show flakes templates
nix flake show templates
# init
nix flake init -t templates#full
cat ./flake.nix


# create flake.nix
cat > /etc/nixos/flake.nix << "EOF"
{
  description = "A simple NixOS flake";

  inputs = {
    # NixOS official software source
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
	# helix editor, use the master branch
    helix.url = "github:helix-editor/helix/master";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.logic-nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        # 将所有 inputs 参数设为所有子模块的特殊参数，子模块直接引用 inputs 中所有依赖项
		{ _module.args = { inherit inputs; };}
      ];
    };
  };
}
EOF
# modified configuration.nix
cat /etc/nixos/configuration.nix
{ config, pkgs, inputs, ... }:
{
  # ...
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    # install helix from inputs
    inputs.helix.packages."${pkgs.system}".helix
  ];
  # ...
}
...


# switch to flakes
nixos-rebuild switch
# switch to flaskes from specify directory or remote repo
nixos-rebuild switch --flake /path/flake#your-hostname
nixos-rebuild switch --flake github:owner/repo#your-hostname


# flake update
# update all to flake.lock
nix flake update
# or only update home-manager
nix flake lock --update-input home-manager

	#
sudo nixos-rebuild switch --flake .
```

### nix-command

```bash
# nix-channel
# no need

# nix-env
nix profile

# nix-shell
nix develop
nix shell
nix run
# eg: only run helix, do not install to system
nix run github:helix-editor/helix/master

# nix-build
nix build

# nix-collect-garbage
nix storage gc --debug

# Interactive environment
nix repl
```

### home-manager

```bash
# init home.nix
cat > /etc/nixos/home.nix << "EOF"
{ config, pkgs, ... }:

{
  # user infomation
  home.username = "logic";
  home.homeDirectory = "/home/logic";

  # 直接将当前文件夹的配置文件，链接到 Home 目录下的指定位置
  # home.file.".config/i3/wallpaper.jpg".source = ./wallpaper.jpg;

  # 递归将某个文件夹中的文件，链接到 Home 目录下的指定位置
  # home.file.".config/i3/scripts" = {
  #   source = ./scripts;
  #   recursive = true;   # 递归整个文件夹
  #   executable = true;  # 将其中所有文件添加「执行」权限
  # };

  # 直接以 text 的方式，在 nix 配置文件中硬编码文件内容
  # home.file.".xxx".text = ''
  #     xxx
  # '';

  # 设置鼠标指针大小以及字体 DPI（适用于 4K 显示器）
  # xresources.properties = {
  #   "Xcursor.size" = 16;
  #   "Xft.dpi" = 172;
  # };

  # 通过 home.packages 安装一些常用的软件
  # 这些软件将仅在当前用户下可用，不会影响系统级别的配置
  # 建议将所有 GUI 软件，以及与 OS 关系不大的 CLI 软件，都通过 home.packages 安装
  home.packages = with pkgs;[
    # archives
    zip
    xz
    unzip
    p7zip

    # utils
    jq # A lightweight and flexible command-line JSON processor
    yq-go # yaml processor https://github.com/mikefarah/yq

    # networking tools
    mtr # A network diagnostic tool
    iperf3
    dnsutils  # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc  # it is a calculator for the IPv4/v6 addresses

    # misc
    cowsay
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg

    # nix related
    #
    # it provides the command `nom` works just like `nix`
    # with more details log output
    nix-output-monitor

    # productivity
    glow # markdown previewer in terminal

    # system call monitoring
    strace # system call monitoring
    ltrace # library call monitoring
    lsof # list open files

    # system tools
    btop  # replacement of htop/nmon
    iotop # io monitoring
    iftop # network monitoring
    sysstat
    lm_sensors # for `sensors` command
    ethtool
    pciutils # lspci
    usbutils # lsusb
  ];

  # git 相关配置
  programs.git = {
    enable = true;
    userName = "Logic";
    userEmail = "logic3579@duck.com";
  };

  # 启用 starship，这是一个漂亮的 shell 提示符
  programs.starship = {
    enable = true;
    # 自定义配置
    settings = {
      add_newline = false;
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;
    };
  };

  # alacritty - 一个跨平台终端，带 GPU 加速功能
  programs.alacritty = {
    enable = true;
    # 自定义配置
    settings = {
      env.TERM = "xterm-256color";
      font = {
        size = 12;
        draw_bold_text_with_bright_colors = true;
      };
      scrolling.multiplier = 5;
      selection.save_to_clipboard = true;
    };
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    # TODO 在这里添加你的自定义 bashrc 内容
    bashrcExtra = ''
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
    '';

    # TODO 设置一些别名方便使用，你可以根据自己的需要进行增删
    shellAliases = {
      k = "kubectl";
      urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
      urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
    };
  };

  home.stateVersion = "23.11";

  programs.home-manager.enable = true;
}
EOF


# generate flake.nix
nix flake new example -t github:nix-community/home-manager#nixos
vim /etc/nixos/flake.nix
{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }: {
    nixosConfigurations = {
      logic-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix

          # 将 home-manager 配置为 nixos 的一个 module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.logic = import ./home.nix;
          }
        ];
      };
    };
  };
}


# switch to home-manager
nixos-rebuild switch


# all configuration
# 自动生成的版本锁文件，它记录了整个 flake 所有输入的数据源、hash 值、版本号，确保系统可复现
/etc/nixos/flake.lock
# flake 的入口文件，执行 sudo nixos-rebuild switch 时会识别并部署它
/etc/nixos/flake.nix
# 在 flake.nix 中被作为系统模块导入，目前所有系统级别的配置都写在此文件中
/etc/nixos/configuration.nix
# 在 flake.nix 中被 home-manager 作为用户的配置导入，包含了用户的所有 Home Manager 配置，负责管理其 Home 文件夹
/etc/nixos/home.nix
# hardware configuration
/etc/nixos/hardware-configuration.nix
```

### module imports

```bash
# example
tree /etc/nixos
/etc/nixos
├── flake.lock
├── flake.nix
├── home
│   ├── default.nix         # 在这里通过 imports = [...] 导入所有子模块
│   ├── fcitx5              # fcitx5 中文输入法设置，我使用了自定义的小鹤音形输入法
│   │   ├── default.nix
│   │   └── rime-data-flypy
│   ├── i3                  # i3wm 桌面配置
│   │   ├── config
│   │   ├── default.nix
│   │   ├── i3blocks.conf
│   │   ├── keybindings
│   │   └── scripts
│   ├── programs
│   │   ├── browsers.nix
│   │   ├── common.nix
│   │   ├── default.nix   # 在这里通过 imports = [...] 导入 programs 目录下的所有 nix 文件
│   │   ├── git.nix
│   │   ├── media.nix
│   │   ├── vscode.nix
│   │   └── xdg.nix
│   ├── rofi              # rofi 应用启动器配置，通过 i3wm 中配置的快捷键触发
│   │   ├── configs
│   │   │   ├── arc_dark_colors.rasi
│   │   │   ├── arc_dark_transparent_colors.rasi
│   │   │   ├── power-profiles.rasi
│   │   │   ├── powermenu.rasi
│   │   │   ├── rofidmenu.rasi
│   │   │   └── rofikeyhint.rasi
│   │   └── default.nix
│   └── shell             # shell 终端相关配置
│       ├── common.nix
│       ├── default.nix
│       ├── nushell
│       │   ├── config.nu
│       │   ├── default.nix
│       │   └── env.nu
│       ├── starship.nix
│       └── terminals.nix
├── hosts
│   ├── msi-rtx4090      # PC 主机的配置
│   │   ├── default.nix  # 之前的 configuration.nix，大部分内容都拆出到 modules
│   │   └── hardware-configuration.nix  # 与系统硬件相关的配置，安装 nixos 时自动生成的
│   └── my-nixos       # 测试用的虚拟机配置
│       ├── default.nix
│       └── hardware-configuration.nix
├── modules          # 从 configuration.nix 中拆分出的一些通用配置
│   ├── i3.nix
│   └── system.nix
└── wallpaper.jpg    # 桌面壁纸，在 i3wm 配置中被引用


# repl lib
nix repl -f '<nixpkgs>'
nix-repl> :e lib.mkDefault
##
lib.mkDefault
lib.mkForce
lib.mkOrder
lib.mkBefore
lib.mkAfter
```

> Reference:
>
> 1. [NixOS Official Manual](https://nixos.org/manual/nix/stable/language/)
> 2. [NixOS 与 Flakes](https://nixos-and-flakes.thiscute.world/)
> 3. [NixOS 中文文档](https://nixos-cn.org/tutorials/lang/)
> 4. [NixOS Packages Search](https://search.nixos.org/packages)
> 5. [NixOS Options Search](https://search.nixos.org/options)
> 6. [Nix Home Manager Manual](https://nix-community.github.io/home-manager/index.xhtml)
