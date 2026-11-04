extends RefCounted
## Builds formation and item overlays from public snapshots and forwards intents.
signal control_created(control: Control, key: String, screen: String)
signal back_requested
signal swap_requested(slot: int)
signal swap_cancel_requested(slot: int)
signal formation_requested(slot: int, uid: int)
signal formation_confirmed
signal item_requested(item: String, uid: int)
signal item_cancel_requested(index: int)
signal ko_requested(slot: int, uid: int)
signal ko_finished
const Content = preload("res://scripts/content.gd")
const ModalFrame = preload("res://scripts/ui/modal_frame.gd")
const BattleDialogs = preload("res://scripts/ui/battle_dialogs.gd")
var current_view: RefCounted

func swap(ui: RefCounted, viewport_size: Vector2, entrant: Dictionary, occupants: Dictionary, reasons: Dictionary, queued_swaps: Array) -> Control:
	var frame: Dictionary = ModalFrame.create("swap", false, ui, viewport_size, "Trazer " + Content.display_name(entrant), "Custa 1 ação. A troca só ocorre ao Conjurar; o substituto recebe ataques destinados à vaga.", 1000)
	_view().swap(frame.body, occupants, reasons, queued_swaps, _register)
	return frame.overlay

func formation(ui: RefCounted, viewport_size: Vector2, party: Array, draft: Array) -> Control:
	var frame: Dictionary = ModalFrame.create("formation", false, ui, viewport_size, "Sua formação", "Entre clareiras, escolha de 1 a 3 ativos. Vagas vazias são permitidas; o restante fica na reserva.", 1340)
	_view().formation(frame.body, party, draft, _register)
	return frame.overlay

func pouch(ui: RefCounted, viewport_size: Vector2, inventory: Dictionary, party: Array, reasons: Dictionary, queued_items: Array, definitions: Dictionary) -> Control:
	var frame: Dictionary = ModalFrame.create("pouch", false, ui, viewport_size, "Mochila", "Itens ficam fora do baralho. Cada uso custa 1 ação e resolve apenas ao Conjurar.", 1050)
	_view().pouch(frame.body, inventory, party, reasons, queued_items, viewport_size, _register, definitions)
	return frame.overlay

func ko(ui: RefCounted, viewport_size: Vector2, occupants: Dictionary, reserves: Array, able: int) -> Control:
	var frame: Dictionary = ModalFrame.create("ko_replacement", false, ui, viewport_size, "O próximo eco", "A fila de ações terminou. Reponha vagas incapacitadas gratuitamente ou mantenha menos ativos.", 1150)
	_view().ko(frame.body, occupants, reserves, able, _register)
	return frame.overlay

func _view() -> RefCounted:
	var view = BattleDialogs.new()
	current_view = view
	view.back_requested.connect(back_requested.emit)
	view.swap_requested.connect(swap_requested.emit)
	view.swap_cancel_requested.connect(swap_cancel_requested.emit)
	view.formation_requested.connect(formation_requested.emit)
	view.formation_confirmed.connect(formation_confirmed.emit)
	view.item_requested.connect(item_requested.emit)
	view.item_cancel_requested.connect(item_cancel_requested.emit)
	view.ko_requested.connect(ko_requested.emit)
	view.ko_finished.connect(ko_finished.emit)
	return view

func _register(control: Control, key: String, screen: String) -> Control:
	control_created.emit(control, key, screen)
	return control
