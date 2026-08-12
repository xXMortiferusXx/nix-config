hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },

	move = "20 monitor_h-120",
	float = true,
})


-- Make file picker windows floating
hl.window_rule({
	name = "floating-file-picker",
	match = { class = "xdg-desktop-portal-gtk" },
	float = true,
	center = true,
	border_size = 0,
})

hl.window_rule({
	name = "floating-file-picker",
	match = { class = "xdg-desktop-portal-hyprland" },
	float = true,
	center = true,
	border_size = 0,
})

-- Layerrule for blur
hl.layer_rule({
	name = "noctalia-shell-blur",
	match = { namespace = "noctalia-bar-content-eDP-1" },
	blur = true,
	ignore_alpha = 0.5,
})

-- Communication workspace
hl.window_rule({
	name = "comms-workspace",
	match = { class = "^(discord|equibop|org.telegram.desktop|whatsapp|Element)$" },
	workspace = 2,
})

hl.window_rule({
	name = "game-launchers-workspace-1",
	match = { title = "Heroic Games Launcher" },
	workspace = 3,
})

-- Game Launchers
hl.window_rule({
	name = "games-launchers-workspace",
	match = { class = "^(steam|net.lutris.Lutris|com.heroicgameslauncher.hgl|heroic|page.kramo.Cartridges|Sidekick)$" },
	workspace = 3,
	center = true,
})

-- Steam menus
hl.window_rule({
	name = "steam-silent",
	match = { class = "^(steam)$", title = "^$" },
	float = true,
})

-- Steam games
hl.window_rule({
    name = "steam-games-optimized",
    match = { class = "^(steam_app_.*)$" },
    immediate = true,
    workspace = 4,
    center = true,
    float = false,
})

-- Steam Spiel-Launch Popup zentrieren
hl.window_rule({
    match = { 
        class = "steam",
        title = "^Steam$",
    },
    float = false,
    center = true,
})

-- Steam notifications
hl.window_rule({
	name = "steam-notifications",
	match = { title = "^(Steam - Benachrichtigung|Friends List|Steam - Notification)$", class = "^(steam)$" },
	float = true,
	pin = true,
	no_focus = true,
	no_initial_focus = true,
	move = "100%-450 100%-150",
	size = "400 100",
})

-- 3D Software
hl.window_rule({
    name = "3d-printing",
    match = { class = "^(OrcaSlicer|prusa-slicer|ideamaker.real)$" },
    workspace = "5",
})

-- Browser workspace
hl.window_rule({
	name = "browser-workspace",
	match = { class = "^(zen-beta|zen|zen-bin|firefox)$" },
	workspace = 1,
})

-- Pavucontrol & Blueman
hl.window_rule({
	name = "pavucontrol-float",
	match = { class = "^(org.pulseaudio.pavucontrol)$" },
	float = true,
	center = true,
        size = { "(monitor_w*0.45)", "(monitor_h*0.45)" },
})

hl.window_rule({
	name = "blueman-float",
	match = { class = "^(blueman-manager)$" },
	float = true,
	center = true,
})

-- Make screenshot windows floating
hl.window_rule({
	name = "satty-overlay",
	match = { class = "^(com.gabm.satty)$" },
	float = true,
	center = true,
})

hl.window_rule({
    name = "exiled-exchange",
    match = { class = "^(exiled-exchange-2)$" },
    no_blur = true,
    no_initial_focus = true,
})

-- Picture-in-Picture
hl.window_rule({
	match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
        keep_aspect_ratio = true,
        move = {"(monitor_w*0.73)", "(monitor_h*0.72)"},
        size = {"(monitor_w*0.25)", "(monitor_h*0.25)"},
	float = true,
	pin = true,
        
})
