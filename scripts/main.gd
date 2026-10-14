extends Control
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
const Vitals = preload("res://scripts/ui/vitals.gd")
const PowerCard = preload("res://scripts/ui/power_card.gd")
const Hand = preload("res://scripts/ui/hand.gd")
const Effects = preload("res://scripts/ui/effects.gd")
const Audio = preload("res://scripts/ui/audio.gd")
const SAVE_PATH = "user://umbral_stats_v1.json"
const LEGACY_SAVE_PATH = "user://feral_hand_stats.json"
const WEB_STATS_KEY = "umbral.stats.v1"

var game = Rules.new()
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
var enemy_art: TextureRect
var enemy_name: Label
var enemy_intent: Label
var burn_label: Label
var player_vitals: Control
var enemy_vitals: Control
var progress_label: Label
var round_label: Label
var preview_label: Label
var notice_label: Label
var energy_label: Label
var cast_button: Button
var redraw_button: Button
var hand_view: Container
var menu_stats: Label
var cards: Array = []
var focus_groups: Dictionary = {}
var inspection: Dictionary = {}
var replacement_index: int = -1
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
	node.item_rect_changed.connect(_queue_debug)
	if key.begins_with("hand."):
		var index: int = int(key.get_slice(".", 1))
		node.focus_entered.connect(func(): last_card_index = index)
		node.mouse_entered.connect(func(): last_card_index = index)
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

