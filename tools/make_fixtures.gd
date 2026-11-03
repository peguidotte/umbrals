extends SceneTree
const Fixtures = preload("res://tests/support/scenario_fixtures.gd")
const Expedition = preload("res://scripts/expedition/expedition.gd")
const Replay = preload("res://scripts/expedition/replay.gd")
func _init() -> void:
	var folder: String = OS.get_environment("UMBRAL_RESULTS_DIR")
	if folder.is_empty(): folder = "res://test-results"
	DirAccess.make_dir_recursive_absolute(folder.path_join("fixture-records"))
	var payload: Dictionary = {}
	var checks: int = 0
	var failed: int = 0
	for name in Fixtures.NAMES:
		var fixture: Dictionary = Fixtures.make(name)
		var run = Expedition.new()
		var valid: bool = not fixture.is_empty() and run.restore(JSON.parse_string(JSON.stringify(fixture.initial_state)))
		checks += 1
		if not valid: failed += 1; continue
		valid = Replay.execute(run, fixture.commands).ok
		checks += 1
		if not valid: failed += 1; continue
		checks += 1
		if run.snapshot() != fixture.snapshot: failed += 1; continue
		payload[name] = fixture.snapshot
		FileAccess.open(folder.path_join("fixture-records/" + name + ".json"), FileAccess.WRITE).store_string(JSON.stringify(fixture))
	FileAccess.open(folder.path_join("fixtures.json"), FileAccess.WRITE).store_string(JSON.stringify(payload))
	var report: Dictionary = {"suite": "scenario_fixtures", "checks": checks, "failed": failed, "names": payload.keys()}
	FileAccess.open(folder.path_join("fixture-report.json"), FileAccess.WRITE).store_string(JSON.stringify(report))
	print(JSON.stringify(report))
	quit(0 if failed == 0 else 1)
