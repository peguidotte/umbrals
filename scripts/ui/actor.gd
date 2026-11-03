class_name UmbralActor
extends Button
signal action_released(action_id: String, origin: Vector2)
const Motion = preload("res://scripts/ui/creature_motion.gd")
var motion: Motion
var facing: String = "right"
var visual_key: String = ""
const Models = preload("res://scripts/domain/models.gd")
const Content = preload("res://scripts/content.gd")
const UI = preload("res://scripts/ui/kit.gd")
var catalog: Content.Catalog = Content.DEFAULT
var portrait: TextureRect
var caption: Label
var passive_caption: Label
var identity: Models.Individual
var reduced_motion: bool = false
var still: bool = false
var accent: Color = UI.tokens.gold

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
	caption = UI.new().label("", 26, UI.tokens.paper, true, true)
	add_child(caption)
	caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_top = -46
	caption.offset_bottom = -14
	passive_caption = UI.new().label("", 16, UI.tokens.muted, false, true)
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
	motion = Motion.new()
	add_child(motion)
	motion.released.connect(func(point: String): action_released.emit(motion.action, emission_point(point)))

func _pivot() -> void:
	if is_instance_valid(portrait): portrait.pivot_offset = Vector2(size.x * 0.5, (size.y - 48) * 0.5)
	queue_redraw()

func set_identity(data: Models.Individual, scale_text: float = 1.0, definitions: Content.Catalog = null) -> void:
	if definitions != null and catalog != definitions:
		catalog = definitions
		visual_key = ""
	identity = data
	if data == null:
		portrait.texture = load(catalog.species["volt"].forms[0].presentation.right.portrait_path)
		portrait.modulate = Color(0.5, 0.62, 0.59, 0.3)
		caption.text = "Vínculo livre"
		passive_caption.text = "Capture outro Umbral"
		disabled = true
	else:
		var species: Content.Species = catalog.species[data.species_id]
		var key: String = "%s/%s/%s" % [data.species_id, data.form_id, facing]
		if key != visual_key:
			visual_key = key
			motion.configure(portrait, catalog.form(data).presentation.direction(facing), data.uid)
		portrait.modulate = Color.WHITE
		accent = Color(species.color)
		caption.text = catalog.display_name(data)
		caption.add_theme_color_override("font_color", accent)
		passive_caption.text = catalog.passives[data.passive].name
		tooltip_text = "%s\n%s: %s\n%s: %s\nClique ou pressione C para inspecionar." % [caption.text, species.trait_name, catalog.trait_text(data), catalog.passives[data.passive].name, catalog.passives[data.passive].description]
		disabled = false
	caption.add_theme_font_size_override("font_size", int(26 * scale_text))
	passive_caption.add_theme_font_size_override("font_size", int(16 * scale_text))
	queue_redraw()

func _process(_delta: float) -> void:
	motion.still = still or identity == null
	motion.reduced_motion = reduced_motion

func set_facing(direction: String) -> void:
	assert(direction in ["left", "right"])
	facing = direction
	visual_key = ""
	if identity != null: set_identity(identity)

func play_action(action_id: String) -> bool:
	motion.reduced_motion = reduced_motion
	return motion.play(action_id)

func cancel_action() -> void:
	motion.reset()

func emission_point(point_id: String) -> Vector2:
	var point: Vector2 = motion.definition.anchors[point_id]
	if motion.definition.mirror: point.x = 1.0 - point.x
	var texture_size: Vector2 = portrait.texture.get_size()
	var drawn: Vector2 = texture_size * minf(portrait.size.x / texture_size.x, portrait.size.y / texture_size.y)
	return portrait.get_global_transform() * ((portrait.size - drawn) * 0.5 + drawn * point)

func _draw() -> void:
	if not disabled and (has_focus() or is_hovered()):
		var center = Vector2(size.x * 0.5, (size.y - 48) * 0.5)
		draw_arc(center, minf(size.x, size.y - 48) * 0.46, 0, TAU, 48, accent, 2, true)
		draw_circle(center + Vector2(0, -(size.y - 48) * 0.46), 4, UI.tokens.paper)
