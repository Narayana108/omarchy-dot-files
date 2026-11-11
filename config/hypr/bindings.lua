-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")
hl.unbind("SUPER + SHIFT + E")
o.bind("SUPER + SHIFT + E", "Communication", "exec uwsm-app -- ferdium")

hl.unbind("SUPER + SHIFT + SLASH")
o.bind("SUPER + SHIFT + SLASH", "Passwords", "exec uwsm-app -- bitwarden-desktop")

o.bind("SUPER + SHIFT + Z", "Notes", "exec uwsm-app -- zettlr -disable-gpu --enable-wayland-ime")
o.rebind("SUPER + SHIFT + S", "Yazi", { tui = "yazi" })

-- middle mouse = num6
hl.bind("mouse:274", hl.dsp.exec_cmd("wtype -k KP_1"))

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
if o.dictation_installed and o.dictation_installed() then
	o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
	o.bind_hold(
		"F9",
		"Start dictation (push-to-talk)",
		"omarchy-dictation start",
		"Stop dictation (push-to-talk)",
		"omarchy-dictation stop"
	)
end
