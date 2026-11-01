hl.on("hyprland.start", function ()
    hl.exec_cmd("fcitx5 -d --replace")
end)

-- Sunshine requires the active desktop environment for capture and audio.
hl.on("hyprland.start", function ()
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP && systemctl --user restart app-dev.lizardbyte.app.Sunshine.service")
end)

-- Launch Clash Verge after the compositor has initialized.
hl.on("hyprland.start", function ()
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP && systemctl --user start clash-verge.service")
end)