func _build_menu() -> void:
	menu_root = Control.new()
	menu_root.name = "TitleScreen"
	_full(menu_root, self)
	var column: VBoxContainer = UI.column(14)
	menu_root.add_child(column)
	column.anchor_left = 0.12
	column.anchor_right = 0.12
	column.anchor_top = 0.16
	column.anchor_bottom = 0.86
	column.offset_right = 650
	column.add_child(ui.label("U M B R A L", 78, UI.PAPER, true))
	column.add_child(ui.label("E C O S   D O   B O S Q U E", 22, UI.GOLD))
	var breathing = Control.new()
	breathing.custom_minimum_size.y = 20
	column.add_child(breathing)
	var primary: Button = _button(column, "INICIAR EXPEDIÇÃO", _start_game.bind(42013), "menu.play", "menu", true)
	primary.custom_minimum_size.x = 410
	_button(column, "GRIMÓRIO DOS UMBRALS", _push.bind("codex"), "menu.codex", "menu")
	_button(column, "OPÇÕES", _push.bind("settings"), "menu.settings", "menu")
	_button(column, "COMO JOGAR", _push.bind("help"), "menu.help", "menu")
	_button(column, "CRÉDITOS", _push.bind("credits"), "menu.credits", "menu")
	if not OS.has_feature("web"):
		_button(column, "SAIR", _quit, "menu.quit", "menu")
	column.add_child(ui.paragraph("Três clareiras. Poderes próprios.\nUm vínculo que muda o destino.", 22, UI.MUTED))
	for child in column.get_children():
		if child is Button:
			child.alignment = HORIZONTAL_ALIGNMENT_LEFT
			child.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			child.custom_minimum_size.x = 450
			child.add_theme_font_size_override("font_size", int(24 * preferences.text_scale()))
			if child != primary:
				child.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
				child.add_theme_stylebox_override("hover", ui.style(Color(0.035, 0.07, 0.075, 0.45), Color.TRANSPARENT))
	var hero: TextureRect = UI.art("ignivar", Vector2(390, 390))
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
	battle_root = Control.new()
	battle_root.name = "BattleScreen"
	_full(battle_root, self)
	visual_layer = Control.new()
	visual_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full(visual_layer, battle_root)
	for i in range(3):
		var actor = Actor.new()
		_at(actor, visual_layer, [Vector2(0.19, 0.35), Vector2(0.33, 0.38), Vector2(0.46, 0.34)][i], Vector2(208 if i == 0 else 190, 232 if i == 0 else 214))
		_register(actor, "party.%d" % i, "battle")
		actor.pressed.connect(_inspect_actor.bind(i))
		actors.append(actor)
	enemy_art = TextureRect.new()
	enemy_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	enemy_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_at(enemy_art, visual_layer, Vector2(0.73, 0.42), Vector2(345, 345))
	enemy_art.pivot_offset = Vector2(172.5, 172.5)
	var enemy_column: VBoxContainer = UI.column(7)
	_at(enemy_column, visual_layer, Vector2(0.73, 0.18), Vector2(370, 144))
	enemy_name = ui.label("", 30, UI.PAPER, true, true)
	enemy_column.add_child(enemy_name)
	enemy_vitals = Vitals.new()
	enemy_vitals.tint = UI.GOLD
	enemy_vitals.caption = "ADVERSÁRIO"
	enemy_vitals.custom_minimum_size = Vector2(370, 74)
	enemy_column.add_child(enemy_vitals)
	enemy_intent = ui.label("", 22, UI.FIRE, false, true)
	enemy_column.add_child(enemy_intent)
	burn_label = ui.label("", 20, UI.FIRE, false, true)
	enemy_column.add_child(burn_label)
	effects = Effects.new()
	_full(effects, battle_root)
	effects.visual_layer = visual_layer
	var margin = MarginContainer.new()
	battle_root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.offset_top = 22
	margin.offset_bottom = 106
	_apply_safe_margin(margin)
	var top: HBoxContainer = UI.row(16)
	margin.add_child(top)
	player_vitals = Vitals.new()
	player_vitals.custom_minimum_size = Vector2(260, 80)
	player_vitals.caption = "SEU FÔLEGO"
	top.add_child(player_vitals)
	top.add_child(UI.spacer())
	var route: VBoxContainer = UI.column(4)
	top.add_child(route)
	progress_label = ui.label("", 20, UI.GOLD, false, true)
	route.add_child(progress_label)
	round_label = ui.label("", 20, UI.PAPER, true, true)
	route.add_child(round_label)
	top.add_child(UI.spacer())
	_button(top, "GUIA", _push.bind("help"), "hud.help", "battle")
	_button(top, "Ⅱ  PAUSA", _push.bind("pause"), "hud.pause", "battle")
	var preview_column: VBoxContainer = UI.column(4)
	_at(preview_column, battle_root, Vector2(0.5, 1), Vector2(1150, 74))
	preview_column.offset_top = -454
	preview_column.offset_bottom = -380
	preview_label = ui.label("", 25, UI.PAPER, false, true)
	preview_column.add_child(preview_label)
	notice_label = ui.label("", 20, UI.MUTED, false, true)
	preview_column.add_child(notice_label)
	hand_view = Hand.new()
	_at(hand_view, battle_root, Vector2(0.5, 1), Vector2(1100, 290))
	hand_view.offset_top = -388
	hand_view.offset_bottom = -98
	var actions: HBoxContainer = UI.row(20)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	_at(actions, battle_root, Vector2(0.5, 1), Vector2(1190, 68))
	actions.offset_top = -80
	actions.offset_bottom = -18
	redraw_button = _button(actions, "TROCAR · R", _redraw, "hud.redraw", "battle")
	cast_button = _button(actions, "CONJURAR · ESPAÇO", _cast, "hud.cast", "battle", true)
	cast_button.custom_minimum_size.x = 300
	_button(actions, "INSPECIONAR · C", _inspect_focused, "hud.inspect", "battle")
	energy_label = ui.label("", 23, UI.GOLD)
	actions.add_child(energy_label)
	_sync_battle(false)

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

