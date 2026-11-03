extends RefCounted
## Completed-run persistence, separate from UI construction and preferences.
const Storage = preload("res://scripts/storage.gd")
const Rules = preload("res://scripts/rules.gd")
const Ids = preload("res://scripts/domain/ids.gd")
const PATH = "user://umbral_stats_v1.json"
const LEGACY_PATH = "user://feral_hand_stats.json"
const WEB_KEY = "umbral.stats.v1"
var writer: Callable = Storage.write_json
var values: Dictionary = {"wins": 0, "runs": 0, "best_damage": 0}
var recorded: bool = false
var last_save_ok: bool = true

func load_saved() -> void:
	var data: Dictionary = Storage.read_json(PATH, WEB_KEY, LEGACY_PATH)
	for key in values:
		if data.get(key) is float or data.get(key) is int: values[key] = maxi(0, int(data[key]))

func begin_run() -> void:
	recorded = false

func record(game: Rules) -> bool:
	if recorded or game.phase not in [Ids.VICTORY, Ids.DEFEAT]: return false
	recorded = true
	values.runs += 1
	if game.phase == Ids.VICTORY: values.wins += 1
	values.best_damage = maxi(values.best_damage, game.total_damage)
	last_save_ok = writer.call(PATH, WEB_KEY, values)
	if not last_save_ok: push_warning("Could not persist run statistics.")
	return true
