#!/usr/bin/env bash
# personal.sh - packages installed on top of end-4/dots-hyprland on this machine.
#
# Reinstall backup. Left out on purpose: everything end-4's own installer
# (sdata/dist-arch metapackages, yay, base-devel) pulls in, and the packages
# archinstall puts on every system (base, linux, linux-lts, linux-firmware,
# amd-ucode, mkinitcpio, efibootmgr, sudo, nano, vim, less, iwd).
# Run end-4's install.sh first, then this file.
#
# The list is grouped, in this order:
#   1. hardware and drivers (DKMS + kernel headers for the NVIDIA module, zram, IPMI)
#   2. desktop pieces outside end-4 (sddm, polkit agent, XWayland, display and
#      notification tools, archiving, keyring GUI)
#   3. Chinese input method (fcitx5), fonts, OCR data
#   4. audio and bluetooth (pipewire stack, easyeffects)
#   5. printing (cups)
#   6. network, remote access and firewall
#   7. shell and command-line tools (zsh plugins, bat, btop, fzf, zoxide, gh)
#   8. development (node, python, build tools, android)
#   9. libraries that were installed explicitly
#  10. chatgpt-bin: from the "openai-chatgpt" repo (/etc/pacman.d/openai-chatgpt.conf)
#
# The pacman wrapper in ~/.zshrc (see personal/home/.zshrc) appends newly
# installed explicit packages here automatically: repo packages to the end of
# the pacman command, anything else as an "#AUR name" line below.
#
# AUR packages cannot be installed with pacman. After the command below, run:
#   yay -S --needed $(sed -n 's/^#AUR //p' personal.sh | tr '\n' ' ')
#AUR clash-verge-rev-bin
#AUR google-chrome
#AUR mihomo-bin
#AUR mpvpaper
#AUR nvidia-580xx-dkms
#AUR nvidia-580xx-utils
#AUR sunshine
#AUR ttf-google-sans-flex-end4
#AUR ttf-readex-pro-variable
#AUR wechat-bin

sudo pacman -S --needed \
    dkms \
    linux-headers \
    linux-lts-headers \
    egl-wayland \
    zram-generator \
    ipmitool \
    stress-ng \
    sddm \
    hyprpolkitagent \
    xorg-xwayland \
    nwg-displays \
    waybar \
    mako \
    seahorse \
    ark \
    7zip \
    unzip \
    fcitx5 \
    fcitx5-chinese-addons \
    fcitx5-configtool \
    fcitx5-gtk \
    fcitx5-qt \
    noto-fonts \
    noto-fonts-cjk \
    ttf-liberation \
    tesseract-data-chi_sim \
    pipewire \
    pipewire-alsa \
    pipewire-jack \
    gst-plugin-pipewire \
    libpulse \
    easyeffects \
    bluez \
    bluez-utils \
    cups \
    cups-pk-helper \
    system-config-printer \
    ghostscript \
    openssh \
    tailscale \
    ufw \
    tcpdump \
    traceroute \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    bat \
    btop \
    fzf \
    zoxide \
    github-cli \
    nodejs \
    npm \
    pnpm \
    python-pip \
    python-yaml \
    meson \
    extra-cmake-modules \
    scdoc \
    dart-sass \
    android-tools \
    android-udev \
    qt5-base \
    libavif \
    libxss \
    libvlc \
    webkit2gtk-4.1 \
    chatgpt-bin
