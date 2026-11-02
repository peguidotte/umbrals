extends SceneTree
const Preferences = preload("res://scripts/ui/preferences.gd")
const SettingsMenu = preload("res://scripts/ui/settings_menu.gd")
var app: Control
var checks: int = 0
var failed: int = 0

func _init() -> void: call_deferred("run")
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		printerr("FAIL: ",message)
func settle() -> void:
	for frame in range(5): await process_frame
func key(code: Key) -> void:
	for down in [true,false]:
		var event = InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame
	await settle()
func press(id: String) -> void:
	var control: Control = app.registry.get(id)
	if not is_instance_valid(control) or not control.is_visible_in_tree():
		expect(false,"Reachable control "+id)
		return
	control.grab_focus()
	await key(KEY_ENTER)
func pad_back() -> void:
	for down in [true,false]:
		var event = InputEventJoypadButton.new()
		event.button_index = JOY_BUTTON_B
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame
	await settle()
func focus_id() -> String:
	var owner: Control = root.gui_get_focus_owner()
	return str(owner.get_meta("ui_id","")) if is_instance_valid(owner) else ""
func snapshot() -> String:
	return JSON.stringify([app.game.rng.state,app.game.party,app.game.hand,app.game.deck,app.game.discard_pile,app.run_save.load_snapshot()])
func expect_footer_clearance() -> void:
	var safe: Rect2 = app.modal_root.panel.get_global_rect().grow(-32)
	var back: Rect2 = app.registry["settings.back"].get_global_rect().grow(8)
	expect(safe.encloses(back),"Back and its decorative frame retain clearance from the panel ornament")
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/settings-gold/"+name+".png")
func run() -> void:
	if DisplayServer.get_name() == "headless": root.size = Vector2i(1600,900)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.visual_capture = true
	await settle()
	expect(ProjectSettings.get_setting("application/config/name") == "Umbral","The application uses the confirmed name without a subtitle")
	var initial: String = snapshot()
	await capture("00-title")
	await press("menu.settings")
	expect(app.modal_root is SettingsMenu and app.screens.entries == ["menu","settings"],"Title opens the dedicated settings view")
	expect(focus_id() == "settings.music","Initial focus reaches music")
	expect(Rect2(Vector2.ZERO,app.size).encloses(app.modal_root.panel.get_global_rect()),"Panel and Back fit in the standard viewport")
	expect_footer_clearance()
	expect(app.modal_root.columns.size.y <= app.modal_root.scroll.size.y+1,"Standard settings fit without vertical scrolling")
	expect(app.modal_root.columns.size.x <= app.modal_root.scroll.size.x+1,"Columns fit without horizontal clipping")
	await capture("02-options")
	await key(KEY_RIGHT)
	expect(is_equal_approx(app.preferences.values.music,0.60),"Keyboard adjusts music in the existing five-percent steps")
	await key(KEY_TAB)
	expect(focus_id() == "settings.sfx","Tab reaches effects")
	await key(KEY_RIGHT)
	expect(is_equal_approx(app.preferences.values.sfx,0.85),"Keyboard adjusts effects")
	await key(KEY_TAB)
	expect(focus_id() == "settings.reduced_motion","Tab order reaches accessibility after audio")
	await key(KEY_ENTER)
	expect(app.preferences.values.reduced_motion and app.menu_root.reduced_motion,"Reduced motion takes effect immediately")
	await key(KEY_TAB)
	await key(KEY_ENTER)
	expect(app.preferences.values.flashes,"Flashes remain individually configurable")
	await key(KEY_TAB)
	await key(KEY_ENTER)
	expect(app.preferences.values.large_text and app.modal_root.text_scale > 1,"Text size rebuilds the settings view")
	expect(focus_id() == "settings.large_text","Text rebuild restores the same focused setting")
	expect(Rect2(Vector2.ZERO,app.size).encloses(app.modal_root.panel.get_global_rect()),"Panel and Back remain visible with enlarged text")
	expect_footer_clearance()
	expect(app.modal_root.columns.size.x <= app.modal_root.scroll.size.x+1,"Enlarged text fits column widths")
	await capture("03-large-text")
	var view_id: int = app.modal_root.get_instance_id()
	await press("settings.info.full")
	expect(app.preferences.values.information_mode == "full","Information mode can be selected with keyboard")
	expect(app.modal_root.get_instance_id() == view_id and focus_id() == "settings.info.full","Mode changes preserve the view and focused choice")
	expect(app.modal_root.mode_buttons.values().filter(func(button: Button): return button.button_pressed).size() == 1,"Exactly one information mode is selected")
	await key(KEY_ENTER)
	expect(app.registry["settings.info.full"].button_pressed,"Reactivating the selected mode cannot leave all modes off")
	var saved = Preferences.new()
	saved.load_saved()
	expect(saved.values == app.preferences.values,"All adjusted settings persist through the existing store")
	expect(snapshot() == initial,"Title settings do not change run state or gameplay RNG")
	await capture("04-full-selected")
	await pad_back()
	expect(app.screens.top() == "menu" and focus_id() == "menu.settings","Controller Back restores the originating title button")
	await press("menu.settings")
	expect(app.registry["settings.info.full"].button_pressed and app.registry["settings.large_text"].button_pressed,"Reopening reflects persisted selections")
	if DisplayServer.get_name() != "headless":
		for resolution in [Vector2i(1280,720),Vector2i(1024,768)]:
			root.size = resolution
			await create_timer(0.2).timeout
			await settle()
			expect(root.size == resolution,"Native viewport resized to "+str(resolution))
			expect(Rect2(Vector2.ZERO,app.size).encloses(app.modal_root.panel.get_global_rect()),"Settings and Back remain inside viewport "+str(resolution))
			await capture("05-"+str(resolution.x)+"x"+str(resolution.y))
		root.size = Vector2i(1672,941)
		await settle()
	await key(KEY_ESCAPE)
	app._start_game(42013)
	await settle()
	app._push("pause")
	await settle()
	await press("pause.settings")
	expect(app.screens.entries == ["battle","pause","settings"],"The same settings view opens over pause")
	var battle_before: String = snapshot()
	var current_mode: String = app.game.information_mode
	await press("settings.info.hidden")
	expect(app.game.information_mode == current_mode and app.game.pending_information_mode == "hidden","Battle information changes apply to the next plan, preserving current information")
	expect(snapshot() == battle_before,"Changing paused settings preserves party, cards, RNG and run checkpoint")
	await pad_back()
	expect(app.screens.top() == "pause" and focus_id() == "pause.settings","Back returns to the originating pause menu")
	app.audio.shutdown()
	root.remove_child(app)
	app.queue_free()
	await create_timer(0.2).timeout
	await settle()
	print(JSON.stringify({"suite":"settings_menu","checks":checks,"failed":failed}))
	call_deferred("quit",1 if failed else 0)
