extends Control
const Assets = preload("res://scripts/assets/catalog.gd")
## Session coordinator. HUDs react to discrete rule signals; the screen stack owns input.

const Rules = preload("res://scripts/rules.gd")
const Content = preload("res://scripts/content.gd")
const UI = preload("res://scripts/ui/kit.gd")
const Screens = preload("res://scripts/ui/screen_stack.gd")
const Preferences = preload("res://scripts/ui/preferences.gd")
const Storage = preload("res://scripts/storage.gd")
const Actions = preload("res://scripts/ui/input_actions.gd")
const World = preload("res://scripts/ui/world.gd")
const Actor = preload("res://scripts/ui/actor.gd")
const PowerCard = preload("res://scripts/ui/power_card.gd")
const Effects = preload("res://scripts/ui/effects.gd")
const Audio = preload("res://scripts/ui/audio.gd")
const Targeting = preload("res://scripts/battle/targeting.gd")
const BattleHUD = preload("res://scripts/ui/battle_hud.gd")
const Conditions = preload("res://scripts/battle/conditions.gd")
const BattlePlan = preload("res://scripts/ui/battle_plan.gd")
const BattleArt = preload("res://scripts/ui/battle_art.gd")
const BattleReadout = preload("res://scripts/ui/battle_readout.gd")
const Expedition = preload("res://scripts/expedition/expedition.gd")
const ExpeditionMap = preload("res://scripts/ui/expedition_map.gd")
const RunSave = preload("res://scripts/expedition/run_save.gd")
const SAVE_PATH = "user://umbral_stats_v1.json"
const LEGACY_SAVE_PATH = "user://feral_hand_stats.json"
const WEB_STATS_KEY = "umbral.stats.v1"

var game = Rules.new()
var expedition = Expedition.new()
var run_save = RunSave.new()
var expedition_active: bool = false
var starter_practice: bool = false
var saved_checkpoint: Dictionary = {}
var checkpoint_id: String = ""
var save_notice: String = ""
var recorded_expeditions: Array[String] = []
var persisted_expeditions: Array[String] = []
var checkpoint_writable: bool = true
var result_counted_in_memory: bool = false
var continue_button: Button
var menu_notice: Label
var map_root: Control
var map_selection: String = ""
var screens = Screens.new()
var preferences = Preferences.new()
var ui = UI.new()
var registry: Dictionary = {}
var focus_memory: Dictionary = {}
var stats: Dictionary = {"wins": 0, "runs": 0, "best_damage": 0}
var world: Control
var audio: Node
var menu_root: Control
var battle_root: Control
var modal_root: Control
var visual_layer: Control
var effects: Control
var actors: Array = []
var enemy_actors: Array = []
var reserve_buttons: Array = []
var pile_zone: String = "draw"
var draw_label: Button
var discard_label: Button
var formation_button: Button
var targeting_index: int = -1
var reserve_uid: int = -1
var formation_draft: Array = [-1, -1, -1]
var progress_label: Label
var round_label: Label
var preview_label: Label
var notice_label: Label
var energy_label: Label
var plan_button: Button
var history_button: Button
var phase_label: Label
var command_strip: HBoxContainer
var command_buttons: Array = []
var cast_button: Button
var redraw_button: Button
var hand_view: Container
var menu_stats: Label
var cards: Array = []
var focus_groups: Dictionary = {}
var inspection: Dictionary = {}
var replacement_index: int = -1
var capture_index: int = -1
var capture_slot: int = -1
var capture_replace_uid: int = -1
var session_active: bool = false
var busy: bool = false
var epoch: int = 0
var seed_number: int = 42013
var result_recorded: bool = false
var last_device: String = "keyboard"
var browser_test: bool = false
var visual_capture: bool = false
var hand_fingerprint: String = ""
var header_text_scale: float = 1.0
var buffered_card: int = -1
var buffered_at: int = 0
var rejected_busy_casts: int = 0
var published_revision: int = 0
var last_card_index: int = 0
var debug_queued: bool = false
var input_serial: int = 0
var interaction_serial: int = 0
var last_interaction: String = ""