func _sync_battle(animate: bool = false) -> void:
	if not is_instance_valid(battle_root): return
	var foe: Dictionary = Content.ENCOUNTERS[game.encounter]
	enemy_art.texture = load("res://assets/%s.svg" % foe.art)
	enemy_name.text = foe.name
	enemy_intent.text = "⚔  INTENÇÃO  %d" % game.intent_damage()
	burn_label.text = "♨  QUEIMADURA  %d" % game.enemy_burn if game.enemy_burn else ""
	player_vitals.text_scale = preferences.text_scale()
	enemy_vitals.text_scale = preferences.text_scale()
	player_vitals.update_health(game.player_hp, game.max_hp, -1, animate and not preferences.values.reduced_motion)
	enemy_vitals.update_health(game.enemy_hp, foe.hp, -1, animate and not preferences.values.reduced_motion)
	var route: Array[String] = []
	for i in range(3): route.append("◆" if i <= game.encounter else "◇")
	progress_label.text = "  ─  ".join(route)
	round_label.text = "Clareira %d  ·  Rodada %d/%d" % [game.encounter + 1, mini(Rules.ROUND_BUDGET, Rules.ROUND_BUDGET - game.plays + 1), Rules.ROUND_BUDGET]
	for i in range(3):
		actors[i].set_identity(game.party[i] if i < game.party.size() else {}, preferences.text_scale())
		actors[i].still = visual_capture
		actors[i].reduced_motion = preferences.values.reduced_motion
	effects.reduced_motion = preferences.values.reduced_motion
	audio.set_boss(game.encounter == 2)
	var fingerprint: String = JSON.stringify(game.hand)
	if fingerprint != hand_fingerprint:
		hand_fingerprint = fingerprint
		_rebuild_hand()
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
		card.configure(game.hand[i], game.umbral_by_uid(game.hand[i].owner), game.party, preferences.text_scale(), preferences.values.reduced_motion)
		_register(card, "hand.%d" % i, "battle")
		card.pressed.connect(_select.bind(i))
		cards.append(card)
	hand_view.layout_cards()
	hand_view.queue_sort()

func _sync_selection() -> void:
	if not is_instance_valid(battle_root): return
	var score: Dictionary = game.preview()
	for i in range(cards.size()):
		cards[i].disabled = busy or game.phase != "battle"
		cards[i].set_chosen(i in game.selected)
	cast_button.disabled = busy or not score.valid or game.phase != "battle"
	redraw_button.disabled = busy or game.selected.is_empty() or game.discards <= 0 or game.phase != "battle"
	cast_button.text = "CONJURANDO…" if busy else "CONJURAR · X" if last_device == "gamepad" else "CONJURAR · ESPAÇO"
	redraw_button.text = "TROCAR %d · %s" % [game.discards, "RB" if last_device == "gamepad" else "R"]
	var gems: String = ""
	for i in range(3): gems += "◆" if i < maxi(0, 3 - int(score.energy)) else "◇"
	energy_label.text = "%s %d/3" % [gems, score.energy]
	energy_label.add_theme_color_override("font_color", UI.FIRE if int(score.energy) > 3 else UI.GOLD)
	if game.selected.is_empty():
		preview_label.text = "Escolha seus poderes"
		notice_label.text = "Clique ou use 1–6  ·  Enter seleciona o poder em foco"
		enemy_vitals.predicted = -1
	else:
		preview_label.text = "%d dano  ·  %d escudo  ·  %d cura" % [score.damage, score.block, score.heal]
		if not score.valid:
			notice_label.text = "⚠  Energia insuficiente — retire um poder ou troque a seleção."
		elif int(score.damage) >= game.enemy_hp:
			notice_label.text = "✦  O adversário cairá antes de revidar."
		else:
			var incoming: int = maxi(0, game.intent_damage() - int(score.block))
			var after: int = maxi(0, mini(game.max_hp, game.player_hp + int(score.heal)) - incoming)
			notice_label.text = "Revide %d  →  você recebe %d  ·  fôlego previsto %d" % [game.intent_damage(), incoming, after]
		enemy_vitals.predicted = maxi(0, game.enemy_hp - int(score.damage)) if score.valid else -1
	enemy_vitals.queue_redraw()
	_set_group("battle")
	_queue_debug()

func _on_rule_changed(kind: String) -> void:
	if not session_active or screens.root() != "battle" or busy: return
	if kind == "selection": _sync_selection()
	else: _sync_battle()
	_queue_debug()

func _start_game(value: int = 42013) -> void:
	epoch += 1
	busy = false
	session_active = true
	result_recorded = false
	replacement_index = -1
	seed_number = value
	hand_fingerprint = ""
	focus_memory.erase("battle")
	game.new_run(value)
	if not is_instance_valid(battle_root): _build_battle()
	else: _sync_battle()
	effects.clear()
	screens.reset("battle")
	_log("run_started", {"party": game.party})

