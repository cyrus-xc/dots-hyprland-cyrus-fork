-- Re-enable blur for every window (the default rules.lua disables it)
hl.window_rule({match = {class = ".*" }, no_blur = false })

-- Keep xwayland context menus unblurred, same as the default config
hl.window_rule({match = {class = "^()$", title = "^()$" }, no_blur = true })

-- Media should stay fully opaque
hl.window_rule({match = {class = "^(mpv|vlc|imv|org.gnome.Loupe|com.obsproject.Studio)$" }, opacity = "1.0 override 1.0 override" })

-- Kitty draws its own translucent background (background_opacity in kitty.conf),
-- so keep the window itself opaque to avoid dimming the text twice
hl.window_rule({match = {class = "^(kitty)$" }, opacity = "1.0 override 1.0 override" })
