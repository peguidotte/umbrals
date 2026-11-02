class_name UmbralTitleButton
extends Button
## Fixed input rectangle; only the painted plate moves. Focus follows its chanfers.
const INK = Color("101c23")
const VIOLET = Color("dec88d")
const IVORY = Color("f3e6c5")
var plate_texture: Texture2D
var plate_size: Vector2 = Vector2.ZERO
var reduced_motion: bool = false
var highlight: float = 0.0
var primary: bool = false
var caption: Label

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var empty = StyleBoxEmpty.new()
		empty.content_margin_left = 24
		empty.content_margin_right = 24
		empty.content_margin_top = 16
		empty.content_margin_bottom = 16
		add_theme_stylebox_override(state, empty)
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		add_theme_color_override(state, Color.TRANSPARENT)
	add_theme_color_override("font_disabled_color", Color("8b917f"))
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	if plate_texture == null:
		# Godot draws the script's plate after Button's own caption. A child draws above it.
		caption = Label.new()
		caption.text = text
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption.add_theme_font_override("font", get_theme_font("font", "Button"))
		caption.add_theme_font_size_override("font_size", get_theme_font_size("font_size", "Button"))
		add_child(caption)
		caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		caption.offset_left = 24
		caption.offset_right = -24

func _process(delta: float) -> void:
	if is_instance_valid(caption):
		caption.text = text
		caption.add_theme_color_override("font_color", Color("8b917f") if disabled else IVORY)
	var target: float = 1.0 if (has_focus() or is_hovered()) and not disabled else 0.0
	var next: float = target if reduced_motion else move_toward(highlight, target, delta * 9.0)
	if not is_equal_approx(highlight, next):
		highlight = next
		queue_redraw()

static func outline(rect: Rect2, cut: float = 14.0) -> PackedVector2Array:
	var a: Vector2 = rect.position
	var b: Vector2 = rect.end
	var c: float = minf(cut, minf(rect.size.x, rect.size.y) * 0.24)
	return PackedVector2Array([a + Vector2(c, 0), Vector2(b.x - c, a.y), Vector2(b.x, a.y + c), b - Vector2(0, c), b - Vector2(c, 0), Vector2(a.x + c, b.y), Vector2(a.x, b.y - c), a + Vector2(0, c)])

func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0: return
	var extent: Vector2 = size if plate_size == Vector2.ZERO else plate_size
	var zoom: float = 1.0 if reduced_motion else 1.0 + highlight * 0.012
	if button_pressed and not reduced_motion: zoom = 0.985
	extent *= zoom
	var shift: Vector2 = Vector2(0, 2) if button_pressed and not reduced_motion else Vector2.ZERO
	var rect = Rect2((size - extent) * 0.5 + shift, extent)
	var points: PackedVector2Array = outline(rect, extent.y * 0.16)
	if plate_texture != null:
		var uvs = PackedVector2Array()
		for point in points: uvs.append((point - rect.position) / rect.size)
		var tint: float = 0.84 if disabled else 1.0 + highlight * 0.08
		if button_pressed: tint = 0.86
		draw_polygon(points, PackedColorArray([Color(tint, tint, tint)]), uvs, plate_texture)
	else:
		draw_colored_polygon(points, Color("343326") if primary else INK)
		var border: PackedVector2Array = points.duplicate()
		border.append(points[0])
		draw_polyline(border, VIOLET.darkened(0.45 if disabled else 0.2 - highlight * 0.2), 2.0, true)
	if has_focus() and not disabled:
		var border: PackedVector2Array = points.duplicate()
		border.append(points[0])
		draw_polyline(border, IVORY, 2.0, true)
		var center: Vector2 = Vector2(rect.end.x - 20, rect.get_center().y)
		draw_colored_polygon(PackedVector2Array([center + Vector2(0, -4), center + Vector2(4, 0), center + Vector2(0, 4), center + Vector2(-4, 0)]), IVORY)
