local wezterm = require("wezterm")
local config = {}

-- Use config builder if available (WezTerm 20220807-113146-c2fee766 and later)
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- Color scheme
config.color_scheme = "Catppuccin Frappe"

-- Window appearance
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_background_opacity = 0.95
config.macos_window_background_blur = 20
config.initial_cols = 208
config.initial_rows = 54

-- Catppuccin Frappé colors for titlebar matching
local frappe = {
	base = "#303446",
	mantle = "#292c3c",
	crust = "#232634",
	text = "#c6d0f5",
	subtext1 = "#b5bfe2",
	subtext0 = "#a5adce",
	overlay2 = "#949cbb",
	overlay1 = "#838ba7",
	overlay0 = "#737994",
	surface2 = "#626880",
	surface1 = "#51576d",
	surface0 = "#414559",
	lavender = "#babbf1",
	blue = "#8caaee",
	sapphire = "#85c1dc",
	sky = "#99d1db",
	teal = "#81c8be",
	green = "#a6d189",
	yellow = "#e5c890",
	peach = "#ef9f76",
	maroon = "#ea999c",
	red = "#e78284",
	mauve = "#ca9ee6",
	pink = "#f4b8e4",
	flamingo = "#eebebe",
	rosewater = "#f2d5cf",
}

-- Window frame colors (for titlebar)
config.window_frame = {
	-- font = wezterm.font({ family = "JetBrains Mono", weight = "Bold" }),
	font = wezterm.font({ family = "Monaco", weight = "Bold" }),
	font_size = 13.0,
	active_titlebar_bg = frappe.base,
	inactive_titlebar_bg = frappe.mantle,
}

-- Tab bar colors
config.colors = {
	tab_bar = {
		background = frappe.crust,
		active_tab = {
			bg_color = frappe.surface2,
			fg_color = frappe.text,
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},
		inactive_tab = {
			bg_color = frappe.surface0,
			fg_color = frappe.subtext1,
		},
		inactive_tab_hover = {
			bg_color = frappe.surface1,
			fg_color = frappe.text,
		},
		new_tab = {
			bg_color = frappe.base,
			fg_color = frappe.text,
		},
		new_tab_hover = {
			bg_color = frappe.mantle,
			fg_color = frappe.text,
		},
	},
}

-- Font configuration
config.font = wezterm.font("Monaco")
--config.font = wezterm.font("JetBrains Mono")
config.font_size = 13.0

-- Tab bar
config.enable_tab_bar = true
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = false

-- ============================================
-- CUSTOM TAB FORMATTING WITH SPACING
-- ============================================
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local title = tab.active_pane.title

	-- Add extra spacing around tab title
	if tab.is_active then
		return {
			{ Text = "   " .. title .. "   " }, -- 3 spaces on each side
		}
	end

	return {
		{ Text = "  " .. title .. "  " }, -- 2 spaces on each side
	}
end)

-- Window padding
config.window_padding = {
	left = 10,
	right = 10,
	top = 10,
	bottom = 10,
}

-- Misc settings
config.enable_scroll_bar = false
config.adjust_window_size_when_changing_font_size = false

config.window_close_confirmation = "NeverPrompt"

return config
