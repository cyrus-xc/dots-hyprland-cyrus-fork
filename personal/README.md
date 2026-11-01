# personal/ — 本机在 end-4 默认配置之上的自定义内容

这个仓库的 `main` 是 cyrus 这台机器（Arch Linux + Hyprland，end-4/dots-hyprland 的 illogical-impulse 配置）
桌面配置的完整来源：

- `dots/`：end-4 原版加上已经整理成功能的改动（见下「已进 main 的功能」），由 end-4 的安装脚本装到 `~/.config`。
- `personal/`：只属于这台机器的个人配置，`personal/apply.sh` 一条命令套用。
- `personal.sh`：本机额外安装的软件包。

## 新机器完整步骤

```bash
git clone https://github.com/cyrus-xc/dots-hyprland-cyrus-fork ~/Development/dots-hyprland-cyrus-fork
cd ~/Development/dots-hyprland-cyrus-fork
./install.sh                 # end-4 的安装脚本：依赖、dots/ 到 ~/.config
bash personal/apply.sh       # 个人配置：复制文件、套补丁、建链接、启用服务（硬件监控那步要 sudo）
bash personal.sh             # 本机额外的仓库包
yay -S --needed $(sed -n 's/^#AUR //p' personal.sh | tr '\n' ' ')   # AUR 包
```

然后注销重新登录（或 `hyprctl reload` 加 Ctrl+Super+R），Hyprland、quickshell、fcitx5、zsh 才会全部读到新配置。

`apply.sh` 可以重复运行（已经一致的文件和已套用的补丁会跳过），`--dry-run` 只打印不改，
`--skip-system` 跳过需要 sudo 的硬件监控系统服务，`--skip-services` 跳过 systemd 用户服务，`--home DIR` 用于测试。
被替换的原文件都留在 `~/.local/state/illogical-impulse/backups/personal-apply-<时间戳>/`。

apply.sh 之后仍要手动做的：
- `~/.config/sunshine/sunshine.conf` 里 `csrf_allowed_origins` 的 `<LAN-IP>` / `<TAILSCALE-IP>` / `<TAILNET-HOST>` 占位符换成真实地址（仓库是公开的，不收真实地址）。
- `~/.config/hypr/monitors.lua` 是本机 HDMI-A-1 4K 缩放 2.0 的配置，换了显示器就用 nwg-displays 重新生成。
- 飞书启动脚本依赖手动安装的 `~/.local/opt/feishu`；Clash 需要自己装 Clash Verge Rev 并导入订阅（订阅不进仓库）。
- Sunshine 自身的配对信息、credentials 不进仓库，要重新配对。

## 目录约定

`home/` 对应 `$HOME`。两类文件：

- **完整文件**：end-4 留给用户改的文件（`hypr/custom/*.lua`、`kitty.conf`、`config.json` 等）和本机新增的文件，apply.sh 直接复制。
- **`*.patch`**：对 end-4 自带文件的个人偏好改动，是相对 `$HOME` 的 unified diff，针对 `main` 的 `dots/` 版本生成。
  apply.sh 用 `patch -p1 -d ~` 套用，也可以手动：
  ```bash
  patch -p1 -d ~ < personal/home/.config/foot/foot.ini.patch
  ```

## 已进 main 的功能（不在 personal/ 里）

这些原本是本机改动，已整理成基于 upstream/main 的分支并合入 main，安装脚本会直接装上：

