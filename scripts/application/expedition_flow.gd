extends RefCounted
## Orchestrates expedition commands and their persistence order. Presentation
## responds to the signals; SessionService remains the checkpoint owner.
signal run_reset_requested(seed: int, fresh: bool)
signal game_changed(game: RefCounted)
signal battle_requested
signal screen_reset_requested(screen: String)
signal map_refresh_requested
signal continue_changed
signal sound_requested(cue: String)
signal logged(event_name: String, details: Dictionary)

var session: RefCounted
var codex_progress: RefCounted

func configure(session_service: RefCounted, progress: RefCounted) -> void:
	session = session_service
	codex_progress = progress

func refresh_checkpoint() -> void:
	session.refresh_checkpoint(codex_progress)
	continue_changed.emit()

func checkpoint() -> void:
	if session.checkpoint(codex_progress):
		var game: RefCounted = session.expedition.battle
		logged.emit("run_finished", {"outcome": game.phase, "damage": game.total_damage})
	continue_changed.emit()

func record_result(game: RefCounted) -> void:
	if session.record_result(game):
		logged.emit("run_finished", {"outcome": game.phase, "damage": game.total_damage})

func start(value: int, information_mode: String, starter: String) -> void:
	run_reset_requested.emit(value, true)
	var game: RefCounted = session.start_expedition(value, information_mode, starter)
	game_changed.emit(game)
	checkpoint()
	screen_reset_requested.emit("map")
	logged.emit("expedition_started", {"party": game.party})

func resume() -> bool:
	if not session.continue_expedition(codex_progress):
		continue_changed.emit()
		return false
	var game: RefCounted = session.expedition.battle
	run_reset_requested.emit(game.seed_value, false)
	game_changed.emit(game)
	session.expedition.settle_battle()
	if session.expedition.phase in ["map", "event"]:
		screen_reset_requested.emit("map")
	else:
		battle_requested.emit()
		if session.expedition.phase in ["victory", "defeat"]: checkpoint()
		screen_reset_requested.emit("battle")
	logged.emit("expedition_continued", {"node": session.expedition.current_node_id})
	return true

func enter_node(id: String, busy: bool, screen: String) -> bool:
	if busy or screen != "map" or not session.expedition_active: return false
	if not session.expedition.choose_node(id): return false
	checkpoint()
	if session.expedition.phase == "event":
		map_refresh_requested.emit()
	elif session.expedition.phase == "map":
		session.save_notice = "Nascente visitada: aliados vivos recuperaram até 25% do HP máximo. " + session.save_notice
		map_refresh_requested.emit()
	else:
		battle_requested.emit()
		screen_reset_requested.emit("battle")
		sound_requested.emit("draw")
	logged.emit("node_entered", {"node": id})
	return true

func resolve_event(choice: String, details: Dictionary) -> void:
	if not session.expedition_active or not session.expedition.choose_event(choice, details): return
	checkpoint()
	map_refresh_requested.emit()
	sound_requested.emit("evolve" if choice == "practice" else "capture")
	logged.emit("event_chosen", {"node": "spring", "choice": choice, "details": details})
