extends "res://scripts/main.gd"
var fixture_name: String = ""
var fixture_ready: bool = false
var cadence_start: int = 0
var cadence_frame: int = 0
var cadence: Array = []
var raster_window: Vector2i = Vector2i.ZERO
var raster_readback: Vector2i = Vector2i.ZERO

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
	if OS.has_feature("web") and bool(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('card_gallery') === '1'")):
		set_process_input(false)
		set_process_unhandled_input(false)
		var gallery = preload("res://tests/browser/card_gallery.gd").new()
		add_child(gallery)
		return
	# This boot is excluded from production packs; the bridge remains read-only.
	if OS.has_feature("web") and bool(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('card_preview') === '1'")):
		preload("res://scripts/assets/card_visual_catalog.gd").preview_enabled = true
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
		var diagnostics: Dictionary = {"fixture": fixture_name, "fixture_ready": fixture_ready}
		var catalog: RefCounted = preload("res://scripts/assets/card_visual_catalog.gd").active()
		if catalog != null and is_instance_valid(screen_host.battle_root):
			var renderer = preload("res://scripts/ui/card_renderer.gd")
			var rows: Array = []
			var expanded: Dictionary = {"visible": false, "mode": "in_place", "duplicate_projection": false}
			for card: Button in cards:
				if card.presentation.is_empty(): continue
				var art: Rect2 = renderer.geometry(card.size, card.presentation.visual.layout).art
				rows.append({"instance_id": card.card.instance_id, "node_id": card.get_instance_id(), "filter": card.texture_filter, "art_logical": [art.size.x, art.size.y], "fanned": card.fanned, "home_rotation": card.home_rotation, "scale": card.scale.x})
				if card.fan_prominent and card.chosen:
					expanded.merge({"visible": card.is_visible_in_tree() and screens.top() == "battle", "instance_id": card.card.instance_id, "node_id": card.get_instance_id(), "filter": card.texture_filter, "rect": [card.global_position.x, card.global_position.y, card.size.x * card.scale.x, card.size.y * card.scale.y], "art_logical": [art.size.x * card.scale.x, art.size.y * card.scale.y], "target_label": card.presentation.target.get("label", "")}, true)
			var window: Vector2i = DisplayServer.window_get_size()
			if window != raster_window:
				raster_window = window
				var pixels: Image = get_viewport().get_texture().get_image()
				raster_readback = pixels.get_size() if pixels != null else Vector2i.ZERO
			var reported: Vector2 = get_viewport().get_texture().get_size()
			diagnostics.card_raster = {"world_filter": world.texture_filter, "window_size": [window.x, window.y], "viewport_texture_reported_size": [reported.x, reported.y], "render_readback_size": [raster_readback.x, raster_readback.y], "hand": rows, "focus": expanded, "catalog": catalog.coverage_diagnostics()}
		JavaScriptBridge.eval("if(window.umbralState) Object.assign(window.umbralState, %s)" % JSON.stringify(diagnostics), true)
