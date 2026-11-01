hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

local qsIsAlive = "qs -c $qsConfig ipc call TEST_ALIVE"

-- Search: Super+Space instead of tapping Super
hl.unbind("SUPER + SUPER_L")
hl.unbind("SUPER + SUPER_R")
hl.bind("SUPER + Space", hl.dsp.global("quickshell:searchToggle"), { description = "Shell: Toggle search" })
hl.bind("SUPER + Space", hl.dsp.exec_cmd(qsIsAlive .. " || pkill fuzzel || fuzzel"))

-- Send window to workspace left/right: Super+Shift+H/L instead of Page_Up/Down
-- (Super+Shift+L was Sleep; sleep is still in the session menu, Ctrl+Alt+Delete)
hl.unbind("SUPER + SHIFT + Page_Up")
hl.unbind("SUPER + SHIFT + Page_Down")
hl.unbind("SUPER + SHIFT + L")
hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ workspace = "r-1" }), { description = "Window: Send to workspace left" })
hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({ workspace = "r+1" }), { description = "Window: Send to workspace right" })

-- Cycle tiling layout
local tiledLayouts = { "dwindle", "master", "scrolling", "monocle" }
hl.bind("CTRL + SUPER + Space", function()
    local current = hl.get_config("general:layout")
    local nextLayout = tiledLayouts[1]
    for i, name in ipairs(tiledLayouts) do
        if name == current then
            nextLayout = tiledLayouts[i % #tiledLayouts + 1]
        end
    end
    hl.config({ general = { layout = nextLayout } })
    hl.exec_cmd("notify-send 'Layout' '" .. nextLayout .. "' -a Hyprland -t 1500")
end, { description = "Window: Cycle tiling layout" })