| 分支 | 内容 |
| --- | --- |
| `feat/settings-displays-page` | 设置里的 Displays 页（显示器信息、布局预览，按钮打开 nwg-displays） |
| `feat/wallpaper-auto-rotate` | 壁纸自动切换（间隔、随机/顺序、文件夹、立即下一张） |
| `feat/tokyo-night-palette` | Tokyo Night 固定配色 |
| `feat/video-wallpaper` | 视频壁纸：选择器列出视频、缩略图、mpvpaper 依赖进安装脚本 |
| `feat/hardware-monitor` | 状态栏按 GPU 显示占用，弹窗显示每个 CPU 封装的负载/功耗/频率/温度和显存/频率；数据来自系统服务 `end4-hardware-monitor`（apply.sh 负责安装到 `/usr/local/libexec` 和 `/etc/systemd/system`） |
| `feat/idle-settings` | General 页的「锁屏与息屏」：自动锁屏/息屏分钟数，读写 hypridle.conf |
| `feat/launcher-all-apps` | 启动器「全部应用」按钮，应用前缀下列出全部应用 |
| `feat/tray-fixes` | 去掉重复的 Fcitx 托盘图标；不再直接 kill kded6 |
| `feat/lock-ipc-islocked` | 锁屏 IPC `isLocked()`，供看门狗使用 |
| `claude-code-backend` | 侧边栏接入本机 Claude Code（upstream PR #3744） |

## 不收在这里的东西

- 生成物：matugen 输出（`hypr/hyprland/colors.lua`、`hypr/hyprlock/colors.conf`、`gtk-3.0/gtk.css`、`gtk-4.0/gtk.css`、`fuzzel_theme.ini` 和 `foot.ini` 的颜色）、
  kde-material-you-colors 输出（`kdeglobals` 颜色、konsole 的 `MaterialYou*.colorscheme`、`TempMyou.profile`）、`dconf/user`、
  `hypr/custom/scripts/__restore_video_wallpaper.sh` 和 `mpvpaper_thumbnails/`、`fcitx5/conf/cached_layouts`。
- 各种 `*.before-*`、`*.backup-*` 备份文件。
- `quickshell/ii/modules/common/widgets/shapes/`：上游是 git 子模块，本机是完整克隆，不算修改。
- 与上游完全一致的 `zshrc.d/`、`starship.toml`、`fontconfig/fonts.conf`、`matugen/`、`kitty/*.py`。
- 含密钥或订阅的目录：`clash-verge-rev`、`sunshine/credentials`、浏览器 profile。
- 与桌面无关的 systemd 用户服务（deepseek-harness、pipeline-*、we-agent*、xhs-*）和 `~/.local/bin` 里指向手动安装软件的链接（claude、cursor、cc-hub、agent-reach）。
- `cava/`、`btop/themes/`：只有默认主题文件。

## 清单

