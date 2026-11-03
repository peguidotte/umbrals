extends Control
const BrowserBridge = preload("res://scripts/ui/browser_bridge.gd")
const SessionService = preload("res://scripts/session/session_service.gd")
const Assets = preload("res://scripts/assets/catalog.gd")
## Session coordinator. HUDs react to discrete rule signals; the screen stack owns input.

const Rules = preload("res://scripts/rules.gd")
const Content = preload("res://scripts/content.gd")
const UI = preload("res://scripts/ui/kit.gd")
const FocusRegistry = preload("res://scripts/ui/focus_registry.gd")
const Screens = preload("res://scripts/ui/screen_stack.gd")
const Preferences = preload("res://scripts/ui/preferences.gd")
const InputDispatch = preload("res://scripts/ui/input_dispatch.gd")
const Actions = preload("res://scripts/ui/input_actions.gd")
const World = preload("res://scripts/ui/world.gd")
const Actor = preload("res://scripts/ui/actor.gd")
const PowerCard = preload("res://scripts/ui/power_card.gd")
const Effects = preload("res://scripts/ui/effects.gd")
const Audio = preload("res://scripts/ui/audio.gd")
const Targeting = preload("res://scripts/battle/targeting.gd")
const BattlePresenter = preload("res://scripts/ui/battle_presenter.gd")
const BattleHUD = preload("res://scripts/ui/battle_hud.gd")
const Conditions = preload("res://scripts/battle/conditions.gd")
const BattlePlan = preload("res://scripts/ui/battle_plan.gd")
const BattleArt = preload("res://scripts/ui/battle_art.gd")
const BattleReadout = preload("res://scripts/ui/battle_readout.gd")
const ExpeditionMap = preload("res://scripts/ui/expedition_map.gd")
const BattleRecords = preload("res://scripts/ui/battle_records.gd")
const ItemPresentation = preload("res://scripts/ui/item_presentation.gd")
const BattleDialogs = preload("res://scripts/ui/battle_dialogs.gd")
const ResolutionFeedback = preload("res://scripts/ui/resolution_feedback.gd")
const RewardView = preload("res://scripts/ui/reward_view.gd")
const InspectionView = preload("res://scripts/ui/inspection_view.gd")
const Codex = preload("res://scripts/ui/codex.gd")
const CodexProgress = preload("res://scripts/codex_progress.gd")
const StarterView = preload("res://scripts/ui/starter_view.gd")
const TitleMenu = preload("res://scripts/ui/title_menu.gd")
const JourneyMenu = preload("res://scripts/ui/journey_menu.gd")
const SettingsMenu = preload("res://scripts/ui/settings_menu.gd")
const TitleTheme = preload("res://scripts/ui/title_theme.gd")
const TitleButton = preload("res://scripts/ui/title_button.gd")

var session = SessionService.new()
var feedback = ResolutionFeedback.new()
var battle_presenter = BattlePresenter.new()
var active_presentation: RefCounted
var codex_progress = CodexProgress.new()
var game = Rules.new()
var starter_practice: bool = false
var continue_button: Button
var menu_notice: Label
var map_root: Control
var map_selection: String = ""
var screens = Screens.new()
var preferences = Preferences.new()
var ui = UI.new()
var registry: Dictionary = {}
var focus_registry = FocusRegistry.new(registry)
var world: Control
var audio: Node
var menu_root: Control
var battle_root: Control
var modal_root: Control
var title_entrance: Tween
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
var inspection: Dictionary = {}
var replacement_index: int = -1
var capture_index: int = -1
var capture_slot: int = -1
var capture_replace_uid: int = -1
var session_active: bool = false
var busy: bool = false
var epoch: int = 0
var seed_number: int = 42013
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
	feedback.progress.connect(_feedback_progress)
	Actions.install()
	preferences.load_saved()
	ui.text_scale = preferences.text_scale()
	header_text_scale = ui.text_scale
	theme = ui.make_theme()
	codex_progress.load_saved()
	_load_stats()
	_refresh_checkpoint()
	audio = Audio.new()
	add_child(audio)
	audio.apply(preferences.values)
	world = World.new()
	add_child(world)
	world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var flags: Dictionary = BrowserBridge.query_flags()
	browser_test = flags.browser_test
	visual_capture = flags.visual_capture
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
		node.pressed.connect(func():
			if screens.root() == "menu": audio.confirm()
			else: audio.play("hover", true))
		if screens.root() == "menu" and screen != "menu":
			node.focus_entered.connect(audio.navigate)
			node.mouse_entered.connect(audio.navigate)
		if browser_test:
			node.pressed.connect(func():
				interaction_serial += 1
				last_interaction = key
				_queue_debug())
	return node

