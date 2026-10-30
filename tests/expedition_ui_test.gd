extends SceneTree
## Isolated scene-level checks. The launcher assigns a temporary XDG data directory.
var app: Control
var checks: int = 0
var failures: int = 0

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func press(id: String) -> void:
	var button: BaseButton = app.registry.get(id)
	if not is_instance_valid(button) or button.disabled:
		expect(false, "Reachable control " + id)
		return
	button.pressed.emit()
	await process_frame

func _init() -> void:
	call_deferred("run")

func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	expect(app.screens.top() == "menu" and root.gui_get_focus_owner().get_meta("ui_id", "") == "menu.play", "Default focus is expedition")
	await press("menu.play")
	expect(app.screens.top() == "starter", "Play opens starter choice")
	await press("starter.ember")
	expect(app.screens.top() == "map" and app.expedition.phase == "map", "Starter opens expedition map")
	var initial: String = JSON.stringify(app.expedition.snapshot())
	await press("map.node.clearing")
	expect(JSON.stringify(app.expedition.snapshot()) == initial and app.screens.top() == "map", "Selecting a node does not enter or consume RNG")
	expect(app.registry["map.node.boss"].disabled, "Boss is visibly locked")
	var before_formation: String = JSON.stringify([app.game.hand, app.game.deck, app.game.discard_pile, app.game.rng.state])
	await press("map.formation")
	await press("formation.0.0")
	await press("formation.confirm")
	expect(app.screens.top() == "map" and app.game.party[0].slot == 0, "Formation can move the starter on the map")
	expect(JSON.stringify([app.game.hand, app.game.deck, app.game.discard_pile, app.game.rng.state]) == before_formation, "Formation preserves cards and RNG")
	await press("map.node.clearing")
	await press("map.confirm")
	expect(app.screens.top() == "battle" and app.expedition.current_node_id == "clearing", "Confirm enters clearing")
	var stable: String = JSON.stringify(app.expedition.snapshot())
	var save_before_id: String = str(app.run_save.load_snapshot().get("checkpoint_id", ""))
	var save_before: String = JSON.stringify(app.run_save.load_snapshot())
	app.queue_free()
	await process_frame
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	expect(not app.registry["menu.continue"].disabled, "Reconstructed app offers Continue")
	await press("menu.play")
	expect(app.screens.top() == "confirm_new", "New run asks before replacing checkpoint")
	await press("new.cancel")
	expect(JSON.stringify(app.run_save.load_snapshot()) == save_before, "Cancel new preserves saved state and RNG")
	await press("menu.practice")
	await press("starter.ember")
	expect(app.screens.top() == "battle" and not app.expedition_active, "Practice opens battle independently")
	expect(JSON.stringify(app.run_save.load_snapshot()) == save_before, "Practice leaves expedition checkpoint intact")
	app._return_menu()
	await process_frame
	await press("menu.continue")
	expect(app.screens.top() == "battle" and JSON.stringify(app.expedition.snapshot()) == stable, "Continue restores exact committed battle, hand and RNG")
	# Play a legal clearing and accept its capture through the scene before testing map navigation.
	var turns: int = 0
	while app.game.phase == "battle" and turns < 20:
		app.game.selected = app.game.best_selection()
		if app.game.preview().valid: app.game.play()
		else: app.game.redraw()
		turns += 1
	app._sync_phase()
	await process_frame
	expect(app.screens.top() == "reward", "Legal clearing reaches reward")
	await press("reward.0")
	await press("capture.reserve")
	await press("capture.confirm")
	await press("map.node.spring")
	var route_before: String = JSON.stringify(app.expedition.snapshot())
	expect(app.map_root._selected_id == "spring" and app.registry["map.selection.detail"].text.contains("Nascente"), "Spring is selected without entering it")
	expect(app.registry["map.node.spring"].text.begins_with("◆"), "Selected spring displays its selection marker")
	await press("map.pause")
	await press("pause.resume")
	expect(app.map_root._selected_id == "spring" and app.registry["map.selection.detail"].text.contains("Nascente"), "Pause and resume preserve the selected route and details")
	expect(app.registry["map.node.spring"].text.begins_with("◆"), "Pause and resume preserve the visible selection marker")
	expect(JSON.stringify(app.expedition.snapshot()) == route_before, "Pause and resume preserve controller state and RNG")
	await press("map.pause")
	await press("pause.settings")
	var large_text: CheckButton = app.registry["settings.large_text"]
	large_text.button_pressed = not large_text.button_pressed
	await process_frame
	await press("settings.back")
	await press("pause.resume")
	expect(app.map_root._selected_id == "spring" and app.registry["map.selection.detail"].text.contains("Nascente"), "Changing text scale and returning preserves the selected route and details")
	expect(app.registry["map.node.spring"].text.begins_with("◆"), "Changing text scale and returning preserves the visible selection marker")
	expect(JSON.stringify(app.expedition.snapshot()) == route_before, "Changing text scale preserves controller state and RNG")
	# Direct terminal fixture verifies profile idempotence, independently of battle simulation.
	app.game.phase = "victory"
	app.checkpoint_id = "isolated-terminal-fixture"
	app.result_recorded = false
	var runs_before: int = int(app.stats.runs)
	app._record_result()
	app.result_recorded = false
	app._record_result()
	expect(int(app.stats.runs) == runs_before + 1, "Recording the same terminal checkpoint twice counts one run")
	app._return_menu()
	await process_frame
	await press("menu.play")
	await press("new.confirm")
	await press("starter.moss")
	expect(app.screens.top() == "map" and app.game.starter_species == "moss", "Confirmed new run B starts after run A")
	var b_id: String = app.checkpoint_id
	var b_saved: Dictionary = app.run_save.load_snapshot()
	expect(b_saved.get("checkpoint_id", "") == b_id, "Confirmed run B owns the new checkpoint")
	var records: Array = app.run_save._records()
	var latest: int = app.run_save._latest(records)
	expect(latest >= 0, "Run B checkpoint exists before corruption fixture")
	if latest >= 0:
		var broken: FileAccess = FileAccess.open(app.run_save._slot_path(latest), FileAccess.WRITE)
		broken.store_string("{truncated")
		broken.close()
		var recovered: Dictionary = app.run_save.load_snapshot()
		expect(recovered.is_empty() or recovered.get("checkpoint_id", "") != save_before_id, "Corrupt new run B never resurrects replaced run A")
	# Restore B to isolate the completed-ID fixture from the corruption fixture.
	expect(app.run_save.save(b_saved), "B checkpoint restored for completed-ID fixture")
	app.game.phase = "victory"
	app.result_recorded = false
	app._record_result()
	app._return_menu()
	await process_frame
	expect(app.registry["menu.continue"].disabled and app.saved_checkpoint.is_empty(), "A completed checkpoint ID cannot Continue from an old nonterminal checkpoint")
	app.queue_free()
	app = null
	await process_frame
	await create_timer(0.3).timeout
	print("Expedition UI: %d assertions, %d failures" % [checks, failures])
	quit(1 if failures else 0)