func _select(index: int) -> void:
	if screens.top() != "battle": return
	if busy:
		buffered_card = index
		buffered_at = Time.get_ticks_msec()
		return
	if game.toggle(index): audio.play("select", true)

func _cast() -> void:
	if screens.top() != "battle": return
	if busy:
		rejected_busy_casts += 1
		_queue_debug()
		return
	if not game.preview().valid: return
	var token: int = epoch
	var selected_cards: Array = game.selected_cards().duplicate(true)
	var active: Dictionary = {}
	var before_hp: int = game.player_hp
	for card in selected_cards: active[int(card.owner)] = true
	busy = true
	var result: Dictionary = game.play()
	if not result.get("ok", false):
		busy = false
		return
	if game.phase in ["victory", "defeat"]: _record_result()
	_sync_selection()
	audio.duck()
	var target: Vector2 = enemy_art.get_global_rect().get_center()
	for i in range(game.party.size()):
		var actor = actors[i]
		if not active.has(int(game.party[i].uid)): continue
		effects.flight(actor.get_global_rect().get_center(), target, Color(Content.SPECIES[game.party[i].species].color))
		audio.play({"ember": "fire", "moss": "leaf", "volt": "storm"}[game.party[i].species])
		if not preferences.values.reduced_motion:
			var tween: Tween = actor.portrait.create_tween()
			tween.tween_property(actor.portrait, "scale", Vector2(1.08, 0.95), 0.10).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween.tween_property(actor.portrait, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_queue_debug()
	await get_tree().create_timer(0.05 if preferences.values.reduced_motion else 0.22).timeout
	if token != epoch: return
	_sync_battle(true)
	if result.applied_damage > 0:
		effects.impact(target, int(result.applied_damage))
		audio.play("impact")
		_float_text("−%d" % result.applied_damage, target + Vector2(20, -50), UI.GOLD, 48)
		if not preferences.values.reduced_motion:
			enemy_art.scale = Vector2(1.06, 0.96)
			enemy_art.create_tween().tween_property(enemy_art, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if int(result.burn_tick) > 0: _float_text("QUEIMA %d" % result.burn_tick, target + Vector2(28, 10), UI.FIRE, 22)
		if preferences.values.flashes:
			enemy_art.modulate = Color(1.6, 1.5, 1.3)
			enemy_art.create_tween().tween_property(enemy_art, "modulate", Color.WHITE, 0.10)
	var healing: int = mini(game.max_hp - before_hp, int(result.heal))
	if healing > 0: _float_text("+%d CURA" % healing, player_vitals.get_global_rect().get_center() + Vector2(80, 40), UI.LEAF, 28)
	if int(result.incoming) > 0: _float_text("−%d" % result.incoming, player_vitals.get_global_rect().get_center() + Vector2(25, 20), UI.FIRE, 32)
	if result.name == "Vínculo triplo": _float_text("VÍNCULO TRIPLO", size * Vector2(0.5, 0.32), UI.GOLD, 32)
	_log("powers_cast", {"damage": result.applied_damage, "energy": result.energy, "block": result.block, "heal": result.heal, "phase": game.phase})
	await get_tree().create_timer(0.05 if preferences.values.reduced_motion else 0.28).timeout
	if token != epoch: return
	busy = false
	_sync_selection()
	_sync_phase()
	if screens.top() == "battle":
		var default: String = focus_memory.get("battle", "hand.0")
		_focus(default, "battle")
		if buffered_card >= 0 and Time.get_ticks_msec() - buffered_at < 160: game.toggle(buffered_card)
	buffered_card = -1
	_queue_debug()

func _redraw() -> void:
	if busy or screens.top() != "battle": return
	if game.redraw():
		audio.play("draw", true)
		_log("powers_redrawn", {"remaining": game.discards})
		_focus("hand.0", "battle")

func _float_text(text: String, point: Vector2, color: Color, font_size: int) -> void:
	var label: Label = ui.label(text, font_size, color, true, true)
	effects.add_child(label)
	label.position = point - Vector2(140, 20)
	label.size = Vector2(280, 56)
	var tween = label.create_tween().set_parallel(true)
	if not preferences.values.reduced_motion:
		tween.tween_property(label, "position:y", label.position.y - 36, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.60).set_delay(0.10)
	tween.chain().tween_callback(label.queue_free)

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
	if game.phase in ["reward", "victory", "defeat"]: _push(game.phase)

func _on_screen_changed() -> void:
	var battle: bool = screens.root() == "battle"
	world.title_mode = not battle
	world.queue_redraw()
	menu_root.visible = not battle
	if is_instance_valid(battle_root): battle_root.visible = battle
	if is_instance_valid(modal_root):
		remove_child(modal_root)
		modal_root.queue_free()
	modal_root = null
	if screens.top() not in ["menu", "battle"]: _build_modal(screens.top())
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
		"pause":
			var body: VBoxContainer = _modal_frame("O bosque espera.", "Sua expedição está em pausa.", 650)
			_button(body, "CONTINUAR", _pop, "pause.resume", screen, true)
			_button(body, "OPÇÕES", _push.bind("settings"), "pause.settings", screen)
			_button(body, "COMO JOGAR", _push.bind("help"), "pause.help", screen)
			_button(body, "VOLTAR AO TÍTULO", _push.bind("confirm_menu"), "pause.menu", screen)
		"settings": _settings()
		"help":
			var body: VBoxContainer = _modal_frame("Seu time é o seu grimório.", "Leia a intenção do inimigo e escolha como responder.", 930)
			body.add_child(ui.paragraph("1. Selecione de 1 a 3 poderes. Cada rodada oferece 3 energia.\n2. Confira dano, escudo, cura e fôlego previsto antes de conjurar.\n3. Escudo absorve o revide e dura só esta rodada.\n4. Queimadura acumula, causa dano ao conjurar e perde 1 carga.\n5. Trait é da espécie; passiva é do indivíduo e permanece ao evoluir.\n6. Capture para mudar o grimório. Evolua para abrir um poder novo.\n7. São 7 rodadas e 2 trocas por encontro.", 23, UI.PAPER))
			body.add_child(ui.paragraph("1–6: poderes  ·  Enter: selecionar em foco  ·  Espaço: conjurar\nR: trocar  ·  C: inspecionar  ·  Esc: pausa/voltar\nControle: A seleciona, X conjura, RB troca, Y inspeciona e B volta.", 20, UI.GOLD))
			_button(body, "VOLTAR", _pop, "help.back", screen, true)
		"credits":
			var body: VBoxContainer = _modal_frame("Feito para despertar ecos.", "", 850)
			body.add_child(ui.paragraph("Umbral: Ecos do Bosque\nCriaturas e poderes: arte vetorial original.\nCenário: criado com Image Gen para este projeto.\nÁudio: síntese original, sem samples externos.\nFontes: DejaVu Sans e DejaVu Serif.", 24, UI.PAPER))
			_button(body, "VOLTAR", _pop, "credits.back", screen, true)
		"codex": _codex()
		"inspect": _inspection()
		"reward": _rewards()
		"replacement": _replacement()
		"victory", "defeat": _ending()
		"confirm_menu":
			var body: VBoxContainer = _modal_frame("Encerrar esta expedição?", "O progresso desta run será perdido. Suas estatísticas continuam salvas.", 760)
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
	body.add_child(ui.paragraph("Movimento reduzido desativa tremores e partículas. Flashes começam desativados. Estas opções ficam salvas neste dispositivo.", 20))
	_button(body, "VOLTAR", _pop, "settings.back", "settings", true)

func _codex() -> void:
	var body: VBoxContainer = _modal_frame("Grimório dos Umbrals", "Conheça os traits antes de escolher seu vínculo.", 1300)
	var row: HBoxContainer = UI.row(26)
	body.add_child(row)
	for species_id in ["ember", "moss", "volt"]:
		var column: VBoxContainer = UI.column(10)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)
		var individual: Dictionary = Rules.make_umbral(species_id, "fierce", 0)
		var species: Dictionary = Content.SPECIES[species_id]
		column.add_child(UI.art(species_id, Vector2(180, 160)))
		column.add_child(ui.label(species.names[0] + " → " + species.names[1], 27, Color(species.color), true, true))
		column.add_child(ui.label(species.trait, 24, UI.GOLD, false, true))
		column.add_child(ui.paragraph(Content.trait_text(individual), 22))
		column.add_child(ui.paragraph("Evolução desbloqueia " + Content.POWERS[species.signature].name.replace("\n", " ") + ".", 20))
	_button(body, "VOLTAR", _pop, "codex.back", "codex", true)

func _inspect_actor(index: int) -> void:
	if index >= game.party.size(): return
	inspection = {"umbral": game.party[index].duplicate(true)}
	_push("inspect")

func _inspect_focused() -> void:
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused is PowerCard:
		inspection = {"umbral": focused.individual.duplicate(true), "card": focused.card.duplicate(true)}
	elif is_instance_valid(focused) and str(focused.get_meta("ui_id", "")).begins_with("hud.") and last_card_index < game.hand.size():
		var card: Dictionary = game.hand[last_card_index]
		inspection = {"umbral": game.umbral_by_uid(int(card.owner)).duplicate(true), "card": card.duplicate(true)}
	else:
		var index: int = 0
		if is_instance_valid(focused) and str(focused.get_meta("ui_id", "")).begins_with("party."):
			index = int(str(focused.get_meta("ui_id")).get_slice(".", 1))
		if index >= game.party.size(): return
		inspection = {"umbral": game.party[index].duplicate(true)}
	_push("inspect")

func _inspection() -> void:
	var umbral: Dictionary = inspection.umbral
	var species: Dictionary = Content.SPECIES[umbral.species]
	var title: String = Content.POWERS[inspection.card.power].name.replace("\n", " ") if inspection.has("card") else Content.display_name(umbral)
	var body: VBoxContainer = _modal_frame(title, "Vínculo de " + Content.display_name(umbral) + " · " + species.element, 1000)
	var row: HBoxContainer = UI.row(28)
	body.add_child(row)
	row.add_child(UI.art("powers/" + Content.POWERS[inspection.card.power].art if inspection.has("card") else species.art[int(umbral.stage) - 1], Vector2(210, 200)))
	var details: VBoxContainer = UI.column(15)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)
	details.add_child(ui.label("TRAIT  " + species.trait, 26, UI.GOLD))
	details.add_child(ui.paragraph(Content.trait_text(umbral), 24, UI.PAPER))
	details.add_child(ui.label("PASSIVA  " + Content.PASSIVES[umbral.passive].name, 25, Color(species.color)))
	details.add_child(ui.paragraph(Content.PASSIVES[umbral.passive].description, 24))
	if inspection.has("card"):
		var score: Dictionary = Rules.evaluate([inspection.card], [umbral])
		body.add_child(ui.paragraph("Custo base %d · dano %d · escudo %d · cura %d\nO resultado final também considera queimadura acumulada e os aliados ativos. Ágil desconta 1 do total do indivíduo, uma vez por rodada." % [Content.POWERS[inspection.card.power].cost, score.damage, score.block, score.heal], 22))
	else:
		var names: Array[String] = []
		for id in species.powers: names.append(Content.POWERS[id].name.replace("\n", " "))
		if int(umbral.stage) == 2: names.append(Content.POWERS[species.signature].name.replace("\n", " "))
		body.add_child(ui.paragraph("PODERES\n" + " · ".join(names), 22))
	_button(body, "VOLTAR", _pop, "inspect.back", "inspect", true)

