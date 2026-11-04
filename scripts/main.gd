extends Control
const SessionRuntime = preload("res://scripts/application/session_runtime.gd")
const BrowserSnapshot = preload("res://scripts/ui/browser_snapshot.gd")
const BrowserBridge = preload("res://scripts/ui/browser_bridge.gd")
const SessionService = preload("res://scripts/session/session_service.gd")
## Session coordinator. HUDs react to discrete rule signals; the screen stack owns input.

const Rules = preload("res://scripts/rules.gd")
const Content = preload("res://scripts/content.gd")
const UI = preload("res://scripts/ui/kit.gd")
const ScreenHost = preload("res://scripts/ui/screen_host.gd")
const ControlRegistry = preload("res://scripts/ui/control_registry.gd")
const FocusRegistry = preload("res://scripts/ui/focus_registry.gd")
const Screens = preload("res://scripts/ui/screen_stack.gd")
const Preferences = preload("res://scripts/ui/preferences.gd")
const InputRouter = preload("res://scripts/ui/input_router.gd")
const Actions = preload("res://scripts/ui/input_actions.gd")
const World = preload("res://scripts/ui/world.gd")
const Audio = preload("res://scripts/ui/audio.gd")
const BattleOverlays = preload("res://scripts/ui/battle_overlays.gd")
const BattleSurface = preload("res://scripts/ui/battle_surface.gd")
const ExpeditionScreen = preload("res://scripts/ui/expedition_screen.gd")
const ResolutionFeedback = preload("res://scripts/ui/resolution_feedback.gd")
const CodexProgress = preload("res://scripts/codex_progress.gd")
const MenuScreens = preload("res://scripts/ui/menu_screens.gd")
const TitleButton = preload("res://scripts/ui/title_button.gd")
const JourneyMenu = preload("res://scripts/ui/journey_menu.gd")

var runtime = SessionRuntime.new()
var menu_screens = MenuScreens.new()
var expedition_screen = ExpeditionScreen.new()
var input_router = InputRouter.new()
var run_flow = runtime.run
var overlays = BattleOverlays.new()
var rewards = runtime.rewards
var commands = runtime.commands
var expedition_flow = runtime.expedition
var turn = runtime.turn
var session = SessionService.new()
var feedback = ResolutionFeedback.new()
var codex_progress = CodexProgress.new()
var game = Rules.new()
var continue_button: Button
var menu_notice: Label
var map_selection: String = ""
var screens = Screens.new()
var preferences = Preferences.new()
var ui = UI.new()
var registry: Dictionary = {}
var focus_registry = FocusRegistry.new(registry)
var control_registry = ControlRegistry.new()
var screen_host = ScreenHost.new()
var world: Control
var audio: Node
var menu_stats: Label
var cards: Array = []
var session_active: bool = false
var browser_test: bool = false
var visual_capture: bool = false
var hand_fingerprint: String = ""
var header_text_scale: float = 1.0
var published_revision: int = 0
var debug_queued: bool = false
var interaction_serial: int = 0
var last_interaction: String = ""

