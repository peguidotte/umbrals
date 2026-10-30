class_name UmbralUI
extends RefCounted
const RuneButton = preload("res://scripts/ui/rune_button.gd")
const BattleArt = preload("res://scripts/ui/battle_art.gd")
const Assets = preload("res://scripts/assets/catalog.gd")
const Paths = preload("res://scripts/assets/binding_paths.gd")
const BODY = preload(Paths.FONTS_BODY)
const DISPLAY = preload(Paths.FONTS_DISPLAY)
const INK = Color("101c23")
const PAPER = Color("f3e6c5")
const GOLD = Color("dec88d")
const MUTED = Color("bac6b6")
const FIRE = Color("ef987b")
const LEAF = Color("91c8a1")
var text_scale: float = 1.0

func make_theme() -> Theme:
	var theme = Theme.new()
	theme.default_font = BODY
	theme.default_font_size = int(22 * text_scale)
	theme.set_color("font_color", "Label", PAPER)
	theme.set_color("font_color", "Button", PAPER)
	theme.set_color("font_focus_color", "Button", PAPER)
	theme.set_font_size("font_size", "Button", int(22 * text_scale))
	theme.set_stylebox("normal", "Button", style(Color(0.055, 0.10, 0.11, 0.90), Color("57604d")))
	theme.set_stylebox("hover", "Button", style(Color("263c35"), GOLD))
	theme.set_stylebox("pressed", "Button", style(Color("344437"), GOLD))
	theme.set_stylebox("disabled", "Button", style(Color("162021"), Color("3d4b45")))
	theme.set_stylebox("focus", "Button", focus_style())
	theme.set_color("font_disabled_color", "Button", Color("8c9a8d"))
	theme.set_stylebox("panel", "PanelContainer", style(Color(0.045, 0.08, 0.10, 0.98), Color("9e936c"), 24))
	theme.set_stylebox("panel", "PopupMenu", style(INK, GOLD, 8))
	theme.set_stylebox("hover", "PopupMenu", style(GOLD, PAPER, 5))
	theme.set_font_size("font_size", "PopupMenu", int(18 * text_scale))
	theme.set_color("font_color", "PopupMenu", PAPER)
	theme.set_color("font_hover_color", "PopupMenu", INK)
	theme.set_color("font_disabled_color", "PopupMenu", MUTED)
	return theme

func style(background: Color, border: Color, padding: int = 16) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(2)
	box.content_margin_left = padding + 8
	box.content_margin_right = padding + 8
	box.content_margin_top = padding
	box.content_margin_bottom = padding
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 5
	return box

func focus_style() -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = Color.TRANSPARENT
	box.border_color = PAPER
	box.set_border_width_all(2)
	box.expand_margin_left = 3
	box.expand_margin_right = 3
	box.expand_margin_top = 3
	box.expand_margin_bottom = 3
	return box

func label(text: String, font_size: int = 24, color: Color = PAPER, display: bool = false, centered: bool = false) -> Label:
	var result = Label.new()
	result.text = tr(text)
	result.add_theme_font_override("font", DISPLAY if display else BODY)
	result.add_theme_font_size_override("font_size", int(font_size * text_scale))
	result.add_theme_color_override("font_color", color)
	result.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	result.add_theme_constant_override("shadow_offset_x", 1)
	result.add_theme_constant_override("shadow_offset_y", 2)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

func paragraph(text: String, font_size: int = 22, color: Color = MUTED) -> Label:
	var result: Label = label(text, font_size, color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result

func button(text: String, callback: Callable, key: String, primary: bool = false) -> Button:
	var result = RuneButton.new()
	result.text = tr(text)
	result.set_meta("ui_id", key)
	result.custom_minimum_size = Vector2(0, 56)
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.pressed.connect(callback)
	if primary:
		result.accent = INK
		result.add_theme_stylebox_override("normal", style(GOLD, PAPER))
		result.add_theme_stylebox_override("hover", style(Color("eee0ae"), PAPER))
		result.add_theme_stylebox_override("pressed", style(Color("b8a778"), GOLD))
		result.add_theme_color_override("font_color", INK)
		result.add_theme_color_override("font_hover_color", INK)
		result.add_theme_color_override("font_pressed_color", INK)
		result.add_theme_color_override("font_focus_color", INK)
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

static func art(asset_id: String, minimum: Vector2) -> TextureRect:
	var result = TextureRect.new()
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.texture = Assets.texture(asset_id) if asset_id.begins_with("attacks/") or asset_id.begins_with("ui/") else BattleArt.texture(asset_id)
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if result.texture is AtlasTexture else CanvasItem.TEXTURE_FILTER_LINEAR
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
