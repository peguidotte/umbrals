extends SceneTree
## Focused regression: follow record links, then return to the exact origin.
const Content = preload("res://scripts/content.gd")
var app: Control
var checks: int = 0
var failed: int = 0
func _init() -> void: call_deferred("run")
func expect(value: bool, message: String) -> bool:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: ", message)
	return value
func key(code: int) -> void:
	for down in [true,false]:
		var event = InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame
	for frame in range(4): await process_frame
func press(id: String) -> void:
	if not expect(app.registry.has(id) and is_instance_valid(app.registry[id]),"Reachable control: "+id): return
	app.registry[id].grab_focus()
	await key(KEY_ENTER)
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await create_timer(0.1).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/codex-navigation/"+name+".png")
func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.visual_capture = true
	app.preferences.values.reduced_motion = true
	for species in Content.SPECIES:
		app.codex_progress.mark("umbrals",species)
		app.codex_progress.mark("umbrals",str(Content.SPECIES[species].art[1]).get_file())
	for power in Content.POWERS: app.codex_progress.mark("powers",power)
	await process_frame
	await press("menu.codex")
	await press("codex.section.details")
	await press("codex.related.fireball")
	await key(KEY_ESCAPE)
	if not expect(app.screens.top() == "codex", "Back from a related power keeps the codex open"):
		await finish()
		return
	expect(app.modal_root.category == "umbrals" and app.modal_root.selected == "ember", "Back restores originating Umbral")
	expect(app.modal_root.record_section == "details", "Back restores originating record tab")
	expect(root.gui_get_focus_owner() == app.registry["codex.related.fireball"], "Back restores the related-power focus")
	# Follow two links from a lineage on the second page, including a scrolled record.
	await press("codex.next")
	await press("codex.entry.dew")
	await press("codex.evolution")
	expect(app.modal_root.selected == "mareveu", "Evolution opens the evolved record")
	await press("codex.section.details")
	app.registry["codex.related.moon_tide"].grab_focus()
	for frame in range(4): await process_frame
	# Use the real scroll produced by revealing the focused link; its position
	# depends on the record layout, and the source must be genuinely visible.
	await process_frame
	var saved_scroll: int = app.modal_root.detail_scroll.scroll_vertical
	expect(saved_scroll > 0, "Origin record is genuinely scrolled")
	await capture("01-origin")
	var model: String = JSON.stringify([app.game.party,app.game.hand,app.game.rng.state,app.codex_progress.records,app.run_save.load_snapshot()])
	await key(KEY_ENTER)
	expect(app.modal_root.category == "powers" and app.modal_root.selected == "moon_tide", "Lineage technique opens from evolved record")
	await capture("02-power")
	await key(KEY_ESCAPE)
	expect(app.screens.top() == "codex" and app.modal_root.selected == "mareveu" and app.modal_root.page == 1, "Back restores evolution and gallery page")
	expect(app.modal_root.detail_scroll.scroll_vertical == saved_scroll, "Back restores exact scroll position")
	expect(root.gui_get_focus_owner() == app.registry["codex.related.moon_tide"], "Back restores technique focus")
	await capture("03-returned")
	await press("codex.back")
	expect(app.screens.top() == "codex" and app.modal_root.selected == "dew" and app.modal_root.page == 1, "Visible Back button restores base lineage on its page")
	expect(root.gui_get_focus_owner() == app.registry["codex.evolution"], "Evolution link focus restored")
	for down in [true,false]:
		var event = InputEventJoypadButton.new()
		event.button_index = JOY_BUTTON_B
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame
	expect(app.screens.top() == "menu", "Controller Back closes at the history root")
	expect(root.gui_get_focus_owner() == app.registry["menu.codex"], "Closing restores menu focus")
	expect(model == JSON.stringify([app.game.party,app.game.hand,app.game.rng.state,app.codex_progress.records,app.run_save.load_snapshot()]), "Navigation leaves game, knowledge, checkpoint and RNG unchanged")
	# Explicit category choice starts a new consultation, rather than keeping stale link history.
	await press("menu.codex")
	await press("codex.section.details")
	await press("codex.related.fireball")
	await press("codex.tab.items")
	await key(KEY_ESCAPE)
	expect(app.screens.top() == "menu", "Explicit category navigation clears old link history")
	await finish()
func finish() -> void:
	app.audio.shutdown()
	root.remove_child(app)
	app.queue_free()
	await create_timer(0.2).timeout
	for frame in range(3): await process_frame
	print(JSON.stringify({"suite":"codex_navigation","checks":checks,"failed":failed}))
	call_deferred("quit",1 if failed else 0)