func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_tree().root.close_requested.connect(_quit)
	expedition_screen.control_created.connect(func(control: Control, id: String): _register(control, id, "map"))
	expedition_screen.node_requested.connect(_enter_node)
	expedition_screen.pause_requested.connect(_push.bind("pause"))
	expedition_screen.selection_changed.connect(func(id: String): map_selection = id)
	expedition_screen.formation_requested.connect(commands.open_formation)
	menu_screens.control_created.connect(_register)
	menu_screens.requested.connect(_menu_intent)
	menu_screens.starter_requested.connect(func(species: String): run_flow.start_selected(run_flow.seed_number, species, str(preferences.values.information_mode)))
	menu_screens.navigation_changed.connect(_set_group.bind("codex"))
	menu_screens.title_navigation.connect(func(): audio.navigate())
	menu_screens.title_awakened.connect(_title_awakened)
	runtime.connect_input(input_router)
	runtime.return_menu_requested.connect(_return_menu)
	runtime.input_inspection_requested.connect(func(): runtime.interactions.inspect_focused(get_viewport().gui_get_focus_owner()))
	runtime.game_changed.connect(_bind_game)
	runtime.screen_requested.connect(_push)
	runtime.screen_pop_requested.connect(_pop)
	runtime.screen_refresh_requested.connect(_on_screen_changed)
	runtime.battle_refresh_requested.connect(_sync_battle)
	runtime.selection_refresh_requested.connect(_sync_selection)
	runtime.battle_requested.connect(_prepare_expedition_battle)
	runtime.run_reset_requested.connect(_reset_expedition_view)
	runtime.practice_reset_requested.connect(_reset_practice_view)
	runtime.effects_clear_requested.connect(func(): screen_host.battle_root.clear_effects())
	runtime.continue_changed.connect(_update_continue_button)
	runtime.focus_memory_requested.connect(func(screen: String, key: String): focus_registry.memory[screen] = key)
	runtime.focus_requested.connect(_focus.bind("hand.0", "battle"))
	runtime.notice_requested.connect(func(message: String): screen_host.battle_root.show_notice(message))
	runtime.reward_feedback_requested.connect(_reward_feedback)
	runtime.phase_requested.connect(_sync_phase)
	runtime.text_scale_requested.connect(_sync_text_scale)
	runtime.debug_requested.connect(_queue_debug)
	runtime.logged.connect(_log)
	overlays.control_created.connect(_register)
	runtime.connect_overlays(overlays)
	feedback.progress.connect(_feedback_progress)
	Actions.install()
	preferences.load_saved()
	ui.text_scale = preferences.text_scale()
	header_text_scale = ui.text_scale
	theme = ui.make_theme()
	codex_progress.load_saved()
	_load_stats()
	audio = Audio.new()
	runtime.configure(game, session, codex_progress, screens, audio, _animate_resolution)
	_refresh_checkpoint()
	add_child(audio)
	audio.apply(preferences.values)
	world = World.new()
	add_child(world)
	world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var flags: Dictionary = BrowserBridge.query_flags()
	browser_test = flags.browser_test
	visual_capture = flags.visual_capture
	control_registry.configure(registry, screens, audio, browser_test)
	control_registry.debug_requested.connect(_queue_debug)
	control_registry.card_pointed.connect(func(index: int):
		turn.last_card_index = index
		turn.aim_card(index))
	control_registry.interaction.connect(func(key: String):
		interaction_serial += 1
		last_interaction = key
		_queue_debug())
	screen_host.configure(screens, focus_registry, world, audio, preferences, get_viewport(), cards, visual_capture)
	screen_host.map_requested.connect(_build_map)
	screen_host.modal_requested.connect(_build_modal)
	screen_host.debug_requested.connect(_queue_debug)
	screen_host.phase_requested.connect(_sync_phase)
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


func _register(node: Control, key: String, screen: String) -> Control:
	return control_registry.register(node, key, screen)

func _build_menu() -> void:
	screen_host.menu_root = menu_screens.title(size, preferences, visual_capture)
	_full(screen_host.menu_root, self)
	_set_group("menu")

func _title_awakened() -> void:
	audio.awaken()
	if browser_test:
		interaction_serial += 1
		last_interaction = "menu.card"
	_queue_debug()

func _build_battle() -> void:
	var surface = BattleSurface.new()
	screen_host.battle_root = surface
	_full(surface, self)
	surface.control_created.connect(func(control: Control, key: String): _register(control, key, "battle"))
	surface.slot_requested.connect(runtime.interactions.click_slot)
	surface.command_requested.connect(_battle_command)
	surface.card_selected.connect(turn.select)
	surface.focus_group_changed.connect(_set_group.bind("battle"))
	surface.changed.connect(_queue_debug)
	surface.boss_changed.connect(audio.set_boss)
	surface.build(ui, registry, _apply_safe_margin, cards)
	world.battle_bottom_inset = surface.bottom_inset()
	_sync_battle(false)

func _battle_command(command: String) -> void:
	if command.begins_with("reserve."):
		commands.open_reserve(int(command.get_slice(".", 1)))
		return
	match command:
		"cast": turn.cast()
		"redraw": turn.redraw()
		"plan": runtime.interactions.open_plan()
		"history": runtime.interactions.open_history()
		"draw", "discard": runtime.interactions.open_pile(command)
		_: _push(command)

func actor_center(side: String, slot: int) -> Vector2:
	return screen_host.battle_root.actor_center(side, slot)

func _apply_safe_margin(margin: MarginContainer) -> void:
	BrowserBridge.apply_safe_margin(margin, size)

func _prepare_battle_presenter() -> void:
	screen_host.battle_root.hand_fingerprint = hand_fingerprint
	screen_host.battle_root.set_state(game, preferences, turn.busy, visual_capture, input_router.last_device, turn.targeting_index)

func _sync_battle(_animate: bool = false) -> void:
	if not is_instance_valid(screen_host.battle_root): return
	_prepare_battle_presenter()
	screen_host.battle_root.sync()
	hand_fingerprint = screen_host.battle_root.hand_fingerprint
	turn.targeting_index = screen_host.battle_root.targeting_index

func _sync_selection() -> void:
	if not is_instance_valid(screen_host.battle_root): return
	_prepare_battle_presenter()
	screen_host.battle_root.sync_selection()
	turn.targeting_index = screen_host.battle_root.targeting_index

func _on_rule_changed(kind: String) -> void:
	if kind not in ["selection", "target"] and not game.party.is_empty(): codex_progress.observe(game, session_active and screens.root() == "battle")
	if not session_active or screens.root() != "battle" or turn.busy: return
	if kind in ["selection", "target"]: _sync_selection()
	else: _sync_battle()
	_queue_debug()