func _button(parent: Node, text: String, callback: Callable, key: String, screen: String, primary: bool = false) -> Button:
	var button: Button
	if screens.root() == "menu":
		button = TitleButton.new()
		button.text = text
		button.primary = primary
		button.reduced_motion = bool(preferences.values.reduced_motion) or visual_capture
		button.custom_minimum_size.y = 56
		button.pressed.connect(callback)
	else: button = ui.button(text, callback, key, primary)
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
	var title = TitleMenu.new()
	menu_root = title
	_full(title, self)
	var callbacks: Array[Callable] = [_push.bind("journey"), _push.bind("codex"), _push.bind("settings"), _push.bind("help"), _push.bind("credits"), _quit]
	title.build(callbacks, _register)
	title.apply_preferences(preferences.values.reduced_motion, visual_capture, preferences.text_scale())
	title.navigation_requested.connect(audio.navigate)
	title.card_awakened.connect(func():
		audio.awaken()
		if browser_test:
			interaction_serial += 1
			last_interaction = "menu.card"
		_queue_debug())
	_set_group("menu")

func _journey_menu() -> void:
	var checkpoint: Dictionary = {}
	if not session.saved_checkpoint.is_empty():
		var candidate = Expedition.new()
		if candidate.restore(session.saved_checkpoint): checkpoint = candidate.public_state()
	var journey = JourneyMenu.new()
	modal_root = journey
	_full(journey, self)
	journey.z_index = 100
	var callbacks: Array[Callable] = [_continue_expedition, _choose_starter.bind(42013), _choose_starter.bind(42013, true), _pop]
	journey.build(ui, checkpoint, session.save_notice, callbacks, _register, bool(preferences.values.reduced_motion) or visual_capture)
	continue_button = journey.continue_button
	menu_notice = journey.notice

func _build_battle() -> void:
	var hud = BattleHUD.new()
	_full(hud, self)
	battle_root = hud
	hud.control_created.connect(func(control: Control, key: String): _register(control, key, "battle"))
	hud.slot_requested.connect(_click_slot)
	hud.command_requested.connect(_battle_command)
	hud.build(ui, _apply_safe_margin)
	battle_presenter.configure(hud, registry, cards)
	if not battle_presenter.control_created.is_connected(_register_battle_control):
		battle_presenter.control_created.connect(_register_battle_control)
		battle_presenter.card_selected.connect(_select)
		battle_presenter.focus_group_changed.connect(_set_group.bind("battle"))
		battle_presenter.changed.connect(_queue_debug)
		battle_presenter.boss_changed.connect(audio.set_boss)
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

func _register_battle_control(control: Control, key: String) -> void:
	_register(control, key, "battle")

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
	BrowserBridge.apply_safe_margin(margin, size)

func _prepare_battle_presenter() -> void:
	battle_presenter.hand_fingerprint = hand_fingerprint
	battle_presenter.set_state(game, preferences, busy, visual_capture, last_device, targeting_index)

func _sync_battle(_animate: bool = false) -> void:
	if not is_instance_valid(battle_root): return
	_prepare_battle_presenter()
	battle_presenter.sync()
	hand_fingerprint = battle_presenter.hand_fingerprint
	targeting_index = battle_presenter.targeting_index

func _sync_selection() -> void:
	if not is_instance_valid(battle_root): return
	_prepare_battle_presenter()
	battle_presenter.sync_selection()
	targeting_index = battle_presenter.targeting_index

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
	if kind not in ["selection", "target"] and not game.party.is_empty(): codex_progress.observe(game, session_active and screens.root() == "battle")
	if not session_active or screens.root() != "battle" or busy: return
	if kind in ["selection", "target"]: _sync_selection()
	else: _sync_battle()
	_queue_debug()

func _choose_starter(value: int = 42013, practice: bool = false) -> void:
	seed_number = value
	starter_practice = practice
	if not practice:
		_refresh_checkpoint()
		if not session.saved_checkpoint.is_empty() or session.run_save.last_status in ["corrupt", "io_error"]:
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
	var view = StarterView.new()
	active_presentation = view
	view.control_created.connect(func(control: Control, key: String): _register(control, key, "starter"))
	view.starter_requested.connect(func(species: String): _start_selected(seed_number, species))
	view.back_requested.connect(_pop)
	view.build(body, ui, bool(preferences.values.reduced_motion) or visual_capture, screens.root() == "menu")

