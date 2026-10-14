extends SceneTree
## Real Godot input events validate keyboard/controller routing without a physical pad claim.
var app: Control
var checks: int = 0
var failed: int = 0

func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + description)

func key(code: int) -> void:
	for down in [true, false]:
		var event = InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame

func pad(button: int) -> void:
	for down in [true, false]:
		var event = InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame

func focus_key() -> String:
	var node = root.gui_get_focus_owner()
	return node.get_meta("ui_id", "") if is_instance_valid(node) else ""

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	expect(focus_key() == "menu.play", "Title gives initial focus to Play")
	await pad(JOY_BUTTON_DPAD_DOWN)
	expect(focus_key() == "menu.codex", "Controller d-pad moves through title choices")
	await pad(JOY_BUTTON_A)
	expect(app.screens.top() == "codex" and focus_key() == "codex.back", "Controller A opens the focused codex")
	await pad(JOY_BUTTON_B)
	expect(app.screens.top() == "menu" and focus_key() == "menu.codex", "Controller B restores the previous menu focus")
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	expect(app.screens.entries == ["menu", "settings"], "Keyboard opens options from title")
	await key(KEY_TAB)
	await key(KEY_TAB)
	expect(focus_key() == "settings.reduced_motion", "Tab reaches reduced-motion without escaping the modal")
	await key(KEY_ENTER)
	expect(app.preferences.values.reduced_motion, "Keyboard toggles and persists reduced motion")
	await key(KEY_ESCAPE)
	expect(app.screens.top() == "menu" and focus_key() == "menu.settings", "Back from options restores title focus")
	await key(KEY_UP)
	await key(KEY_UP)
	await key(KEY_ENTER)
	await process_frame
	expect(app.screens.top() == "battle" and app.game.hand.size() == 6, "Keyboard starts an actual expedition")
	var id: int = app.registry["hand.0"].get_instance_id()
	await key(KEY_1)
	await key(KEY_2)
	expect(app.game.selected.size() == 2 and app.registry["hand.0"].get_instance_id() == id, "Selection preserves the card node and focus infrastructure")
	await key(KEY_C)
	expect(app.screens.top() == "inspect", "Inspection is accessible without the mouse")
	expect(app.modal_root.z_index > 6, "Modal renders above lifted cards")
	await key(KEY_ESCAPE)
	expect(app.screens.top() == "battle", "Back from inspection preserves combat")
	await key(KEY_ESCAPE)
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	expect(app.screens.entries == ["battle", "pause", "settings"], "Nested options retain pause and combat")
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE)
	expect(app.screens.top() == "battle" and app.game.selected.size() == 2, "Resuming keeps the selected powers")
	await pad(JOY_BUTTON_X)
	await pad(JOY_BUTTON_X)
	expect(app.game.actions == 1, "Repeated cast during feedback cannot spend another round")
	await create_timer(0.25).timeout
	expect(not app.busy and app.game.phase == "battle", "Feedback completes and releases input")
	expect(app.effects.trauma == 0 and app.effects.particles.is_empty(), "Reduced-motion casting has no shake or particles")
	expect(app.audio.voices.size() == 4, "Repeated feedback uses a bounded audio pool")
	print(JSON.stringify({"suite": "ui_input_flow", "checks": checks, "failed": failed, "device_validation": "synthetic Godot keyboard/gamepad events"}))
	app.audio.shutdown()
	await create_timer(0.12).timeout
	root.remove_child(app)
	app.queue_free()
	await process_frame
	quit(0 if failed == 0 else 1)
