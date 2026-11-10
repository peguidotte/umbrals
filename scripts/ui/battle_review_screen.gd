extends RefCounted
## Presents inspection, public piles and resolved history. The caller supplies
## already-redacted data; no future enemy plan or draw order is exposed here.
signal control_created(control: Control, key: String, screen: String)
signal back_requested
const Content = preload("res://scripts/content.gd")
const ModalFrame = preload("res://scripts/ui/modal_frame.gd")
const InspectionView = preload("res://scripts/ui/inspection_view.gd")
const BattleRecords = preload("res://scripts/ui/battle_records.gd")
var current_view: RefCounted

func inspection(ui: RefCounted, viewport_size: Vector2, selected: Dictionary, party: Array, enemies: Array, public_intents: Array, power: Dictionary) -> Control:
	var individual: Dictionary = selected.umbral
	var enemy: bool = bool(selected.get("enemy", false))
	var display: String = str(individual.get("name", "Umbral")) if enemy else Content.display_name(individual)
	var title: String = str(Content.POWERS[selected.card.power].name).replace("\n", " ") if selected.has("card") else display
	var frame: Dictionary = ModalFrame.create("inspect", false, ui, viewport_size, title, ("Adversário · " if enemy else "Vínculo · ") + Content.nature_text(individual), 1000)
	var view = InspectionView.new()
	current_view = view
	view.back_requested.connect(back_requested.emit)
	view.build(selected, party, enemies, public_intents, power, viewport_size, frame.body, _register, ui.text_scale)
	return frame.overlay

func pile(ui: RefCounted, viewport_size: Vector2, zone: String, source: Array, party: Array) -> Control:
	var subtitle: String = "%d cartas · Agrupadas por dono e poder. A ordem da compra permanece oculta." % source.size()
	var frame: Dictionary = ModalFrame.create("pile", false, ui, viewport_size, "Pilha de " + ("compra" if zone == "draw" else "descarte"), subtitle, 1080)
	var owners: Dictionary = {}
	for individual in party: owners[int(individual.uid)] = individual
	var view = _records()
	view.pile(frame.body, source, owners, _register)
	return frame.overlay

func history(ui: RefCounted, viewport_size: Vector2, result: Dictionary) -> Control:
	var subtitle: String = "Clareira %d · rodada %d · apenas efeitos já resolvidos" % [int(result.get("encounter_index", 0)) + 1, int(result.get("resolved_round", 1))]
	var frame: Dictionary = ModalFrame.create("history", false, ui, viewport_size, "O que aconteceu na rodada", subtitle, 1180)
	var view = _records()
	view.history(frame.body, result, viewport_size, _register)
	return frame.overlay

func _records() -> RefCounted:
	var view = BattleRecords.new()
	current_view = view
	view.back_requested.connect(back_requested.emit)
	return view

func _register(control: Control, key: String, screen: String) -> Control:
	control_created.emit(control, key, screen)
	return control
