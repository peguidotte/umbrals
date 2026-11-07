extends RefCounted
## Owns starter selection and practice lifecycle; expedition persistence stays
## in ExpeditionFlow and SessionService. Rules is replaced only at run start.
signal screen_push_requested(screen: String)
signal screen_pop_requested
signal game_changed(game: RefCounted)
signal practice_reset_requested(seed: int)
signal battle_requested
signal effects_clear_requested
signal screen_reset_requested(screen: String)
signal logged(event_name: String, details: Dictionary)

const Rules = preload("res://scripts/rules.gd")

var session: RefCounted
var expedition: RefCounted
var seed_number: int = 42013
var starter_practice: bool = false

func configure(session_service: RefCounted, expedition_flow: RefCounted) -> void:
	session = session_service
	expedition = expedition_flow

func choose_starter(value: int = 42013, practice: bool = false) -> void:
	seed_number = value
	starter_practice = practice
	if not practice:
		expedition.refresh_checkpoint()
		if session.run_save.last_status == "incompatible": return
		if not session.saved_checkpoint.is_empty() or session.run_save.last_status in ["corrupt", "io_error"]:
			screen_push_requested.emit("confirm_new")
			return
	screen_push_requested.emit("starter")

func confirm_new_expedition() -> void:
	screen_pop_requested.emit()
	screen_push_requested.emit("starter")

func start_selected(value: int, starter: String, information_mode: String) -> void:
	if starter_practice: start_practice(value, starter, information_mode)
	else: expedition.start(value, information_mode, starter)

func start_practice(value: int, starter: String, information_mode: String) -> void:
	session.start_practice()
	var game: RefCounted = Rules.new()
	game_changed.emit(game)
	seed_number = value
	practice_reset_requested.emit(value)
	game.new_run(value, information_mode, starter)
	battle_requested.emit()
	effects_clear_requested.emit()
	screen_reset_requested.emit("battle")
	logged.emit("run_started", {"party": game.party})

func retry(game: RefCounted, information_mode: String) -> void:
	if session.expedition_active: expedition.start(game.seed_value, information_mode, game.starter_species)
	else: start_practice(game.seed_value, game.starter_species, information_mode)

func new_seed(game: RefCounted) -> void:
	var value: int = int(Time.get_unix_time_from_system() * 1000) % 1000000
	if value == game.seed_value: value += 1
	choose_starter(value)