func _reset_practice_view(_value: int) -> void:
	turn.epoch += 1
	feedback.cancel()
	turn.busy = false
	session_active = true
	map_selection = ""
	rewards.replacement_index = -1
	turn.targeting_index = -1
	hand_fingerprint = ""
	focus_registry.memory.erase("battle")

func _start_game(value: int = 42013, starter: String = "ember") -> void:
	run_flow.start_practice(value, starter, str(preferences.values.information_mode))

func _animate_resolution(result: Dictionary, _token: int) -> void:
	await screen_host.battle_root.play_resolution(feedback, result, audio, preferences, game.reserves())

func _feedback_progress(index: int, total: int, line: String) -> void:
	screen_host.battle_root.feedback_progress(index, total, line)

func _float_text(text: String, point: Vector2, color: Color, _font_size: int) -> void:
	screen_host.battle_root.popup(point, text, color)

func _push(screen: String) -> void:
	screen_host.push(screen)

func _pop() -> void:
	screen_host.pop()

func _sync_phase() -> void:
	if turn.busy or screens.top() != "battle": return
	if session.expedition_active: session.expedition.settle_battle()
	if game.phase == "replacement": _push("ko_replacement")
	elif game.phase in ["reward", "victory", "defeat"]: _push(game.phase)

func _on_screen_changed() -> void:
	screen_host.refresh()


func _build_modal(screen: String) -> void:
	if screen in ["inspect", "reward", "replacement", "capture_destination", "history", "swap", "formation", "pouch", "plan", "pile", "ko_replacement"]:
		_battle_overlay(screen)
		return
	if screen == "codex" and session_active: codex_progress.observe(game, screens.root() == "battle")
	screen_host.modal_root = menu_screens.build_modal(screen, ui, size, preferences, visual_capture, session, codex_progress, game, screens.root())
	_full(screen_host.modal_root, self)
	if screen == "journey":
		continue_button = screen_host.modal_root.continue_button
		menu_notice = screen_host.modal_root.notice

func _battle_overlay(screen: String) -> void:
	var draft: Dictionary = {"inspection": runtime.interactions.inspection, "pile_zone": runtime.interactions.pile_zone, "reserve_uid": commands.reserve_uid, "formation_draft": commands.formation_draft, "replacement_index": rewards.replacement_index, "capture_index": rewards.capture_index, "capture_replace_uid": rewards.capture_replace_uid, "capture_slot": rewards.capture_slot}
	screen_host.modal_root = overlays.build(screen, ui, size, game, preferences, draft)
	_full(screen_host.modal_root, self)

func _menu_intent(intent: String) -> void:
	match intent:
		"back": _pop()
		"confirm_new": run_flow.confirm_new_expedition()
		"return_menu": _return_menu()
		"quit": _quit()
		"continue": _continue_expedition()
		"new": run_flow.choose_starter(42013)
		"practice": run_flow.choose_starter(42013, true)
		"history": runtime.interactions.open_history()
		"new_seed": _new_seed()
		"retry": _retry_seed()
		_: _push(intent)

func _reward_feedback(individual: Dictionary, evolved: bool) -> void:
	_float_text(Content.display_name(individual).to_upper() + (" DESPERTA" if evolved else " SE JUNTOU"), size * Vector2(0.5, 0.25), UI.GOLD, 36)
	screen_host.battle_root.reward_burst(individual)

func _retry_seed() -> void:
	run_flow.retry(game, str(preferences.values.information_mode))

func _new_seed() -> void:
	run_flow.new_seed(game)

func _set_group(screen: String) -> void:
	screen_host.set_group(screen)

func _focus(key: String, screen: String) -> void:
	screen_host.focus(key, screen)

func _return_menu() -> void:
	turn.epoch += 1
	feedback.cancel()
	turn.busy = false
	session_active = false
	if is_instance_valid(screen_host.battle_root): screen_host.battle_root.clear_effects()
	audio.set_boss(false)
	_refresh_checkpoint()
	_update_continue_button()
	_update_menu_stats()
	screens.reset("menu")

func _quit() -> void:
	if not is_instance_valid(audio) or audio.shutting_down: return
	audio.shutdown()
	audio.queue_free()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()

func _on_preferences_changed() -> void:
	audio.apply(preferences.values)
	world.still = visual_capture or preferences.values.reduced_motion
	screen_host.menu_root.apply_preferences(preferences.values.reduced_motion, visual_capture, preferences.text_scale())
	for control in registry.values():
		if is_instance_valid(control) and control is TitleButton:
			control.reduced_motion = bool(preferences.values.reduced_motion) or visual_capture
			control.queue_redraw()
	if preferences.values.reduced_motion: screen_host.suppress_motion()
	if is_instance_valid(screen_host.battle_root): screen_host.battle_root.apply_reduced_motion(preferences.values.reduced_motion)
	if session_active: game.set_information_mode(str(preferences.values.information_mode))
	if session.expedition_active and not turn.busy: _checkpoint_expedition()
	_sync_text_scale()
	_queue_debug()

