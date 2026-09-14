-- Hyprland 0.56+; select Hyprland (UWSM) in tuigreet.
-- UWSM starts DMS and Fcitx5 through graphical-session.target.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        touchpad = { natural_scroll = true },
    },
    general = {
        gaps_in = 6,
        gaps_out = 12,
        border_size = 2,
        layout = "dwindle",
    },
})

hl.bind("SUPER + Return", hl.dsp.exec_cmd("uwsm app -- kitty"))
hl.bind("SUPER + Space", hl.dsp.exec_cmd("dms ipc call spotlight toggle"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("dms ipc call lock lock"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("uwsm app -- nautilus"))
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("uwsm stop"))

for _, direction in ipairs({ "left", "right", "up", "down" }) do
    hl.bind("SUPER + " .. direction, hl.dsp.focus({ direction = direction }))
end
for workspace = 1, 5 do
    hl.bind("SUPER + " .. workspace, hl.dsp.focus({ workspace = workspace }))
    hl.bind("SUPER + SHIFT + " .. workspace, hl.dsp.window.move({ workspace = workspace }))
end

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))

local mediaKeys = {
    XF86AudioRaiseVolume = "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+",
    XF86AudioLowerVolume = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
    XF86AudioMute = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
    XF86MonBrightnessUp = "brightnessctl set +5%",
    XF86MonBrightnessDown = "brightnessctl set 5%-",
}
for key, command in pairs(mediaKeys) do
    hl.bind(key, hl.dsp.exec_cmd(command), { locked = true, repeating = true })
end
