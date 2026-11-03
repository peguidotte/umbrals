extends "res://scripts/ui/screens/modal_view.gd"

func render_screen() -> void:
	if screen == Ids.REPLACEMENT: _replacement()
	else: _rewards()

func _rewards() -> void:
	var body: VBoxContainer = _modal_frame("Um novo eco responde.", "Capture uma nova passiva ou desperte a evolução de um aliado. +8 de fôlego.", 1440)
	var row: HBoxContainer = UI.row(16)
	if game.reward_offers.size() > 3:
		var scroll = ScrollContainer.new()
		scroll.custom_minimum_size.y = 560
		scroll.follow_focus = true
		body.add_child(scroll)
		scroll.add_child(row)
	else:
		body.add_child(row)
	for i in range(game.reward_offers.size()):
		var offer: Models.RewardOffer = game.reward_offers[i]
		var evolved: bool = offer.kind == Ids.EVOLVE
		var original: Models.Individual = game.umbral_by_uid(int(offer.uid)) if evolved else offer.umbral
		var candidate: Models.Individual = original.clone()
		if evolved: candidate.form_id = offer.target_form_id
		var species: Content.Species = game.catalog.species[candidate.species_id]
		var panel = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if game.reward_offers.size() > 3: panel.custom_minimum_size.x = 360
		panel.add_theme_stylebox_override("panel", ui.style(UI.tokens.reward_surface, Color(species.color), 16))
		row.add_child(panel)
		var column: VBoxContainer = UI.column(10)
		panel.add_child(column)
		column.add_child(ui.label("EVOLUÇÃO" if evolved else "NOVA ALIANÇA", 18, Color(species.color), false, true))
		column.add_child(UI.image(game.catalog.portrait_path(candidate), Vector2(155, 132)))
		column.add_child(ui.label(game.catalog.display_name(candidate), 30, Color(species.color), true, true))
		column.add_child(ui.paragraph(species.trait_name + "\n" + game.catalog.trait_text(candidate), 21, UI.tokens.paper))
		column.add_child(ui.label("Instinto: " + game.catalog.passives[candidate.passive].name, 22, UI.tokens.gold))
		column.add_child(ui.paragraph(game.catalog.passives[candidate.passive].description, 19))
		column.add_child(ui.paragraph("✦ " + _new_power_names(original, candidate) if evolved else capture_description(candidate, game.catalog), 20, UI.tokens.gold if evolved else UI.tokens.muted))
		if evolved:
			var transition = game.catalog.form(original).transition(offer.transition_id)
			if transition.health_cost > 0: column.add_child(ui.paragraph("Custo: %d de fôlego" % transition.health_cost, 19, UI.tokens.fire))
		_button(column, "DESPERTAR" if evolved else "CAPTURAR", request.bind("take_reward", i), "reward.%d" % i, Ids.REWARD, true)
	body.add_child(ui.paragraph("A evolução preserva sua passiva. Uma captura traz outro indivíduo.", 19))

func _replacement() -> void:
	var offered: Models.Individual = game.reward_offers[replacement_index].umbral
	var body: VBoxContainer = _modal_frame("Quem abre espaço?", "O novo %s tem %s. Escolha um vínculo para substituir." % [game.catalog.display_name(offered), game.catalog.passives[offered.passive].name], 1230)
	var row: HBoxContainer = UI.row(20)
	body.add_child(row)
	for i in range(game.party.size()):
		var umbral: Models.Individual = game.party[i]
		var column: VBoxContainer = UI.column(12)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)
		column.add_child(UI.image(game.catalog.portrait_path(umbral), Vector2(180, 170)))
		column.add_child(ui.label(game.catalog.display_name(umbral), 30, Color(game.catalog.species[umbral.species_id].color), true, true))
		column.add_child(ui.label(game.catalog.passives[umbral.passive].name, 22, UI.tokens.muted, false, true))
		_button(column, "SUBSTITUIR", request.bind("accept_reward", [replacement_index, umbral.uid]), "replace.%d" % i, Ids.REPLACEMENT, true)
	_button(body, "MANTER MEU TIME", request.bind("pop"), "replacement.back", Ids.REPLACEMENT)

func _new_power_names(before: Models.Individual, after: Models.Individual) -> String:
	var names: Array[String] = []
	for power in game.catalog.form(after).powers:
		if game.catalog.form(before).power(power.power_id) == null: names.append(power.name.replace("\n", " "))
	return " · ".join(names) if not names.is_empty() else "Nova forma e novos atributos"

static func capture_description(individual: Models.Individual, definitions: Content.Catalog = null) -> String:
	if definitions == null: definitions = Content.DEFAULT
	var count: int = definitions.form(individual).powers.size()
	var words: Dictionary = {1: "um", 2: "dois", 3: "três"}
	return "Adiciona %s %s ao grimório." % [words.get(count, str(count)), "poder" if count == 1 else "poderes"]