func _sync_text_scale() -> void:
	# The rule model already advanced; never rebuild the displayed committed hand
	# against that model while its snapshots are still being animated.
	if turn.busy: return
	if not is_equal_approx(header_text_scale, preferences.text_scale()):
		var focused: Control = get_viewport().gui_get_focus_owner()
		var key: String = focused.get_meta("ui_id", "") if is_instance_valid(focused) else ""
		header_text_scale = preferences.text_scale()
		ui.text_scale = header_text_scale
		theme = ui.make_theme()
		remove_child(screen_host.menu_root)
		screen_host.menu_root.queue_free()
		_build_menu()
		if is_instance_valid(screen_host.battle_root):
			remove_child(screen_host.battle_root)
			screen_host.battle_root.queue_free()
			screen_host.battle_root = null
			cards.clear()
			hand_fingerprint = ""
			_build_battle()
		focus_registry.memory[screens.top()] = key
		_on_screen_changed()

func _input(event: InputEvent) -> void:
	if input_router.route(event, screens.top(), session_active, browser_test):
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
	var presentation: Dictionary = {"revision": published_revision, "busy": turn.busy, "session_active": session_active, "targeting_index": turn.targeting_index, "logical_size": [size.x, size.y], "device": input_router.last_device, "feedback": screen_host.battle_root.feedback_metrics() if is_instance_valid(screen_host.battle_root) else {"hits": 0, "flights": 0, "bursts": 0, "trauma": 0, "particles": 0}, "rejected_busy_casts": turn.rejected_busy_casts, "overlay_z": screen_host.modal_root.z_index if is_instance_valid(screen_host.modal_root) else 0, "audio": BrowserBridge.audio_snapshot(audio.voices.size()), "node_count": get_tree().get_node_count(), "title_effect": screen_host.menu_root.effect_state(), "title_audio": BrowserBridge.title_audio_snapshot(audio.title_active, audio.navigation_count, audio.awakening_count), "input_serial": input_router.input_serial, "interaction_serial": interaction_serial, "last_interaction": last_interaction}
	if is_instance_valid(screen_host.modal_root) and screen_host.modal_root is JourneyMenu:
		presentation["journey_checkpoint"] = screen_host.modal_root.public_checkpoint
	BrowserBridge.publish(BrowserSnapshot.build(game, session, screens, preferences, presentation), registry, get_viewport().gui_get_focus_owner())

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
	expedition_flow.refresh_checkpoint()

func _update_continue_button() -> void:
	if is_instance_valid(continue_button): continue_button.disabled = session.saved_checkpoint.is_empty()
	if is_instance_valid(menu_notice):
		menu_notice.text = session.save_notice
		menu_notice.visible = not session.save_notice.is_empty()

func _checkpoint_expedition() -> void:
	expedition_flow.checkpoint()

func _reset_expedition_view(value: int, fresh: bool) -> void:
	turn.epoch += 1
	feedback.cancel()
	turn.busy = false
	run_flow.starter_practice = false
	session_active = true
	map_selection = ""
	if fresh:
		rewards.replacement_index = -1
		rewards.capture_index = -1
	run_flow.seed_number = value
	hand_fingerprint = ""
	turn.targeting_index = -1
	if is_instance_valid(screen_host.battle_root): screen_host.battle_root.clear_effects()

func _prepare_expedition_battle() -> void:
	hand_fingerprint = ""
	turn.targeting_index = -1
	if not is_instance_valid(screen_host.battle_root): _build_battle()
	else: _sync_battle()

func _start_expedition(value: int = 42013, starter: String = "ember") -> void:
	expedition_flow.start(value, str(preferences.values.information_mode), starter)

func _continue_expedition() -> void:
	expedition_flow.resume()

func _build_map() -> void:
	var snapshot: Dictionary = session.expedition.public_state()
	snapshot["save_notice"] = session.save_notice
	screen_host.map_root = expedition_screen.build(self, snapshot, preferences.text_scale(), map_selection)

func _enter_node(id: String) -> void:
	expedition_flow.enter_node(id, turn.busy, screens.top())

func _load_stats() -> void:
	session.load_stats()

func _record_result() -> void:
	expedition_flow.record_result(game)

func _update_menu_stats() -> void:
	if not is_instance_valid(menu_stats): return
	menu_stats.text = "%d vitórias  ·  %d expedições  ·  novos instintos a cada semente" % [session.stats.wins, session.stats.runs]
