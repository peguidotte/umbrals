extends RefCounted
## Owns the battle HUD projection and emits UI intents; it never owns the session.
const Items = preload("res://scripts/ui/item_presentation.gd")
const Content = preload("res://scripts/content.gd")
const Rules = preload("res://scripts/rules.gd")
const UI = preload("res://scripts/ui/kit.gd")
const PowerCard = preload("res://scripts/ui/power_card.gd")
const Targeting = preload("res://scripts/battle/targeting.gd")
const BattleArt = preload("res://scripts/ui/battle_art.gd")
const BattleReadout = preload("res://scripts/ui/battle_readout.gd")
signal control_created(control: Control, key: String)
signal card_selected(index: int)
signal focus_group_changed
signal changed
signal boss_changed(active: bool)
var game: RefCounted
var preferences: RefCounted
var registry: Dictionary
var battle_root: Control
var cards: Array
var targeting_index: int = -1
var hand_fingerprint: String = ""
var busy: bool = false
var visual_capture: bool = false
var last_device: String = "keyboard"
var visual_layer
var effects
var actors
var enemy_actors
var reserve_buttons
var round_label
var progress_label
var preview_label
var notice_label
var hand_view
var energy_label
var cast_button
var redraw_button
var plan_button
var history_button
var phase_label
var command_strip
var command_buttons
var draw_label
var discard_label

func configure(hud: Control, controls: Dictionary, card_nodes: Array) -> void:
	battle_root = hud
	registry = controls
	cards = card_nodes
	visual_layer = hud.visual_layer
	effects = hud.effects
	actors = hud.actors
	enemy_actors = hud.enemy_actors
	reserve_buttons = hud.reserve_buttons
	round_label = hud.round_label
	progress_label = hud.progress_label
	preview_label = hud.preview_label
	notice_label = hud.notice_label
	hand_view = hud.hand_view
	energy_label = hud.energy_label
	cast_button = hud.cast_button
	redraw_button = hud.redraw_button
	plan_button = hud.plan_button
	history_button = hud.history_button
	phase_label = hud.phase_label
	command_strip = hud.command_strip
	command_buttons = hud.command_buttons
	draw_label = hud.draw_label
	discard_label = hud.discard_label

func set_state(model: RefCounted, settings: RefCounted, is_busy: bool, capture: bool, device: String, aimed: int) -> void:
	game = model
	preferences = settings
	busy = is_busy
	visual_capture = capture
	last_device = device
	targeting_index = aimed

func _at_slot(side: String, slot: int) -> Dictionary:
	for individual in game.party if side == "ally" else game.enemies:
		if int(individual.get("slot", -1)) == slot: return individual
	return {}

func sync() -> void:
	if not is_instance_valid(battle_root): return
	var displayed_round: int = int(game.last_result.get("resolved_round", game.round_number)) if game.phase in ["reward", "victory", "defeat"] else game.round_number
	round_label.text = "Rodada %d" % displayed_round
	var route: Array = Content.route_encounter_ids()
	var encounter_id: String = str(Content.ENCOUNTERS[game.encounter].get("id", ""))
	progress_label.text = route_progress(encounter_id, route)
	var intents: Array = game.public_intents()
	for slot in range(3):
		actors[slot].set_identity(_at_slot("ally", slot), preferences.text_scale())
		enemy_actors[slot].set_identity(_at_slot("enemy", slot), preferences.text_scale())
		var intent: Dictionary = {}
		for candidate in intents:
			if int(candidate.get("slot", -1)) == slot: intent = candidate
		enemy_actors[slot].set_intent(intent)
	for actor in actors + enemy_actors:
		actor.still = visual_capture
		actor.reduced_motion = preferences.values.reduced_motion
	var reserves: Array = game.reserves()
	for i in range(6):
		var button: Button = reserve_buttons[i]
		button.disabled = busy or i >= reserves.size() or game.phase != "battle"
		button.icon = null
		button.text = "—"
		button.tooltip_text = "Vaga de reserva vazia. Até seis Umbrals no time."
		if i < reserves.size():
			var individual: Dictionary = reserves[i]
			button.icon = BattleArt.texture(Content.art_binding(individual))
			button.text = Content.display_name(individual)
			button.tooltip_text = "%s · HP %d/%d
