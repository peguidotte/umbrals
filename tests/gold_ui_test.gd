extends SceneTree
const Progress = preload("res://scripts/codex_progress.gd")
const Rules = preload("res://scripts/rules.gd")
var app: Control
var checks: int = 0
var failed: int = 0
func _init() -> void:
	call_deferred("run")
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		printerr("FAIL: ", message)
func key(code: int) -> void:
	for down in [true, false]:
		var event = InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame
	await process_frame
func activate(id: String) -> void:
	expect(app.registry.has(id) and is_instance_valid(app.registry[id]), "Control exists: " + id)
	app.registry[id].grab_focus()
	await key(KEY_ENTER)
func capture(file: String) -> void:
	await create_timer(0.25).timeout
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	expect(root.get_texture().get_image().save_png("res://test-results/gold-ui/" + file + ".png") == OK, "Capture " + file)
func texts(node: Node) -> String:
	var result: String = node.text if node is Label or node is Button else ""
	for child in node.get_children(): result += "\n" + texts(child)
	return result
func run() -> void:
	# This test is run with a disposable XDG_DATA_HOME, never the player's save.
	var p = Progress.new()
	expect(not p.knows("umbrals", "ember"), "New profile is empty")
	var rules = Rules.new()
	rules.new_run(42013, "partial", "ember")
	var before: String = JSON.stringify([rules.party, rules.hand, rules.inventory, rules.enemy_plan, rules.rng.state])
	p.observe(rules, false)
	expect(before == JSON.stringify([rules.party, rules.hand, rules.inventory, rules.enemy_plan, rules.rng.state]), "Discovery leaves run and RNG untouched")
	expect(p.knows("umbrals", "ember") and not p.knows("umbrals", "ignivar"), "Base discovery does not reveal evolution")
	expect(p.knows("powers", "fireball") and not p.knows("powers", "inferno"), "Known powers only")
	expect(p.knows("items", "potion"), "Owned items are recorded")
	var reloaded = Progress.new()
	reloaded.load_saved()
	expect(reloaded.records == p.records, "Discovery roundtrip persists")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Progress.PATH))
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.preferences.values.reduced_motion = true
	app.visual_capture = true
	app.screen_host.menu_root.apply_preferences(true, true, 1.0)
	await process_frame
	await capture("01-menu")
	expect(root.gui_get_focus_owner() == app.registry["menu.play"], "Menu starts focused")
	await activate("menu.codex")
	expect(app.screens.top() == "codex", "Menu opens codex")
	expect(not "Combustão" in texts(app.screen_host.modal_root), "Empty codex hides trait")
	await capture("02-undiscovered")
	await key(KEY_ESCAPE)
	expect(app.screens.top() == "menu" and root.gui_get_focus_owner() == app.registry["menu.codex"], "Back restores menu focus")
	await activate("menu.play")
	expect(app.screens.top() == "journey", "Play still opens expedition choices")
	await key(KEY_ESCAPE)
	# Real game startup, no combat simulation.
	app._start_game(42013, "ember")
	await process_frame
	var snapshot: String = JSON.stringify([app.game.party, app.game.hand, app.game.rng.state])
	await key(KEY_ESCAPE)
	await activate("pause.codex")
	expect(app.screens.top() == "codex", "Pause opens codex")
	expect(app.codex_progress.knows("umbrals", "ember"), "Actual run records starter")
	await capture("03-discovered")
	await activate("codex.section.details")
	await activate("codex.related.fireball")
	expect(app.screen_host.modal_root.category == "powers" and app.screen_host.modal_root.selected == "fireball", "Related power opens record")
	await capture("04-power")
	for category in ["passives", "items", "umbrals"]:
		await activate("codex.tab." + category)
		expect(app.screen_host.modal_root.category == category, "Category " + category)
	await activate("codex.next")
	expect(app.screen_host.modal_root.page == 1, "Pagination works")
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE)
	expect(app.screens.top() == "battle", "Return to paused battle")
	expect(snapshot == JSON.stringify([app.game.party, app.game.hand, app.game.rng.state]), "Codex does not change battle")
	# A discovered evolution is visible; the preview uses exact evolved atlas.
	app.codex_progress.mark("umbrals", "moss")
	app.codex_progress.mark("umbrals", "ignivar")
	app.codex_progress.save()
	app._push("codex")
	await process_frame
	await capture("05-evolution")
	for dimensions in [Vector2i(1280, 720), Vector2i(1024, 768)]:
		root.size = dimensions
		await process_frame
		await capture("codex-%dx%d" % [dimensions.x, dimensions.y])
		for control in app.focus_registry.groups.get("codex", []):
			if control.get_parent() == app.screen_host.modal_root.entries or control == app.screen_host.modal_root.close:
				expect(root.get_visible_rect().encloses(control.get_global_rect()), "Visible control within viewport")
	app._pop()
	app._push("codex")
	app.screen_host.modal_root.text_scale = 1.25
	# Rebuild through the actual accessibility preference flow.
	app.preferences.set_value("large_text", true)
	await process_frame
	await capture("06-large-text")
	expect(app.screens.top() == "codex" and is_instance_valid(app.registry["codex.back"]), "Large text keeps codex and return control")
	app.audio.shutdown()
	root.remove_child(app)
	app.queue_free()
	p = null
	reloaded = null
	rules = null
	await create_timer(0.2).timeout
	for frame in range(3): await process_frame
	print(JSON.stringify({"suite": "gold_ui", "checks": checks, "failed": failed}))
	call_deferred("quit", 1 if failed else 0)
