extends SceneTree
const Expedition = preload("res://scripts/expedition/expedition.gd")
const Replay = preload("res://scripts/expedition/replay.gd")
func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = args.find("--input")
	if index < 0 or index + 1 >= args.size(): quit(2); return
	var data: Dictionary = Replay.decode(JSON.parse_string(FileAccess.get_file_as_string(args[index + 1])))
	var run = Expedition.new()
	if data.is_empty() or not run.restore(data.initial_state): quit(2); return
	var report: Dictionary = Replay.execute(run, data.commands)
	report.merge({"suite": "run_replay", "checks": maxi(1, data.commands.size()), "failed": 0 if report.ok else 1})
	print(JSON.stringify(report))
	quit(0 if report.ok else 1)
