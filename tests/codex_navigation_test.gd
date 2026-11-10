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
func key(code: int, shift: bool = false) -> void:
	for down in [true,false]:
		var event = InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.shift_pressed = shift
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame
	for frame in range(4): await process_frame
func pad(button: int) -> void:
	for down in [true,false]:
		var event = InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame
	for frame in range(4): await process_frame
func expect_codex_focus(message: String) -> bool:
	var focused: Control = root.gui_get_focus_owner()
	return expect(is_instance_valid(focused) and app.screen_host.modal_root.is_ancestor_of(focused) and focused.is_visible_in_tree(), message)
func check_forward_focus(context: String) -> void:
	if not expect_codex_focus(context+": destination receives focus without another input"): return
	expect(root.gui_get_focus_owner() == app.registry["codex.section.story"], context+": reading tab is the destination focus")
	# Walk past one complete cycle: a single Tab must not start at the title
	# behind the modal, and wrapping must remain inside the rebuilt record.
	for step in range(app.focus_registry.groups["codex"].size()+1):
		await key(KEY_TAB)
		if not expect_codex_focus(context+": Tab stays in the codex at step %d" % step): return
	await key(KEY_TAB,true)
	expect_codex_focus(context+": Shift+Tab stays in the codex")
func press(id: String) -> void:
	if not expect(app.registry.has(id) and is_instance_valid(app.registry[id]),"Reachable control: "+id): return
	app.registry[id].grab_focus()
	await key(KEY_ENTER)
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await create_timer(0.1).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/codex-navigation/"+name+".png")
func check_form_links() -> void:
	var record = preload("res://scripts/ui/codex/record.gd").new()
	var controls: Dictionary = {}
	var selected: Array = []
	root.add_child(record)
	record.setup(null, func(control: Control, id: String, _screen: String): controls[id] = control, 1.0)
	record.form_requested.connect(func(id: String): selected.append(id))
	record._form_links([
		{"id": "branch_a", "name": "Primeira forma longa"},
		{"id": "branch_b", "name": "Segunda forma longa"},
		{"id": "branch_c", "name": "Terceira forma longa"},
	])
	for frame in range(4): await process_frame
	var scroll: ScrollContainer = record.get_node("FormLinksScroll")
	expect(controls.size() == 3 and controls.has("codex.evolution"), "Every discovered branch has a registered link and the first keeps its ID")
	for id in controls:
		var button: Button = controls[id]
		expect(button.size.x >= button.get_combined_minimum_size().x and button.size.x >= 180, "Branch names have their full natural width")
	controls["codex.evolution.2"].grab_focus()
	for frame in range(5): await process_frame
	expect(scroll.scroll_horizontal > 0 and controls["codex.evolution.2"].has_focus(), "Keyboard focus scrolls the last branch into view")
	controls["codex.evolution.2"].pressed.emit()
	expect(selected == ["branch_c"], "The branch link emits the selected form ID")
	root.remove_child(record)
	record.queue_free()
	await process_frame

func check_immediate_back() -> void:
	expect(app.screen_host.modal_root.go_back(), "Related power Back has an origin")
	var origin: Control = app.registry["codex.related.fireball"]
	if expect(root.gui_get_focus_owner() == origin, "Back restores keyboard focus synchronously before the next input"):
		var event = InputEventKey.new()
		event.keycode = KEY_TAB
		event.physical_keycode = KEY_TAB
		event.pressed = true
		Input.parse_input_event(event)
		await process_frame
		var moved: Control = root.gui_get_focus_owner()
		expect(is_instance_valid(moved) and moved != origin and app.screen_host.modal_root.is_ancestor_of(moved), "Immediate Tab advances inside the restored codex")
		event.pressed = false
		Input.parse_input_event(event)
		for frame in range(4): await process_frame
		expect(root.gui_get_focus_owner() == moved, "Deferred scroll never steals the focus chosen by a quick Tab")
	else:
		for frame in range(4): await process_frame
	origin.grab_focus()

