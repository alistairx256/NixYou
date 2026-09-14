# NixYou

可复用的 NixOS unstable + Home Manager 模块。仓库不绑定主机名、用户名、家目录或 CPU 架构，也不包含机器硬件与引导配置。
具体平台能否使用全部工具，取决于 nixpkgs 中对应软件包的平台支持。

## 配置内容

- `modules/base.nix`：基础工具、垃圾回收、内存管理，以及 zsh、Git 和个人命令行工具配置。
- `modules/desktop.nix`：niri、Hyprland（UWSM）、DankMaterialShell、greetd/tuigreet 会话选择、PipeWire、NetworkManager、蓝牙、桌面门户、中文输入法，以及 Kitty/Ghostty 的安装与配置。
- `modules/development.nix`：Vite+ 管理 Node.js/pnpm，SDKMAN 管理 Java 21，uv 管理 Python；提供 VS Code、Zed、Zig、Clang/LLVM、CMake、Ninja、Go、rustup、Podman 和 direnv。
- `modules/home.nix`：仅负责 Home Manager 集成；个人设置通过各功能模块的 `home-manager.sharedModules` 应用到登记的用户。
- `config/`：各软件的原生配置文件，包括 niri、Hyprland、Kitty 和 Ghostty；这里不放 Nix 模块。

根目录的 `flake.nix` 保留为入口，其他 `.nix` 文件统一放在 `modules/`。
调整软件包、Home Manager 选项或配置文件部署方式时编辑对应模块；调整终端配色、桌面快捷键等原生设置时编辑 `config/` 下对应文件。

## 在现有 NixOS 配置中使用

`flake.nix` 导出以下模块，不再定义具体的 `nixosConfigurations`：

| 导出 | 内容 |
| --- | --- |
| `nixosModules.default` | 基础 + 桌面 + 开发 + Home Manager |
| `nixosModules.base` | 基础系统、zsh、Git 和命令行工具，包含 Home Manager 集成 |
| `nixosModules.home` | 仅 Home Manager 集成 |
| `nixosModules.desktop` | 桌面与输入法，包含 Home Manager 集成 |
| `nixosModules.development` | 开发工具与运行时初始化，包含 Home Manager 集成 |

