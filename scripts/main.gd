extends Control
## Composition and session commands only. Views own nodes; rules own consequences.
const Rules = preload("res://scripts/rules.gd")
const Content = preload("res://scripts/content.gd")
const Models = preload("res://scripts/domain/models.gd")
const Ids = preload("res://scripts/domain/ids.gd")
const UI = preload("res://scripts/ui/kit.gd")
const Screens = preload("res://scripts/ui/screen_stack.gd")
const Navigation = preload("res://scripts/ui/navigation.gd")
const Preferences = preload("res://scripts/ui/preferences.gd")
const Actions = preload("res://scripts/ui/input_actions.gd")
const World = preload("res://scripts/ui/world.gd")
const PowerCard = preload("res://scripts/ui/power_card.gd")
const Audio = preload("res://scripts/ui/audio.gd")
const ScreenView = preload("res://scripts/ui/screens/screen_view.gd")
const Title = preload("res://scripts/ui/screens/title_screen.gd")
const Battle = preload("res://scripts/ui/screens/battle_view.gd")
const Modal = preload("res://scripts/ui/screens/modal_view.gd")
const Overlays = preload("res://scripts/ui/screens/overlay_factory.gd")
const Feedback = preload("res://scripts/ui/combat_feedback.gd")
const Statistics = preload("res://scripts/session/statistics.gd")
const Diagnostics = preload("res://scripts/platform/browser_diagnostics.gd")

var game: Rules = Rules.new()
var screens: Screens = Screens.new()
var preferences: Preferences = Preferences.new()
var ui: UI = UI.new()
var statistics: Statistics = Statistics.new()
var navigation: Navigation
var world: World
var audio: Audio
var title: Title
var battle: Battle
var overlay: Modal
var feedback: Feedback = Feedback.new()
var diagnostics: Diagnostics = Diagnostics.new()
var inspection: Dictionary = {}
var replacement_index: int = -1
var session_active: bool = false
var last_device: String = "keyboard"
var header_text_scale: float = 1.0
var buffered_card: int = -1
var buffered_at: int = 0
var rejected_busy_casts: int = 0
var last_card_index: int = 0

func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_tree().root.close_requested.connect(_quit)
	Actions.install()
	preferences.load_saved()
	ui.text_scale = preferences.text_scale()
	header_text_scale = ui.text_scale
	theme = ui.make_theme()
	statistics.load_saved()
	navigation = Navigation.new(get_viewport())
	navigation.activated.connect(func(_key: String): audio.play("hover", true))
	navigation.card_focused.connect(func(index: int): last_card_index = index)
	add_child(diagnostics)
	diagnostics.configure(navigation, _debug_snapshot)
	audio = Audio.new()
	add_child(audio)
	audio.apply(preferences.values)
	add_child(feedback)
	feedback.configure(ui, preferences, audio)
	feedback.finished.connect(_on_feedback_finished)
	world = World.new()
	add_child(world)
	world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world.still = diagnostics.visual_capture or preferences.values.reduced_motion
	screens.changed.connect(_on_screen_changed)
	preferences.changed.connect(_on_preferences_changed)
	game.state_changed.connect(_on_rule_changed)
	resized.connect(diagnostics.queue_snapshot)
	_build_title()
	_on_screen_changed()
	_log("ui_started", {"screen": Ids.MENU})
	if "--smoke-exit" in OS.get_cmdline_user_args(): call_deferred("_smoke_exit")

func _mount(view: ScreenView) -> void:
	view.configure(ui, preferences, navigation)
	view.action_requested.connect(_on_view_action)
	add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _build_title() -> void:
	title = Title.new()
	_mount(title)
	title.build(statistics.values)

func _build_battle() -> void:
	battle = Battle.new()
	_mount(battle)
	battle.build(game, diagnostics.visual_capture)

func _on_view_action(command: String, payload: Variant) -> void:
	match command:
		"start_game": _start_game(int(payload))
		"push": _push(str(payload))
		"pop": _pop()
		"quit": _quit()
		"select": _select(int(payload))
		"cast": _cast()
		"redraw": _redraw()
		"use_item": _use_item(int(payload))
		"equip_item": _equip_item(int(payload[0]), int(payload[1]))
		"inspect_actor": _inspect_actor(int(payload))
		"inspect_focused": _inspect_focused()
		"take_reward": _take_reward(int(payload))
		"accept_reward": _accept_reward(int(payload[0]), int(payload[1]))
		"return_menu": _return_menu()
		"new_seed": _new_seed()

func _sync_battle(animate: bool = false) -> void:
	if is_instance_valid(battle):
		battle.render(feedback.busy, last_device, animate)
		world.set_environment(game.catalog.encounters[game.encounter].environment)
		audio.set_environment(game.catalog.encounters[game.encounter].environment)
		audio.set_boss(game.encounter == game.catalog.encounters.size() - 1)

func _sync_selection() -> void:
	if is_instance_valid(battle): battle.render_selection(feedback.busy, last_device)

func _on_rule_changed(kind: String) -> void:
	if not session_active or screens.root() != Ids.BATTLE or feedback.busy: return
	if kind == "selection": _sync_selection()
	else: _sync_battle()
	diagnostics.queue_snapshot()