func _start_game(value: int = 42013, starter: String = "ember") -> void:
	session.start_practice()
	_bind_game(Rules.new())
	epoch += 1
	feedback.cancel()
	busy = false
	session_active = true
	map_selection = ""
	replacement_index = -1
	seed_number = value
	targeting_index = -1
	hand_fingerprint = ""
	focus_registry.memory.erase("battle")
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

func _animate_resolution(result: Dictionary, _token: int) -> void:
	await feedback.play(result, {"actors": actors, "enemy_actors": enemy_actors, "audio": audio, "effects": effects, "preferences": preferences.values, "reserves": game.reserves(), "reserve_buttons": reserve_buttons, "viewport_size": size, "tree": get_tree(), "text_scale": preferences.text_scale()})

func _feedback_progress(index: int, total: int, line: String) -> void:
	phase_label.text = "EXECUTANDO · efeito %d de %d" % [index, total]
	preview_label.text = line
	notice_label.text = "Ao terminar, abra RESUMO para rever danos, escudos e reações."

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
	focus_registry.remember(screens.top(), get_viewport().gui_get_focus_owner())

func _push(screen: String) -> void:
	_remember_focus()
	screens.push(screen)

func _pop() -> void:
	if screens.top() == "codex" and is_instance_valid(modal_root) and modal_root is Codex:
		if modal_root.go_back(): return
	_remember_focus()
	screens.pop()

func _sync_phase() -> void:
	if busy or screens.top() != "battle": return
	if session.expedition_active: session.expedition.settle_battle()
	if game.phase == "replacement": _push("ko_replacement")
	elif game.phase in ["reward", "victory", "defeat"]: _push(game.phase)

