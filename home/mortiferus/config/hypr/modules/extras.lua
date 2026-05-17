hl.config({
	misc = {
		force_default_wallpaper = -1, -- Set to 0 or 1 to disable the anime mascot wallpapers
		disable_hyprland_logo = false, -- If true disables the random hyprland logo / anime girl background. :(
		focus_on_activate = false,
	        mouse_move_enables_dpms = true,
		key_press_enables_dpms = true,
		vrr = 2,
	},

	xwayland = {
		force_zero_scaling = true,
	},
        
	general = {
          allow_tearing = true,
        },
        
        cursor = {
          sync_gsettings_theme = true,
          no_hardware_cursors = 2,
          enable_hyprcursor = true,
          warp_on_change_workspace = 2,
          no_warps = true,
        },
})