func _start_game(value: int = 42013) -> void:
	feedback.cancel()
	buffered_card = -1
	session_active = true
	statistics.begin_run()
	replacement_index = -1
	navigation.focus_memory.erase(Ids.BATTLE)
	game.new_run(value)
	if not is_instance_valid(battle): _build_battle()
	_sync_battle()
	screens.reset(Ids.BATTLE)
	_log("run_started", {"party": Models.records(game.party)})

func _cast() -> void:
	if screens.top() != Ids.BATTLE: return
	if feedback.busy:
		rejected_busy_casts += 1
		diagnostics.queue_snapshot()
		return
	if not game.preview().valid: return
	var selected_cards: Array[Models.CardInstance] = game.selected_cards()
	feedback.begin()
	var result: Models.ResolutionResult = game.play()
	if not result.ok:
		feedback.cancel()
		return
	if statistics.record(game): _log("run_finished", {"outcome": game.phase, "damage": game.total_damage})
	_sync_selection()
	_log("powers_cast", {"damage": result.applied_damage, "energy": result.evaluation.energy, "block": result.evaluation.block, "heal": result.evaluation.heal, "phase": game.phase, "events": Models.records(result.combat_events)})
	feedback.present(battle, result, selected_cards, last_device)

func _on_feedback_finished() -> void:
	_sync_battle()
	_sync_phase()
	if screens.top() == Ids.BATTLE:
		navigation.focus(navigation.focus_memory.get(Ids.BATTLE, "hand.0"), Ids.BATTLE)
		if buffered_card >= 0 and Time.get_ticks_msec() - buffered_at < 160: game.toggle(buffered_card)
	buffered_card = -1
	diagnostics.queue_snapshot()

func _smoke_exit() -> void:
	await get_tree().create_timer(0.15).timeout
	await _quit()

func _select(index: int) -> void:
	if screens.top() != Ids.BATTLE: return
	if feedback.busy:
		buffered_card = index
		buffered_at = Time.get_ticks_msec()
		return
	if game.toggle(index): audio.play("select", true)

func _redraw() -> void:
	if feedback.busy or screens.top() != Ids.BATTLE: return
	if game.redraw():
		audio.play("draw", true)
		_log("powers_redrawn", {"remaining": game.discards})
		navigation.focus("hand.0", Ids.BATTLE)

func _use_item(id: int) -> void:
	if feedback.busy or screens.top() != Ids.INVENTORY: return
	var outcome = game.use_item(id)
	if outcome == null: return
	audio.play("leaf")
	_log("item_used", {"events": Models.records(outcome.events)})
	if statistics.record(game): _log("run_finished", {"outcome": game.phase, "damage": game.total_damage})
	_sync_battle()
	_on_screen_changed()
	if game.phase != Ids.BATTLE: _pop()

func _equip_item(id: int, uid: int) -> void:
	if feedback.busy or screens.top() != Ids.INVENTORY: return
	if not game.equip_item(id, uid): return
	audio.play("select", true)
	_sync_battle()
	_on_screen_changed()

func _push(screen: String) -> void:
	navigation.remember(screens.top())
	screens.push(screen)

func _pop() -> void:
	navigation.remember(screens.top())
	screens.pop()

func _sync_phase() -> void:
	if feedback.busy or screens.top() != Ids.BATTLE: return
	if game.phase in [Ids.REWARD, Ids.VICTORY, Ids.DEFEAT]: _push(game.phase)

func _on_screen_changed() -> void:
	var in_battle: bool = screens.root() == Ids.BATTLE
	world.title_mode = not in_battle
	world.queue_redraw()
	title.visible = not in_battle
	if is_instance_valid(battle): battle.visible = in_battle
	if is_instance_valid(overlay):
		remove_child(overlay)
		overlay.queue_free()
	overlay = null
	if screens.top() not in [Ids.MENU, Ids.BATTLE]:
		overlay = Overlays.create(screens.top())
		_mount(overlay)
		overlay.build(screens.top(), game, inspection, replacement_index)
	navigation.set_group(screens.top())
	navigation.focus(navigation.focus_memory.get(screens.top(), ""), screens.top())
	diagnostics.queue_snapshot()
	_sync_phase()

func _inspect_actor(index: int) -> void:
	if index >= game.party.size(): return
	inspection = {"umbral": game.party[index].clone()}
	_push(Ids.INSPECT)

func _inspect_focused() -> void:
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused is PowerCard:
		inspection = {"umbral": focused.individual.clone(), "card": focused.card}
	elif is_instance_valid(focused) and str(focused.get_meta("ui_id", "")).begins_with("hud.") and last_card_index < game.hand.size():
		var card: Models.CardInstance = game.hand[last_card_index]
		inspection = {"umbral": game.umbral_by_uid(int(card.owner)).clone(), "card": card}
	else:
		var index: int = 0
		if is_instance_valid(focused) and str(focused.get_meta("ui_id", "")).begins_with("party."):
			index = int(str(focused.get_meta("ui_id")).get_slice(".", 1))
		if index >= game.party.size(): return
		inspection = {"umbral": game.party[index].clone()}
	_push(Ids.INSPECT)

