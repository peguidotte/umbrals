extends SceneTree
const Fixtures = preload("res://tests/support/scenario_fixtures.gd")
const Rules = preload("res://scripts/rules.gd")
const Replay = preload("res://scripts/session/run_replay.gd")

func _init() -> void:
	var fixtures: Dictionary = {}
	var checks: int = 0
	var failed: int = 0
	for name in Fixtures.NAMES:
		var fixture: Dictionary = Fixtures.make(name)
		checks += 1
		if fixture.is_empty():
			failed += 1
			continue
		var game = Rules.new(Fixtures.catalog_for(name))
		checks += 1
		if not game.restore_state(JSON.parse_string(JSON.stringify(fixture.initial_state))): failed += 1
		var replayed: Dictionary = Replay.run(game, fixture.commands)
		checks += 1
		if not replayed.ok or replayed.state != fixture.snapshot: failed += 1
		fixtures[name] = fixture
	var directory: String = OS.get_environment("UMBRAL_RESULTS_DIR")
	if directory.is_empty(): directory = "res://test-results"
	DirAccess.make_dir_recursive_absolute(directory.path_join("fixture-records"))
	for name in fixtures:
		var record = FileAccess.open(directory.path_join("fixture-records/%s.json" % name), FileAccess.WRITE)
		record.store_string(JSON.stringify(fixtures[name]))
	var output = FileAccess.open(directory.path_join("fixtures.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify(fixtures))
	var report: Dictionary = {"suite": "scenario_fixtures", "checks": checks, "failed": failed, "fixtures": fixtures.keys()}
	var report_file = FileAccess.open(directory.path_join("fixture-report.json"), FileAccess.WRITE)
	report_file.store_string(JSON.stringify(report, "  "))
	print(JSON.stringify(report))
	quit(0 if failed == 0 else 1)