Escolha uma vaga para trocar (1 ação)." % [Content.display_name(individual), int(individual.hp), int(individual.max_hp)]
			button.disabled = button.disabled or int(individual.hp) <= 0
			button.modulate = Color.WHITE if int(individual.hp) > 0 else Color(0.6, 0.65, 0.7)
	draw_label.text = "%d\nCompra" % game.deck.size()
	discard_label.text = "%d\nDescarte" % game.discard_pile.size()
	if registry.has("hud.backpack"):
		var pouch: Button = registry["hud.backpack"]
		pouch.text = str(Items.count(game.inventory, Content.CONSUMABLES))
		pouch.tooltip_text = "MOCHILA · " + Items.summary(game.inventory, Content.CONSUMABLES, true) + ". Cada uso custa 1 ação; consultar é grátis."
	effects.reduced_motion = preferences.values.reduced_motion
	boss_changed.emit(is_route_final(encounter_id, route))
	var fingerprint: String = JSON.stringify(game.hand.map(func(card: Dictionary) -> String: return str(card.instance_id)))
	if fingerprint != hand_fingerprint:
		hand_fingerprint = fingerprint
		_rebuild_hand()
	else:
		for i in range(cards.size()): cards[i].configure(game.hand[i], game.umbral_by_uid(int(game.hand[i].owner)), game.party, preferences.text_scale(), preferences.values.reduced_motion)
	sync_selection()
	focus_group_changed.emit()
	changed.emit()

func _rebuild_hand() -> void:
	for card in cards:
		hand_view.remove_child(card)
		card.queue_free()
	cards.clear()
	for i in range(game.hand.size()):
		var card = PowerCard.new()
		hand_view.add_child(card)
		card.configure(game.hand[i], game.umbral_by_uid(int(game.hand[i].owner)), game.party, preferences.text_scale(), preferences.values.reduced_motion)
		control_created.emit(card, "hand.%d" % i)
		card.pressed.connect(_on_card_selected.bind(i))
		cards.append(card)
	hand_view.layout_cards()
	hand_view.queue_sort()

