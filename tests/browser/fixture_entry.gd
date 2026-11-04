extends "res://scripts/main.gd"
var fixture_name: String = ""
var fixture_ready: bool = false
func _ready() -> void:
	super._ready()
	if OS.has_feature("web"):
		fixture_name = str(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('fixture') || ''"))
		if not fixture_name.is_empty(): call_deferred("_boot_fixture")

func _boot_fixture() -> void:
	var payload: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/browser/fixtures.json"))
	if not payload is Dictionary or not payload.has(fixture_name): return
	var candidate = preload("res://scripts/expedition/expedition.gd").new()
	if not candidate.restore(payload[fixture_name]): return
	_start_game()
	session.expedition = candidate
	session.expedition_active = true
	runtime.bind_game(session.expedition.battle)
	if bool(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('large_text') === '1'")): preferences.set_value("large_text", true)
	_sync_battle()
	screens.reset("battle")
	_sync_phase()
	fixture_ready = true
	_queue_debug()

func _publish_test_state() -> void:
	super._publish_test_state()
	if browser_test:
		JavaScriptBridge.eval("if(window.umbralState) Object.assign(window.umbralState, %s)" % JSON.stringify({"fixture": fixture_name, "fixture_ready": fixture_ready}), true)