func run() -> void:
	await check_form_links()
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.visual_capture = true
	app.preferences.values.reduced_motion = true
	for species in Content.SPECIES:
		app.codex_progress.mark("umbrals",species)
		app.codex_progress.mark("umbrals",str(Content.SPECIES[species].art[1]).get_file())
	for power in Content.POWERS: app.codex_progress.mark("powers",power)
	await process_frame
	if app.screens.top() == "menu": await press("menu.settings")
	await press("settings.codex")
	await press("codex.section.details")
	await press("codex.related.fireball")
	await check_forward_focus("Related power")
	await check_immediate_back()
	if not expect(app.screens.top() == "codex", "Back from a related power keeps the codex open"):
		await finish()
		return
	expect(app.screen_host.modal_root.category == "umbrals" and app.screen_host.modal_root.selected == "ember", "Back restores originating Umbral")
	expect(app.screen_host.modal_root.record_section == "details", "Back restores originating record tab")
	expect(root.gui_get_focus_owner() == app.registry["codex.related.fireball"], "Back restores the related-power focus")
	# Follow two links from a lineage on the second page, including a scrolled record.
	await press("codex.next")
	await press("codex.entry.dew")
	await press("codex.evolution")
	expect(app.screen_host.modal_root.selected == "mareveu", "Evolution opens the evolved record")
	await check_forward_focus("Evolution")
	await press("codex.section.details")
	app.registry["codex.related.moon_tide"].grab_focus()
	for frame in range(4): await process_frame
	# Use the real scroll produced by revealing the focused link; its position
	# depends on the record layout, and the source must be genuinely visible.
	await process_frame
	var saved_scroll: int = app.screen_host.modal_root.detail_scroll.scroll_vertical
	# A user may move the viewport after focusing a link. Back must preserve
	# that origin rather than run another automatic focus-reveal scroll.
	app.screen_host.modal_root.detail_scroll.scroll_vertical = maxi(1, saved_scroll - 11)
	saved_scroll = app.screen_host.modal_root.detail_scroll.scroll_vertical
	expect(saved_scroll > 0, "Origin record is genuinely scrolled")
	await capture("01-origin")
	var model: String = JSON.stringify([app.game.party,app.game.hand,app.game.rng.state,app.codex_progress.records,app.session.run_save.load_snapshot()])
	await key(KEY_ENTER)
	expect(app.screen_host.modal_root.category == "powers" and app.screen_host.modal_root.selected == "moon_tide", "Lineage technique opens from evolved record")
	await check_forward_focus("Lineage power")
	await capture("02-power")
	await key(KEY_ESCAPE)
	expect(app.screens.top() == "codex" and app.screen_host.modal_root.selected == "mareveu" and app.screen_host.modal_root.page == 1, "Back restores evolution and gallery page")
	if app.screen_host.modal_root.detail_scroll.scroll_vertical != saved_scroll:
		print(JSON.stringify({"event":"codex_scroll_mismatch","saved":saved_scroll,"actual":app.screen_host.modal_root.detail_scroll.scroll_vertical,"maximum":app.screen_host.modal_root.detail_scroll.get_v_scroll_bar().max_value,"page":app.screen_host.modal_root.detail_scroll.get_v_scroll_bar().page,"record_minimum":app.screen_host.modal_root.details.custom_minimum_size.y,"focus_rect":app.registry["codex.related.moon_tide"].get_global_rect()}))
	expect(app.screen_host.modal_root.detail_scroll.scroll_vertical == saved_scroll, "Back restores exact scroll position")
	expect(root.gui_get_focus_owner() == app.registry["codex.related.moon_tide"], "Back restores technique focus")
	await capture("03-returned")
	await press("codex.back")
	expect(app.screens.top() == "codex" and app.screen_host.modal_root.selected == "dew" and app.screen_host.modal_root.page == 1, "Visible Back button restores base lineage on its page")
	expect(root.gui_get_focus_owner() == app.registry["codex.evolution"], "Evolution link focus restored")
	await pad(JOY_BUTTON_A)
	expect(app.screen_host.modal_root.selected == "mareveu", "Controller A opens the evolved record")
	if expect_codex_focus("Controller evolution receives focus"):
		expect(root.gui_get_focus_owner() == app.registry["codex.section.story"], "Controller evolution starts at the reading tab")
		await pad(JOY_BUTTON_DPAD_DOWN)
		expect(root.gui_get_focus_owner() == app.registry["codex.section.details"], "Controller down reaches the destination details tab")
		await pad(JOY_BUTTON_A)
		expect(app.screen_host.modal_root.record_section == "details" and root.gui_get_focus_owner() == app.registry["codex.section.details"], "Controller A activates details and keeps focus on the rebuilt tab")
	await pad(JOY_BUTTON_B)
	expect(app.screen_host.modal_root.selected == "dew" and root.gui_get_focus_owner() == app.registry["codex.evolution"], "Controller B restores the originating form and link focus")
	await pad(JOY_BUTTON_B)
	expect(app.screens.top() == "settings", "Controller Back closes at the history root")
	expect(root.gui_get_focus_owner() == app.registry["settings.codex"], "Closing restores menu focus")
	expect(model == JSON.stringify([app.game.party,app.game.hand,app.game.rng.state,app.codex_progress.records,app.session.run_save.load_snapshot()]), "Navigation leaves game, knowledge, checkpoint and RNG unchanged")
	# Explicit category choice starts a new consultation, rather than keeping stale link history.
	if app.screens.top() == "menu": await press("menu.settings")
	await press("settings.codex")
	await press("codex.section.details")
	await press("codex.related.fireball")
	await press("codex.tab.items")
	await key(KEY_ESCAPE)
	expect(app.screens.top() == "settings", "Explicit category navigation clears old link history")
	await finish()
func finish() -> void:
	app.audio.shutdown()
	root.remove_child(app)
	app.queue_free()
	await create_timer(0.2).timeout
	for frame in range(3): await process_frame
	print(JSON.stringify({"suite":"codex_navigation","checks":checks,"failed":failed}))
	call_deferred("quit",1 if failed else 0)
