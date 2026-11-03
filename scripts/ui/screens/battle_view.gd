extends "res://scripts/ui/screens/screen_view.gd"
const Rules = preload("res://scripts/rules.gd")
const Models = preload("res://scripts/domain/models.gd")
const Content = preload("res://scripts/content.gd")
const Actor = preload("res://scripts/ui/actor.gd")
const Vitals = preload("res://scripts/ui/vitals.gd")
const PowerCard = preload("res://scripts/ui/power_card.gd")
const Hand = preload("res://scripts/ui/hand.gd")
const Effects = preload("res://scripts/ui/effects.gd")
var game: Rules
var visual_capture: bool = false
var busy: bool = false
var last_device: String = "keyboard"
var hand_fingerprint: String = ""
var visual_layer: Control
var effects: Effects
var enemy_art: TextureRect
var enemy_name: Label
var enemy_intent: Label
var burn_label: Label
var player_vitals: Vitals
var enemy_vitals: Vitals
var progress_label: Label
var round_label: Label
var preview_label: Label
var notice_label: Label
var energy_label: Label
var cast_button: Button
var inventory_button: Button
var redraw_button: Button
var hand_view: Hand
var actors: Array[Actor] = []
var cards: Array[PowerCard] = []

func build(rules: Rules, capture: bool) -> void:
	game = rules
	visual_capture = capture
	name = "BattleScreen"
	visual_layer = Control.new()
	visual_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full(visual_layer, self)
	for i in range(3):
		var actor = Actor.new()
		_at(actor, visual_layer, [Vector2(0.19, 0.35), Vector2(0.33, 0.38), Vector2(0.46, 0.34)][i], Vector2(208 if i == 0 else 190, 232 if i == 0 else 214))
		navigation.register(actor, "party.%d" % i, Ids.BATTLE)
		actor.pressed.connect(request.bind("inspect_actor", i))
		actors.append(actor)
	enemy_art = TextureRect.new()
	enemy_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	enemy_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_at(enemy_art, visual_layer, Vector2(0.73, 0.42), Vector2(345, 345))
	enemy_art.pivot_offset = Vector2(172.5, 172.5)
	var enemy_column: VBoxContainer = UI.column(7)
	_at(enemy_column, visual_layer, Vector2(0.73, 0.18), Vector2(370, 144))
	enemy_name = ui.label("", 30, UI.tokens.paper, true, true)
	enemy_column.add_child(enemy_name)
	enemy_vitals = Vitals.new()
	enemy_vitals.tint = UI.tokens.gold
	enemy_vitals.caption = "ADVERSÁRIO"
	enemy_vitals.custom_minimum_size = Vector2(370, 74)
	enemy_column.add_child(enemy_vitals)
	enemy_intent = ui.label("", 22, UI.tokens.fire, false, true)
	enemy_column.add_child(enemy_intent)
	burn_label = ui.label("", 20, UI.tokens.fire, false, true)
	enemy_column.add_child(burn_label)
	effects = Effects.new()
	_full(effects, self)
	effects.visual_layer = visual_layer
	var margin = MarginContainer.new()
	self.add_child(margin)
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
	progress_label = ui.label("", 20, UI.tokens.gold, false, true)
	route.add_child(progress_label)
	round_label = ui.label("", 20, UI.tokens.paper, true, true)
	route.add_child(round_label)
	top.add_child(UI.spacer())
	var help: Button = _button(top, "GUIA", request.bind("push", Ids.HELP), "hud.help", Ids.BATTLE)
	help.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var pause: Button = _button(top, "Ⅱ  PAUSA", request.bind("push", Ids.PAUSE), "hud.pause", Ids.BATTLE)
	pause.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var bag_margin = MarginContainer.new()
	add_child(bag_margin)
	bag_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bag_margin.offset_top = 112
	bag_margin.offset_bottom = 168
	_apply_safe_margin(bag_margin)
	var bag_row: HBoxContainer = UI.row()
	bag_margin.add_child(bag_row)
	inventory_button = _button(bag_row, "BOLSA", request.bind("push", Ids.INVENTORY), "hud.inventory", Ids.BATTLE)
	bag_row.add_child(UI.spacer())
	var preview_column: VBoxContainer = UI.column(4)
	_at(preview_column, self, Vector2(0.5, 1), Vector2(1150, 74))
	preview_column.offset_top = -454
	preview_column.offset_bottom = -380
	preview_label = ui.label("", 25, UI.tokens.paper, false, true)
	preview_column.add_child(preview_label)
	notice_label = ui.label("", 20, UI.tokens.muted, false, true)
	preview_column.add_child(notice_label)
	hand_view = Hand.new()
	_at(hand_view, self, Vector2(0.5, 1), Vector2(1100, 290))
	hand_view.offset_top = -388
	hand_view.offset_bottom = -98
	var actions: HBoxContainer = UI.row(20)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	_at(actions, self, Vector2(0.5, 1), Vector2(1190, 68))
	actions.offset_top = -80
	actions.offset_bottom = -18
	redraw_button = _button(actions, "TROCAR · R", request.bind("redraw"), "hud.redraw", Ids.BATTLE)
	cast_button = _button(actions, "CONJURAR · ESPAÇO", request.bind("cast"), "hud.cast", Ids.BATTLE, true)
	cast_button.custom_minimum_size.x = 300
	_button(actions, "INSPECIONAR · C", request.bind("inspect_focused"), "hud.inspect", Ids.BATTLE)
	energy_label = ui.label("", 23, UI.tokens.gold)
	actions.add_child(energy_label)
	render(false, "keyboard")

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

