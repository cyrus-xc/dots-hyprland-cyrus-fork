# personal/ — 本机在 end-4 默认配置之上的自定义内容

这个目录是 cyrus 这台机器（Arch Linux + Hyprland，end-4/dots-hyprland 的 illogical-impulse 配置）上
所有与 end-4 默认值不同的配置文件和脚本的备份。对照基准是 upstream/main 的 `2f2a376f`（2026-10-11）。

目录按原始路径组织：`home/` 对应 `$HOME`。两类文件：

- **完整文件**：end-4 留给用户改的文件（`hypr/custom/*.lua`、`kitty.conf`、`config.json` 等）和本机新增的文件，直接复制。
- **`*.patch`**：对 end-4 自带文件的修改，存成相对 `~/.config` 的 unified diff，升级 end-4 后重新套用：
  ```bash
  patch -p1 -d ~/.config < personal/home/.config/<路径>.patch
  ```

仓库根目录的 `personal.sh` 是装机用的包列表，见文末。

## 不收在这里的东西

- 三项已经整理成分支的功能（都基于 upstream/main）：
  `feat/settings-displays-page`（设置里的 Displays 页）、`feat/wallpaper-auto-rotate`（壁纸自动切换）、
  `feat/tokyo-night-palette`（Tokyo Night 配色）。
- Claude Code 侧边栏集成：在 `claude-code-backend` 分支，已提 upstream PR #3744。`config.json` 里的 `ai.claudeCode` 段属于它。
- matugen 生成的文件（`hypr/hyprland/colors.lua`、`hypr/hyprlock/colors.conf`、`foot.ini`、`fuzzel_theme.ini`、`kdeglobals` 的颜色），
  `hypr/custom/scripts/__restore_video_wallpaper.sh`，以及各种 `*.before-*` 备份文件。
- `quickshell/ii/modules/common/widgets/shapes/`：上游是 git 子模块，本机是完整克隆，不算修改。
- `~/.config/zshrc.d/`、`starship.toml`、`fontconfig/fonts.conf`：与上游完全一致。
- 与桌面无关的 systemd 用户服务（deepseek-harness、pipeline-*、we-agent、xhs-*）。

## 清单