func sync_selection() -> void:
	if not is_instance_valid(battle_root): return
	if registry.has("hud.backpack"):
		registry["hud.backpack"].disabled = busy or game.phase != "battle"
	plan_button.disabled = busy or game.phase != "battle"
	history_button.disabled = busy or game.last_result.is_empty()
	draw_label.disabled = busy
	discard_label.disabled = busy
	# Rules have already advanced to the next hand/phase. Keep the committed
	# cards and targets visible until their event sequence finishes playing.
	if busy:
		command_strip.visible = false
		for card in cards: card.disabled = true
		for button in reserve_buttons: button.disabled = true
		cast_button.disabled = true
		cast_button.text = "CONJURANDO…"
		redraw_button.disabled = true
		phase_label.text = "EXECUTANDO · aguarde os efeitos"
		for button in command_buttons: button.disabled = true
		changed.emit()
		return
	var score: Dictionary = game.preview()
	phase_label.text = {"battle": "PLANEJAR  →  MIRAR  →  CONJURAR", "replacement": "REPOSIÇÃO · escolha quem continua", "reward": "ENCONTRO VENCIDO · escolha uma recompensa", "victory": "EXPEDIÇÃO CONCLUÍDA", "defeat": "EXPEDIÇÃO ENCERRADA"}.get(game.phase, "BATALHA")
	var entries: Array = game.planned_actions()
	var planned_cost: int = int(score.get("actions", 0))
	var own_cost: int = int(Rules.evaluate(game.selected_cards(), game.party).actions)
	command_strip.visible = not entries.is_empty() and game.phase == "battle"
	for i in range(command_buttons.size()):
		var button: Button = command_buttons[i]
		button.visible = i < entries.size()
		button.disabled = game.phase != "battle"
		if i < entries.size():
			button.text = BattleReadout.plan_entry(entries[i], game.party, game.enemies)
			if i == command_buttons.size() - 1 and entries.size() > command_buttons.size(): button.text = "+%d comandos · REVISAR PLANO" % (entries.size() - i)
			button.tooltip_text = button.text + "\nToque para revisar, alterar alvos ou remover. Inimigos podem intercalar; empates são sorteados ao Conjurar."
	if not targeting_index in game.selected:
		targeting_index = game.selected.back() if not game.selected.is_empty() else -1
	plan_button.text = "PLANO %d" % [game.selected.size() + game.queued_swaps.size() + game.queued_items.size()]
	plan_button.tooltip_text = "Revisar, inspecionar e editar os comandos · " + ("LB" if last_device == "gamepad" else "P")
	history_button.tooltip_text = "Resumo da última rodada: danos reais, escudos, reações e ações canceladas."
	for i in range(cards.size()):
		var reason: String = game.card_reason(i)
		cards[i].blocked = not reason.is_empty()
		cards[i].blocked_caption = {"Umbral incapacitado": "INCAPACITADO", "Age na próxima rodada": "PRÓXIMA RODADA", "Umbral na reserva": "NA RESERVA"}.get(reason, "INDISPONÍVEL")
		cards[i].disabled = busy or game.phase != "battle" or cards[i].blocked
		var scope: String = str(Content.POWERS[game.hand[i].power].get("scope", "single"))
		cards[i].target_caption = "→ " + (["superior", "centro", "inferior"][clampi(int(game.hand[i].get("target_slot", 1)), 0, 2)] if scope == "single" else {"upper_pair": "sup + centro", "lower_pair": "centro + inf", "all": "todos"}.get(scope, "todos"))
		if Content.POWERS[game.hand[i].power].get("target", "enemy") == "self": cards[i].target_caption = "Si próprio"
		var hypothetical: Array = game.selected_cards().duplicate()
		hypothetical.append(game.hand[i])
		cards[i].insufficient_actions = not i in game.selected and not cards[i].blocked and planned_cost + int(Rules.evaluate(hypothetical, game.party).actions) - own_cost > game.action_budget()
		cards[i].aiming = i == targeting_index
		cards[i].set_chosen(i in game.selected)
		if cards[i].blocked: cards[i].tooltip_text = reason
	cast_button.disabled = busy or not score.valid or game.phase != "battle"
	redraw_button.disabled = busy or game.phase != "battle"
	cast_button.text = "CONJURANDO…" if busy else "CONJURAR"
	redraw_button.text = "RESORTEAR · R\nPassa a rodada"
	var cost: int = int(score.get("actions", score.get("energy", 0)))
	energy_label.configure(game.action_budget(), cost)
	energy_label.add_theme_font_size_override("font_size", int(16 * preferences.text_scale()))
	energy_label.tooltip_text = "%d de %d ações planejadas" % [cost, game.action_budget()]
	energy_label.add_theme_color_override("font_color", UI.FIRE if cost > game.action_budget() else UI.GOLD)
	if cost > game.action_budget(): phase_label.text = "PLANO EXCEDE AS AÇÕES · remova um comando"
	if game.selected.is_empty() and game.queued_swaps.is_empty() and game.queued_items.is_empty():
		preview_label.text = "Escolha poderes · depois escolha os alvos no campo"
		notice_label.text = "Velocidade ordena · P: revisar plano · Espaço: conjurar"
	else:
		preview_label.text = "%d potência · %d escudo · %d cura  |  %d troca(s) · %d item(ns)" % [int(score.get("damage", 0)), int(score.get("block", 0)), int(score.get("heal", 0)), game.queued_swaps.size(), game.queued_items.size()]
		notice_label.text = str(score.reason) if not score.valid else "Estimativa dos seus poderes; velocidade, defesas e estados mudam o resultado."
		if game.pending_information_mode != game.information_mode:
			notice_label.text += " Informação muda na próxima rodada."
	if score.valid and targeting_index >= 0:
		var aimed: Dictionary = game.hand[targeting_index]
		var power: Dictionary = Content.POWERS[aimed.power]
		if power.get("scope", "single") == "single" and power.get("target", "enemy") != "self":
			var target: Dictionary = _at_slot("enemy" if power.get("target", "enemy") == "enemy" else "ally", int(aimed.target_slot))
			var target_name: String = str(target.get("name", "")) if target.has("name") else Content.display_name(target) if not target.is_empty() else "Vaga vazia"
			notice_label.text = "Alvo: %s · Q/E: mudar · P: plano" % target_name
	_sync_targets()
	focus_group_changed.emit()
	changed.emit()

func _scope_slots(power: Dictionary, slot: int) -> Array:
	return Targeting.slots(str(power.get("scope", "single")), slot)

func _sync_targets() -> void:
	for actor in actors + enemy_actors:
		actor.target_marked = false
		actor.targeted = false
		actor.target_available = false
	if targeting_index in game.selected and targeting_index >= 0 and targeting_index < game.hand.size():
		var card: Dictionary = game.hand[targeting_index]
		var power: Dictionary = Content.POWERS[card.power]
		var is_enemy: bool = str(power.get("target", "enemy")) == "enemy"
		var slot: int = int(card.get("target_slot", 1))
		var list: Array = enemy_actors if is_enemy else actors
		var options: Array[int] = game.target_options(targeting_index)
		for target_slot in options: list[target_slot].target_available = true
		for target_slot in _scope_slots(power, slot):
			if target_slot in options: list[int(target_slot)].target_marked = true
		if slot in options: list[slot].targeted = true
	for actor in actors + enemy_actors: actor.queue_redraw()


func _on_card_selected(index: int) -> void:
	card_selected.emit(index)

static func route_progress(encounter_id: String, route: Array) -> String:
	return "·  Clareira %d/%d" % [route.find(encounter_id) + 1, route.size()]

static func is_route_final(encounter_id: String, route: Array) -> bool:
	return not route.is_empty() and encounter_id == str(route.back())
