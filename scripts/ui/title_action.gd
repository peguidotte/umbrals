extends Button
const Gold = preload("res://scripts/ui/gold_theme.gd")
var indicator_scale: float = 1.0
func _ready() -> void:
	flat = true
	add_theme_font_override("font", Gold.display_font())
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		add_theme_color_override(state, Color("fff0d0"))
	add_theme_color_override("font_disabled_color", Color("a8b5cb"))
	add_theme_color_override("font_outline_color", Color("081b39"))
	add_theme_color_override("font_shadow_color", Color(0.01,0.02,0.05,0.9))
	add_theme_constant_override("shadow_offset_y", 2)
	for changed: Signal in [focus_entered, focus_exited, mouse_entered, mouse_exited]:
		changed.connect(queue_redraw)
func _draw() -> void:
	if disabled or not (has_focus() or is_hovered()): return
	var inset: float = 18.0 * indicator_scale
	var bottom: float = size.y - 6.0 * indicator_scale
	draw_line(Vector2(inset,bottom),Vector2(size.x-inset,bottom),Gold.GOLD,2.5*indicator_scale,true)
	var center: Vector2 = Vector2(8*indicator_scale,size.y*0.5)
	var radius: float = 5.0*indicator_scale
	var points: PackedVector2Array = [center+Vector2(0,-radius),center+Vector2(radius,0),center+Vector2(0,radius),center+Vector2(-radius,0),center+Vector2(0,-radius)]
	draw_polyline(points,Gold.GOLD,2.0*indicator_scale,true)
