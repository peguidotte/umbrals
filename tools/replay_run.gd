extends SceneTree
const Rules = preload("res://scripts/rules.gd")
const Replay = preload("res://scripts/session/run_replay.gd")
const Fixtures = preload("res://tests/support/scenario_fixtures.gd")

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = args.find("--input")
	if index < 0 or index + 1 >= args.size():
		quit(2)
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(args[index + 1]))
	if not data is Dictionary or not data.get("commands") is Array:
		quit(2)
		return
	var game = Rules.new(Fixtures.catalog_for(data.get("name", "battle")))
	if data.has("initial_state") and not game.restore_state(data.initial_state):
		quit(2)
		return
	var report: Dictionary = Replay.run(game, data.commands)
	report["suite"] = "run_replay"
	report["checks"] = maxi(1, data.commands.size())
	report["failed"] = 0 if report.ok else 1
	print(JSON.stringify(report))
	quit(0 if report.ok else 1)
