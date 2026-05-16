hl.config({
	input = {
		kb_layout = "de,de",
		kb_variant = "",
		kb_model = "",
		kb_options = "grp:alt_space_toggle",
		kb_rules = "",

		numlock_by_default = true,

		repeat_rate = 35,
		repeat_delay = 200,

		follow_mouse = 1,

		sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

		touchpad = {
			natural_scroll = true,
		},
	},
})

hl.gesture({
	fingers = 3,
	direction = "vertical",
	action = "workspace",
})


hl.device({
	name = "all:mouse",
	tap_to_click = true,
})