func _rewards() -> void:
	var body: VBoxContainer = _modal_frame("Um novo eco responde.", "Capture uma nova passiva ou desperte a evolução de um aliado. +8 de fôlego.", 1440)
	var row: HBoxContainer = UI.row(16)
	body.add_child(row)
	for i in range(game.reward_offers.size()):
		var offer: Dictionary = game.reward_offers[i]
		var evolved: bool = offer.kind == "evolve"
		var original: Dictionary = game.umbral_by_uid(int(offer.uid)) if evolved else offer.umbral
		var candidate: Dictionary = original.duplicate(true)
		if evolved: candidate.stage = 2
		var species: Dictionary = Content.SPECIES[candidate.species]
		var panel = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", ui.style(Color("15292c"), Color(species.color), 16))
		row.add_child(panel)
		var column: VBoxContainer = UI.column(10)
		panel.add_child(column)
		column.add_child(ui.label("EVOLUÇÃO" if evolved else "NOVA ALIANÇA", 18, Color(species.color), false, true))
		column.add_child(UI.art(species.art[int(candidate.stage) - 1], Vector2(155, 132)))
		column.add_child(ui.label(Content.display_name(candidate), 30, Color(species.color), true, true))
		column.add_child(ui.paragraph(species.trait + "\n" + Content.trait_text(candidate), 21, UI.PAPER))
		column.add_child(ui.label("Instinto: " + Content.PASSIVES[candidate.passive].name, 22, UI.GOLD))
		column.add_child(ui.paragraph(Content.PASSIVES[candidate.passive].description, 19))
		column.add_child(ui.paragraph("✦ " + Content.POWERS[species.signature].name.replace("\n", " ") if evolved else "Adiciona três poderes ao grimório.", 20, UI.GOLD if evolved else UI.MUTED))
		_button(column, "DESPERTAR" if evolved else "CAPTURAR", _take_reward.bind(i), "reward.%d" % i, "reward", true)
	body.add_child(ui.paragraph("A evolução preserva sua passiva. Uma captura traz outro indivíduo.", 19))