func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_tree().root.close_requested.connect(_quit)
	Actions.install()
	preferences.load_saved()
	ui.text_scale = preferences.text_scale()
	header_text_scale = ui.text_scale
	theme = ui.make_theme()
	_load_stats()
	_refresh_checkpoint()
	audio = Audio.new()
	add_child(audio)
	audio.apply(preferences.values)
	world = World.new()
	add_child(world)
	world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if OS.has_feature("web"):
		browser_test = bool(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('test') === '1'"))
		visual_capture = bool(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('visual') === '1'"))
	world.still = visual_capture or preferences.values.reduced_motion
	screens.changed.connect(_on_screen_changed)
	preferences.changed.connect(_on_preferences_changed)
	game.state_changed.connect(_on_rule_changed)
	resized.connect(_layout_changed)
	_build_menu()
	_on_screen_changed()
	_log("ui_started", {"screen": "menu"})
	if "--smoke-exit" in OS.get_cmdline_user_args(): call_deferred("_smoke_exit")

func _smoke_exit() -> void:
	await get_tree().create_timer(0.15).timeout
	await _quit()

func _full(node: Control, parent: Node) -> void:
	parent.add_child(node)
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _at(node: Control, parent: Control, anchor: Vector2, extent: Vector2) -> void:
	parent.add_child(node)
	node.anchor_left = anchor.x
	node.anchor_right = anchor.x
	node.anchor_top = anchor.y
	node.anchor_bottom = anchor.y
	node.offset_left = -extent.x * 0.5
	node.offset_right = extent.x * 0.5
	node.offset_top = -extent.y * 0.5
	node.offset_bottom = extent.y * 0.5

func _register(node: Control, key: String, screen: String) -> Control:
	node.set_meta("ui_id", key)
	node.set_meta("ui_screen", screen)
	registry[key] = node
	node.focus_entered.connect(_queue_debug)
	node.focus_entered.connect(_reveal_focused_control.bind(node))
	node.item_rect_changed.connect(_queue_debug)
	if key.begins_with("hand."):
		var index: int = int(key.get_slice(".", 1))
		node.focus_entered.connect(func():
			last_card_index = index
			_aim_card(index))
		node.mouse_entered.connect(func():
			last_card_index = index
			_aim_card(index))
	if node is BaseButton:
		node.pressed.connect(func(): audio.play("hover", true))
		if browser_test:
			node.pressed.connect(func():
				interaction_serial += 1
				last_interaction = key
				_queue_debug())
	return node

func _button(parent: Node, text: String, callback: Callable, key: String, screen: String, primary: bool = false) -> Button:
	var button: Button = ui.button(text, callback, key, primary)
	parent.add_child(button)
	_register(button, key, screen)
	return button

func _reveal_focused_control(control: Control) -> void:
	# Focus may be restored before a newly built modal has its final layout.
	await get_tree().process_frame
	if not is_instance_valid(control) or not control.is_inside_tree() or not control.has_focus(): return
	var parent: Node = control.get_parent()
	while parent != null:
		if parent is ScrollContainer: parent.ensure_control_visible(control)
		parent = parent.get_parent()
	_queue_debug()

func _build_menu() -> void:
	menu_root = Control.new()
	menu_root.name = "TitleScreen"
	_full(menu_root, self)
	var column: VBoxContainer = UI.column(7)
	menu_root.add_child(column)
	column.anchor_left = 0.12
	column.anchor_right = 0.12
	column.anchor_top = 0.07
	column.anchor_bottom = 0.92
	column.offset_right = 650
	column.add_child(ui.label("U M B R A L", 78, UI.PAPER, true))
	column.add_child(ui.label("E C O S   D O   B O S Q U E", 22, UI.GOLD))
	var breathing = Control.new()
	breathing.custom_minimum_size.y = 20
	column.add_child(breathing)
	var primary: Button = _button(column, "INICIAR EXPEDIÇÃO", _choose_starter.bind(42013), "menu.play", "menu", true)
	primary.custom_minimum_size.x = 410
	continue_button = _button(column, "CONTINUAR EXPEDIÇÃO", _continue_expedition, "menu.continue", "menu")
	continue_button.disabled = saved_checkpoint.is_empty()
	_button(column, "TREINO DE BATALHA", _choose_starter.bind(42013, true), "menu.practice", "menu")
	_button(column, "GRIMÓRIO DOS UMBRALS", _push.bind("codex"), "menu.codex", "menu")
	_button(column, "OPÇÕES", _push.bind("settings"), "menu.settings", "menu")
	_button(column, "COMO JOGAR", _push.bind("help"), "menu.help", "menu")
	_button(column, "CRÉDITOS", _push.bind("credits"), "menu.credits", "menu")
	if not OS.has_feature("web"):
		_button(column, "SAIR", _quit, "menu.quit", "menu")
	menu_notice = ui.paragraph(save_notice if not save_notice.is_empty() else "Escolha sua rota. Preserve seus vínculos.", 18, UI.MUTED)
	column.add_child(menu_notice)
	for child in column.get_children():
		if child is Button:
			child.alignment = HORIZONTAL_ALIGNMENT_LEFT
			child.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			child.custom_minimum_size.x = 450
			child.add_theme_font_size_override("font_size", int(24 * preferences.text_scale()))
			if child != primary:
				child.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
				child.add_theme_stylebox_override("hover", ui.style(Color(0.035, 0.07, 0.075, 0.45), Color.TRANSPARENT))
	var hero: TextureRect = UI.art("umbrals/ignivar", Vector2(390, 390))
	_at(hero, menu_root, Vector2(0.76, 0.57), Vector2(390, 390))
	menu_stats = ui.label("", 18, UI.MUTED)
	menu_root.add_child(menu_stats)
	menu_stats.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	menu_stats.offset_left = 34
	menu_stats.offset_top = -37
	menu_stats.offset_right = 800
	_update_menu_stats()
	var version: Label = ui.label("v" + Content.VERSION, 18, UI.GOLD)
	menu_root.add_child(version)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.offset_left = -140
	version.offset_top = -37
	version.offset_right = -30
	_set_group("menu")

func _build_battle() -> void:
	var hud = BattleHUD.new()
	_full(hud, self)
	battle_root = hud
	hud.control_created.connect(func(control: Control, key: String): _register(control, key, "battle"))
	hud.slot_requested.connect(_click_slot)
	hud.command_requested.connect(_battle_command)
	hud.build(ui, _apply_safe_margin)
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
	world.battle_bottom_inset = -visual_layer.offset_bottom
	_sync_battle(false)

func _battle_command(command: String) -> void:
	if command.begins_with("reserve."):
		_open_reserve(int(command.get_slice(".", 1)))
		return
	match command:
		"cast": _cast()
		"redraw": _redraw()
		"plan": _open_plan()
		"draw", "discard": _open_pile(command)
		"history": _open_history()
		_: _push(command)

func _at_slot(side: String, slot: int) -> Dictionary:
	for individual in game.party if side == "ally" else game.enemies:
		if int(individual.get("slot", -1)) == slot: return individual
	return {}

func actor_center(side: String, slot: int) -> Vector2:
	var list: Array = actors if side == "ally" else enemy_actors
	if slot < 0 or slot >= list.size(): return size * Vector2(0.5, 0.35)
	var actor: Control = list[slot]
	return actor.get_global_rect().get_center() - Vector2(0, 12)

func _apply_safe_margin(margin: MarginContainer) -> void:
	var inset: int = 32
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var window: Vector2i = DisplayServer.window_get_size()
	var additional_left: int = 0
	var additional_right: int = 0
	if safe.size.x > 0 and safe.size.x <= window.x and safe.size.y <= window.y:
		var scale_x: float = size.x / maxf(1, window.x)
		additional_left = int(maxi(0, safe.position.x) * scale_x)
		additional_right = int(maxi(0, window.x - safe.end.x) * scale_x)
	margin.add_theme_constant_override("margin_left", inset + additional_left)
	margin.add_theme_constant_override("margin_right", inset + additional_right)

func _sync_battle(_animate: bool = false) -> void:
	if not is_instance_valid(battle_root): return
	var displayed_round: int = int(game.last_result.get("resolved_round", game.round_number)) if game.phase in ["reward", "victory", "defeat"] else game.round_number
	round_label.text = "Rodada %d" % displayed_round
	progress_label.text = "·  Clareira %d/%d" % [game.encounter + 1, Content.ENCOUNTERS.size()]
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
			button.icon = BattleArt.texture(str(Content.SPECIES[individual.species].art[int(individual.stage) - 1]))
			button.text = Content.display_name(individual)
			button.tooltip_text = "%s · HP %d/%d
Escolha uma vaga para trocar (1 ação)." % [Content.display_name(individual), int(individual.hp), int(individual.max_hp)]
			button.disabled = button.disabled or int(individual.hp) <= 0
			button.modulate = Color.WHITE if int(individual.hp) > 0 else Color(0.6, 0.65, 0.7)
	draw_label.text = "%d\nCompra" % game.deck.size()
	discard_label.text = "%d\nDescarte" % game.discard_pile.size()
	if registry.has("hud.backpack"):
		var pouch: Button = registry["hud.backpack"]
		pouch.text = str(int(game.inventory.get("potion", 0)) + int(game.inventory.get("revive", 0)))
		pouch.tooltip_text = "MOCHILA · %d poções · %d reanimação. Cada uso custa 1 ação; consultar é grátis." % [int(game.inventory.get("potion", 0)), int(game.inventory.get("revive", 0))]
	effects.reduced_motion = preferences.values.reduced_motion
	audio.set_boss(game.encounter == Content.ENCOUNTERS.size() - 1)
	var fingerprint: String = JSON.stringify(game.hand.map(func(card: Dictionary) -> String: return str(card.instance_id)))
	if fingerprint != hand_fingerprint:
		hand_fingerprint = fingerprint
		_rebuild_hand()
	else:
		for i in range(cards.size()): cards[i].configure(game.hand[i], game.umbral_by_uid(int(game.hand[i].owner)), game.party, preferences.text_scale(), preferences.values.reduced_motion)
	_sync_selection()
	_set_group("battle")
	_queue_debug()

func _rebuild_hand() -> void:
	for card in cards:
		hand_view.remove_child(card)
		card.queue_free()
	cards.clear()
	for i in range(game.hand.size()):
		var card = PowerCard.new()
		hand_view.add_child(card)
		card.configure(game.hand[i], game.umbral_by_uid(int(game.hand[i].owner)), game.party, preferences.text_scale(), preferences.values.reduced_motion)
		_register(card, "hand.%d" % i, "battle")
		card.pressed.connect(_select.bind(i))
		cards.append(card)
	hand_view.layout_cards()
	hand_view.queue_sort()

func _sync_selection() -> void:
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
		_queue_debug()
		return
	var score: Dictionary = game.preview()
	phase_label.text = {"battle": "PLANEJAMENTO · selecione, escolha alvos e conjure", "replacement": "REPOSIÇÃO · escolha quem continua", "reward": "ENCONTRO VENCIDO · escolha uma recompensa", "victory": "EXPEDIÇÃO CONCLUÍDA", "defeat": "EXPEDIÇÃO ENCERRADA"}.get(game.phase, "BATALHA")
	var entries: Array = game.planned_actions()
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
		cards[i].set_chosen(i in game.selected)
		cards[i].aiming = i == targeting_index
		if cards[i].blocked: cards[i].tooltip_text = reason
	cast_button.disabled = busy or not score.valid or game.phase != "battle"
	redraw_button.disabled = busy or game.phase != "battle"
	cast_button.text = "CONJURANDO…" if busy else "CONJURAR"
	redraw_button.text = "RESORTEAR · R\nPassa a rodada"
	var cost: int = int(score.get("actions", score.get("energy", 0)))
	energy_label.text = "%d/%d no plano · %d livre(s)" % [cost, game.action_budget(), maxi(0, game.action_budget() - cost)]
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
	_set_group("battle")
	_queue_debug()

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

func _click_slot(side: String, slot: int) -> void:
	if busy or screens.top() != "battle": return
	if targeting_index in game.selected and targeting_index >= 0:
		var power: Dictionary = Content.POWERS[game.hand[targeting_index].power]
		var expected: String = "enemy" if str(power.get("target", "enemy")) == "enemy" else "ally"
		if side == expected and game.set_target(targeting_index, slot):
			audio.play("select", true)
			_sync_selection()
			return
		notice_label.text = "Este poder só alcança " + ("inimigos aptos." if expected == "enemy" else "o próprio dono." if power.get("target", "enemy") == "self" else "aliados aptos.")
		audio.play("hover", true)
		return
	var individual: Dictionary = _at_slot(side, slot)
	if not individual.is_empty():
		inspection = {"umbral": _public_individual(individual), "enemy": side == "enemy"}
		_push("inspect")

func _on_rule_changed(kind: String) -> void:
	if not session_active or screens.root() != "battle" or busy: return
	if kind in ["selection", "target"]: _sync_selection()
	else: _sync_battle()
	_queue_debug()

func _choose_starter(value: int = 42013, practice: bool = false) -> void:
	seed_number = value
	starter_practice = practice
	if not practice:
		_refresh_checkpoint()
		if not saved_checkpoint.is_empty() or run_save.last_status in ["corrupt", "io_error"]:
			_push("confirm_new")
			return
	_push("starter")

func _confirm_new_expedition() -> void:
	_pop()
	_push("starter")

func _start_selected(value: int, starter: String) -> void:
	if starter_practice: _start_game(value, starter)
	else: _start_expedition(value, starter)

func _starter_choices() -> void:
	var body: VBoxContainer = _modal_frame("Escolha seu primeiro vínculo", "Você começa com um Umbral. Cada um traz três poderes, com duas cópias de cada.", 1150)
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
		var choice: Button = _button(column, Content.display_name(individual), _start_selected.bind(seed_number, species_id), "starter." + species_id, "starter", true)
		choice.tooltip_text = Content.trait_text(individual) + "\nResistências: " + Content.resistance_text(individual)
	_button(body, "VOLTAR", _pop, "starter.back", "starter")

func _start_game(value: int = 42013, starter: String = "ember") -> void:
	expedition_active = false
	_bind_game(Rules.new())
	epoch += 1
	busy = false
	session_active = true
	result_recorded = false
	result_counted_in_memory = false
	map_selection = ""
	replacement_index = -1
	seed_number = value
	targeting_index = -1
	hand_fingerprint = ""
	focus_memory.erase("battle")
	game.new_run(value, str(preferences.values.information_mode), starter)
	if not is_instance_valid(battle_root): _build_battle()
	else: _sync_battle()
	effects.clear()
	screens.reset("battle")
	_log("run_started", {"party": game.party})

func _aim_card(index: int) -> void:
	if busy or screens.top() != "battle" or not index in game.selected or targeting_index == index: return
	targeting_index = index
	_sync_selection()

func _select(index: int) -> void:
	if screens.top() != "battle": return
	if busy:
		buffered_card = index
		buffered_at = Time.get_ticks_msec()
		return
	if game.toggle(index):
		targeting_index = index
		last_card_index = index
		audio.play("select", true)
		_sync_selection()

func _cast() -> void:
	if screens.top() != "battle": return
	if busy:
		rejected_busy_casts += 1
		_queue_debug()
		return
	if not game.preview().valid: return
	busy = true
	var token: int = epoch
	var result: Dictionary = game.play()
	if not result.get("ok", false):
		busy = false
		_sync_selection()
		return
	if game.phase in ["victory", "defeat"]: _record_result()
	_checkpoint_expedition()
	_sync_selection()
	await _animate_resolution(result, token)
	if token != epoch: return
	busy = false
	_sync_text_scale()
	targeting_index = -1
	_sync_battle(true)
	_sync_phase()
	if screens.top() == "battle": _focus("hand.0", "battle")
	_log("powers_cast", {"damage": result.get("applied_damage", 0), "phase": game.phase})
	buffered_card = -1
	_queue_debug()

func _animate_resolution(result: Dictionary, token: int) -> void:
	audio.duck()
	var events: Array = result.get("events", [])
	var effect_index: int = 0
	for event in events:
		if token != epoch: return
		effect_index += 1
		phase_label.text = "EXECUTANDO · efeito %d de %d" % [effect_index, events.size()]
		preview_label.text = BattleReadout.event_line(event)
		notice_label.text = "Ao terminar, abra RESUMO para rever danos, escudos e reações."
		var kind: String = str(event.get("kind", ""))
		var side: String = str(event.get("actor_side", "ally"))
		var source: Vector2 = actor_center(side, int(event.get("actor_slot", 1)))
		var target: Vector2 = _feedback_point(str(event.get("target_side", "enemy")), int(event.get("target_slot", 1)), int(event.get("target_uid", -1)))
		var amount: int = int(event.get("amount", 0))
		for actor in actors + enemy_actors:
			actor.acting = not actor.identity.is_empty() and actor.enemy == (side == "enemy") and int(actor.identity.uid) == int(event.get("actor_uid", -1))
			actor.queue_redraw()
		if kind == "attack":
			var nature: Dictionary = Content.NATURES.get(str(event.get("nature", "")), {"name": "", "color": "b5a6f1"})
			var color: Color = Color(nature.color)
			var element: String = str(nature.name)
			effects.flight(source, target, color, element)
			audio.play("storm" if element == "Raio" else "leaf" if element in ["Água", "Bosque"] else "fire")
			await get_tree().create_timer(0.02 if preferences.values.reduced_motion else 0.22).timeout
			if token != epoch: return
			_apply_event_snapshot(event)
			if preferences.values.flashes:
				var slot: int = int(event.get("target_slot", -1))
				var targets: Array = enemy_actors if event.get("target_side", "enemy") == "enemy" else actors
				if slot >= 0 and slot < 3:
					var portrait: TextureRect = targets[slot].portrait
					var rest: Color = portrait.modulate
					portrait.modulate = Color(1.8, 1.8, 1.8)
					portrait.create_tween().tween_property(portrait, "modulate", rest, 0.08)
			effects.impact(target, amount)
			audio.play("impact")
			_float_text("BLOQUEADO" if amount == 0 else "−%d%s" % [amount, " RESISTIU" if int(event.get("resistance", 0)) > 0 else ""], target + Vector2(0, -28), UI.FIRE if side == "enemy" else UI.GOLD, 26)
		elif kind == "reaction":
			_apply_event_snapshot(event)
			effects.burst(target, UI.GOLD, 12)
			_float_text(str(event.label).to_upper(), target + Vector2(0, -52), UI.GOLD, 22)
		elif kind == "condition":
			_apply_event_snapshot(event)
			var condition: String = str(event.get("condition", ""))
			_float_text(str(Conditions.DEFINITIONS.get(condition, {}).get("name", condition)).to_upper(), target + Vector2(0, -6), UI.LEAF, 19)
		elif kind == "condition_spent":
			_apply_event_snapshot(event)
		elif kind == "canceled":
			_float_text("NÃO AGIU", source, UI.MUTED, 19)
		elif kind == "burn":
			_apply_event_snapshot(event)
			effects.burst(target, UI.FIRE, 8)
			_float_text("−%d QUEIMA" % amount, target, UI.FIRE, 19)
		elif kind in ["heal", "revive", "block", "wet", "swap", "ko", "prepare"]:
			_apply_event_snapshot(event)
			var label: String = {"heal": "+%d HP" % amount, "revive": "REANIMADO", "block": "+%d ESCUDO" % amount, "wet": "ENCHARCADO", "swap": "TROCA", "ko": "INCAPACITADO", "prepare": "+%d CARGA" % amount}[kind]
			_float_text(label, target, UI.LEAF if kind in ["heal", "revive"] else UI.GOLD, 19)
			if kind in ["heal", "revive"]: audio.play("leaf")
		await get_tree().create_timer(0.01 if preferences.values.reduced_motion else 0.07).timeout
	for actor in actors + enemy_actors:
		actor.acting = false
		actor.queue_redraw()
	await get_tree().create_timer(0.03 if preferences.values.reduced_motion else 0.15).timeout

func _feedback_point(side: String, slot: int, uid: int) -> Vector2:
	if side == "ally" and slot < 0:
		var reserves: Array = game.reserves()
		for index in range(reserves.size()):
			if int(reserves[index].uid) == uid and index < reserve_buttons.size():
				return reserve_buttons[index].get_global_rect().get_center() - Vector2(0, 18)
	return actor_center(side, slot)

func _apply_event_snapshot(event: Dictionary) -> void:
	var slot: int = int(event.get("target_slot", -1))
	var snapshot: Dictionary = event.get("target_state", {})
	if slot < 0 or slot >= 3 or snapshot.is_empty(): return
	var targets: Array = enemy_actors if event.get("target_side", "enemy") == "enemy" else actors
	targets[slot].set_identity(snapshot, preferences.text_scale())

func _redraw() -> void:
	if busy or screens.top() != "battle": return
	busy = true
	var token: int = epoch
	if not game.redraw():
		busy = false
		_sync_selection()
		return
	audio.play("draw", true)
	_checkpoint_expedition()
	_sync_selection()
	await _animate_resolution(game.last_result, token)
	if token != epoch: return
	busy = false
	if game.phase in ["victory", "defeat"]: _record_result()
	_sync_text_scale()
	targeting_index = -1
	_sync_battle()
	_sync_phase()
	if screens.top() == "battle": _focus("hand.0", "battle")
	_log("hand_redrawn", {"round": game.round_number})

func _float_text(text: String, point: Vector2, color: Color, _font_size: int) -> void:
	effects.popup(point, text, color)

func _remember_focus() -> void:
	var focused: Control = get_viewport().gui_get_focus_owner()
	if is_instance_valid(focused): focus_memory[screens.top()] = focused.get_meta("ui_id", "")

func _push(screen: String) -> void:
	_remember_focus()
	screens.push(screen)

func _pop() -> void:
	_remember_focus()
	screens.pop()

func _sync_phase() -> void:
	if busy or screens.top() != "battle": return
	if expedition_active: expedition.settle_battle()
	if game.phase == "replacement": _push("ko_replacement")
	elif game.phase in ["reward", "victory", "defeat"]: _push(game.phase)

func _on_screen_changed() -> void:
	var battle: bool = screens.root() == "battle"
	world.title_mode = not battle
	world.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if not battle else CanvasItem.TEXTURE_FILTER_NEAREST
	world.queue_redraw()
	menu_root.visible = screens.root() == "menu"
	if is_instance_valid(map_root): map_root.visible = screens.root() == "map"
	if is_instance_valid(battle_root): battle_root.visible = battle
	if is_instance_valid(modal_root):
		# Keep the pressed Control in-tree until Godot finishes its input event.
		# Hiding immediately blocks input; queue_free releases it at frame end.
		modal_root.hide()
		modal_root.queue_free()
	modal_root = null
	if screens.top() == "map": _build_map()
	elif screens.top() not in ["menu", "battle"]: _build_modal(screens.top())
	_set_group(screens.top())
	_focus(focus_memory.get(screens.top(), ""), screens.top())
	_queue_debug()
	_sync_phase()

func _modal_frame(title: String, subtitle: String = "", width: float = 850) -> VBoxContainer:
	modal_root = Control.new()
	modal_root.name = "Overlay_" + screens.top()
	modal_root.z_index = 100
	_full(modal_root, self)
	var shade = ColorRect.new()
	_full(shade, modal_root)
	shade.color = Color(0.012, 0.026, 0.035, 0.92)
	var center = CenterContainer.new()
	_full(center, modal_root)
	center.offset_left = 32
	center.offset_top = 24
	center.offset_right = -32
	center.offset_bottom = -24
	var panel = PanelContainer.new()
	panel.custom_minimum_size.x = minf(width, size.x - 96)
	center.add_child(panel)
	var column: VBoxContainer = UI.column(18)
	panel.add_child(column)
	column.add_child(ui.label(title, 40, UI.PAPER, true, true))
	if not subtitle.is_empty(): column.add_child(ui.paragraph(subtitle, 22, UI.MUTED))
	return column

func _build_modal(screen: String) -> void:
	match screen:
		"starter": _starter_choices()
		"confirm_new":
			var body: VBoxContainer = _modal_frame("Começar uma nova expedição?", "A expedição salva será substituída ao escolher o primeiro vínculo. Voltar mantém o progresso atual.", 850)
			_button(body, "MANTER A EXPEDIÇÃO SALVA", _pop, "new.cancel", screen, true)
			_button(body, "ESCOLHER NOVO VÍNCULO", _confirm_new_expedition, "new.confirm", screen)
		"pause":
			var body: VBoxContainer = _modal_frame("O bosque espera.", "Sua expedição está em pausa.", 650)
			_button(body, "CONTINUAR", _pop, "pause.resume", screen, true)
			_button(body, "OPÇÕES", _push.bind("settings"), "pause.settings", screen)
			_button(body, "COMO JOGAR", _push.bind("help"), "pause.help", screen)
			_button(body, "VOLTAR AO TÍTULO", _push.bind("confirm_menu"), "pause.menu", screen)
		"settings": _settings()
		"help": _help()
		"credits":
			var body: VBoxContainer = _modal_frame("Feito para despertar ecos.", "", 850)
			body.add_child(ui.paragraph("Umbral: Ecos do Bosque\nCriaturas e poderes: arte vetorial original.\nCenário: criado com Image Gen para este projeto.\nÁudio: síntese original, sem samples externos.\nFontes: DejaVu Sans e DejaVu Serif.", 24, UI.PAPER))
			_button(body, "VOLTAR", _pop, "credits.back", screen, true)
		"codex": _codex()
		"inspect": _inspection()
		"reward": _rewards()
		"replacement": _replacement()
		"capture_destination": _capture_destination()
		"history": _history()
		"swap": _swap_choices()
		"formation": _formation_choices()
		"pouch": _pouch()
		"plan": _plan_choices()
		"pile": _pile_contents()
		"ko_replacement": _ko_replacement()
		"victory", "defeat": _ending()
		"confirm_menu":
			var body: VBoxContainer = _modal_frame("Voltar ao título?", ("A expedição será retomada no último estado confirmado. Comandos ainda não conjurados serão desfeitos." if expedition_active else "O treino atual será encerrado. A expedição salva fica preservada."), 760)
			_button(body, "CONTINUAR NO BOSQUE", _pop, "confirm.cancel", screen, true)
			_button(body, "VOLTAR AO TÍTULO", _return_menu, "confirm.yes", screen)

func _settings() -> void:
	var body: VBoxContainer = _modal_frame("Opções", "Ajuste o ritmo, a leitura e o som para você.", 820)
	for key in ["music", "sfx"]:
		var row: HBoxContainer = UI.row(18)
		body.add_child(row)
		row.add_child(ui.label("Música" if key == "music" else "Efeitos e interface", 24))
		var slider = HSlider.new()
		slider.custom_minimum_size = Vector2(330, 48)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = preferences.values[key]
		row.add_child(slider)
		_register(slider, "settings." + key, "settings")
		var percentage: Label = ui.label("%d%%" % int(slider.value * 100), 22, UI.GOLD)
		percentage.custom_minimum_size.x = 90
		row.add_child(percentage)
		slider.value_changed.connect(func(value: float): percentage.text = "%d%%" % int(value * 100); preferences.set_value(key, value))
	for key in ["reduced_motion", "flashes", "large_text"]:
		var check = CheckButton.new()
		check.text = {"reduced_motion": "Movimento reduzido", "flashes": "Flashes de impacto", "large_text": "Texto ampliado"}[key]
		check.custom_minimum_size.y = 56
		check.button_pressed = preferences.values[key]
		body.add_child(check)
		_register(check, "settings." + key, "settings")
		check.toggled.connect(func(value: bool): preferences.set_value(key, value))
	body.add_child(ui.label("Informação inimiga", 23, UI.GOLD))
	var information: HBoxContainer = UI.row(10)
	body.add_child(information)
	for mode in ["hidden", "partial", "full"]:
		var label: String = {"hidden": "OCULTA", "partial": "PARCIAL", "full": "COMPLETA"}[mode]
		var choice: Button = _button(information, ("✓ " if preferences.values.information_mode == mode else "") + label, _choose_information.bind(mode), "settings.info." + mode, "settings")
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(ui.paragraph("Parcial revela a categoria; completa também mostra força, alcance e alvo. Mudar durante a batalha vale na próxima rodada. A IA permanece a mesma.", 18))
	body.add_child(ui.paragraph("Movimento reduzido desativa tremores e partículas. Flashes começam desativados. Estas opções ficam salvas neste dispositivo.", 20))
	_button(body, "VOLTAR", _pop, "settings.back", "settings", true)

func _codex() -> void:
	var body: VBoxContainer = _modal_frame("Grimório dos Umbrals", "Conheça os traits antes de escolher seu vínculo.", 1300)
	var row: HBoxContainer = UI.row(26)
	body.add_child(row)
	for species_id in Content.SPECIES:
		var column: VBoxContainer = UI.column(10)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)
		var individual: Dictionary = Rules.make_umbral(species_id, "fierce", 0)
		var species: Dictionary = Content.SPECIES[species_id]
		column.add_child(UI.art("umbrals/" + species_id, Vector2(180, 160)))
		column.add_child(ui.label(species.names[0] + " → " + species.names[1], 27, Color(species.color), true, true))
		column.add_child(ui.label(species.trait, 24, UI.GOLD, false, true))
		column.add_child(ui.paragraph(Content.nature_text(individual) + " · Resistências: " + Content.resistance_text(individual), 18))
		column.add_child(ui.paragraph(Content.trait_text(individual), 22))
		column.add_child(ui.paragraph("Técnica de linhagem: " + Content.POWERS[species.signature].name.replace("\n", " ") + ".", 20))
	_button(body, "VOLTAR", _pop, "codex.back", "codex", true)

func _inspect_actor(index: int) -> void:
	var individual: Dictionary = _at_slot("ally", index)
	if individual.is_empty(): return
	inspection = {"umbral": individual.duplicate(true)}
	_push("inspect")

func _help() -> void:
	var frame: VBoxContainer = _modal_frame("Seu time é o seu grimório.", "Planeje sem gastar; Conjurar confirma a rodada.", 1040)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = minf(460, size.y - 320)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.focus_mode = Control.FOCUS_ALL
	frame.add_child(scroll)
	var body: VBoxContainer = UI.column(16)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	body.add_child(ui.label("Escolha o caminho do bosque", 25, UI.GOLD))
	body.add_child(ui.paragraph("Na expedição, selecione um ponto do mapa para ver o que ele oferece e confirme para seguir. Após a primeira clareira, a mata oferece combate e recompensa; a nascente recupera até 25% do HP máximo dos aliados vivos, sem reanimar ou dar uma recompensa. Sua escolha fecha a outra rota.\nCONTINUAR EXPEDIÇÃO retoma o último estado confirmado, inclusive o turno de combate. Comandos ainda não conjurados são desfeitos; cartas e sorteios ficam preservados. O treino de batalha é separado da expedição salva.", 22))
	body.add_child(ui.paragraph("1. Selecione poderes da mão. Veja ações livres e comandos no campo.\n2. Escolha os alvos clicando nas criaturas. As vagas são superior, central e inferior; não há retaguarda.\n3. Abra PLANO para alterar alvos, retirar comandos ou tocar em i e consultar um poder.\n4. Conjure quando estiver pronto. Prioridade e velocidade intercalam aliados e inimigos; clicar primeiro não antecipa o golpe.", 23, UI.PAPER))
	body.add_child(ui.label("Entenda o resultado", 25, UI.GOLD))
	body.add_child(ui.paragraph("RESUMO mostra a última rodada: HP perdido, escudo absorvido, resistências, efeitos e reações. Escudo protege nesta rodada; Queima atinge o HP mesmo com escudo. Informação parcial mostra a categoria inimiga, sem prometer dano ou alvo.", 22))
	body.add_child(ui.paragraph("Encharcado + Raio: Condução dobra a potência.\nSemeado + Bosque: Brotação dá escudo à fonte.\nSemeado + Água: Floração cura a fonte.\nSemeado + Fogo: Incêndio aplica Queima.\nUma semente ativa uma reação e é consumida. Interferência enfraquece o próximo ataque, sem impedir ações.", 22, UI.LEAF))
	body.add_child(ui.label("Time e recursos", 25, UI.GOLD))
	body.add_child(ui.paragraph("Comece com 1; até 3 no campo e 6 no time. Capture para uma vaga livre ou para a reserva, por escolha. Cartas de reservas aptos ficam fora do baralho; a entrada custa 1 ação e mistura suas cartas na próxima compra normal. O substituto recebe o golpe da vaga.\nNa mochila, você começa com 2 poções e 1 reanimação. Usar custa 1 ação; consultar é grátis. Reanimar devolve HP agora; se estiver em campo, age na próxima rodada. Reposição após nocaute é gratuita ao terminar a fila; cartas do incapacitado continuam bloqueadas.\nRESORTEAR passa a rodada inteira: nenhum comando aliado executa, os inimigos agem e a mão se renova.", 22))
	body.add_child(ui.paragraph("1–6: poderes · Espaço: conjurar · Q/E: alvo · P: plano\nBackspace: limpar · C: inspecionar · Esc: voltar\nControle: A seleciona, X conjura, RB resorteia, Y inspeciona, LB abre o plano e B volta.", 19, UI.GOLD))
	_button(frame, "VOLTAR", _pop, "help.back", "help", true)
	_register(scroll, "help.content", "help")

func _inspect_focused() -> void:
	if busy: return
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused is PowerCard:
		inspection = {"umbral": focused.individual.duplicate(true), "card": focused.card.duplicate(true)}
	elif focused is Actor:
		if focused.identity.is_empty(): return
		inspection = {"umbral": _public_individual(focused.identity), "enemy": focused.enemy}
	elif is_instance_valid(focused) and str(focused.get_meta("ui_id", "")).begins_with("reserve."):
		var index: int = int(str(focused.get_meta("ui_id")).get_slice(".", 1))
		var reserves: Array = game.reserves()
		if index >= reserves.size(): return
		inspection = {"umbral": reserves[index].duplicate(true)}
	elif last_card_index >= 0 and last_card_index < game.hand.size():
		var card: Dictionary = game.hand[last_card_index]
		inspection = {"umbral": game.umbral_by_uid(int(card.owner)).duplicate(true), "card": card.duplicate(true)}
	else: return
	_push("inspect")

func _inspection() -> void:
	var individual: Dictionary = inspection.umbral
	var species: Dictionary = Content.SPECIES.get(individual.get("species", ""), {})
	var enemy: bool = bool(inspection.get("enemy", false))
	var display: String = str(individual.get("name", "Umbral")) if enemy or species.is_empty() else Content.display_name(individual)
	var title: String = str(Content.POWERS[inspection.card.power].name).replace("\n", " ") if inspection.has("card") else display
	var frame: VBoxContainer = _modal_frame(title, ("Adversário · " if enemy else "Vínculo · ") + Content.nature_text(individual), 1000)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = minf(520, size.y - 320)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.focus_mode = Control.FOCUS_ALL
	frame.add_child(scroll)
	var body: VBoxContainer = UI.column(16)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	var row: HBoxContainer = UI.row(28)
	body.add_child(row)
	var art_id: String = str(individual.get("art", "umbrals/ember")) if enemy or species.is_empty() else str(species.art[int(individual.stage) - 1])
	var portrait: TextureRect = UI.art(str(Content.POWERS[inspection.card.power].art) if inspection.has("card") else art_id, Vector2(210, 200))
	if not inspection.has("card"): portrait.texture = BattleArt.texture(art_id)
	row.add_child(portrait)
	var details: VBoxContainer = UI.column(12)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)
	details.add_child(ui.label("HP %d/%d · ATQ %d · DEF %d · VEL %d" % [int(individual.get("hp", 0)), int(individual.get("max_hp", 0)), int(individual.get("attack", 0)), int(individual.get("defense", 0)), int(individual.get("speed", 0))], 23, UI.GOLD))
	details.add_child(ui.paragraph("Resistências: " + Content.resistance_text(individual), 20))
	if not enemy and not species.is_empty():
		details.add_child(ui.label("TRAIT  " + species.trait, 24, UI.GOLD))
		details.add_child(ui.paragraph(Content.trait_text(individual), 21, UI.PAPER))
	if not enemy and Content.PASSIVES.has(individual.get("passive", "")):
		var passive: Dictionary = Content.PASSIVES[individual.passive]
		details.add_child(ui.label("PASSIVA  " + passive.name, 23, UI.LEAF))
		details.add_child(ui.paragraph(passive.description, 21))
	var conditions: Array[String] = Conditions.labels(individual, true)
	if not conditions.is_empty():
		for id in Conditions.DEFINITIONS:
			if int(individual.get("statuses", {}).get(id, 0)) <= 0: continue
			var source: Dictionary = individual.get("status_sources", {}).get(id, {})
			var roster: Array = game.party if source.get("side", "ally") == "ally" else game.enemies
			for unit in roster:
				if int(unit.uid) == int(source.get("uid", -1)):
					conditions.append("Fonte de %s: %s · %s" % [Conditions.DEFINITIONS[id].name, str(unit.name) if unit.has("name") else Content.display_name(unit), "reserva" if int(unit.slot) < 0 else "vaga " + ["superior", "central", "inferior"][clampi(int(unit.slot), 0, 2)]])
		body.add_child(ui.paragraph("\n".join(conditions), 18))
	if inspection.has("card"):
		var power: Dictionary = Rules.power_effect(inspection.card, individual, game.active_party(true).size())
		body.add_child(ui.paragraph("Natureza do golpe: " + Content.NATURES[power.nature].name + " · Aprendizado: " + {"nature": "por natureza", "lineage": "linhagem", "universal": "universal"}[power.learning] + "\n" + PowerCard.effect_text(power), 20, UI.GOLD))
		body.add_child(ui.paragraph("%d ação(ões) · potência %d · escudo %d · cura %d\nAlcance: %s. A velocidade ordena a execução; estados e defesa modificam o resultado." % [int(power.cost), floori(float(power.damage) * float(power.get("attack_multiplier", 1.0))), int(power.block), int(power.heal), {"single": "individual", "upper_pair": "superior + centro", "lower_pair": "centro + inferior", "all": "todos"}.get(str(power.get("scope", "single")), "individual")], 21))
	elif enemy:
		for intent in game.public_intents():
			if int(intent.slot) != int(individual.slot) or not intent.has("nature"): continue
			var known: Array[String] = []
			if Content.NATURES.has(str(intent.nature)): known.append("Natureza anunciada: " + Content.NATURES[str(intent.nature)].name)
			for id in intent.get("conditions", {}):
				known.append("Anuncia %s %d: %s" % [Conditions.DEFINITIONS[id].name, int(intent.conditions[id]), Conditions.DEFINITIONS[id].description])
			if not known.is_empty(): body.add_child(ui.paragraph("\n".join(known), 20, UI.GOLD))
		body.add_child(ui.paragraph("A intenção mostrada sobre o adversário respeita seu modo de informação. Inspecionar não revela planos ocultos.", 20))
	else:
		var names: Array[String] = []
		for power_id in individual.get("known_powers", species.get("powers", [])): names.append(str(Content.POWERS[power_id].name).replace("\n", " "))
		body.add_child(ui.paragraph("PODERES\n" + " · ".join(names), 21))
	_button(frame, "VOLTAR", _pop, "inspect.back", "inspect", true)

