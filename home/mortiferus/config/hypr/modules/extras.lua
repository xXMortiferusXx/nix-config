hl.config({
	misc = {
		force_default_wallpaper = -1, -- Set to 0 or 1 to disable the anime mascot wallpapers
		disable_hyprland_logo = false, -- If true disables the random hyprland logo / anime girl background. :(
		focus_on_activate = true,
		vrr = 1,
		mouse_move_enables_dpms = true,
                key_press_enables_dpms = true,
		always_follow_on_dnd = true,
	},

	xwayland = {
		force_zero_scaling = true,
	},
        
	general = {
          allow_tearing = true,
        },
})