func _take_reward(index: int) -> void:
	if game.reward_offers[index].kind == "capture" and game.party.size() == 3:
		replacement_index = index
		_push("replacement")
		return
	_accept_reward(index)

func _accept_reward(index: int, replace_uid: int = -1) -> void:
	var offer: Dictionary = game.reward_offers[index].duplicate(true)
	var evolved: bool = offer.kind == "evolve"
	if not game.choose_reward(index, replace_uid): return
	replacement_index = -1
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
	var body: VBoxContainer = _modal_frame("Quem abre espaço?", "O novo %s tem %s. Escolha um vínculo para substituir." % [Content.display_name(offered), Content.PASSIVES[offered.passive].name], 1230)
	var row: HBoxContainer = UI.row(20)
	body.add_child(row)
	for i in range(game.party.size()):
		var umbral: Dictionary = game.party[i]
		var column: VBoxContainer = UI.column(12)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)
		column.add_child(UI.art(Content.SPECIES[umbral.species].art[int(umbral.stage) - 1], Vector2(180, 170)))
		column.add_child(ui.label(Content.display_name(umbral), 30, Color(Content.SPECIES[umbral.species].color), true, true))
		column.add_child(ui.label(Content.PASSIVES[umbral.passive].name, 22, UI.MUTED, false, true))
		_button(column, "SUBSTITUIR", _accept_reward.bind(replacement_index, int(umbral.uid)), "replace.%d" % i, "replacement", true)
	_button(body, "MANTER MEU TIME", _pop, "replacement.back", "replacement")

