extends "res://scripts/main.gd"
## Alternate test-only boot scene. Release export excludes this directory.
const Fixtures = preload("res://tests/support/scenario_fixtures.gd")
var fixture_name: String = "battle"
var fixture_ready: bool = false

func _ready() -> void:
	if OS.has_feature("web"):
		fixture_name = str(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('fixture') || 'battle'"))
	if fixture_name not in Fixtures.NAMES:
		push_error("Unknown fixture")
		get_tree().quit(2)
		return
	game = Rules.new(Fixtures.catalog_for(fixture_name))
	super._ready()
	call_deferred("_open_fixture")

func _open_fixture() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/browser/fixtures.json"))
	if not data is Dictionary or not data.has(fixture_name):
		push_error("Missing fixture data")
		get_tree().quit(2)
		return
	if OS.has_feature("web") and bool(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('large_text') === '1'")):
		preferences.set_value("large_text", true)
	_start_game(42013)
	if not game.restore_state(data[fixture_name].snapshot):
		push_error("Fixture checkpoint rejected")
		get_tree().quit(2)
		return
	_sync_battle()
	_sync_phase()
	fixture_ready = true
	diagnostics.queue_snapshot()

func _debug_snapshot() -> Dictionary:
	var data: Dictionary = super._debug_snapshot()
	data["fixture"] = fixture_name
	data["fixture_ready"] = fixture_ready
	return data
