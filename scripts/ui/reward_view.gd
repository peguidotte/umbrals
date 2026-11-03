extends RefCounted
## Reward presentation emits choices; the session owns all mutations.
const Content = preload("res://scripts/content.gd")
const UI = preload("res://scripts/ui/kit.gd")
const Rules = preload("res://scripts/rules.gd")
const Targeting = preload("res://scripts/battle/targeting.gd")
signal reward_requested(index: int)
signal formation_requested
signal history_requested
signal replacement_requested(index: int, uid: int)
signal slot_requested(slot: int)
signal confirm_requested(index: int, uid: int, slot: int)
signal back_requested
var ui = UI.new()
var register: Callable

func _button(parent: Node, text: String, action: Callable, key: String, screen: String, primary: bool = false) -> Button:
	var button: Button = ui.button(text, action, key, primary)
	parent.add_child(button)
	register.call(button, key, screen)
	return button

func rewards(body: VBoxContainer, offers: Array, individuals: Dictionary, viewport_size: Vector2, registry: Callable) -> void:
	register = registry
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = minf(500, viewport_size.y - 340)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	body.add_child(scroll)
	var row: HBoxContainer = UI.row(16)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(row)
	for i in range(offers.size()):
		var offer: Dictionary = offers[i]
		var evolved: bool = offer.kind == "evolve"
		var original: Dictionary = individuals.get(int(offer.uid), {}) if evolved else offer.umbral
		var candidate: Dictionary = original.duplicate(true)
		if evolved: candidate.form_id = str(offer.target_form_id)
		var species: Dictionary = Content.SPECIES[candidate.species]
		var panel = PanelContainer.new()
		panel.custom_minimum_size.x = 360
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", ui.style(Color("15292c"), Color(species.color), 16))
		row.add_child(panel)
		var column: VBoxContainer = UI.column(8)
		panel.add_child(column)
		column.add_child(ui.label("EVOLUÇÃO" if evolved else "NOVA ALIANÇA", 18, Color(species.color), false, true))
		column.add_child(UI.art(Content.art_binding(candidate), Vector2(120, 96)))
		column.add_child(ui.label(Content.display_name(candidate), 28, Color(species.color), true, true))
		column.add_child(ui.paragraph(str(Content.form_definition(candidate.species, Content.form_id(candidate)).trait) + "\n" + Content.trait_text(candidate), 19, UI.PAPER))
		column.add_child(ui.label("Instinto: " + Content.PASSIVES[candidate.passive].name, 22, UI.GOLD))
		column.add_child(ui.paragraph(Content.PASSIVES[candidate.passive].description, 18))
		column.add_child(ui.paragraph("Melhora atributos e poderes conhecidos; preserva as cópias." if evolved else "Escolha uma vaga livre ou a reserva; seis cartas próprias.", 18, UI.GOLD if evolved else UI.MUTED))
		_button(column, "DESPERTAR" if evolved else "CAPTURAR", reward_requested.emit.bind(i), "reward.%d" % i, "reward", true)
	body.add_child(ui.paragraph("Capturar no campo entre encontros não custa ações. Manter na reserva preserva um time menor; trazê-la durante a batalha custa 1 ação.", 19))
	var controls: HBoxContainer = UI.row(12)
	body.add_child(controls)
	_button(controls, "AJUSTAR FORMAÇÃO ATUAL", formation_requested.emit, "reward.formation", "reward")
	_button(controls, "REVER ÚLTIMA RODADA", history_requested.emit, "reward.history", "reward")


func destination(body: VBoxContainer, offer: Dictionary, options: Array, occupants: Dictionary, outgoing: Dictionary, capture_index: int, capture_replace_uid: int, capture_slot: int, registry: Callable) -> void:
	register = registry
	if capture_replace_uid >= 0: body.add_child(ui.paragraph("Ao confirmar, libera " + Content.display_name(outgoing) + ". Voltar mantém seu time.", 20, UI.FIRE))
	var row: HBoxContainer = UI.row(12)
	body.add_child(row)
	for slot in range(Rules.MAX_ACTIVE):
		var occupant: Dictionary = occupants.get(slot, {})
		var label: String = Targeting.SLOT_NAMES[slot].to_upper() + "\n" + ("Vaga livre" if occupant.is_empty() else Content.display_name(occupant))
		if not occupant.is_empty() and int(occupant.uid) == capture_replace_uid: label += " · saída escolhida"
		var choice: Button = _button(row, ("✓ " if capture_slot == slot else "") + label, slot_requested.emit.bind(slot), "capture.slot.%d" % slot, "capture_destination")
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.custom_minimum_size.y = 82
		choice.disabled = not slot in options
	var reserve: Button = _button(body, ("✓ " if capture_slot == -1 else "") + "MANTER NA RESERVA", slot_requested.emit.bind(-1), "capture.reserve", "capture_destination")
	reserve.disabled = not -1 in options
	body.add_child(ui.paragraph("No campo: os poderes entram no baralho inicial, misturados com os demais. Na reserva: ficam fora do ciclo até você trazer esse Umbral.", 21))
	var destination: String = "RESERVA" if capture_slot < 0 else "CAMPO · " + Targeting.SLOT_NAMES[capture_slot].to_upper()
	_button(body, "CAPTURAR → " + destination, confirm_requested.emit.bind(capture_index, capture_replace_uid, capture_slot), "capture.confirm", "capture_destination", true)
	_button(body, "VOLTAR", back_requested.emit, "capture.back", "capture_destination")


func replacement(body: VBoxContainer, offer: Dictionary, party: Array, replacement_index: int, viewport_size: Vector2, registry: Callable) -> void:
	register = registry
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = minf(390, viewport_size.y - 340)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	body.add_child(scroll)
	var grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)
	for i in range(party.size()):
		var umbral: Dictionary = party[i]
		var column: VBoxContainer = UI.column(12)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(column)
		column.add_child(UI.art(Content.art_binding(umbral), Vector2(96, 72)))
		column.add_child(ui.label(Content.display_name(umbral), 24, Color(Content.SPECIES[umbral.species].color), true, true))
		column.add_child(ui.label("%s · %d/%d HP · %s" % [Content.PASSIVES[umbral.passive].name, int(umbral.hp), int(umbral.max_hp), "reserva" if int(umbral.slot) < 0 else Targeting.SLOT_NAMES[int(umbral.slot)]], 16, UI.MUTED, false, true))
		_button(column, "ESCOLHER SAÍDA", replacement_requested.emit.bind(replacement_index, int(umbral.uid)), "replace.%d" % i, "replacement", true)
	_button(body, "MANTER MEU TIME", back_requested.emit, "replacement.back", "replacement")