func render(is_busy: bool, device: String, animate: bool = false) -> void:
	busy = is_busy
	last_device = device
	if not is_instance_valid(self): return
	var foe: Resource = game.catalog.encounters[game.encounter]
	enemy_art.texture = load(foe.enemy.art_path)
	enemy_name.text = foe.name
	enemy_intent.text = "⚔  INTENÇÃO  %d" % game.intent_damage() if game.intent_damage() > 0 else game.enemy_action().display_name
	var enemy_status: Array[String] = []
	var player_status: Array[String] = []
	for status in game.statuses:
		var label: String = ("♨  QUEIMADURA" if status.definition.status_id == "burn" else status.definition.display_name.to_upper()) + "  %d" % status.stacks
		if status.target == "enemy": enemy_status.append(label)
		else: player_status.append(label)
	if game.enemy_block > 0: enemy_status.append("◇  ESCUDO  %d" % game.enemy_block)
	burn_label.text = " · ".join(enemy_status)
	player_vitals.tooltip_text = " · ".join(player_status)
	player_vitals.text_scale = preferences.text_scale()
	enemy_vitals.text_scale = preferences.text_scale()
	player_vitals.update_health(game.player_hp, game.max_hp, -1, animate and not preferences.values.reduced_motion)
	enemy_vitals.update_health(game.enemy_hp, foe.hp, -1, animate and not preferences.values.reduced_motion)
	var route: Array[String] = []
	for i in range(game.catalog.encounters.size()): route.append("◆" if i <= game.encounter else "◇")
	progress_label.text = "  ─  ".join(route)
	round_label.text = "Clareira %d  ·  Rodada %d/%d" % [game.encounter + 1, mini(Rules.ROUND_BUDGET, Rules.ROUND_BUDGET - game.plays + 1), Rules.ROUND_BUDGET]
	for i in range(3):
		actors[i].set_identity(game.party[i] if i < game.party.size() else null, preferences.text_scale(), game.catalog)
		actors[i].still = visual_capture
		actors[i].reduced_motion = preferences.values.reduced_motion
	effects.reduced_motion = preferences.values.reduced_motion
	var fingerprint: String = JSON.stringify({"hand": Models.records(game.hand), "party": Models.records(game.party)})
	if fingerprint != hand_fingerprint:
		hand_fingerprint = fingerprint
		_rebuild_hand()
	render_selection(busy, last_device)
	navigation.set_group(Ids.BATTLE)
	navigation.changed.emit()

