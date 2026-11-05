extends "res://scripts/main.gd"
var fixture_name: String = ""
var fixture_ready: bool = false
var cadence_start: int = 0
var cadence_frame: int = 0
var cadence: Array = []

func _process(_delta: float) -> void:
	if not OS.has_feature("web") or not fixture_ready: return
	var now: int = Time.get_ticks_usec()
	if cadence_start == 0:
		cadence_start = now
		cadence_frame = Engine.get_frames_drawn()
	elif now - cadence_start >= 2000000:
		var frames: int = Engine.get_frames_drawn() - cadence_frame
		cadence.append({"time_us": now, "frames": frames, "fps": frames * 1000000.0 / (now - cadence_start)})
		JavaScriptBridge.eval("window.fixtureCadence = " + JSON.stringify(cadence))
		cadence_start = now
		cadence_frame = Engine.get_frames_drawn()
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
	screens.reset("map" if candidate.phase in ["map", "event"] else "battle")
	_sync_phase()
	fixture_ready = true
	_queue_debug()

func _publish_test_state() -> void:
	await super._publish_test_state()
	if browser_test:
		JavaScriptBridge.eval("if(window.umbralState) Object.assign(window.umbralState, %s)" % JSON.stringify({"fixture": fixture_name, "fixture_ready": fixture_ready}), true)