func _take_reward(index: int) -> void:
	if game.reward_offers[index].kind == Ids.CAPTURE and game.party.size() == Rules.MAX_TEAM:
		replacement_index = index
		_push(Ids.REPLACEMENT)
		return
	_accept_reward(index)

func _accept_reward(index: int, replace_uid: int = -1) -> void:
	var offer: Models.RewardOffer = game.reward_offers[index]
	var evolved: bool = offer.kind == Ids.EVOLVE
	if not game.choose_reward(index, replace_uid): return
	replacement_index = -1
	_sync_battle()
	screens.reset(Ids.BATTLE)
	audio.play(Ids.EVOLVE if evolved else Ids.CAPTURE)
	var individual: Models.Individual = game.umbral_by_uid(int(offer.uid)) if evolved else offer.umbral
	feedback.float_text(battle, game.catalog.display_name(individual).to_upper() + (" DESPERTA" if evolved else " SE JUNTOU"), size * Vector2(0.5, 0.25), UI.tokens.gold, 36)
	for actor in battle.actors:
		if actor.identity != null and int(actor.identity.uid) == int(individual.uid):
			battle.effects.burst(actor.get_global_rect().get_center(), Color(game.catalog.species[individual.species_id].color), 32)
	_log("reward_chosen", {"kind": offer.kind, Ids.REPLACEMENT: replace_uid, "party": Models.records(game.party)})
	diagnostics.queue_snapshot()

func _return_menu() -> void:
	feedback.cancel()
	buffered_card = -1
	session_active = false
	audio.set_boss(false)
	title.set_stats(statistics.values)
	screens.reset(Ids.MENU)

func _new_seed() -> void:
	var value: int = int(Time.get_unix_time_from_system() * 1000) % 1000000
	if value == game.seed_value: value += 1
	_start_game(value)

func _quit() -> void:
	if not is_instance_valid(audio) or audio.shutting_down: return
	feedback.cancel()
	audio.shutdown()
	audio.queue_free()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()

func _on_preferences_changed() -> void:
	audio.apply(preferences.values)
	world.still = diagnostics.visual_capture or preferences.values.reduced_motion
	if preferences.values.reduced_motion and feedback.busy:
		feedback.cancel()
		buffered_card = -1
		_sync_battle()
		_sync_phase()
	if is_instance_valid(battle): battle.apply_preferences()
	if not is_equal_approx(header_text_scale, preferences.text_scale()):
		feedback.cancel()
		buffered_card = -1
		var focused: Control = get_viewport().gui_get_focus_owner()
		var key: String = focused.get_meta("ui_id", "") if is_instance_valid(focused) else ""
		header_text_scale = preferences.text_scale()
		ui.text_scale = header_text_scale
		theme = ui.make_theme()
		remove_child(title)
		title.queue_free()
		_build_title()
		if is_instance_valid(battle):
			remove_child(battle)
			battle.queue_free()
			_build_battle()
		navigation.focus_memory[screens.top()] = key
		_on_screen_changed()
	diagnostics.queue_snapshot()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo: return
	if event is InputEventJoypadMotion and absf(event.axis_value) < 0.25: return
	diagnostics.observe_input(event)
	var device: String = "gamepad" if event is InputEventJoypadButton or event is InputEventJoypadMotion else "keyboard" if event is InputEventKey else "mouse" if event is InputEventMouseButton else last_device
	if device != last_device:
		last_device = device
		if session_active: _sync_selection()
	if event.is_action_pressed("umbral_back"):
		if screens.top() == Ids.BATTLE: _push(Ids.PAUSE)
		elif screens.top() in [Ids.VICTORY, Ids.DEFEAT]: _return_menu()
		elif screens.top() != Ids.MENU: _pop()
		get_viewport().set_input_as_handled()
		return
	if screens.top() != Ids.BATTLE: return
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

func _debug_snapshot() -> Dictionary:
	var data: Dictionary = game.snapshot()
	data.merge({"screen": screens.top(), "stack": screens.entries.duplicate(), "busy": feedback.busy, "phase": game.phase if session_active else Ids.MENU, "hand": Models.records(game.hand) if session_active else [], "stats": statistics.values.duplicate(), "preferences": preferences.values.duplicate(), "logical_size": [size.x, size.y], "device": last_device, "overlay_z": overlay.z_index if is_instance_valid(overlay) else 0, "card_max_z": 6, "feedback": battle.feedback_snapshot() if is_instance_valid(battle) else {"hits": 0, "flights": 0, "bursts": 0, "trauma": 0, "particles": 0}}, true)
	data.feedback["rejected_busy_casts"] = rejected_busy_casts
	data["audio"] = {"voice_pool": audio.voices.size(), "music_muted": AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "music_db": AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))}
	return data

func _log(event_name: String, details: Dictionary) -> void:
	var entry: Dictionary = {"event": event_name, "version": Content.VERSION, "seed": game.seed_value, "action": game.actions}
	entry.merge(details)
	print(JSON.stringify(entry))
