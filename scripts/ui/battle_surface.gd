extends Control
## Owns the battle widget tree and its presentation projection. Session commands
## remain in the application; this surface only emits player intent.
signal control_created(control: Control, key: String)
signal slot_requested(side: String, slot: int)
signal command_requested(command: String)
signal card_selected(index: int)
signal focus_group_changed
signal changed
signal boss_changed(active: bool)

const BattleHUD = preload("res://scripts/ui/battle_hud.gd")
const BattlePresenter = preload("res://scripts/ui/battle_presenter.gd")
const Content = preload("res://scripts/content.gd")
var hud: Control
var presenter = BattlePresenter.new()
var cards: Array = []
var hand_fingerprint: String:
	get: return presenter.hand_fingerprint
	set(value): presenter.hand_fingerprint = value
var targeting_index: int:
	get: return presenter.targeting_index

func build(ui: RefCounted, registry: Dictionary, safe_margin: Callable, card_nodes: Array) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	cards = card_nodes
	hud = BattleHUD.new()
	add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.control_created.connect(control_created.emit)
	hud.slot_requested.connect(slot_requested.emit)
	hud.command_requested.connect(command_requested.emit)
	hud.build(ui, safe_margin)
	presenter.configure(hud, registry, cards)
	presenter.control_created.connect(control_created.emit)
	presenter.card_selected.connect(card_selected.emit)
	presenter.focus_group_changed.connect(focus_group_changed.emit)
	presenter.changed.connect(changed.emit)
	presenter.boss_changed.connect(boss_changed.emit)

func bottom_inset() -> float:
	return -hud.visual_layer.offset_bottom

func set_state(model: RefCounted, preferences: RefCounted, busy: bool, capture: bool, device: String, aimed: int) -> void:
	presenter.set_state(model, preferences, busy, capture, device, aimed)

func sync() -> void:
	presenter.sync()

func sync_selection() -> void:
	presenter.sync_selection()

func actor_center(side: String, slot: int) -> Vector2:
	var list: Array = hud.actors if side == "ally" else hud.enemy_actors
	if slot < 0 or slot >= list.size(): return size * Vector2(0.5, 0.35)
	var actor: Control = list[slot]
	return actor.get_global_rect().get_center() - Vector2(0, 12)

func show_notice(message: String) -> void:
	hud.notice_label.text = message

func feedback_progress(index: int, total: int, line: String) -> void:
	hud.phase_label.text = "EXECUTANDO · efeito %d de %d" % [index, total]
	hud.preview_label.text = line
	hud.notice_label.text = "Ao terminar, abra RESUMO para rever danos, escudos e reações."

func play_resolution(feedback: RefCounted, result: Dictionary, sound: Node, preferences: RefCounted, reserves: Array) -> void:
	await feedback.play(result, {"actors": hud.actors, "enemy_actors": hud.enemy_actors, "audio": sound, "effects": hud.effects, "preferences": preferences.values, "reserves": reserves, "reserve_buttons": hud.reserve_buttons, "viewport_size": size, "tree": get_tree(), "text_scale": preferences.text_scale()})

func apply_reduced_motion(reduced: bool) -> void:
	hud.effects.reduced_motion = reduced
	if reduced: hud.effects.clear()
	for actor in hud.actors + hud.enemy_actors: actor.reduced_motion = reduced
	for card in cards:
		card.reduced_motion = reduced
		card._react()

func clear_effects() -> void:
	hud.effects.clear()

func popup(point: Vector2, text: String, color: Color) -> void:
	hud.effects.popup(point, text, color)

func reward_burst(individual: Dictionary) -> void:
	for actor in hud.actors:
		if not actor.identity.is_empty() and int(actor.identity.uid) == int(individual.uid):
			hud.effects.burst(actor.get_global_rect().get_center(), Color(Content.SPECIES[individual.species].color), 32)

func feedback_metrics() -> Dictionary:
	return {"hits": hud.effects.hits, "flights": hud.effects.flights, "bursts": hud.effects.bursts, "trauma": hud.effects.trauma, "particles": hud.effects.particles.size()}
