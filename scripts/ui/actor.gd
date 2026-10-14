class_name UmbralActor
extends Button
const Assets = preload("res://scripts/assets/catalog.gd")
const Content = preload("res://scripts/content.gd")
const UI = preload("res://scripts/ui/kit.gd")
var portrait: TextureRect
var caption: Label
var passive_caption: Label
var identity: Dictionary = {}
var reduced_motion: bool = false
var still: bool = false
var idle_clock: float = 0.0
var accent: Color = UI.GOLD

func _ready() -> void:
	add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait)
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.offset_bottom = -48
	caption = UI.new().label("", 26, UI.PAPER, true, true)
	add_child(caption)
	caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_top = -46
	caption.offset_bottom = -14
	passive_caption = UI.new().label("", 16, UI.MUTED, false, true)
	add_child(passive_caption)
	passive_caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	passive_caption.offset_top = -13
	passive_caption.offset_bottom = 8
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	resized.connect(_pivot)
	_pivot()

func _pivot() -> void:
	if is_instance_valid(portrait): portrait.pivot_offset = Vector2(size.x * 0.5, (size.y - 48) * 0.5)
	queue_redraw()

func set_identity(data: Dictionary, scale_text: float = 1.0) -> void:
	identity = data
	if data.is_empty():
		portrait.texture = Assets.texture("umbrals/volt")
		portrait.modulate = Color(0.5, 0.62, 0.59, 0.3)
		caption.text = "Vínculo livre"
		passive_caption.text = "Capture outro Umbral"
		disabled = true
	else:
		var species: Dictionary = Content.SPECIES[data.species]
		portrait.texture = Assets.texture(species.art[int(data.stage) - 1])
		portrait.modulate = Color.WHITE
		accent = Color(species.color)
		caption.text = Content.display_name(data)
		caption.add_theme_color_override("font_color", accent)
		passive_caption.text = Content.PASSIVES[data.passive].name
		tooltip_text = "%s\n%s: %s\n%s: %s\nClique ou pressione C para inspecionar." % [caption.text, species.trait, Content.trait_text(data), Content.PASSIVES[data.passive].name, Content.PASSIVES[data.passive].description]
		disabled = false
	caption.add_theme_font_size_override("font_size", int(26 * scale_text))
	passive_caption.add_theme_font_size_override("font_size", int(16 * scale_text))
	queue_redraw()

func _process(delta: float) -> void:
	if still or reduced_motion or not is_instance_valid(portrait): return
	idle_clock += delta
	portrait.position.y = sin(idle_clock * 1.4 + float(identity.get("uid", 0))) * 3

func _draw() -> void:
	if not disabled and (has_focus() or is_hovered()):
		var center = Vector2(size.x * 0.5, (size.y - 48) * 0.5)
		draw_arc(center, minf(size.x, size.y - 48) * 0.46, 0, TAU, 48, accent, 2, true)
		draw_circle(center + Vector2(0, -(size.y - 48) * 0.46), 4, UI.PAPER)
