class_name UmbralUI
extends RefCounted
const RuneButton = preload("res://scripts/ui/rune_button.gd")
const Style = preload("res://scripts/ui/style.gd")
static var tokens: Style.Definition = Style.current
var text_scale: float = 1.0

func make_theme() -> Theme:
	var theme = Theme.new()
	theme.default_font = tokens.body
	theme.default_font_size = int(tokens.body_size * text_scale)
	theme.set_color("font_color", "Label", tokens.paper)
	theme.set_color("font_color", "Button", tokens.paper)
	theme.set_color("font_focus_color", "Button", tokens.paper)
	theme.set_font_size("font_size", "Button", int(tokens.body_size * text_scale))
	theme.set_stylebox("normal", "Button", style(tokens.surface, tokens.surface_border))
	theme.set_stylebox("hover", "Button", style(tokens.hover, tokens.gold))
	theme.set_stylebox("pressed", "Button", style(tokens.pressed, tokens.gold))
	theme.set_stylebox("disabled", "Button", style(tokens.disabled_surface, tokens.disabled_border))
	theme.set_stylebox("focus", "Button", focus_style())
	theme.set_color("font_disabled_color", "Button", tokens.disabled_text)
	theme.set_stylebox("panel", "PanelContainer", style(tokens.panel, tokens.panel_border, 24))
	return theme

func style(background: Color, border: Color, padding: int = 16) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(tokens.border_width)
	box.set_corner_radius_all(tokens.corner_radius)
	box.content_margin_left = padding + 8
	box.content_margin_right = padding + 8
	box.content_margin_top = padding
	box.content_margin_bottom = padding
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = tokens.shadow_size
	return box

func focus_style() -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = Color.TRANSPARENT
	box.border_color = tokens.paper
	box.set_border_width_all(tokens.focus_width)
	box.expand_margin_left = tokens.focus_margin
	box.expand_margin_right = tokens.focus_margin
	box.expand_margin_top = tokens.focus_margin
	box.expand_margin_bottom = tokens.focus_margin
	return box

func label(text: String, font_size: int = 24, color: Color = Color(-1, -1, -1), display: bool = false, centered: bool = false) -> Label:
	var result = Label.new()
	result.text = tr(text)
	result.add_theme_font_override("font", tokens.display if display else tokens.body)
	result.add_theme_font_size_override("font_size", int(font_size * text_scale))
	result.add_theme_color_override("font_color", tokens.paper if color.r < 0 else color)
	result.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	result.add_theme_constant_override("shadow_offset_x", 1)
	result.add_theme_constant_override("shadow_offset_y", 2)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

func paragraph(text: String, font_size: int = 22, color: Color = Color(-1, -1, -1)) -> Label:
	var result: Label = label(text, font_size, tokens.muted if color.r < 0 else color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result

func button(text: String, callback: Callable, key: String, primary: bool = false) -> Button:
	var result = RuneButton.new()
	result.text = tr(text)
	result.set_meta("ui_id", key)
	result.custom_minimum_size = Vector2(0, tokens.button_height)
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.pressed.connect(callback)
	if primary:
		result.accent = tokens.ink
		result.add_theme_stylebox_override("normal", style(tokens.gold, tokens.paper))
		result.add_theme_stylebox_override("hover", style(tokens.primary_hover, tokens.paper))
		result.add_theme_stylebox_override("pressed", style(tokens.primary_pressed, tokens.gold))
		result.add_theme_color_override("font_color", tokens.ink)
		result.add_theme_color_override("font_hover_color", tokens.ink)
		result.add_theme_color_override("font_pressed_color", tokens.ink)
		result.add_theme_color_override("font_focus_color", tokens.ink)
	return result

static func column(gap: int = 12) -> VBoxContainer:
	var result = VBoxContainer.new()
	result.add_theme_constant_override("separation", gap)
	return result

static func row(gap: int = 16) -> HBoxContainer:
	var result = HBoxContainer.new()
	result.add_theme_constant_override("separation", gap)
	return result

static func spacer() -> Control:
	var result = Control.new()
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result

static func art(path: String, minimum: Vector2) -> TextureRect:
	return image("res://assets/" + path + ".svg", minimum)

static func image(path: String, minimum: Vector2) -> TextureRect:
	var result = TextureRect.new()
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.texture = load(path)
	result.custom_minimum_size = minimum
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

static func focus_chain(controls: Array, horizontal: bool = false) -> void:
	if controls.is_empty(): return
	for i in range(controls.size()):
		var current: Control = controls[i]
		var previous: Control = controls[posmod(i - 1, controls.size())]
		var next: Control = controls[(i + 1) % controls.size()]
		current.focus_next = next.get_path()
		current.focus_previous = previous.get_path()
		if horizontal:
			current.focus_neighbor_left = previous.get_path()
			current.focus_neighbor_right = next.get_path()
		else:
			current.focus_neighbor_top = previous.get_path()
			current.focus_neighbor_bottom = next.get_path()