func _choose_information(mode: String) -> void:
	preferences.set_value("information_mode", mode)
	_on_screen_changed()

func _open_pile(zone: String) -> void:
	if busy or screens.top() != "battle": return
	pile_zone = zone
	_push("pile")

func _pile_contents() -> void:
	var source: Array = game.deck if pile_zone == "draw" else game.discard_pile
	var body: VBoxContainer = _modal_frame("Pilha de " + ("compra" if pile_zone == "draw" else "descarte"), "%d cartas · Agrupadas por dono e poder. A ordem da compra permanece oculta." % source.size(), 1080)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 300
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var list: VBoxContainer = UI.column(10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var grouped: Dictionary = {}
	for card in source:
		var key: String = "%s:%s" % [card.owner, card.power]
		if not grouped.has(key): grouped[key] = {"card": card, "count": 0}
		grouped[key].count += 1
	var keys: Array = grouped.keys()
	keys.sort()
	for key in keys:
		var group: Dictionary = grouped[key]
		var owner: Dictionary = game.umbral_by_uid(int(group.card.owner))
		list.add_child(ui.label("%d×  %s · %s%s" % [int(group.count), str(Content.POWERS[group.card.power].name).replace("\n", " "), Content.display_name(owner), " · INCAPACITADO" if int(owner.hp) <= 0 else ""], 23, UI.MUTED if int(owner.hp) <= 0 else UI.PAPER))
	if source.is_empty(): list.add_child(ui.paragraph("Esta pilha está vazia.", 23))
	body.add_child(ui.paragraph("Cartas usadas e não usadas vão ao descarte no fim da rodada. O descarte só é embaralhado quando a compra acaba. Reservas aptas ficam fora do ciclo.", 19))
	_button(body, "VOLTAR", _pop, "pile.back", "pile", true)

func _open_plan() -> void:
	if busy or screens.top() != "battle" or game.phase != "battle": return
	_push("plan")

func _plan_choices() -> void:
	var score: Dictionary = game.preview()
	var body: VBoxContainer = _modal_frame("Plano da rodada", "%d de %d ações · Trocas e itens primeiro, depois prioridade e velocidade." % [int(score.actions), game.action_budget()], 1200)
	var view = BattlePlan.new()
	body.add_child(view)
	view.control_created.connect(func(control: Control, key: String): _register(control, key, "plan"))
	view.remove_requested.connect(_remove_command)
	view.target_requested.connect(_plan_target)
	view.inspect_requested.connect(_inspect_plan_power)
	view.populate(game.planned_actions(), game.hand, game.party.map(_public_individual), game.enemies.map(_public_individual), preferences.text_scale())
	body.add_child(ui.paragraph("Só os seus comandos. Inimigos intercalam ações por velocidade; empates entre donos são sorteados ao Conjurar. Defesa, estados e nocautes podem mudar o resultado.", 18))
	var controls: HBoxContainer = UI.row(12)
	body.add_child(controls)
	_button(controls, "VOLTAR AO CAMPO", _pop, "plan.back", "plan", true)
	var clear: Button = _button(controls, "LIMPAR PLANO", _clear_plan, "plan.clear", "plan")
	clear.disabled = game.planned_actions().is_empty()
	var commit: Button = _button(controls, "CONJURAR PLANO", _cast_from_plan, "plan.cast", "plan", true)
	commit.disabled = not score.valid
	if not score.valid and not game.planned_actions().is_empty(): body.add_child(ui.paragraph(str(score.reason), 20, UI.FIRE))

func _cast_from_plan() -> void:
	if busy or screens.top() != "plan" or not game.preview().valid: return
	_pop()
	_cast()

func _inspect_plan_power(index: int) -> void:
	if busy or index < 0 or index >= game.hand.size(): return
	var card: Dictionary = game.hand[index]
	inspection = {"umbral": game.umbral_by_uid(int(card.owner)).duplicate(true), "card": card.duplicate(true)}
	_push("inspect")

func _open_history() -> void:
	if busy or game.last_result.is_empty(): return
	_push("history")

func _history() -> void:
	var result: Dictionary = game.last_result
	var body: VBoxContainer = _modal_frame("O que aconteceu na rodada", "Clareira %d · rodada %d · apenas efeitos já resolvidos" % [int(result.get("encounter_index", 0)) + 1, int(result.get("resolved_round", 1))], 1180)
	body.add_child(ui.label("%d HP retirado dos inimigos · %d HP perdido pelo time" % [int(result.get("applied_damage", 0)), int(result.get("incoming", 0))], 22, UI.GOLD))
	if bool(result.get("passed", false)): body.add_child(ui.paragraph("Você resorteou: nenhuma ação aliada foi executada. Os inimigos agiram normalmente.", 20))
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = minf(390, size.y - 370)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.focus_mode = Control.FOCUS_ALL
	body.add_child(scroll)
	var list: VBoxContainer = UI.column(12)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var number: int = 0
	for event in result.get("events", []):
		var text: String = BattleReadout.event_line(event)
		if text.is_empty(): continue
		number += 1
		list.add_child(ui.paragraph("%d. %s" % [number, text], 21, UI.FIRE if event.actor_side == "enemy" else UI.PAPER))
	_button(body, "VOLTAR", _pop, "history.back", "history", true)
	_register(scroll, "history.content", "history")

func _plan_target(index: int, slot: int) -> void:
	if game.set_target(index, slot):
		targeting_index = index
		_sync_selection()

func _remove_command(kind: String, id: int) -> void:
	match kind:
		"power": game.toggle(id)
		"swap": game.cancel_swap(id)
		"item": game.cancel_item(id)
	_sync_selection()
	_on_screen_changed()

func _clear_plan() -> void:
	if busy: return
	game.clear_plan()
	targeting_index = -1
	_sync_selection()
	if screens.top() == "plan": _on_screen_changed()

func _cycle_target(direction: int) -> void:
	if busy or not targeting_index in game.selected: return
	var options: Array[int] = game.target_options(targeting_index)
	if options.size() < 2: return
	var current: int = options.find(int(game.hand[targeting_index].get("target_slot", -1)))
	if game.set_target(targeting_index, options[posmod(current + direction, options.size())]): audio.play("select", true)

func _open_reserve(index: int) -> void:
	if busy or screens.top() != "battle": return
	var reserves: Array = game.reserves()
	if index < 0 or index >= reserves.size() or int(reserves[index].hp) <= 0: return
	reserve_uid = int(reserves[index].uid)
	_push("swap")

func _swap_choices() -> void:
	var entrant: Dictionary = game.umbral_by_uid(reserve_uid)
	var body: VBoxContainer = _modal_frame("Trazer " + Content.display_name(entrant), "Custa 1 ação. A troca só ocorre ao Conjurar; o substituto recebe ataques destinados à vaga.", 1000)
	var row: HBoxContainer = UI.row(14)
	body.add_child(row)
	for slot in range(3):
		var occupant: Dictionary = _at_slot("ally", slot)
		var label: String = ["SUPERIOR", "CENTRAL", "INFERIOR"][slot]
		label += "\n" + (Content.display_name(occupant) if not occupant.is_empty() else "Vaga vazia")
		var choice: Button = _button(row, label, _queue_swap.bind(slot), "swap.slot.%d" % slot, "swap", true)
		choice.custom_minimum_size = Vector2(280, 100)
		choice.tooltip_text = game.swap_reason(slot, reserve_uid)
		choice.disabled = not choice.tooltip_text.is_empty()
	for queued in game.queued_swaps:
		_button(body, "CANCELAR TROCA · " + ["SUPERIOR", "CENTRAL", "INFERIOR"][int(queued.slot)], _cancel_swap.bind(int(queued.slot)), "swap.cancel.%d" % int(queued.slot), "swap")
	body.add_child(ui.paragraph("As cartas de quem entra participam da próxima compra normal. Planejar e cancelar não altera o campo nem compra cartas.", 20))
	_button(body, "VOLTAR", _pop, "swap.back", "swap")

func _queue_swap(slot: int) -> void:
	var occupant: Dictionary = _at_slot("ally", slot)
	var accepted: bool = game.queue_deploy(slot, reserve_uid) if occupant.is_empty() else game.queue_swap(int(occupant.uid), reserve_uid)
	if accepted:
		_pop()
		_sync_battle()
	else: notice_label.text = "Não foi possível planejar essa troca. Confira ações e outras trocas."

func _cancel_swap(slot: int) -> void:
	game.cancel_swap(slot)
	_on_screen_changed()
	_sync_battle()

func _open_formation() -> void:
	if busy: return
	formation_draft = [-1, -1, -1]
	for individual in game.party:
		if int(individual.get("slot", -1)) >= 0: formation_draft[int(individual.slot)] = int(individual.uid)
	_push("formation")

func _formation_choices() -> void:
	var body: VBoxContainer = _modal_frame("Sua formação", "Entre clareiras, escolha de 1 a 3 ativos. Vagas vazias são permitidas; o restante fica na reserva.", 1340)
	for slot in range(3):
		var row: HBoxContainer = UI.row(8)
		body.add_child(row)
		var label: Label = ui.label(["SUPERIOR", "CENTRAL", "INFERIOR"][slot], 17, UI.GOLD)
		label.custom_minimum_size.x = 112
		row.add_child(label)
		for i in range(game.party.size()):
			var individual: Dictionary = game.party[i]
			var choice: Button = _button(row, ("✓ " if int(formation_draft[slot]) == int(individual.uid) else "") + Content.display_name(individual), _draft_formation.bind(slot, int(individual.uid)), "formation.%d.%d" % [slot, i], "formation")
			choice.custom_minimum_size.x = 125
			choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			choice.disabled = int(individual.hp) <= 0
			choice.add_theme_font_size_override("font_size", 17)
		_button(row, "VAZIO", _draft_formation.bind(slot, -1), "formation.clear.%d" % slot, "formation").add_theme_font_size_override("font_size", 16)
	var confirm: Button = _button(body, "CONFIRMAR FORMAÇÃO", _commit_formation, "formation.confirm", "formation", true)
	confirm.disabled = formation_draft == [-1, -1, -1]
	_button(body, "VOLTAR", _pop, "formation.back", "formation")

func _draft_formation(slot: int, uid: int) -> void:
	for i in range(3):
		if int(formation_draft[i]) == uid: formation_draft[i] = -1
	formation_draft[slot] = uid
	_on_screen_changed()

func _commit_formation() -> void:
	if game.set_formation(formation_draft):
		_pop()
		targeting_index = -1
		_checkpoint_expedition()
		if screens.root() == "map": _on_screen_changed()
		else: _sync_battle()

func _pouch() -> void:
	var frame: VBoxContainer = _modal_frame("Mochila", "Itens ficam fora do baralho. Cada uso custa 1 ação e resolve apenas ao Conjurar.", 1050)
	frame.add_child(ui.label("%d poção(ões) · %d reanimação(ões)" % [int(game.inventory.get("potion", 0)), int(game.inventory.get("revive", 0))], 22, UI.GOLD))
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = minf(360, size.y - 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	frame.add_child(scroll)
	var body: VBoxContainer = UI.column(12)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	for i in range(game.party.size()):
		var individual: Dictionary = game.party[i]
		var row: HBoxContainer = UI.row(12)
		body.add_child(row)
		var label: Label = ui.label("%s · %d/%d HP" % [Content.display_name(individual), int(individual.hp), int(individual.max_hp)], 20)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var heal: Button = _button(row, "POÇÃO", _queue_item.bind("potion", int(individual.uid)), "pouch.potion.%d" % i, "pouch")
		heal.tooltip_text = game.item_reason("potion", int(individual.uid))
		heal.disabled = not heal.tooltip_text.is_empty()
		var revive: Button = _button(row, "REANIMAR", _queue_item.bind("revive", int(individual.uid)), "pouch.revive.%d" % i, "pouch")
		revive.tooltip_text = game.item_reason("revive", int(individual.uid))
		revive.disabled = not revive.tooltip_text.is_empty()
	for i in range(game.queued_items.size()):
		_button(body, "CANCELAR ITEM %d" % (i + 1), _cancel_item.bind(i), "pouch.cancel.%d" % i, "pouch")
	body.add_child(ui.paragraph("Reanimar devolve HP agora. Se estiver em campo, os poderes ficam disponíveis na próxima rodada. Reservas continuam fora do baralho; não há compra extra.", 18))
	_button(frame, "VOLTAR", _pop, "pouch.back", "pouch", true)

func _queue_item(item: String, uid: int) -> void:
	if busy: return
	if game.queue_item(item, uid):
		_pop()
		_sync_battle()

func _cancel_item(index: int) -> void:
	game.cancel_item(index)
	_on_screen_changed()
	_sync_battle()

func _ko_replacement() -> void:
	var body: VBoxContainer = _modal_frame("O próximo eco", "A fila de ações terminou. Reponha vagas incapacitadas gratuitamente ou mantenha menos ativos.", 1150)
	var reserves: Array = game.reserves()
	for slot in range(3):
		var occupant: Dictionary = _at_slot("ally", slot)
		if occupant.is_empty() or int(occupant.hp) > 0: continue
		body.add_child(ui.label("Vaga " + ["superior", "central", "inferior"][slot] + " · " + Content.display_name(occupant), 23, UI.GOLD))
		var row: HBoxContainer = UI.row(10)
		body.add_child(row)
		for i in range(reserves.size()):
			var choice: Button = _button(row, Content.display_name(reserves[i]), _replace_ko.bind(slot, int(reserves[i].uid)), "ko.%d.%d" % [slot, i], "ko_replacement", true)
			choice.disabled = int(reserves[i].hp) <= 0
	body.add_child(ui.paragraph("Cartas dos incapacitados continuam bloqueadas. Continuar dispensa novas perguntas sobre esse nocaute; trazer alguém depois custa 1 ação. Um novo nocaute reabre a oferta gratuita.", 20))
	var able: int = game.active_party(true).size()
	if able == 0: body.add_child(ui.paragraph("Escolha ao menos um Umbral apto para continuar. Essa reposição não gasta ações.", 20, UI.GOLD))
	var next: Button = _button(body, "CONTINUAR COM %d ATIVO(S)" % able, _finish_ko, "ko.finish", "ko_replacement", true)
	next.disabled = able == 0

func _replace_ko(slot: int, uid: int) -> void:
	if game.replace_after_ko(slot, uid):
		_checkpoint_expedition()
		_sync_battle()
		_on_screen_changed()

func _finish_ko() -> void:
	if game.finish_replacements():
		_checkpoint_expedition()
		screens.reset("battle")
		_sync_battle()

func _rewards() -> void:
	var body: VBoxContainer = _modal_frame("Um novo eco responde.", "Capture e escolha Campo ou Reserva, ou evolua um aliado.", 1440)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = minf(500, size.y - 340)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	body.add_child(scroll)
	var row: HBoxContainer = UI.row(16)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(row)
	for i in range(game.reward_offers.size()):
		var offer: Dictionary = game.reward_offers[i]
		var evolved: bool = offer.kind == "evolve"
		var original: Dictionary = game.umbral_by_uid(int(offer.uid)) if evolved else offer.umbral
		var candidate: Dictionary = original.duplicate(true)
		if evolved: candidate.stage = 2
		var species: Dictionary = Content.SPECIES[candidate.species]
		var panel = PanelContainer.new()
		panel.custom_minimum_size.x = 360
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", ui.style(Color("15292c"), Color(species.color), 16))
		row.add_child(panel)
		var column: VBoxContainer = UI.column(8)
		panel.add_child(column)
		column.add_child(ui.label("EVOLUÇÃO" if evolved else "NOVA ALIANÇA", 18, Color(species.color), false, true))
		column.add_child(UI.art(species.art[int(candidate.stage) - 1], Vector2(120, 96)))
		column.add_child(ui.label(Content.display_name(candidate), 28, Color(species.color), true, true))
		column.add_child(ui.paragraph(species.trait + "\n" + Content.trait_text(candidate), 19, UI.PAPER))
		column.add_child(ui.label("Instinto: " + Content.PASSIVES[candidate.passive].name, 22, UI.GOLD))
		column.add_child(ui.paragraph(Content.PASSIVES[candidate.passive].description, 18))
		column.add_child(ui.paragraph("Melhora atributos e poderes conhecidos; preserva as cópias." if evolved else "Escolha uma vaga livre ou a reserva; seis cartas próprias.", 18, UI.GOLD if evolved else UI.MUTED))
		_button(column, "DESPERTAR" if evolved else "CAPTURAR", _take_reward.bind(i), "reward.%d" % i, "reward", true)
	body.add_child(ui.paragraph("Capturar no campo entre encontros não custa ações. Manter na reserva preserva um time menor; trazê-la durante a batalha custa 1 ação.", 19))
	var controls: HBoxContainer = UI.row(12)
	body.add_child(controls)
	_button(controls, "AJUSTAR FORMAÇÃO ATUAL", _open_formation, "reward.formation", "reward")
	_button(controls, "REVER ÚLTIMA RODADA", _open_history, "reward.history", "reward")

func _take_reward(index: int) -> void:
	if game.reward_offers[index].kind == "capture":
		if game.party.size() >= Rules.MAX_TEAM:
			replacement_index = index
			_push("replacement")
		else:
			_choose_capture_destination(index)
		return
	_accept_reward(index)

func _choose_capture_destination(index: int, outgoing_uid: int = -1) -> void:
	capture_index = index
	capture_replace_uid = outgoing_uid
	capture_slot = -1
	var outgoing: Dictionary = game.umbral_by_uid(outgoing_uid)
	if int(outgoing.get("slot", -1)) >= 0: capture_slot = int(outgoing.slot)
	else:
		for slot in game.capture_destinations(index, outgoing_uid):
			if slot >= 0:
				capture_slot = slot
				break
	_push("capture_destination")

func _capture_destination() -> void:
	var candidate: Dictionary = game.reward_offers[capture_index].umbral
	var body: VBoxContainer = _modal_frame("Onde %s vai lutar?" % Content.display_name(candidate), "Escolha o destino para o próximo encontro. A captura só acontece ao confirmar.", 1040)
	var options: Array[int] = game.capture_destinations(capture_index, capture_replace_uid)
	if capture_replace_uid >= 0: body.add_child(ui.paragraph("Ao confirmar, libera " + Content.display_name(game.umbral_by_uid(capture_replace_uid)) + ". Voltar mantém seu time.", 20, UI.FIRE))
	var row: HBoxContainer = UI.row(12)
	body.add_child(row)
	for slot in range(Rules.MAX_ACTIVE):
		var occupant: Dictionary = _at_slot("ally", slot)
		var label: String = Targeting.SLOT_NAMES[slot].to_upper() + "\n" + ("Vaga livre" if occupant.is_empty() else Content.display_name(occupant))
		if not occupant.is_empty() and int(occupant.uid) == capture_replace_uid: label += " · saída escolhida"
		var choice: Button = _button(row, ("✓ " if capture_slot == slot else "") + label, _select_capture_slot.bind(slot), "capture.slot.%d" % slot, "capture_destination")
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.custom_minimum_size.y = 82
		choice.disabled = not slot in options
	var reserve: Button = _button(body, ("✓ " if capture_slot == -1 else "") + "MANTER NA RESERVA", _select_capture_slot.bind(-1), "capture.reserve", "capture_destination")
	reserve.disabled = not -1 in options
	body.add_child(ui.paragraph("No campo: os poderes entram no baralho inicial, misturados com os demais. Na reserva: ficam fora do ciclo até você trazer esse Umbral.", 21))
	var destination: String = "RESERVA" if capture_slot < 0 else "CAMPO · " + Targeting.SLOT_NAMES[capture_slot].to_upper()
	_button(body, "CAPTURAR → " + destination, _accept_reward.bind(capture_index, capture_replace_uid, capture_slot), "capture.confirm", "capture_destination", true)
	_button(body, "VOLTAR", _pop, "capture.back", "capture_destination")

func _select_capture_slot(slot: int) -> void:
	if not slot in game.capture_destinations(capture_index, capture_replace_uid): return
	capture_slot = slot
	focus_memory["capture_destination"] = "capture.reserve" if slot < 0 else "capture.slot.%d" % slot
	_on_screen_changed()

func _accept_reward(index: int, replace_uid: int = -1, destination: int = -2) -> void:
	var offer: Dictionary = game.reward_offers[index].duplicate(true)
	var evolved: bool = offer.kind == "evolve"
	var accepted: bool = expedition.choose_reward(index, replace_uid, destination) if expedition_active else game.choose_reward(index, replace_uid, destination)
	if not accepted: return
	replacement_index = -1
	capture_index = -1
	capture_replace_uid = -1
	if expedition_active:
		_checkpoint_expedition()
		screens.reset("map")
		audio.play("evolve" if evolved else "capture")
		_log("reward_chosen", {"kind": offer.kind, "replacement": replace_uid, "party": game.party})
		return
	_sync_battle()
	screens.reset("battle")
	audio.play("evolve" if evolved else "capture")
	var individual: Dictionary = game.umbral_by_uid(int(offer.uid)) if evolved else offer.umbral
	_float_text(Content.display_name(individual).to_upper() + (" DESPERTA" if evolved else " SE JUNTOU"), size * Vector2(0.5, 0.25), UI.GOLD, 36)
	for actor in actors:
		if not actor.identity.is_empty() and int(actor.identity.uid) == int(individual.uid):
			effects.burst(actor.get_global_rect().get_center(), Color(Content.SPECIES[individual.species].color), 32)
	_log("reward_chosen", {"kind": offer.kind, "replacement": replace_uid, "party": game.party})
	_queue_debug()

func _replacement() -> void:
	var offered: Dictionary = game.reward_offers[replacement_index].umbral
	var body: VBoxContainer = _modal_frame("Quem abre espaço?", "O novo %s tem %s. Escolha quem sai; depois escolha Campo ou Reserva. Nada muda antes de confirmar a captura." % [Content.display_name(offered), Content.PASSIVES[offered.passive].name], 1230)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = minf(390, size.y - 340)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	body.add_child(scroll)
	var grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)
	for i in range(game.party.size()):
		var umbral: Dictionary = game.party[i]
		var column: VBoxContainer = UI.column(12)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(column)
		column.add_child(UI.art(Content.SPECIES[umbral.species].art[int(umbral.stage) - 1], Vector2(96, 72)))
		column.add_child(ui.label(Content.display_name(umbral), 24, Color(Content.SPECIES[umbral.species].color), true, true))
		column.add_child(ui.label("%s · %d/%d HP · %s" % [Content.PASSIVES[umbral.passive].name, int(umbral.hp), int(umbral.max_hp), "reserva" if int(umbral.slot) < 0 else Targeting.SLOT_NAMES[int(umbral.slot)]], 16, UI.MUTED, false, true))
		_button(column, "ESCOLHER SAÍDA", _choose_capture_destination.bind(replacement_index, int(umbral.uid)), "replace.%d" % i, "replacement", true)
	_button(body, "MANTER MEU TIME", _pop, "replacement.back", "replacement")

func _ending() -> void:
	var won: bool = game.phase == "victory"
	var body: VBoxContainer = _modal_frame("A aurora tem seus nomes." if won else "Ainda existem outros ecos.", "Expedição concluída." if won else "Combine proteção, cura e queimadura para encontrar outro caminho.", 1050)
	body.add_child(UI.art(Content.SPECIES[game.party[0].species].art[int(game.party[0].stage) - 1] if won else "characters/stag", Vector2(240, 180)))
	body.add_child(ui.label("%d DANO  ·  %d UMBRALS  ·  SEMENTE %d" % [game.total_damage, game.party.size(), game.seed_value], 23, UI.GOLD, false, true))
	_button(body, "REVER ÚLTIMA RODADA", _open_history, "result.history", screens.top())
	_button(body, "NOVA EXPEDIÇÃO", _new_seed, "result.new", screens.top(), true)
	_button(body, "REPETIR ESTA SEMENTE", _retry_seed, "result.retry", screens.top())
	_button(body, "VOLTAR AO TÍTULO", _return_menu, "result.menu", screens.top())

func _retry_seed() -> void:
	if expedition_active: _start_expedition(game.seed_value, game.starter_species)
	else: _start_game(game.seed_value, game.starter_species)

func _set_group(screen: String) -> void:
	var group: Array = []
	for key in registry:
		var control = registry[key]
		if is_instance_valid(control) and control.is_inside_tree() and control.get_meta("ui_screen", "") == screen and control.is_visible_in_tree():
			if control.focus_mode == Control.FOCUS_NONE or (control is BaseButton and control.disabled): continue
			group.append(control)
	focus_groups[screen] = group
	UI.focus_chain(group, screen in ["battle", "reward", "replacement"])

func _focus(key: String, screen: String) -> void:
	if registry.has(key) and is_instance_valid(registry[key]) and registry[key].is_visible_in_tree():
		var target: Control = registry[key]
		if not (target is BaseButton and target.disabled):
			target.grab_focus()
			_queue_debug()
			return
	var group: Array = focus_groups.get(screen, [])
	if not group.is_empty():
		var target: Control = group[0]
		if screen == "battle":
			for card in cards:
				if is_instance_valid(card) and card.is_visible_in_tree() and not card.disabled:
					target = card
					break
		if is_instance_valid(target): target.grab_focus()
	_queue_debug()

func _return_menu() -> void:
	epoch += 1
	busy = false
	session_active = false
	if is_instance_valid(effects): effects.clear()
	audio.set_boss(false)
	_refresh_checkpoint()
	_update_continue_button()
	_update_menu_stats()
	screens.reset("menu")

func _new_seed() -> void:
	var value: int = int(Time.get_unix_time_from_system() * 1000) % 1000000
	if value == game.seed_value: value += 1
	_choose_starter(value)

func _quit() -> void:
	if not is_instance_valid(audio) or audio.shutting_down: return
	audio.shutdown()
	audio.queue_free()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()

func _on_preferences_changed() -> void:
	audio.apply(preferences.values)
	world.still = visual_capture or preferences.values.reduced_motion
	if is_instance_valid(effects): effects.reduced_motion = preferences.values.reduced_motion
	if preferences.values.reduced_motion and is_instance_valid(effects): effects.clear()
	if session_active: game.set_information_mode(str(preferences.values.information_mode))
	if expedition_active and not busy: _checkpoint_expedition()
	for actor in actors + enemy_actors: actor.reduced_motion = preferences.values.reduced_motion
	for card in cards:
		card.reduced_motion = preferences.values.reduced_motion
		card._react()
	_sync_text_scale()
	_queue_debug()

func _sync_text_scale() -> void:
	# The rule model already advanced; never rebuild the displayed committed hand
	# against that model while its snapshots are still being animated.
	if busy: return
	if not is_equal_approx(header_text_scale, preferences.text_scale()):
		var focused: Control = get_viewport().gui_get_focus_owner()
		var key: String = focused.get_meta("ui_id", "") if is_instance_valid(focused) else ""
		header_text_scale = preferences.text_scale()
		ui.text_scale = header_text_scale
		theme = ui.make_theme()
		remove_child(menu_root)
		menu_root.queue_free()
		_build_menu()
		if is_instance_valid(battle_root):
			remove_child(battle_root)
			battle_root.queue_free()
			battle_root = null
			cards.clear()
			actors.clear()
			enemy_actors.clear()
			reserve_buttons.clear()
			hand_fingerprint = ""
			_build_battle()
		focus_memory[screens.top()] = key
		_on_screen_changed()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo: return
	if event is InputEventJoypadMotion and absf(event.axis_value) < 0.25: return
	if browser_test and event.is_pressed():
		input_serial += 1
		_queue_debug()
	var device: String = "gamepad" if event is InputEventJoypadButton or event is InputEventJoypadMotion else "keyboard" if event is InputEventKey else "mouse" if event is InputEventMouseButton else last_device
	if device != last_device:
		last_device = device
		if session_active: _sync_selection()
	if event.is_action_pressed("umbral_back"):
		if screens.top() == "ko_replacement":
			_finish_ko()
			get_viewport().set_input_as_handled()
			return
		if screens.top() in ["battle", "map"]: _push("pause")
		elif screens.top() in ["victory", "defeat"]: _return_menu()
		elif screens.top() != "menu": _pop()
		get_viewport().set_input_as_handled()
		return
	if screens.top() != "battle": return
	for i in range(6):
		if event.is_action_pressed("umbral_card_%d" % i):
			_select(i)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("umbral_cast"):
		_cast()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("umbral_redraw"):
		_redraw()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("umbral_plan"):
		_open_plan()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("umbral_clear"):
		_clear_plan()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("umbral_target_previous") or event.is_action_pressed("umbral_target_next"):
		_cycle_target(1 if event.is_action_pressed("umbral_target_next") else -1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("umbral_inspect"):
		_inspect_focused()
		get_viewport().set_input_as_handled()

func _layout_changed() -> void:
	_queue_debug()

func _queue_debug() -> void:
	if browser_test and not debug_queued:
		debug_queued = true
		call_deferred("_publish_test_state")

func _publish_test_state() -> void:
	debug_queued = false
	if not browser_test: return
	var controls: Dictionary = {}
	for key in registry:
		var control = registry[key]
		if not is_instance_valid(control) or not control.is_inside_tree(): continue
		var center: Vector2 = control.get_global_transform() * (control.size * 0.5)
		var rect: Rect2 = control.get_global_rect()
		var data: Dictionary = {"x": rect.position.x, "y": rect.position.y, "w": control.size.x, "h": control.size.y, "cx": center.x, "cy": center.y, "visible": control.is_visible_in_tree(), "active": control.get_meta("ui_screen", "") == screens.top(), "disabled": control.disabled if control is BaseButton else false, "focused": control.has_focus()}
		if control is BaseButton: data["text"] = control.text
		data["instance_id"] = control.get_instance_id()
		if control is PowerCard:
			data["nature"] = control.power.nature
			data["effect_text"] = control.tooltip_text
			data["title_fits"] = control.title_fits()
			data["reduced_motion"] = control.reduced_motion
			data["card_instance"] = control.card.get("instance_id", "")
			data["chosen"] = control.chosen
			data["blocked"] = control.blocked
		if control is Button and not control is PowerCard and not control is Actor:
			var style: StyleBox = control.get_theme_stylebox("normal", "Button")
			if style is StyleBoxFlat and style.bg_color.a >= 0.95 and not control.disabled:
				var foreground: Color = control.get_theme_color("font_focus_color" if control.has_focus() else "font_color", "Button")
				data["foreground"] = [foreground.r, foreground.g, foreground.b]
				data["background"] = [style.bg_color.r, style.bg_color.g, style.bg_color.b]
		if control is Range: data["value"] = control.value
		if control is CheckButton: data["checked"] = control.button_pressed
		controls[key] = data
	var focus: Control = get_viewport().gui_get_focus_owner()
	published_revision += 1
	var party_public: Array = []
	var enemies_public: Array = []
	for individual in game.party: party_public.append(_public_individual(individual))
	for individual in game.enemies: enemies_public.append(_public_individual(individual))
	var state: Dictionary = {"version": Content.VERSION, "revision": published_revision, "screen": screens.top(), "stack": screens.entries, "busy": busy, "phase": game.phase if session_active else "menu", "hand": game.hand if session_active else [], "deck": game.deck, "discard": game.discard_pile, "party": party_public, "enemies": enemies_public, "selected": game.selected, "targeting_index": targeting_index, "planned_actions": game.planned_actions(), "hp": game.player_hp, "enemy_hp": game.enemy_hp, "plays": game.plays, "actions": game.actions, "encounter": game.encounter, "round_number": game.round_number, "action_budget": game.action_budget(), "hand_capacity": game.hand_capacity(), "queued_swaps": game.queued_swaps, "queued_items": game.queued_items, "inventory": game.inventory, "intents": game.public_intents(), "information_mode": game.information_mode, "pending_information_mode": game.pending_information_mode, "stats": stats, "offers": game.reward_offers, "preview": game.preview(), "preferences": preferences.values, "focused": focus.get_meta("ui_id", "") if is_instance_valid(focus) else "", "controls": controls, "logical_size": [size.x, size.y], "device": last_device, "feedback": {"hits": effects.hits if is_instance_valid(effects) else 0, "flights": effects.flights if is_instance_valid(effects) else 0, "bursts": effects.bursts if is_instance_valid(effects) else 0, "trauma": effects.trauma if is_instance_valid(effects) else 0, "particles": effects.particles.size() if is_instance_valid(effects) else 0, "rejected_busy_casts": rejected_busy_casts}}

	state["expedition"] = expedition.public_state() if expedition_active else {}
	state["checkpoint_status"] = run_save.last_status
	state["resolved_reactions"] = [] if busy else game.last_result.get("events", []).filter(func(event: Dictionary) -> bool: return event.kind == "reaction")
	state["overlay_z"] = modal_root.z_index if is_instance_valid(modal_root) else 0
	state["card_max_z"] = 6
	state["audio"] = {"voice_pool": audio.voices.size(), "music_muted": AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "music_db": AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))}
	state["node_count"] = get_tree().get_node_count()
	state["input_serial"] = input_serial
	state["interaction_serial"] = interaction_serial
	state["last_interaction"] = last_interaction
	JavaScriptBridge.eval("window.umbralState = " + JSON.stringify(state), true)