func _ending() -> void:
	var won: bool = game.phase == "victory"
	var body: VBoxContainer = _modal_frame("A aurora tem seus nomes." if won else "Ainda existem outros ecos.", "Expedição concluída." if won else "Combine proteção, cura e queimadura para encontrar outro caminho.", 1050)
	body.add_child(UI.art(Content.SPECIES[game.party[0].species].art[int(game.party[0].stage) - 1] if won else "stag", Vector2(240, 180)))
	body.add_child(ui.label("%d DANO  ·  %d UMBRALS  ·  SEMENTE %d" % [game.total_damage, game.party.size(), game.seed_value], 23, UI.GOLD, false, true))
	_button(body, "NOVA EXPEDIÇÃO", _new_seed, "result.new", screens.top(), true)
	_button(body, "REPETIR ESTA SEMENTE", _start_game.bind(game.seed_value), "result.retry", screens.top())
	_button(body, "VOLTAR AO TÍTULO", _return_menu, "result.menu", screens.top())

func _set_group(screen: String) -> void:
	var group: Array = []
	for key in registry:
		var control = registry[key]
		if is_instance_valid(control) and control.is_inside_tree() and control.get_meta("ui_screen", "") == screen and control.is_visible_in_tree():
			if control is BaseButton and control.disabled: continue
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
		var target: Control = registry.get("hand.0") if screen == "battle" and registry.has("hand.0") else group[0]
		if is_instance_valid(target): target.grab_focus()
	_queue_debug()

