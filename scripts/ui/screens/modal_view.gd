extends "res://scripts/ui/screens/screen_view.gd"
const Rules = preload("res://scripts/rules.gd")
const Models = preload("res://scripts/domain/models.gd")
const Content = preload("res://scripts/content.gd")
var game: Rules
var screen: String
var inspection: Dictionary
var replacement_index: int

func _modal_frame(title: String, subtitle: String = "", width: float = 850) -> VBoxContainer:
	name = "Overlay_" + screen
	z_index = 100
	var shade = ColorRect.new()
	_full(shade, self)
	shade.color = UI.tokens.modal_shade
	var center = CenterContainer.new()
	_full(center, self)
	center.offset_left = 32
	center.offset_top = 24
	center.offset_right = -32
	center.offset_bottom = -24
	var panel = PanelContainer.new()
	panel.custom_minimum_size.x = minf(width, size.x - 96)
	center.add_child(panel)
	var column: VBoxContainer = UI.column(18)
	panel.add_child(column)
	column.add_child(ui.label(title, 40, UI.tokens.paper, true, true))
	if not subtitle.is_empty(): column.add_child(ui.paragraph(subtitle, 22, UI.tokens.muted))
	return column

func build(screen_id: String, rules: Rules, inspected: Dictionary, replacement: int) -> void:
	screen = screen_id
	game = rules
	inspection = inspected
	replacement_index = replacement
	render_screen()

func render_screen() -> void:
	assert(false, "Modal must implement render_screen")
