hl.env("XMODIFIERS", "@im=fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULES", "wayland;fcitx")
hl.env("SDL_IM_MODULE", "fcitx")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
-- NVIDIA 580 EGL leaks one sync_file fd per surface with explicit sync
-- https://github.com/NVIDIA/egl-wayland/issues/196
hl.env("__NV_DISABLE_EXPLICIT_SYNC", "1")