| 文件 | 类型 | 内容 | 来源 |
| --- | --- | --- | --- |
| `.zshrc` | 完整 | oh-my-zsh + starship + zoxide，`cat` 别名到 bat，HF 镜像；「personal.sh package tracker」段（见下）；末尾「Cyrus Fastfetch」段 | 用户自建 |
| `.zshenv` | 完整 | 把 `~/.local/bin` 加进 PATH（uv、cc-hub 等） | 用户自建 |
| `.config/clash-proxy.sh` | 完整 | 登录时清空代理环境变量 | 用户自建 |
| `.config/clash-commands.zsh` | 完整 | `clash on/off/status/ui…` 函数，控制 Clash Verge 用户服务 | 用户自建 |
| `.config/environment.d/70-clash-proxy.conf` | 完整 | systemd 用户会话的代理环境变量（127.0.0.1:7890，内网 no_proxy） | 用户自建 |
| `.config/fcitx5/config`、`profile`、`conf/{pinyin,punctuation,chttrans,notifications}.conf` | 完整 | fcitx5：Ctrl+Space 切换、共享输入状态；默认组 us + pinyin | 用户配置 |
| `.config/hypr/custom/env.lua` | 完整 | fcitx5 输入法环境变量；`__GLX_VENDOR_LIBRARY_NAME=nvidia`；`__NV_DISABLE_EXPLICIT_SYNC=1` 规避 NVIDIA 580 句柄泄漏（egl-wayland #196） | 2026-10-30 |
| `.config/hypr/custom/execs.lua` | 完整 | 启动 fcitx5；导入环境后重启 Sunshine 用户服务；启动 Clash Verge | 用户配置 |
| `.config/hypr/custom/general.lua` | 完整 | 全局窗口透明：激活 0.95、非激活 0.88、全屏 1.0 | 2026-10-30 |
| `.config/hypr/custom/rules.lua` | 完整 | 重新打开所有窗口的模糊；媒体类和 kitty 窗口强制不透明 | 2026-10-30 |
| `.config/hypr/custom/keybinds.lua` | 完整 | Super+Space 打开搜索；Super+Shift+H/L 把窗口移到左/右工作区；Ctrl+Super+Space 循环切换平铺布局 | 2026-11-01 |
| `.config/hypr/hypridle.conf` | 完整 | 30 分钟锁屏、60 分钟息屏，删掉自动休眠（常开服务器）；带 `end4-idle-settings` 元数据行 | 2026-10-28 |
| `.config/hypr/monitors.lua`、`monitors.conf`、`workspaces.conf` | 完整 | nwg-displays 生成：HDMI-A-1 3840x2160@60 缩放 2.0 | 2026-10-30 |
| `.config/hypr/hyprland/general.lua.patch` | 补丁 | 阴影 `render_power` 10 → 4 | 2026-10-31 |
| `.config/hypr/hyprland/variables.lua.patch` | 补丁 | 文件管理器/任务管理器回退命令里 fish → zsh | 用户配置 |
| `.config/illogical-impulse/config.json` | 完整 | 壳层全部设置：配色 `tokyo-night`、壁纸自动切换开启（30 分钟、顺序）、Google Sans Flex 字体、透明、托盘固定 fcitx、dock/启动器固定应用、夜灯 19:00–06:30、quickshell 锁屏、`apps.*` 用 zsh、Claude Code 侧边栏默认 session。其中 `wallpaperPath`/`thumbnailPath`/时钟坐标是运行时状态，会随使用变化 | 持续累积 |
| `.config/kitty/kitty.conf` | 完整 | `background_opacity 0.85`、`background_blur 20`、`dynamic_background_opacity yes`；`shell zsh`；Ctrl+V 粘贴 | 2026-10-30 |
| `.config/foot/foot.ini.patch` | 补丁 | `shell=fish` → `shell=zsh`（颜色部分是 matugen 生成的，不收） | 用户配置 |
| `.local/share/konsole/Profile 1.profile.patch` | 补丁 | Konsole 默认 profile 的 shell fish → zsh | 用户配置 |
| `.config/quickshell/ii/modules/common/Config.qml.patch` | 补丁 | `apps.changePassword` / `apps.update` 命令 fish → zsh | 用户配置 |
| `.config/quickshell/ii/services/LauncherSearch.qml.patch` | 补丁 | 启动器 `$sudo …` 命令用 zsh 执行 | 用户配置 |
| `.config/btop/btop.conf` | 完整 | btop 偏好 | 用户配置 |
| `.config/nwg-displays/config` | 完整 | nwg-displays 偏好（确认超时 15 s 等） | 用户配置 |
| `.local/bin/qs-watchdog` | 完整 | quickshell 独占内存 > 1 GB 或句柄 > 4096 时重启它；锁屏状态下重启后重新上锁；没在运行时拉起并上锁 | 2026-10-30 |
| `.config/systemd/user/qs-watchdog.{service,timer}` | 完整 | 每 5 分钟运行一次看门狗（apply.sh 会 enable） | 2026-10-30 |
| `.local/bin/sunshine-wake` | 完整 | Moonlight 连接时点亮显示器、确保 quickshell 在跑、把焦点交给锁屏 | 2026-10-30 |
| `.config/sunshine/sunshine.conf` | 完整（脱敏） | wlr 采集 + nvenc，`global_prep_cmd` 调用 sunshine-wake；`csrf_allowed_origins` 的地址已替换成占位符 | 2026-10-30 |
| `.config/systemd/user/clash-verge.service`、`clash-verge.service.d/*.conf` | 完整 | Clash Verge Rev 作为用户服务；dashboard 路径；服务自身不继承代理变量 | 用户配置 |
| `.local/bin/clash-dashboard` | 完整 | 用 Chrome app 模式打开本机 Clash 控制台（secret 是占位符） | 用户自建 |
| `.local/bin/feishu` | 完整 | 飞书启动包装：2 倍缩放、小光标 | 用户自建 |
| `.config/fastfetch/` | 完整（链接） | 见下「Fastfetch」；apply.sh 通过 `setup-fastfetch.sh` 建链接 | 用户自建 |

