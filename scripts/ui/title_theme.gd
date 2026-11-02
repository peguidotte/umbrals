class_name UmbralTitleTheme
extends RefCounted
## Menu-only identity. Battle, map and information colors keep their contracts.
const Kit = preload("res://scripts/ui/kit.gd")
const INK = Color("101c23")
const VIOLET = Color("dec88d")
const PAPER = Color("f3e6c5")

static func make_theme(base: Theme) -> Theme:
	var result: Theme = base.duplicate()
	var box = StyleBoxFlat.new()
	box.bg_color = Color(0.04, 0.075, 0.08, 0.96)
	box.border_color = Color("8d805a")
	box.set_border_width_all(1)
	box.set_corner_radius_all(2)
	box.set_content_margin_all(28)
	box.shadow_color = Color(0.01, 0, 0.03, 0.5)
	box.shadow_size = 18
	result.set_stylebox("panel", "PanelContainer", box)
	result.set_color("font_color", "Label", PAPER)
	result.set_color("font_color", "Button", PAPER)
	result.set_color("font_focus_color", "Button", PAPER)
	result.set_color("font_hover_color", "Button", PAPER)
	return result
