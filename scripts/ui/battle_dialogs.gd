extends RefCounted
## Battle dialogs render supplied snapshots and emit player intent.
const Content = preload("res://scripts/content.gd")
const Items = preload("res://scripts/ui/item_presentation.gd")
const UI = preload("res://scripts/ui/kit.gd")
signal back_requested
signal swap_requested(slot: int)
signal swap_cancel_requested(slot: int)
signal formation_requested(slot: int, uid: int)
signal formation_confirmed
signal item_requested(item: String, uid: int)
signal item_cancel_requested(index: int)
signal ko_requested(slot: int, uid: int)
signal ko_finished
var ui = UI.new()
var register: Callable

func _button(parent: Node, text: String, action: Callable, key: String, screen: String, primary: bool = false) -> Button:
	var button: Button = ui.button(text, action, key, primary)
	parent.add_child(button)
	register.call(button, key, screen)
	return button

func swap(body: VBoxContainer, occupants: Dictionary, reasons: Dictionary, queued_swaps: Array, registry: Callable) -> void:
	register = registry
	
	var row: HBoxContainer = UI.row(14)
	body.add_child(row)
	for slot in range(3):
		var occupant: Dictionary = occupants.get(slot, {})
		var label: String = ["SUPERIOR", "CENTRAL", "INFERIOR"][slot]
		label += "\n" + (Content.display_name(occupant) if not occupant.is_empty() else "Vaga vazia")
		var choice: Button = _button(row, label, swap_requested.emit.bind(slot), "swap.slot.%d" % slot, "swap", true)
		choice.custom_minimum_size = Vector2(280, 100)
		choice.tooltip_text = str(reasons.get(slot, ""))
		choice.disabled = not choice.tooltip_text.is_empty()
	for queued in queued_swaps:
		_button(body, "CANCELAR TROCA · " + ["SUPERIOR", "CENTRAL", "INFERIOR"][int(queued.slot)], swap_cancel_requested.emit.bind(int(queued.slot)), "swap.cancel.%d" % int(queued.slot), "swap")
	body.add_child(ui.paragraph("As cartas de quem entra participam da próxima compra normal. Planejar e cancelar não altera o campo nem compra cartas.", 20))
	_button(body, "VOLTAR", back_requested.emit, "swap.back", "swap")



func formation(body: VBoxContainer, party: Array, formation_draft: Array, registry: Callable) -> void:
	register = registry
	for slot in range(3):
		var row: HBoxContainer = UI.row(8)
		body.add_child(row)
		var label: Label = ui.label(["SUPERIOR", "CENTRAL", "INFERIOR"][slot], 17, UI.GOLD)
		label.custom_minimum_size.x = 112
		row.add_child(label)
		for i in range(party.size()):
			var individual: Dictionary = party[i]
			var choice: Button = _button(row, ("✓ " if int(formation_draft[slot]) == int(individual.uid) else "") + Content.display_name(individual), formation_requested.emit.bind(slot, int(individual.uid)), "formation.%d.%d" % [slot, i], "formation")
			choice.custom_minimum_size.x = 125
			choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			choice.disabled = int(individual.hp) <= 0
			choice.add_theme_font_size_override("font_size", 17)
		_button(row, "VAZIO", formation_requested.emit.bind(slot, -1), "formation.clear.%d" % slot, "formation").add_theme_font_size_override("font_size", 16)
	var confirm: Button = _button(body, "CONFIRMAR FORMAÇÃO", formation_confirmed.emit, "formation.confirm", "formation", true)
	confirm.disabled = formation_draft == [-1, -1, -1]
	_button(body, "VOLTAR", back_requested.emit, "formation.back", "formation")



func pouch(frame: VBoxContainer, inventory: Dictionary, party: Array, reasons: Dictionary, queued_items: Array, viewport_size: Vector2, registry: Callable, definitions: Dictionary) -> void:
	register = registry
	var item_ids: Array = Items.choices(definitions, inventory)
	frame.add_child(ui.label(Items.summary(inventory, definitions), 22, UI.GOLD))
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = minf(360, viewport_size.y - 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	frame.add_child(scroll)
	var body: VBoxContainer = UI.column(12)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	for i in range(party.size()):
		var individual: Dictionary = party[i]
		var row: HBoxContainer = UI.row(12)
		body.add_child(row)
		var label: Label = ui.label("%s · %d/%d HP" % [Content.display_name(individual), int(individual.hp), int(individual.max_hp)], 20)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		for item_id in item_ids:
			var choice: Button = _button(row, Items.name_for(item_id, definitions).to_upper(), item_requested.emit.bind(item_id, int(individual.uid)), "pouch.%s.%d" % [item_id, i], "pouch")
			choice.tooltip_text = str(reasons.get("%s:%d" % [item_id, int(individual.uid)], ""))
			choice.disabled = not choice.tooltip_text.is_empty()
	for i in range(queued_items.size()):
		_button(body, "CANCELAR ITEM %d" % (i + 1), item_cancel_requested.emit.bind(i), "pouch.cancel.%d" % i, "pouch")
	body.add_child(ui.paragraph("Reanimar devolve HP agora. Se estiver em campo, os poderes ficam disponíveis na próxima rodada. Reservas continuam fora do baralho; não há compra extra.", 18))
	_button(frame, "VOLTAR", back_requested.emit, "pouch.back", "pouch", true)



func ko(body: VBoxContainer, occupants: Dictionary, reserves: Array, able: int, registry: Callable) -> void:
	register = registry
	
	for slot in range(3):
		var occupant: Dictionary = occupants.get(slot, {})
		if occupant.is_empty() or int(occupant.hp) > 0: continue
		body.add_child(ui.label("Vaga " + ["superior", "central", "inferior"][slot] + " · " + Content.display_name(occupant), 23, UI.GOLD))
		var row: HBoxContainer = UI.row(10)
		body.add_child(row)
		for i in range(reserves.size()):
			var choice: Button = _button(row, Content.display_name(reserves[i]), ko_requested.emit.bind(slot, int(reserves[i].uid)), "ko.%d.%d" % [slot, i], "ko_replacement", true)
			choice.disabled = int(reserves[i].hp) <= 0
	body.add_child(ui.paragraph("Cartas dos incapacitados continuam bloqueadas. Continuar dispensa novas perguntas sobre esse nocaute; trazer alguém depois custa 1 ação. Um novo nocaute reabre a oferta gratuita.", 20))
	
	if able == 0: body.add_child(ui.paragraph("Escolha ao menos um Umbral apto para continuar. Essa reposição não gasta ações.", 20, UI.GOLD))
	var next: Button = _button(body, "CONTINUAR COM %d ATIVO(S)" % able, ko_finished.emit, "ko.finish", "ko_replacement", true)
	next.disabled = able == 0