在你自己的系统 flake 中添加本仓库作为 input，再导入模块。例如下面的 `workstation`、`alice` 和路径都由使用方指定：

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixyou = {
      url = "path:/absolute/path/to/NixYou";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixyou, ... }: {
    nixosConfigurations.workstation = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix # 你已有的机器、硬件与引导配置
        nixyou.nixosModules.default
        {
          users.users.alice = {
            isNormalUser = true;
            extraGroups = [ "wheel" "networkmanager" ];
            # 登录密码沿用已有机器配置。
          };
          home-manager.users.alice.home.stateVersion = "26.05";
        }
      ];
    };
  };
}
```

`home.stateVersion` 应使用该用户最初启用 Home Manager 时的版本，已有配置不要改成示例值。
`system.stateVersion` 继续由现有机器配置维护。
Home Manager 从 `users.users.<name>` 获取用户名与家目录，因此自定义 home 路径也无需修改通用模块。
只对 `home-manager.users` 中登记的用户生成个人配置；添加第二个用户时，为它登记对应的 `home.stateVersion` 即可。

如果只需要基础与开发环境，将示例中的 `nixyou.nixosModules.default` 替换为：

```nix
nixyou.nixosModules.base
nixyou.nixosModules.development
```

这不会启用桌面会话，但开发模块仍会安装 VS Code、Zed 等开发工具。
在**使用方的系统 flake 目录**执行：

```sh
nix flake lock
nix flake check
sudo nixos-rebuild build --flake .#workstation
sudo nixos-rebuild switch --flake .#workstation
```

保留使用方生成的 `flake.lock`，以固定 nixpkgs、Home Manager 和主题源码。
如果使用 Git，先把新增文件加入版本控制，否则 flake 可能忽略未跟踪文件。
本仓库只导出模块，在这里运行 `nix flake check` 不等同于完成整机配置验证，应在使用方组合好模块后检查与构建。
当前 Windows 工作环境没有可用的 Nix，因此这里没有执行 Nix 求值、整机构建或图形会话测试。

## 桌面与输入法

tuigreet 默认启动 niri，按 F2 可选择 **Hyprland (UWSM)**。DMS 和 Fcitx5 由图形会话的 systemd 用户服务启动。
使用 Hyprland 时选择 UWSM 会话，以保证启动和退出时正确管理这些服务。

两种桌面的主要快捷键：

| 快捷键 | 功能 |
| --- | --- |
| Super + Enter | Kitty 终端 |
| Super + Space | DMS 应用启动器 |
| Super + L | DMS 锁屏 |
| Super + E | 文件管理器 |
| Super + Q | 关闭窗口 |
| Super + 方向键 | 切换焦点 |
| Super + Shift + E | 退出桌面会话 |

niri 使用 Super + PageUp/PageDown 切换工作区；Hyprland 使用 Super + 1–5。
配置分别位于 `config/niri/config.kdl` 和 `config/hypr/hyprland.lua`（Hyprland 0.56+）。
这些文件由 Home Manager 管理；修改仓库后重建即可，不要用 `dms setup` 覆盖它们。
DMS 自身的主题、面板等设置仍可通过界面调整。

默认使用 **Fcitx5 + Rime + 雾凇拼音**，Ctrl + Space 切换输入法。
将 `modules/desktop.nix` 中 `useRime` 改为 `false`，即可使用 `fcitx5-chinese-addons` + 萌娘百科词库。
萌娘词库属于 Fcitx 拼音引擎，不会自动用于 Rime。
两种方案均安装 Candlelight 主题，默认 `macOS-dark`；主题源码通过 flake 固定到具体提交。
如已有个人 Fcitx profile/theme 设置，可能覆盖系统默认值，可用 `fcitx5-configtool` 调整。
Rime 方案更新后可从输入法菜单执行“重新部署”。

Wayland 环境配置了 `XMODIFIERS`、`QT_IM_MODULES`、`QT_IM_MODULE`、`SDL_IM_MODULE` 和 `GLFW_IM_MODULE`。
GTK 3/4 的 `gtk-im-module` 写入对应的 `settings.ini`，不全局设置 `GTK_IM_MODULE`，让原生 Wayland GTK 使用文本输入协议。
VS Code 在原生 Wayland 下若无法输入中文，可尝试：

```sh
code --ozone-platform=wayland --enable-wayland-ime --wayland-text-input-version=3
```

字体包含 Noto、Noto CJK Sans/Serif、Noto Color Emoji 和 JetBrains Mono Nerd Font。

## 终端配置

Kitty 和 Ghostty 均已加入配置，使用用户的登录 shell。两个终端预设 JetBrains Mono Nerd Font、12 号字体、12 像素内边距和深色背景，支持 Ctrl + Shift + C/V 复制粘贴。

| 仓库文件 | Home Manager 部署位置 |
| --- | --- |
| `config/kitty/kitty.conf` | 内容合入 `~/.config/kitty/kitty.conf` |
| `config/ghostty/config` | 链接到 `~/.config/ghostty/config` |

修改仓库中的文件后重建即可。Super + Enter 启动 Kitty；Ghostty 可从 DMS 应用启动器或 `ghostty` 命令打开。
如需将快捷键改为 Ghostty，在 niri/Lua 配置中将终端启动命令里的 `kitty` 替换为 `ghostty`。
字体包由桌面模块提供；单独使用 Home Manager 集成时，需要自行安装对应字体。

## 开发运行时初始化

完成系统重建并重新登录后，以配置了 Home Manager 的普通用户执行，**不要加 sudo**：

```sh
dev-setup
exec zsh
sdk list java
```

从列表选择 Java 21 的完整 Identifier（如 `21.x.y-tem` 格式，必须替换为实际版本），然后执行：

```sh
dev-setup <Java-21-Identifier>
exec zsh
```

`dev-setup` 会按需下载 Vite+ 和 SDKMAN，将 Node.js 默认版本设为 LTS、pnpm 设为 10，安装 uv 管理的 Python 3.13。
传入 Java 21 Identifier 时还会安装该 JDK，并通过 `sdk default java` 设为默认。
脚本可重复执行；重复执行会重新应用这些默认值。日常更换版本直接使用相应管理器即可。
SDKMAN 设置 `JAVA_HOME`，Home Manager 负责 zsh 初始化与 PATH。

```sh
vp env doctor
node --version
pnpm --version
sdk current java
java -version
uv python list

# 在各自项目目录内固定版本
vp env pin lts pnpm@10
uv python pin 3.13
uv venv
```

系统不再全局安装 `nodejs`、`pnpm`、`jdk21` 或 `python3`；其他 Nix 包仍可能把它们作为构建或运行依赖。
`uv` 来自 Nix，Python 来自 uv，`--default` 会在 `~/.local/bin` 提供 `python` 和 `python3` 命令。
`nix-ld` 提供下载版 Node/JDK/Python 常用的动态加载器及库；特殊原生依赖应在项目 devShell 中补充。
GUI 编辑器通常能通过 PATH 找到 Java；需要 `JAVA_HOME` 的扩展可从 zsh 启动编辑器，或在扩展内选择 SDKMAN 的 JDK 目录。
管理器下载的运行时不受 `flake.lock` 固定；项目应保留 `.node-version`/`package.json`、`.sdkmanrc`、`.python-version` 和依赖锁文件。

## 参考

- [DMS 的 NixOS 模块](https://danklinux.com/docs/dankmaterialshell/nixos)
- [Fcitx5 的 Wayland 配置](https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland)
- [Candlelight 主题](https://github.com/thep0y/fcitx5-themes-candlelight)
- [Vite+ 环境管理](https://viteplus.dev/guide/env)
- [SDKMAN 安装](https://sdkman.io/install/)
- [uv 安装 Python](https://docs.astral.sh/uv/guides/install-python/)
