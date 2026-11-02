class_name UmbralGoldTheme
extends RefCounted
const Kit = preload("res://scripts/ui/kit.gd")
const Assets = preload("res://scripts/assets/catalog.gd")
const DISPLAY = preload("res://assets/fonts/cormorant/versions/1.0.0/display.ttf")
const Frame = preload("res://scripts/ui/gold_frame.gd")
static var _display: FontVariation

static func display_font() -> Font:
	if _display == null:
		_display = FontVariation.new()
		_display.base_font = DISPLAY
		_display.variation_embolden = 0.8
		_display.variation_opentype = {"wght": 650}
	return _display

const PAPER = Color("f3e6c5")
const GOLD = Color("dec88d")
const MUTED = Color("bac6b6")
const INK = Color("101c23")

static func box(selected: bool = false, padding: int = 18) -> StyleBoxFlat:
	var result = StyleBoxFlat.new()
	result.bg_color = Color(0.04, 0.075, 0.08, 0.94 if selected else 0.86)
	result.border_color = GOLD if selected else Color("685f45")
	result.set_border_width_all(2 if selected else 1)
	result.set_corner_radius_all(2)
	result.set_content_margin_all(padding)
	if selected:
		result.shadow_color = Color(0.87, 0.69, 0.32, 0.18)
		result.shadow_size = 8
	return result

static func label(text: String, size: int = 22, color: Color = PAPER, display: bool = false) -> Label:
	var l: Label = Kit.new().label(text, size, color, display)
	if display: l.add_theme_font_override("font", display_font())
	return l

static func paragraph(text: String, size: int = 20, color: Color = MUTED) -> Label:
	return Kit.new().paragraph(text, size, color)

static func button(text: String, selected: bool = false) -> Button:
	var b = Button.new()
	b.text = text
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size.y = 56
	b.add_theme_font_override("font", display_font())
	b.add_theme_font_size_override("font_size", 22)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, box(selected if state == "normal" else state not in ["normal", "disabled"], 12))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, PAPER)
	b.add_theme_color_override("font_disabled_color", MUTED)
	var ornament = Frame.new()
	ornament.corner = 24
	ornament.inset = 0
	b.add_child(ornament)
	ornament.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ornament.visible = selected
	var refresh: Callable = func(): ornament.visible = selected or b.has_focus() or b.is_hovered()
	b.focus_entered.connect(refresh)
	b.focus_exited.connect(refresh)
	b.mouse_entered.connect(refresh)
	b.mouse_exited.connect(refresh)
	return b

static func background(parent: Control) -> void:
	var art = TextureRect.new()
	art.texture = Assets.texture("world/gold-forest")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func line() -> HSeparator:
	var l = HSeparator.new()
	var style = StyleBoxLine.new()
	style.color = Color("8d805a")
	style.thickness = 1
	l.add_theme_stylebox_override("separator", style)
	return l
