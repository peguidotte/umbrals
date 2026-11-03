extends "res://scripts/ui/screens/modal_view.gd"
const PowerCopy = preload("res://scripts/ui/power_copy.gd")

func render_screen() -> void:
	if screen == Ids.INSPECT: _inspection()
	else: _codex()

func _codex() -> void:
	var body: VBoxContainer = _modal_frame("Grimório dos Umbrals", "Conheça os traits antes de escolher seu vínculo.", 1300)
	var row: Container
	var scroll: ScrollContainer
	if game.catalog.species.size() > 3:
		scroll = ScrollContainer.new()
		scroll.custom_minimum_size.y = 440
		scroll.focus_mode = Control.FOCUS_ALL
		body.add_child(scroll)
		var grid = GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 26)
		grid.add_theme_constant_override("v_separation", 26)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(grid)
		row = grid
	else:
		row = UI.row(26)
		body.add_child(row)
	for species_id in game.catalog.species:
		var column: VBoxContainer = UI.column(10)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.custom_minimum_size.x = 260
		row.add_child(column)
		var individual: Models.Individual = game.catalog.make_individual(species_id, "fierce", 0)
		var species: Content.Species = game.catalog.species[species_id]
		column.add_child(UI.image(game.catalog.portrait_path(individual), Vector2(180, 160)))
		var lineage: Label = ui.label(Content.evolution_names(species), 27, Color(species.color), true, true)
		lineage.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(lineage)
		column.add_child(ui.label(species.trait_name, 24, UI.tokens.gold, false, true))
		column.add_child(ui.paragraph(game.catalog.trait_text(individual), 22))
		column.add_child(ui.paragraph("Evoluções: " + _next_forms(individual), 20))
	_button(body, "VOLTAR", request.bind("pop"), "codex.back", Ids.CODEX, true)
	if scroll != null:
		navigation.register(scroll, "codex.list", Ids.CODEX)
		scroll.gui_input.connect(func(event: InputEvent):
			if event.is_action_pressed("ui_down"): scroll.scroll_vertical += 80
			if event.is_action_pressed("ui_up"): scroll.scroll_vertical -= 80)

func _inspection() -> void:
	var umbral: Models.Individual = inspection.umbral
	var species: Content.Species = game.catalog.species[umbral.species_id]
	var title: String = game.catalog.power_stats(inspection.card.power, umbral).name.replace("\n", " ") if inspection.has("card") else game.catalog.display_name(umbral)
	var body: VBoxContainer = _modal_frame(title, "Vínculo de " + game.catalog.display_name(umbral) + " · " + species.element, 1000)
	var row: HBoxContainer = UI.row(28)
	body.add_child(row)
	row.add_child(UI.image(game.catalog.power_stats(inspection.card.power, umbral).art_path if inspection.has("card") else game.catalog.portrait_path(umbral), Vector2(210, 200)))
	var details: VBoxContainer = UI.column(15)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)
	details.add_child(ui.label("TRAIT  " + species.trait_name, 26, UI.tokens.gold))
	details.add_child(ui.paragraph(game.catalog.trait_text(umbral), 24, UI.tokens.paper))
	details.add_child(ui.label("PASSIVA  " + game.catalog.passives[umbral.passive].name, 25, Color(species.color)))
	details.add_child(ui.paragraph(game.catalog.passives[umbral.passive].description, 24))
	if inspection.has("card"):
		var power: Content.Power = game.catalog.power_stats(inspection.card.power, umbral)
		body.add_child(ui.paragraph(power.identity.description, 22, UI.tokens.paper))
		var special: Array[String] = PowerCopy.special_effects(power)
		if not special.is_empty(): body.add_child(ui.paragraph(" · ".join(special), 20))
		var score: Models.CastEvaluation = Rules.evaluate([inspection.card], [umbral], 0, game.catalog)
		body.add_child(ui.paragraph("Custo base %d · dano %d · escudo %d · cura %d\nO resultado final também considera queimadura acumulada e os aliados ativos. Ágil desconta 1 do total do indivíduo, uma vez por rodada." % [game.catalog.power_stats(inspection.card.power, umbral).cost, score.damage, score.block, score.heal], 22))
	else:
		var names: Array[String] = []
		for power in game.catalog.form(umbral).powers: names.append(power.name.replace("\n", " "))
		body.add_child(ui.paragraph("PODERES\n" + " · ".join(names), 22))
	_button(body, "VOLTAR", request.bind("pop"), "inspect.back", Ids.INSPECT, true)

func _next_forms(individual: Models.Individual) -> String:
	var names: Array[String] = []
	for transition in game.catalog.form(individual).evolutions:
		names.append(game.catalog.species[individual.species_id].form(transition.target_form_id).display_name)
	return " · ".join(names) if not names.is_empty() else "Forma final"