func _return_menu() -> void:
	epoch += 1
	busy = false
	session_active = false
	if is_instance_valid(effects): effects.clear()
	audio.set_boss(false)
	_update_menu_stats()
	screens.reset("menu")

func _new_seed() -> void:
	var value: int = int(Time.get_unix_time_from_system() * 1000) % 1000000
	if value == game.seed_value: value += 1
	_start_game(value)

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
	for actor in actors: actor.reduced_motion = preferences.values.reduced_motion
	for card in cards:
		card.reduced_motion = preferences.values.reduced_motion
		card._react()
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
			hand_fingerprint = ""
			_build_battle()
		focus_memory[screens.top()] = key
		_on_screen_changed()
	_queue_debug()

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
		if screens.top() == "battle": _push("pause")
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
			data["title_fits"] = control.title_fits()
			data["reduced_motion"] = control.reduced_motion
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
	var state: Dictionary = {"version": Content.VERSION, "revision": published_revision, "screen": screens.top(), "stack": screens.entries, "busy": busy, "phase": game.phase if session_active else "menu", "hand": game.hand if session_active else [], "deck": game.deck, "discard": game.discard_pile, "party": game.party, "selected": game.selected, "hp": game.player_hp, "enemy_hp": game.enemy_hp, "burn": game.enemy_burn, "intent": game.intent_damage(), "plays": game.plays, "actions": game.actions, "discards": game.discards, "encounter": game.encounter, "stats": stats, "offers": game.reward_offers, "preview": game.preview(), "preferences": preferences.values, "focused": focus.get_meta("ui_id", "") if is_instance_valid(focus) else "", "controls": controls, "logical_size": [size.x, size.y], "device": last_device, "feedback": {"hits": effects.hits if is_instance_valid(effects) else 0, "flights": effects.flights if is_instance_valid(effects) else 0, "bursts": effects.bursts if is_instance_valid(effects) else 0, "trauma": effects.trauma if is_instance_valid(effects) else 0, "particles": effects.particles.size() if is_instance_valid(effects) else 0, "rejected_busy_casts": rejected_busy_casts}}
	state["overlay_z"] = modal_root.z_index if is_instance_valid(modal_root) else 0
	state["card_max_z"] = 6
	state["audio"] = {"voice_pool": audio.voices.size(), "music_muted": AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "music_db": AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))}
	state["node_count"] = get_tree().get_node_count()
	state["input_serial"] = input_serial
	state["interaction_serial"] = interaction_serial
	state["last_interaction"] = last_interaction
	JavaScriptBridge.eval("window.umbralState = " + JSON.stringify(state), true)

func _log(event_name: String, details: Dictionary) -> void:
	var entry: Dictionary = {"event": event_name, "version": Content.VERSION, "seed": game.seed_value, "action": game.actions}
	entry.merge(details)
	print(JSON.stringify(entry))

func _load_stats() -> void:
	var data: Dictionary = Storage.read_json(SAVE_PATH, WEB_STATS_KEY, LEGACY_SAVE_PATH)
	if data is Dictionary:
		for key in stats:
			if data.get(key) is float or data.get(key) is int: stats[key] = maxi(0, int(data[key]))

func _record_result() -> void:
	if result_recorded: return
	result_recorded = true
	stats.runs = int(stats.runs) + 1
	if game.phase == "victory": stats.wins = int(stats.wins) + 1
	stats.best_damage = maxi(int(stats.best_damage), game.total_damage)
	if not Storage.write_json(SAVE_PATH, WEB_STATS_KEY, stats):
		push_warning("Could not persist run statistics.")
	_log("run_finished", {"outcome": game.phase, "damage": game.total_damage})

func _update_menu_stats() -> void:
	menu_stats.text = "%d vitórias  ·  %d expedições  ·  novos instintos a cada semente" % [stats.wins, stats.runs]