func _on_screen_changed() -> void:
	if is_instance_valid(title_entrance): title_entrance.kill()
	menu_root.modulate = Color.WHITE
	var battle: bool = screens.root() == "battle"
	world.title_mode = not battle
	world.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if not battle else CanvasItem.TEXTURE_FILTER_NEAREST
	world.queue_redraw()
	menu_root.visible = screens.root() == "menu"
	menu_root.input_active = screens.top() == "menu"
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
	_focus(focus_registry.memory.get(screens.top(), ""), screens.top())
	if screens.root() == "menu":
		audio.set_title(true)
		var arriving: Control = menu_root if screens.top() == "menu" else modal_root
		if is_instance_valid(arriving):
			arriving.modulate = Color.WHITE
			if not preferences.values.reduced_motion and not visual_capture:
				arriving.modulate.a = 0.0
				title_entrance = arriving.create_tween()
				title_entrance.tween_property(arriving, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else: audio.set_title(false)
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
	if screens.root() == "menu": panel.theme = TitleTheme.make_theme(ui.make_theme())
	panel.custom_minimum_size.x = minf(width, size.x - 96)
	center.add_child(panel)
	var column: VBoxContainer = UI.column(18)
	panel.add_child(column)
	column.add_child(ui.label(title, 40, UI.PAPER, screens.root() != "menu", true))
	if not subtitle.is_empty(): column.add_child(ui.paragraph(subtitle, 22, UI.MUTED))
	return column

func _build_modal(screen: String) -> void:
	match screen:
		"journey": _journey_menu()
		"starter": _starter_choices()
		"confirm_new":
			var body: VBoxContainer = _modal_frame("Começar uma nova expedição?", "A expedição salva será substituída ao escolher o primeiro vínculo. Voltar mantém o progresso atual.", 850)
			_button(body, "MANTER A EXPEDIÇÃO SALVA", _pop, "new.cancel", screen, true)
			_button(body, "ESCOLHER NOVO VÍNCULO", _confirm_new_expedition, "new.confirm", screen)
		"pause":
			var body: VBoxContainer = _modal_frame("O bosque espera.", "Sua expedição está em pausa.", 650)
			_button(body, "CONTINUAR", _pop, "pause.resume", screen, true)
			_button(body, "GRIMÓRIO", _push.bind("codex"), "pause.codex", screen)
			_button(body, "OPÇÕES", _push.bind("settings"), "pause.settings", screen)
			_button(body, "COMO JOGAR", _push.bind("help"), "pause.help", screen)
			_button(body, "VOLTAR AO TÍTULO", _push.bind("confirm_menu"), "pause.menu", screen)
		"settings": _settings()
		"help": _help()
		"credits":
			var body: VBoxContainer = _modal_frame("Feito para despertar ecos.", "", 850)
			body.add_child(ui.paragraph("Umbral\nCriaturas e poderes: arte vetorial original.\nCenário: criado com Image Gen para este projeto.\nÁudio: síntese original, sem samples externos.\nFontes: DejaVu Sans e DejaVu Serif.", 24, UI.PAPER))
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
			var body: VBoxContainer = _modal_frame("Voltar ao título?", ("A expedição será retomada no último estado confirmado. Comandos ainda não conjurados serão desfeitos." if session.expedition_active else "O treino atual será encerrado. A expedição salva fica preservada."), 760)
			_button(body, "CONTINUAR NO BOSQUE", _pop, "confirm.cancel", screen, true)
			_button(body, "VOLTAR AO TÍTULO", _return_menu, "confirm.yes", screen)

func _settings() -> void:
	var view = SettingsMenu.new()
	modal_root = view
	_full(view,self)
	view.z_index = 100
	view.build(preferences,_register,_pop)

func _codex() -> void:
	if session_active: codex_progress.observe(game, screens.root() == "battle")
	var view = Codex.new()
	modal_root = view
	_full(view, self)
	view.z_index = 100
	view.build(codex_progress, _register, _pop, preferences.text_scale())
	view.navigation_changed.connect(func(): _set_group("codex"))

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
	_button(frame, "CRÉDITOS", _push.bind("credits"), "help.credits", "help")
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
	var view = InspectionView.new()
	active_presentation = view
	view.back_requested.connect(_pop)
	var power: Dictionary = {}
	if inspection.has("card"):
		power = Rules.power_effect(inspection.card, inspection.umbral, game.active_party(true).size())
	var individual: Dictionary = inspection.umbral
	var enemy: bool = bool(inspection.get("enemy", false))
	var display: String = str(individual.get("name", "Umbral")) if enemy else Content.display_name(individual)
	var title: String = str(Content.POWERS[inspection.card.power].name).replace("\n", " ") if inspection.has("card") else display
	var frame: VBoxContainer = _modal_frame(title, ("Adversário · " if enemy else "Vínculo · ") + Content.nature_text(individual), 1000)
	view.build(inspection, game.party, game.enemies, game.public_intents(), power, size, frame, _register)

func _open_pile(zone: String) -> void:
	if busy or screens.top() != "battle": return
	pile_zone = zone
	_push("pile")

func _battle_records():
	var view = BattleRecords.new()
	active_presentation = view
	view.back_requested.connect(_pop)
	return view

func _pile_contents() -> void:
	var source: Array = game.deck if pile_zone == "draw" else game.discard_pile
	var body: VBoxContainer = _modal_frame("Pilha de " + ("compra" if pile_zone == "draw" else "descarte"), "%d cartas · Agrupadas por dono e poder. A ordem da compra permanece oculta." % source.size(), 1080)
	var owners: Dictionary = {}
	for individual in game.party: owners[int(individual.uid)] = individual
	_battle_records().pile(body, source, owners, _register)

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
	_battle_records().history(body, result, size, _register)

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

func _battle_dialogs():
	var view = BattleDialogs.new()
	active_presentation = view
	view.back_requested.connect(_pop)
	view.swap_requested.connect(_queue_swap)
	view.swap_cancel_requested.connect(_cancel_swap)
	view.formation_requested.connect(_draft_formation)
	view.formation_confirmed.connect(_commit_formation)
	view.item_requested.connect(_queue_item)
	view.item_cancel_requested.connect(_cancel_item)
	view.ko_requested.connect(_replace_ko)
	view.ko_finished.connect(_finish_ko)
	return view

func _swap_choices() -> void:
	var entrant: Dictionary = game.umbral_by_uid(reserve_uid)
	var body: VBoxContainer = _modal_frame("Trazer " + Content.display_name(entrant), "Custa 1 ação. A troca só ocorre ao Conjurar; o substituto recebe ataques destinados à vaga.", 1000)
	var occupants: Dictionary = {}
	var reasons: Dictionary = {}
	for slot in range(3):
		occupants[slot] = _at_slot("ally", slot)
		reasons[slot] = game.swap_reason(slot, reserve_uid)
	_battle_dialogs().swap(body, occupants, reasons, game.queued_swaps, _register)

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
	_battle_dialogs().formation(body, game.party, formation_draft, _register)

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
	var reasons: Dictionary = {}
	for individual in game.party:
		for item in ItemPresentation.choices(Content.CONSUMABLES, game.inventory):
			reasons["%s:%d" % [item, int(individual.uid)]] = game.item_reason(item, int(individual.uid))
	_battle_dialogs().pouch(frame, game.inventory, game.party, reasons, game.queued_items, size, _register, Content.CONSUMABLES)

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
	var occupants: Dictionary = {}
	for slot in range(3): occupants[slot] = _at_slot("ally", slot)
	_battle_dialogs().ko(body, occupants, game.reserves(), game.active_party(true).size(), _register)

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

func _reward_view():
	var view = RewardView.new()
	active_presentation = view
	view.reward_requested.connect(_take_reward)
	view.formation_requested.connect(_open_formation)
	view.history_requested.connect(_open_history)
	view.replacement_requested.connect(_choose_capture_destination)
	view.slot_requested.connect(_select_capture_slot)
	view.confirm_requested.connect(_accept_reward)
	view.back_requested.connect(_pop)
	return view

func _rewards() -> void:
	var body: VBoxContainer = _modal_frame("Um novo eco responde.", "Capture e escolha Campo ou Reserva, ou evolua um aliado.", 1440)
	var individuals: Dictionary = {}
	for individual in game.party: individuals[int(individual.uid)] = individual
	_reward_view().rewards(body, game.reward_offers, individuals, size, _register)

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
	var occupants: Dictionary = {}
	for slot in range(Rules.MAX_ACTIVE): occupants[slot] = _at_slot("ally", slot)
	var view = _reward_view()
	view.destination(body, game.reward_offers[capture_index], game.capture_destinations(capture_index, capture_replace_uid), occupants, game.umbral_by_uid(capture_replace_uid), capture_index, capture_replace_uid, capture_slot, _register)

func _select_capture_slot(slot: int) -> void:
	if not slot in game.capture_destinations(capture_index, capture_replace_uid): return
	capture_slot = slot
	focus_registry.memory["capture_destination"] = "capture.reserve" if slot < 0 else "capture.slot.%d" % slot
	_on_screen_changed()

func _accept_reward(index: int, replace_uid: int = -1, destination: int = -2) -> void:
	var offer: Dictionary = game.reward_offers[index].duplicate(true)
	var evolved: bool = offer.kind == "evolve"
	var accepted: bool = session.expedition.choose_reward(index, replace_uid, destination) if session.expedition_active else game.choose_reward(index, replace_uid, destination)
	if not accepted: return
	replacement_index = -1
	capture_index = -1
	capture_replace_uid = -1
	if session.expedition_active:
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
	var view = _reward_view()
	view.replacement(body, game.reward_offers[replacement_index], game.party, replacement_index, size, _register)

func _ending() -> void:
	var won: bool = game.phase == "victory"
	var body: VBoxContainer = _modal_frame("A aurora tem seus nomes." if won else "Ainda existem outros ecos.", "Expedição concluída." if won else "Combine proteção, cura e queimadura para encontrar outro caminho.", 1050)
	body.add_child(UI.art(Content.art_binding(game.party[0]) if won else "characters/stag", Vector2(240, 180)))
	body.add_child(ui.label("%d DANO  ·  %d UMBRALS  ·  SEMENTE %d" % [game.total_damage, game.party.size(), game.seed_value], 23, UI.GOLD, false, true))
	_button(body, "REVER ÚLTIMA RODADA", _open_history, "result.history", screens.top())
	_button(body, "NOVA EXPEDIÇÃO", _new_seed, "result.new", screens.top(), true)
	_button(body, "REPETIR ESTA SEMENTE", _retry_seed, "result.retry", screens.top())
	_button(body, "VOLTAR AO TÍTULO", _return_menu, "result.menu", screens.top())

func _retry_seed() -> void:
	if session.expedition_active: _start_expedition(game.seed_value, game.starter_species)
	else: _start_game(game.seed_value, game.starter_species)

func _set_group(screen: String) -> void:
	focus_registry.set_group(screen)

func _focus(key: String, screen: String) -> void:
	focus_registry.restore(key, screen, cards)
	_queue_debug()

func _return_menu() -> void:
	epoch += 1
	feedback.cancel()
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
	menu_root.apply_preferences(preferences.values.reduced_motion, visual_capture, preferences.text_scale())
	for control in registry.values():
		if is_instance_valid(control) and control is TitleButton:
			control.reduced_motion = bool(preferences.values.reduced_motion) or visual_capture
			control.queue_redraw()
	if preferences.values.reduced_motion:
		if is_instance_valid(title_entrance): title_entrance.kill()
		menu_root.modulate = Color.WHITE
		if is_instance_valid(modal_root): modal_root.modulate = Color.WHITE
	if is_instance_valid(effects): effects.reduced_motion = preferences.values.reduced_motion
	if preferences.values.reduced_motion and is_instance_valid(effects): effects.clear()
	if session_active: game.set_information_mode(str(preferences.values.information_mode))
	if session.expedition_active and not busy: _checkpoint_expedition()
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
		focus_registry.memory[screens.top()] = key
		_on_screen_changed()

func _input(event: InputEvent) -> void:
	if InputDispatch.ignored(event): return
	if browser_test and event.is_pressed():
		input_serial += 1
		_queue_debug()
	var device: String = InputDispatch.device(event, last_device)
	if device != last_device:
		last_device = device
		if session_active: _sync_selection()
	var intent: Dictionary = InputDispatch.intent(event, screens.top())
	if intent.is_empty(): return
	match intent.action:
		"back":
			if screens.top() == "ko_replacement": _finish_ko()
			elif screens.top() in ["battle", "map"]: _push("pause")
			elif screens.top() in ["victory", "defeat"]: _return_menu()
			elif screens.top() != "menu": _pop()
		"card": _select(int(intent.index))
		"cast": _cast()
		"redraw": _redraw()
		"plan": _open_plan()
		"clear": _clear_plan()
		"target": _cycle_target(int(intent.direction))
		"inspect": _inspect_focused()
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
	published_revision += 1
	var party_public: Array = []
	var enemies_public: Array = []
	for individual in game.party: party_public.append(_public_individual(individual))
	for individual in game.enemies: enemies_public.append(_public_individual(individual))
	var state: Dictionary = {"version": Content.VERSION, "revision": published_revision, "screen": screens.top(), "stack": screens.entries, "busy": busy, "phase": game.phase if session_active else "menu", "hand": game.hand if session_active else [], "deck": game.deck, "discard": game.discard_pile, "party": party_public, "enemies": enemies_public, "selected": game.selected, "targeting_index": targeting_index, "planned_actions": game.planned_actions(), "hp": game.player_hp, "enemy_hp": game.enemy_hp, "plays": game.plays, "actions": game.actions, "encounter": game.encounter, "round_number": game.round_number, "action_budget": game.action_budget(), "hand_capacity": game.hand_capacity(), "queued_swaps": game.queued_swaps, "queued_items": game.queued_items, "inventory": game.inventory, "intents": game.public_intents(), "information_mode": game.information_mode, "pending_information_mode": game.pending_information_mode, "stats": session.stats, "offers": game.reward_offers, "preview": game.preview(), "preferences": preferences.values, "logical_size": [size.x, size.y], "device": last_device, "feedback": {"hits": effects.hits if is_instance_valid(effects) else 0, "flights": effects.flights if is_instance_valid(effects) else 0, "bursts": effects.bursts if is_instance_valid(effects) else 0, "trauma": effects.trauma if is_instance_valid(effects) else 0, "particles": effects.particles.size() if is_instance_valid(effects) else 0, "rejected_busy_casts": rejected_busy_casts}}

	state["expedition"] = session.expedition.public_state() if session.expedition_active else {}
	state["checkpoint_status"] = session.run_save.last_status
	state["resolved_reactions"] = [] if busy else game.last_result.get("events", []).filter(func(event: Dictionary) -> bool: return event.kind == "reaction")
	state["overlay_z"] = modal_root.z_index if is_instance_valid(modal_root) else 0
	state["card_max_z"] = 6
	state["audio"] = {"voice_pool": audio.voices.size(), "music_muted": AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "music_db": AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))}
	state["node_count"] = get_tree().get_node_count()
	state["title_effect"] = menu_root.effect_state()
	state["title_audio"] = {"active": audio.title_active, "navigation_count": audio.navigation_count, "awakening_count": audio.awakening_count, "ui_muted": AudioServer.is_bus_mute(AudioServer.get_bus_index("UI"))}
	if is_instance_valid(modal_root) and modal_root is JourneyMenu:
		state["journey_summary"] = JourneyMenu.checkpoint_summary(modal_root.public_checkpoint) if not modal_root.public_checkpoint.is_empty() else ""
		state["journey_party"] = modal_root.public_checkpoint.get("party", []).map(func(individual: Dictionary) -> Dictionary: return _public_individual(individual))
	state["input_serial"] = input_serial
	state["interaction_serial"] = interaction_serial
	state["last_interaction"] = last_interaction
	BrowserBridge.publish(state, registry, get_viewport().gui_get_focus_owner())