func _public_individual(individual: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in ["uid", "species", "passive", "stage", "name", "art", "hp", "max_hp", "attack", "defense", "speed", "block", "statuses", "status_sources", "resistances", "slot", "can_act_round"]:
		if individual.has(key): result[key] = individual[key].duplicate(true) if individual[key] is Dictionary or individual[key] is Array else individual[key]
	return result

func _log(event_name: String, details: Dictionary) -> void:
	var entry: Dictionary = {"event": event_name, "version": Content.VERSION, "seed": game.seed_value, "action": game.actions}
	entry.merge(details)
	print(JSON.stringify(entry))

func _bind_game(next_game: RefCounted) -> void:
	if game.state_changed.is_connected(_on_rule_changed): game.state_changed.disconnect(_on_rule_changed)
	game = next_game
	game.state_changed.connect(_on_rule_changed)

func _refresh_checkpoint() -> void:
	saved_checkpoint = run_save.load_snapshot()
	if not saved_checkpoint.is_empty():
		var candidate = Expedition.new()
		if not candidate.restore(saved_checkpoint):
			saved_checkpoint = {}
			save_notice = "O progresso salvo não pôde ser lido. Você pode iniciar uma nova expedição."
			run_save.last_status = "corrupt"
		elif str(saved_checkpoint.get("checkpoint_id", "")) in persisted_expeditions:
			saved_checkpoint = {}
			save_notice = "Esta expedição já foi encerrada. Comece um novo vínculo."
			run_save.clear()
		elif run_save.last_status == "recovered": save_notice = "Recuperamos o último progresso válido da expedição."
	elif run_save.last_status in ["corrupt", "io_error"]:
		save_notice = "Não foi possível ler o progresso salvo. Verifique o armazenamento do navegador ou inicie uma nova expedição."

func _update_continue_button() -> void:
	if is_instance_valid(continue_button): continue_button.disabled = saved_checkpoint.is_empty()
	if is_instance_valid(menu_notice): menu_notice.text = save_notice if not save_notice.is_empty() else "Escolha sua rota. Preserve seus vínculos."

func _checkpoint_expedition() -> void:
	if not expedition_active: return
	expedition.settle_battle()
	if expedition.phase in ["victory", "defeat"]:
		_record_result()
		if result_recorded:
			if not checkpoint_writable:
				save_notice = "Resultado salvo. Esta expedição foi jogada sem substituir o progresso anterior."
				return
			if run_save.clear():
				saved_checkpoint = {}
				save_notice = "Expedição encerrada. Seus resultados foram salvos."
			else:
				# Preserve the terminal state if clearing is blocked by a bad backup.
				var terminal: Dictionary = expedition.snapshot()
				terminal["checkpoint_id"] = checkpoint_id
				if run_save.save(terminal): save_notice = "Resultado salvo. O registro de conclusão será limpo ao voltar ao título."
				else: save_notice = "Resultado salvo. Não foi possível atualizar o progresso antigo; essa expedição concluída não poderá ser retomada."
			return
	if not checkpoint_writable:
		save_notice = "Não foi possível substituir o progresso anterior. Esta nova expedição não será salva; o registro anterior foi preservado."
		return
	var checkpoint: Dictionary = expedition.snapshot()
	checkpoint["checkpoint_id"] = checkpoint_id
	if run_save.save(checkpoint):
		saved_checkpoint = checkpoint
		save_notice = "Progresso salvo · você pode continuar pelo título."
	else:
		save_notice = "Não foi possível salvar. Você pode jogar, mas este avanço pode ser perdido ao fechar."
	_update_continue_button()

func _start_expedition(value: int = 42013, starter: String = "ember") -> void:
	var previous: Dictionary = run_save.load_snapshot()
	checkpoint_writable = true
	if not previous.is_empty() or run_save.last_status in ["corrupt", "io_error"]:
		# Explicitly replacing a run must retire its recovery copy as well.
		checkpoint_writable = run_save.clear()
	epoch += 1
	busy = false
	expedition_active = true
	starter_practice = false
	session_active = true
	result_recorded = false
	result_counted_in_memory = false
	map_selection = ""
	replacement_index = -1
	capture_index = -1
	targeting_index = -1
	seed_number = value
	checkpoint_id = "%d-%d-%d" % [value, int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	expedition.new_run(value, str(preferences.values.information_mode), starter)
	_bind_game(expedition.battle)
	hand_fingerprint = ""
	if is_instance_valid(effects): effects.clear()
	_checkpoint_expedition()
	screens.reset("map")
	_log("expedition_started", {"party": game.party})

func _continue_expedition() -> void:
	_refresh_checkpoint()
	if saved_checkpoint.is_empty():
		_update_continue_button()
		return
	var candidate = Expedition.new()
	if not candidate.restore(saved_checkpoint): return
	epoch += 1
	busy = false
	expedition = candidate
	checkpoint_writable = true
	expedition_active = true
	starter_practice = false
	session_active = true
	result_recorded = false
	result_counted_in_memory = false
	map_selection = ""
	checkpoint_id = str(saved_checkpoint.get("checkpoint_id", "legacy-" + str(candidate.battle.seed_value)))
	_bind_game(expedition.battle)
	seed_number = game.seed_value
	hand_fingerprint = ""
	targeting_index = -1
	if is_instance_valid(effects): effects.clear()
	expedition.settle_battle()
	if expedition.phase == "map": screens.reset("map")
	else:
		if not is_instance_valid(battle_root): _build_battle()
		else: _sync_battle()
		if expedition.phase in ["victory", "defeat"]: _checkpoint_expedition()
		screens.reset("battle")
	_log("expedition_continued", {"node": expedition.current_node_id})

func _build_map() -> void:
	if is_instance_valid(map_root):
		map_root.hide()
		map_root.queue_free()
	map_root = ExpeditionMap.new()
	map_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_root.offset_left = 30
	map_root.offset_right = -30
	map_root.offset_top = 24
	map_root.offset_bottom = -24
	map_root.control_created.connect(func(control: Control, id: String): _register(control, id, "map"))
	map_root.node_requested.connect(_enter_node)
	map_root.pause_requested.connect(_push.bind("pause"))
	map_root.selection_changed.connect(func(id: String): map_selection = id)
	if map_root.has_signal("formation_requested"): map_root.formation_requested.connect(_open_formation)
	var snapshot: Dictionary = expedition.public_state()
	snapshot["save_notice"] = save_notice
	map_root.populate(snapshot, preferences.text_scale(), map_selection)
	_full(map_root, self)
	map_root.offset_left = 30
	map_root.offset_right = -30
	map_root.offset_top = 24
	map_root.offset_bottom = -24

func _enter_node(id: String) -> void:
	if busy or screens.top() != "map" or not expedition_active: return
	if not expedition.choose_node(id): return
	_checkpoint_expedition()
	if expedition.phase == "map":
		save_notice = "Nascente visitada: aliados vivos recuperaram até 25% do HP máximo. " + save_notice
		_on_screen_changed()
	else:
		hand_fingerprint = ""
		targeting_index = -1
		if not is_instance_valid(battle_root): _build_battle()
		else: _sync_battle()
		screens.reset("battle")
		audio.play("draw")
	_log("node_entered", {"node": id})

func _load_stats() -> void:
	var data: Dictionary = Storage.read_json(SAVE_PATH, WEB_STATS_KEY, LEGACY_SAVE_PATH)
	if data is Dictionary:
		for key in stats:
			if data.get(key) is float or data.get(key) is int: stats[key] = maxi(0, int(data[key]))
		if data.get("completed_expeditions") is Array:
			for id in data.completed_expeditions:
				if id is String and not id in recorded_expeditions: recorded_expeditions.append(id)
			while recorded_expeditions.size() > 128: recorded_expeditions.pop_front()
	persisted_expeditions.assign(recorded_expeditions)

func _record_result() -> void:
	if result_recorded: return
	var already_counted: bool = expedition_active and not checkpoint_id.is_empty() and checkpoint_id in recorded_expeditions
	if not already_counted and not result_counted_in_memory:
		result_counted_in_memory = true
		stats.runs = int(stats.runs) + 1
		if game.phase == "victory": stats.wins = int(stats.wins) + 1
		stats.best_damage = maxi(int(stats.best_damage), game.total_damage)
		if expedition_active:
			recorded_expeditions.append(checkpoint_id)
			while recorded_expeditions.size() > 128: recorded_expeditions.pop_front()
	var data: Dictionary = stats.duplicate()
	data["completed_expeditions"] = recorded_expeditions
	result_recorded = Storage.write_json(SAVE_PATH, WEB_STATS_KEY, data)
	if result_recorded: persisted_expeditions.assign(recorded_expeditions)
	if not result_recorded:
		save_notice = "Não foi possível salvar o resultado desta expedição."
		push_warning("Could not persist run statistics.")
	_log("run_finished", {"outcome": game.phase, "damage": game.total_damage})

func _update_menu_stats() -> void:
	menu_stats.text = "%d vitórias  ·  %d expedições  ·  novos instintos a cada semente" % [stats.wins, stats.runs]
