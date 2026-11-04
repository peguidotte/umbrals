extends RefCounted
## Reward and capture overlays render snapshots; the session owns choices.
signal control_created(control: Control, key: String, screen: String)
signal reward_requested(index: int)
signal formation_requested
signal history_requested
signal replacement_requested(index: int, uid: int)
signal slot_requested(slot: int)
signal confirm_requested(index: int, uid: int, slot: int)
signal back_requested
const Content = preload("res://scripts/content.gd")
const ModalFrame = preload("res://scripts/ui/modal_frame.gd")
const RewardView = preload("res://scripts/ui/reward_view.gd")
var current_view: RefCounted

func rewards(ui: RefCounted, viewport_size: Vector2, offers: Array, party: Array) -> Control:
	var frame: Dictionary = ModalFrame.create("reward", false, ui, viewport_size, "Um novo eco responde.", "Capture e escolha Campo ou Reserva, ou evolua um aliado.", 1440)
	var individuals: Dictionary = {}
	for individual in party: individuals[int(individual.uid)] = individual
	_view().rewards(frame.body, offers, individuals, viewport_size, _register)
	return frame.overlay

func destination(ui: RefCounted, viewport_size: Vector2, offer: Dictionary, options: Array, occupants: Dictionary, outgoing: Dictionary, index: int, replace_uid: int, slot: int) -> Control:
	var frame: Dictionary = ModalFrame.create("capture_destination", false, ui, viewport_size, "Onde %s vai lutar?" % Content.display_name(offer.umbral), "Escolha o destino para o próximo encontro. A captura só acontece ao confirmar.", 1040)
	_view().destination(frame.body, offer, options, occupants, outgoing, index, replace_uid, slot, _register)
	return frame.overlay

func replacement(ui: RefCounted, viewport_size: Vector2, offer: Dictionary, party: Array, index: int) -> Control:
	var offered: Dictionary = offer.umbral
	var subtitle: String = "O novo %s tem %s. Escolha quem sai; depois escolha Campo ou Reserva. Nada muda antes de confirmar a captura." % [Content.display_name(offered), Content.PASSIVES[offered.passive].name]
	var frame: Dictionary = ModalFrame.create("replacement", false, ui, viewport_size, "Quem abre espaço?", subtitle, 1230)
	_view().replacement(frame.body, offer, party, index, viewport_size, _register)
	return frame.overlay

func _view() -> RefCounted:
	var view = RewardView.new()
	current_view = view
	view.reward_requested.connect(reward_requested.emit)
	view.formation_requested.connect(formation_requested.emit)
	view.history_requested.connect(history_requested.emit)
	view.replacement_requested.connect(replacement_requested.emit)
	view.slot_requested.connect(slot_requested.emit)
	view.confirm_requested.connect(confirm_requested.emit)
	view.back_requested.connect(back_requested.emit)
	return view

func _register(control: Control, key: String, screen: String) -> Control:
	control_created.emit(control, key, screen)
	return control
