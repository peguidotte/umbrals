extends RefCounted
## Builds the shared overlay shell; screens populate the returned column.
const UI = preload("res://scripts/ui/kit.gd")
const TitleTheme = preload("res://scripts/ui/title_theme.gd")

static func create(screen: String, menu: bool, ui: RefCounted, viewport_size: Vector2, title: String, subtitle: String = "", width: float = 850) -> Dictionary:
	var overlay = Control.new()
	overlay.name = "Overlay_" + screen
	overlay.z_index = 100
	var shade = ColorRect.new()
	overlay.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.012, 0.026, 0.035, 0.92)
	var center = CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 32
	center.offset_top = 24
	center.offset_right = -32
	center.offset_bottom = -24
	var panel = PanelContainer.new()
	if menu: panel.theme = TitleTheme.make_theme(ui.make_theme())
	panel.custom_minimum_size.x = minf(width, viewport_size.x - 96)
	center.add_child(panel)
	var column: VBoxContainer = UI.column(18)
	panel.add_child(column)
	column.add_child(ui.label(title, 40, UI.PAPER, not menu, true))
	if not subtitle.is_empty(): column.add_child(ui.paragraph(subtitle, 22, UI.MUTED))
	return {"overlay": overlay, "body": column}

static func fade_in(control: Control) -> Tween:
	control.modulate.a = 0.0
	var tween: Tween = control.create_tween()
	tween.tween_property(control, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return tween