func _public_individual(individual: Dictionary) -> Dictionary:
	return BrowserBridge.public_individual(individual)

func _log(event_name: String, details: Dictionary) -> void:
	var entry: Dictionary = {"event": event_name, "version": Content.VERSION, "seed": game.seed_value, "action": game.actions}
	entry.merge(details)
	print(JSON.stringify(entry))

func _bind_game(next_game: RefCounted) -> void:
	if game.state_changed.is_connected(_on_rule_changed): game.state_changed.disconnect(_on_rule_changed)
	game = next_game
	game.state_changed.connect(_on_rule_changed)

func _refresh_checkpoint() -> void:
	session.refresh_checkpoint(codex_progress)

func _update_continue_button() -> void:
	if is_instance_valid(continue_button): continue_button.disabled = session.saved_checkpoint.is_empty()
	if is_instance_valid(menu_notice):
		menu_notice.text = session.save_notice
		menu_notice.visible = not session.save_notice.is_empty()

func _checkpoint_expedition() -> void:
	if session.checkpoint(codex_progress):
		_log("run_finished", {"outcome": game.phase, "damage": game.total_damage})
	_update_continue_button()

func _start_expedition(value: int = 42013, starter: String = "ember") -> void:
	epoch += 1
	feedback.cancel()
	busy = false
	starter_practice = false
	session_active = true
	map_selection = ""
	replacement_index = -1
	capture_index = -1
	targeting_index = -1
	seed_number = value
	_bind_game(session.start_expedition(value, str(preferences.values.information_mode), starter))
	hand_fingerprint = ""
	if is_instance_valid(effects): effects.clear()
	_checkpoint_expedition()
	screens.reset("map")
	_log("expedition_started", {"party": game.party})

