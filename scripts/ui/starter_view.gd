extends RefCounted
## Renders starter choices and reports the chosen species without starting a run.
const UI = preload("res://scripts/ui/kit.gd")
const Content = preload("res://scripts/content.gd")
const Rules = preload("res://scripts/rules.gd")
const BattleArt = preload("res://scripts/ui/battle_art.gd")
const TitleButton = preload("res://scripts/ui/title_button.gd")
signal control_created(control: Control, key: String)
signal starter_requested(species: String)
signal back_requested

func build(body: VBoxContainer, ui: RefCounted, reduced_motion: bool, title_mode: bool) -> void:
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 14)
	body.add_child(grid)
	var roles: Dictionary = {"ember": "Pressão e Queima", "moss": "Semeado e proteção", "volt": "Condução e Interferência", "dew": "Encharcado e cura"}
	for species_id in Content.STARTERS:
		var panel = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(panel)
		var row: HBoxContainer = UI.row(16)
		panel.add_child(row)
		var portrait: TextureRect = UI.art("umbrals/" + species_id, Vector2(96, 96))
		portrait.texture = BattleArt.texture(species_id)
		row.add_child(portrait)
		var column: VBoxContainer = UI.column(8)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)
		var individual: Dictionary = Rules.make_umbral(species_id, "", 1)
		column.add_child(ui.label(Content.nature_text(individual) + " · " + str(roles[species_id]), 19, UI.MUTED))
		var choice: Button = _button(column, Content.display_name(individual), true, ui, title_mode, reduced_motion)
		choice.pressed.connect(_choose.bind(species_id))
		choice.tooltip_text = Content.trait_text(individual) + "\nResistências: " + Content.resistance_text(individual)
		control_created.emit(choice, "starter." + species_id)
	var back: Button = _button(body, "VOLTAR", false, ui, title_mode, reduced_motion)
	back.pressed.connect(func(): back_requested.emit())
	control_created.emit(back, "starter.back")

func _button(parent: Node, text: String, primary: bool, ui: RefCounted, title_mode: bool, reduced_motion: bool) -> Button:
	var button: Button
	if title_mode:
		button = TitleButton.new()
		button.text = text
		button.primary = primary
		button.reduced_motion = reduced_motion
		button.custom_minimum_size.y = 56
	else:
		button = ui.button(text, func(): pass, "", primary)
	parent.add_child(button)
	return button

func _choose(species: String) -> void:
	starter_requested.emit(species)