## personal.sh 和 pacman 包装函数

`personal.sh`（仓库根目录）只有一条 `sudo pacman -S --needed …` 命令，列出本机显式安装、
但 end-4 安装脚本不会装、也不属于 archinstall 基础集的包，按用途分组排列；AUR 包以 `#AUR 名字` 行列在前面，
安装命令写在注释里。生成方法：`pacman -Qeq` 减去 `sdata/dist-arch/*/PKGBUILD` 的 depends/makedepends 和元包名，
减去 base、linux*、linux-firmware、amd-ucode、mkinitcpio、efibootmgr、sudo、nano、vim、less、iwd。

`.zshrc` 里的「personal.sh package tracker」段：

- `alias pacman='personal_pacman command pacman'`（函数名不带下划线前缀：Claude Code 的 shell 快照不会收录 `_` 开头的函数，否则在它的终端里 pacman 会报 command not found），以及一个 `sudo` 函数，把 `sudo [选项] pacman …` 也送进同一个包装。
- 包装在运行前后各取一次 `pacman -Qeq`，新增的显式安装包：在同步仓库里能查到的追加到 `personal.sh` 那条命令末尾，查不到的追加成 `#AUR 名字` 行。已列出的不重复加。
- pacman 的参数原样传递，退出码原样返回。`personal.sh` 不存在或不可写时什么都不做。
- `yay` 同样包装：`personal_yay() { personal_pacman command yay "$@" }` 加 `alias yay='personal_yay'`，走同一套比对和分类逻辑（`pacman -Si` 查得到的是仓库包，否则记为 `#AUR`）。只搜索、只升级、卸载等操作不会产生新的显式包，自然原样透传。
- 路径通过 `${XDG_CONFIG_HOME:-$HOME/.config}/cyrus-dotfiles` 链接定位仓库（apply.sh 建这个链接），也可通过 `CYRUS_DOTFILES_DIR` 覆盖；不绑定用户名和仓库检出目录。


## Fastfetch：透明人物 Logo + Catnap 信息栏

- 配置：`home/.config/fastfetch/config.jsonc`，基于 Fastfetch 官方
  [examples/13.jsonc](https://github.com/fastfetch-cli/fastfetch/blob/2.70.0/presets/examples/13.jsonc)，蓝紫配色。
- 图片：`home/Pictures/fastfetch/*.png`，统一 1024×1024 RGBA，每次启动随机选择。
  `originals/` 保留输入原图，不参与 Logo 随机选择。
- Kitty 本地终端使用 `kitty-direct`；SSH 或其他终端自动降级为小号 Arch ASCII Logo。
- `.zshrc` 只在交互式 TTY 中显示，管道、非交互脚本和 `TERM=dumb` 保持安静。
- 本机使用 Fastfetch 官方 2.70.0 用户级二进制 `~/.local/bin/fastfetch`（未收入 Git）。
  Arch 重装时由 `personal.sh` 安装 `fastfetch`。

恢复：先安装 Fastfetch，再运行 `bash personal/setup-fastfetch.sh`，然后将
`personal/home/.zshrc` 的 Fastfetch 段合并到自己的 `.zshrc`。
脚本按自身位置定位仓库，并创建相对符号链接，不写死 `/home/用户名`。
若已有真实配置/图片目录，脚本会停止，避免覆盖。仓库整体换位置后重新运行即可。

临时隐藏：`TERM=dumb zsh`；手动运行：`fastfetch`。