| 文件 | 类型 | 内容 | 来源 |
| --- | --- | --- | --- |
| `.zshrc` | 完整 | oh-my-zsh + starship + zoxide，`cat` 别名到 bat，HF 镜像；末尾是 pacman 包装函数（见下） | 用户自建；包装函数 2026-11-01 |
| `.config/clash-proxy.sh` | 完整 | 登录时清空代理环境变量 | 用户自建 |
| `.config/clash-commands.zsh` | 完整 | `clash on/off/status/ui…` 函数，控制 Clash Verge 用户服务 | 用户自建 |
| `.config/hypr/custom/env.lua` | 完整 | fcitx5 输入法环境变量；`__GLX_VENDOR_LIBRARY_NAME=nvidia`；`__NV_DISABLE_EXPLICIT_SYNC=1` 规避 NVIDIA 580 句柄泄漏（egl-wayland #196） | 输入法/显卡早于 10-30；显式同步 2026-10-30 |
| `.config/hypr/custom/execs.lua` | 完整 | 启动 fcitx5；导入环境后重启 Sunshine 用户服务；启动 Clash Verge | 用户配置 |
| `.config/hypr/custom/general.lua` | 完整 | 全局窗口透明：激活 0.95、非激活 0.88、全屏 1.0 | 2026-10-30 |
| `.config/hypr/custom/rules.lua` | 完整 | 重新打开所有窗口的模糊；媒体类和 kitty 窗口强制不透明 | 2026-10-30 |
| `.config/hypr/custom/keybinds.lua` | 完整 | Super+Space 打开搜索（代替单击 Super）；Super+Shift+H/L 把窗口移到左/右工作区；Ctrl+Super+Space 循环切换平铺布局 | 2026-11-01 |
| `.config/hypr/hypridle.conf` | 完整 | 30 分钟锁屏、60 分钟息屏，删掉自动休眠（这台机器是常开服务器）；带 `end4-idle-settings` 元数据行，由设置页脚本维护 | 2026-10-28 |
| `.config/hypr/monitors.lua`、`monitors.conf` | 完整 | nwg-displays 生成：HDMI-A-1 3840x2160@60 缩放 2.0 | 2026-10-30 |
| `.config/hypr/workspaces.conf` | 完整 | nwg-displays 生成，当前为空 | 2026-10-30 |
| `.config/hypr/hyprland/general.lua.patch` | 补丁 | 阴影 `render_power` 10 → 4 | 2026-10-31 |
| `.config/hypr/hyprland/variables.lua.patch` | 补丁 | 文件管理器/任务管理器回退命令里 fish → zsh | 用户配置 |
| `.config/illogical-impulse/config.json` | 完整 | 壳层全部设置。与默认不同的主要有：配色 `tokyo-night`、壁纸自动切换开启（30 分钟、按文件名顺序）、Google Sans Flex 字体、透明开关、托盘固定 fcitx、dock/启动器固定应用、夜灯 19:00–06:30、锁屏用 quickshell 而非 hyprlock、`apps.*` 里 fish → zsh | 持续累积 |
| `.config/kitty/kitty.conf` | 完整 | `background_opacity 0.85`、`background_blur 20`、`dynamic_background_opacity yes`；`shell zsh`；Ctrl+V 粘贴 | 透明 2026-10-30，其余早于此 |
| `.config/quickshell/ii/modules/common/Config.qml.patch` | 补丁 | `apps.changePassword` / `apps.update` 命令 fish → zsh（只含这两行） | 用户配置 |
| `.config/quickshell/ii/modules/settings/GeneralConfig.qml.patch` | 补丁 | General 页新增「锁屏与息屏」一节：自动锁屏/息屏开关和分钟数，读写 hypridle.conf | 2026-10-28 |
| `.config/quickshell/ii/scripts/settings/idle-settings.py` | 新文件 | 上面那一节的后端：只改 hypridle.conf 里的标准 lock/DPMS listener，原子写入，重启 hypridle | 2026-10-28 |
| `.config/quickshell/ii/modules/ii/bar/{Resource,Resources,ResourcesPopup,StyledPopup}.qml.patch`、`services/ResourceUsage.qml.patch` | 补丁 | 状态栏资源区：用每块 GPU 的占用取代 swap；弹窗显示每个 CPU 封装的负载/功耗/频率/温度和 GPU 显存/频率；弹窗不出屏幕 | 2026-10-29 |
| `.config/quickshell/ii/scripts/resources/end4-hardware-monitor.py`、`.service` | 新文件 | 上面数据的来源：系统级服务，读传感器写到 `/run/end4-hardware/status.json`。本机安装位置：`/usr/local/libexec/end4-hardware-monitor.py` 和 `/etc/systemd/system/end4-hardware-monitor.service`（内容与这两个文件相同） | 2026-10-29 |
| `.config/quickshell/ii/modules/ii/overview/{SearchBar,SearchWidget}.qml.patch`、`services/{AppSearch,LauncherSearch}.qml.patch` | 补丁 | 启动器加「全部应用」按钮，应用前缀下按名称列出全部应用；`$sudo …` 用 zsh 执行 | 用户配置 |
| `.config/quickshell/ii/services/TrayService.qml.patch` | 补丁 | 去掉 quickshell 残留的重复 Fcitx 托盘图标 | 早于 10-30 |
| `.config/quickshell/ii/services/ConflictKiller.qml.patch` | 补丁 | 不再直接 kill kded6，先检查托盘接口是否可用，必要时让 kded6 加载 statusnotifierwatcher 模块 | 早于 10-30 |
| `.config/quickshell/ii/modules/common/panels/lock/LockScreen.qml.patch` | 补丁 | 锁屏 IPC 增加 `isLocked()`，供看门狗查询 | 2026-10-30 |
| `.config/quickshell/ii/modules/ii/sidebarLeft/SidebarLeft.qml.patch` | 补丁 | 左侧栏打开时独占键盘焦点并自动聚焦输入框（新版 Hyprland 下 OnDemand 会丢焦点；代价是不能点外面关闭） | 2026-11-01 |
| `.config/quickshell/ii/translations/{en_US,zh_CN}.json.patch` | 补丁 | 上面这些界面用到的文案（锁屏/息屏、GPU 弹窗、全部应用） | 随各功能 |
| `.local/bin/qs-watchdog` | 新文件 | quickshell 独占内存 > 1 GB 或句柄 > 4096 时重启它；锁屏状态下重启后重新上锁；没在运行时拉起并上锁 | 2026-10-30 |
| `.config/systemd/user/qs-watchdog.{service,timer}` | 新文件 | 每 5 分钟运行一次看门狗（已 enable） | 2026-10-30 |
| `.local/bin/sunshine-wake` | 新文件 | Moonlight 连接时点亮显示器、确保 quickshell 在跑、把焦点交给锁屏 | 2026-10-30 |
| `.config/sunshine/sunshine.conf` | 完整（脱敏） | wlr 采集 + nvenc，`global_prep_cmd` 调用 sunshine-wake。`csrf_allowed_origins` 里的局域网 IP、Tailscale IP 和 tailnet 主机名已替换成占位符 | 2026-10-30 |
| `.config/systemd/user/clash-verge.service`、`clash-verge.service.d/*.conf` | 新文件 | Clash Verge Rev 作为用户服务运行；dashboard 路径；服务自身不继承代理变量 | 用户配置 |

## personal.sh 和 pacman 包装函数

`personal.sh`（仓库根目录）只有一条 `sudo pacman -S --needed …` 命令，列出本机显式安装、
但 end-4 安装脚本不会装、也不属于 archinstall 基础集的包，按用途分组排列；AUR 包以 `#AUR 名字` 行列在前面，
安装命令写在注释里。生成方法：`pacman -Qeq` 减去 `sdata/dist-arch/*/PKGBUILD` 的 depends/makedepends 和元包名，
减去 base、linux*、linux-firmware、amd-ucode、mkinitcpio、efibootmgr、sudo、nano、vim、less、iwd。

`.zshrc` 末尾的「personal.sh package tracker」段：

- `alias pacman='personal_pacman command pacman'`（函数名不带下划线前缀：Claude Code 的 shell 快照不会收录 `_` 开头的函数，否则在它的终端里 pacman 会报 command not found），以及一个 `sudo` 函数，把 `sudo [选项] pacman …` 也送进同一个包装。
- 包装在运行前后各取一次 `pacman -Qeq`，新增的显式安装包：在同步仓库里能查到的追加到 `personal.sh` 那条命令末尾，查不到的追加成 `#AUR 名字` 行。已列出的不重复加。
- pacman 的参数原样传递，退出码原样返回。`personal.sh` 不存在或不可写时什么都不做。
- 直接用 `yay` 安装的包不经过这个函数，不会被记录。
- 路径写死为 `/home/pcd/Development/dots-hyprland-cyrus-fork/personal.sh`，要求那个检出在 main 分支上。