func _continue_expedition() -> void:
	if not session.continue_expedition(codex_progress):
		_update_continue_button()
		return
	epoch += 1
	feedback.cancel()
	busy = false
	starter_practice = false
	session_active = true
	map_selection = ""
	_bind_game(session.expedition.battle)
	seed_number = game.seed_value
	hand_fingerprint = ""
	targeting_index = -1
	if is_instance_valid(effects): effects.clear()
	session.expedition.settle_battle()
	if session.expedition.phase == "map": screens.reset("map")
	else:
		if not is_instance_valid(battle_root): _build_battle()
		else: _sync_battle()
		if session.expedition.phase in ["victory", "defeat"]: _checkpoint_expedition()
		screens.reset("battle")
	_log("expedition_continued", {"node": session.expedition.current_node_id})

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
	var snapshot: Dictionary = session.expedition.public_state()
	snapshot["save_notice"] = session.save_notice
	map_root.populate(snapshot, preferences.text_scale(), map_selection)
	_full(map_root, self)
	map_root.offset_left = 30
	map_root.offset_right = -30
	map_root.offset_top = 24
	map_root.offset_bottom = -24

func _enter_node(id: String) -> void:
	if busy or screens.top() != "map" or not session.expedition_active: return
	if not session.expedition.choose_node(id): return
	_checkpoint_expedition()
	if session.expedition.phase == "map":
		session.save_notice = "Nascente visitada: aliados vivos recuperaram até 25% do HP máximo. " + session.save_notice
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
	session.load_stats()

func _record_result() -> void:
	if session.record_result(game):
		_log("run_finished", {"outcome": game.phase, "damage": game.total_damage})

func _update_menu_stats() -> void:
	if not is_instance_valid(menu_stats): return
	menu_stats.text = "%d vitórias  ·  %d expedições  ·  novos instintos a cada semente" % [session.stats.wins, session.stats.runs]
