extends Control
## Standalone authoring preview. Does not create or mutate a game session.
const Content = preload("res://scripts/content.gd")
const Models = preload("res://scripts/domain/models.gd")
const UI = preload("res://scripts/ui/kit.gd")
const Actor = preload("res://scripts/ui/actor.gd")
const Clip = preload("res://scripts/catalog/clip_definition.gd")
const Markers = preload("res://scripts/ui/emission_markers.gd")
var species_picker: OptionButton
var form_picker: OptionButton
var direction_picker: OptionButton
var action_picker: OptionButton
var actor: Actor
var details: TextEdit
var ui: UI = UI.new()

func _ready() -> void:
	theme = ui.make_theme()
	var background = ColorRect.new()
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = UI.tokens.ink
	var margin = MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 28)
	var column: VBoxContainer = UI.column(18)
	margin.add_child(column)
	column.add_child(ui.label("GALERIA DE UMBRALS", 32, UI.tokens.gold, true))
	column.add_child(ui.paragraph("Inspecione cada forma, direção, animação e ponto de emissão. Poses procedurais e quadros autorais são identificados nos dados.", 20))
	var selectors: HBoxContainer = UI.row(14)
	column.add_child(selectors)
	species_picker = _picker(selectors, "Espécie")
	for id in Content.SPECIES: species_picker.add_item(id)
	form_picker = _picker(selectors, "Forma")
	direction_picker = _picker(selectors, "Direção")
	for id in ["right", "left"]: direction_picker.add_item(id)
	action_picker = _picker(selectors, "Animação")
	for id in Clip.ACTIONS: action_picker.add_item(id)
	var play: Button = ui.button("REPRODUZIR", play_selected, "gallery.play", true)
	selectors.add_child(play)
	var row: HBoxContainer = UI.row(24)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(row)
	var preview = CenterContainer.new()
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(preview)
	actor = Actor.new()
	actor.custom_minimum_size = Vector2(400, 440)
	preview.add_child(actor)
	actor.focus_mode = Control.FOCUS_NONE
	var markers = Markers.new()
	markers.actor = actor
	add_child(markers)
	markers.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	details = TextEdit.new()
	details.editable = false
	details.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	details.add_theme_color_override("font_readonly_color", UI.tokens.paper)
	details.custom_minimum_size.x = 480
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)
	species_picker.item_selected.connect(func(_index: int): _species_changed())
	form_picker.item_selected.connect(func(_index: int): _refresh())
	direction_picker.item_selected.connect(func(_index: int): _refresh())
	action_picker.item_selected.connect(func(_index: int): play_selected())
	_species_changed()
	UI.focus_chain([species_picker, form_picker, direction_picker, action_picker, play, details])
	species_picker.grab_focus()
	if "--gallery-capture" in OS.get_cmdline_user_args(): _capture()

func _picker(parent: Node, caption: String) -> OptionButton:
	parent.add_child(ui.label(caption, 18))
	var result = OptionButton.new()
	result.custom_minimum_size = Vector2(170, 52)
	parent.add_child(result)
	return result

func _species_changed() -> void:
	form_picker.clear()
	var species = Content.SPECIES[species_picker.get_item_text(species_picker.selected)]
	for shape in species.forms: form_picker.add_item(shape.form_id)
	_refresh()

func select_form(species_id: String, form_id: String) -> void:
	for index in range(species_picker.item_count):
		if species_picker.get_item_text(index) == species_id: species_picker.select(index)
	_species_changed()
	for index in range(form_picker.item_count):
		if form_picker.get_item_text(index) == form_id: form_picker.select(index)
	_refresh()

func _refresh() -> void:
	var species_id: String = species_picker.get_item_text(species_picker.selected)
	var shape_id: String = form_picker.get_item_text(form_picker.selected)
	var species = Content.SPECIES[species_id]
	var individual = Models.Individual.new(species_id, species.passive_pool[0], 1, shape_id)
	actor.set_identity(individual)
	actor.set_facing(direction_picker.get_item_text(direction_picker.selected))
	play_selected()

func play_selected() -> void:
	if actor.identity == null: return
	var action: String = action_picker.get_item_text(action_picker.selected)
	actor.play_action(action)
	var shape = Content.form(actor.identity)
	var clip = actor.motion.definition.clip(action)
	details.text = "Espécie: %s\nForma: %s\nNome: %s\nDireção: %s\nEspelhamento declarado: %s\nAção: %s\nModo: %s\nDuração: %.2f s\nEmissão: %s\n\n%s\n\n%s" % [actor.identity.species_id, shape.form_id, shape.display_name, actor.facing, actor.motion.definition.mirror, action, clip.mode, clip.duration, ("%s em %.2f s" % [clip.release_point, clip.release_time]) if not clip.release_point.is_empty() else "nenhuma", shape.resource_path, shape.presentation.authoring_notes]

func _capture() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var path: String = args[args.find("--gallery-capture") + 1]
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