func _rebuild_hand() -> void:
	for card in cards:
		hand_view.remove_child(card)
		card.queue_free()
	cards.clear()
	for i in range(game.hand.size()):
		var card = PowerCard.new()
		hand_view.add_child(card)
		card.configure(game.hand[i], game.umbral_by_uid(game.hand[i].owner), game.party, preferences.text_scale(), preferences.values.reduced_motion, game.catalog)
		navigation.register(card, "hand.%d" % i, Ids.BATTLE)
		card.pressed.connect(request.bind("select", i))
		cards.append(card)
	hand_view.layout_cards()
	hand_view.queue_sort()

func render_selection(is_busy: bool, device: String) -> void:
	busy = is_busy
	last_device = device
	if not is_instance_valid(self): return
	var projection: Models.ResolutionResult = game.preview_round()
	var score: Models.CastEvaluation = projection.evaluation
	for i in range(cards.size()):
		cards[i].disabled = busy or game.phase != Ids.BATTLE
		cards[i].set_chosen(i in game.selected)
	inventory_button.disabled = busy or game.phase != Ids.BATTLE
	cast_button.disabled = busy or not score.valid or game.phase != Ids.BATTLE
	redraw_button.disabled = busy or game.selected.is_empty() or game.discards <= 0 or game.phase != Ids.BATTLE
	cast_button.text = "CONJURANDO…" if busy else "CONJURAR · X" if last_device == "gamepad" else "CONJURAR · ESPAÇO"
	redraw_button.text = "TROCAR %d · %s" % [game.discards, "RB" if last_device == "gamepad" else "R"]
	var gems: String = ""
	for i in range(Rules.ENERGY): gems += "◆" if i < maxi(0, Rules.ENERGY - int(score.energy)) else "◇"
	energy_label.text = "%s %d/3" % [gems, score.energy]
	energy_label.add_theme_color_override("font_color", UI.tokens.fire if int(score.energy) > Rules.ENERGY else UI.tokens.gold)
	if game.selected.is_empty():
		preview_label.text = "Escolha seus poderes"
		notice_label.text = "Clique ou use 1–6  ·  Enter seleciona o poder em foco"
		enemy_vitals.predicted = -1
	else:
		preview_label.text = "%d dano  ·  %d escudo  ·  %d cura" % [score.damage, score.block, score.heal]
		if not score.valid:
			notice_label.text = "⚠  Energia insuficiente — retire um poder ou troque a seleção."
		elif projection.ok and projection.enemy_hp_after == 0:
			notice_label.text = "✦  O adversário cairá antes de revidar."
		else:
			var incoming: int = projection.incoming
			var after: int = projection.player_hp_after
			notice_label.text = "Revide %d  →  você recebe %d  ·  fôlego previsto %d" % [game.intent_damage(), incoming, after]
		enemy_vitals.predicted = projection.enemy_hp_after if projection.ok else -1
	enemy_vitals.queue_redraw()
	navigation.set_group(Ids.BATTLE)
	navigation.changed.emit()

func apply_preferences() -> void:
	effects.reduced_motion = preferences.values.reduced_motion
	if preferences.values.reduced_motion: effects.clear()
	for actor in actors: actor.reduced_motion = preferences.values.reduced_motion
	for card in cards: card.apply_motion(preferences.values.reduced_motion)

func feedback_snapshot() -> Dictionary:
	var bounds: Rect2 = enemy_name.get_global_rect()
	return {"enemy_name_bounds": {"x": bounds.position.x, "y": bounds.position.y, "w": bounds.size.x, "h": bounds.size.y}, "hits": effects.hits, "flights": effects.flights, "bursts": effects.bursts, "trauma": effects.trauma, "particles": effects.particles.size()}
