extends SceneTree
const Space = preload("res://scripts/ui/refuge_space.gd")
var app: Control
var checks: int = 0
var failed: int = 0

func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + description)

func key(code: int, pressed: bool) -> void:
	var event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame

func hold(code: int, frames: int) -> void:
	await key(code, true)
	for i in range(frames): await physics_frame
	await key(code, false)
	await physics_frame

func button(code: int) -> void:
	for down in [true, false]:
		var event = InputEventJoypadButton.new()
		event.button_index = code
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame

func stick(value: float) -> void:
	var event = InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	Input.parse_input_event(event)
	await process_frame

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var straight: Vector2 = Space.walk(Space.SPAWN, Vector2.RIGHT, 0.1)
	var diagonal: Vector2 = Space.walk(Space.SPAWN, Vector2.ONE, 0.1)
	expect(straight == diagonal, "Vertical input cannot change lane or horizontal speed")
	var wall: Vector2 = Space.SPAWN
	for i in range(150): wall = Space.walk(wall, Vector2.LEFT, 0.1)
	expect(Space.clear(wall) and wall.x == Space.LEFT, "Left boundary blocks without tunnelling")
	for i in range(150): wall = Space.walk(wall, Vector2.RIGHT, 0.1)
	expect(Space.clear(wall) and wall.x == Space.RIGHT, "Right boundary blocks without tunnelling")
	expect(Space.nearest(Space.SPAWN).is_empty(), "Spawn cannot interact remotely")
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.registry["menu.play"].pressed.emit()
	await process_frame
	await physics_frame
	var room: Control = app.screen_host.refuge_root
	expect(app.screens.entries == ["refuge"] and room.has_focus(), "Play enters a focused spatial root")
	var before: String = JSON.stringify([app.game.rng.state, app.game.party, app.session.run_save.load_snapshot(), app.session.stats])
	await key(KEY_E, true)
	await key(KEY_E, false)
	expect(app.screens.top() == "refuge", "Interact outside station range does not open a panel")
	var repeat = InputEventKey.new()
	repeat.keycode = KEY_UP
	repeat.physical_keycode = KEY_UP
	repeat.pressed = true
	repeat.echo = true
	Input.parse_input_event(repeat)
	await process_frame
	expect(room.has_focus(), "OS key repeat is consumed instead of moving GUI focus")
	await key(KEY_UP, false)
	await hold(KEY_UP, 20)
	await hold(KEY_A, 102)
	expect(room.canvas.point.distance_to(Space.SPAWN) > 250 and room.has_focus(), "Arrow and WASD walk without moving GUI focus")
	expect(Space.nearest(room.canvas.point) == "codex", "Real held input reaches the reading desk")
	await key(KEY_E, true)
	await key(KEY_E, false)
	expect(app.screens.top() == "codex" and not room.active, "Proximity interaction opens the real discovery codex")
	var paused: Vector2 = room.canvas.point
	await hold(KEY_D, 10)
	expect(room.canvas.point == paused, "Codex captures movement input")
	await key(KEY_ESCAPE, true)
	await key(KEY_ESCAPE, false)
	await physics_frame
	expect(app.screens.top() == "refuge" and room.has_focus() and room.canvas.point == paused, "Closing codex restores position and avatar focus")
	await stick(0.1)
	for i in range(10): await physics_frame
	expect(room.canvas.point == paused, "Analog deadzone prevents drift")
	await stick(1.0)
	for i in range(18): await physics_frame
	await stick(0)
	expect(room.canvas.point.x > paused.x + 40, "Controller left stick moves the avatar")
	await button(JOY_BUTTON_B)
	expect(app.screens.top() == "menu", "Controller B leaves the room without a stuck root")
	app.registry["menu.play"].pressed.emit()
	await process_frame
	await physics_frame
	expect(room.canvas.point == Space.SPAWN, "Fresh entry resets only transient avatar position")
	await hold(KEY_D, 205)
	expect(app.screens.top() == "journey" and app.registry["journey.continue"].disabled, "Walking through right exit opens departure without accepting New")
	var departure: Vector2 = room.canvas.point
	await button(JOY_BUTTON_B)
	await physics_frame
	expect(room.canvas.point == departure and room.has_focus(), "Controller back restores room position and focus")
	for i in range(12): await physics_frame
	expect(app.screens.top() == "refuge", "Exit threshold does not reopen on return")
	app.preferences.set_value("reduced_motion", true)
	await process_frame
	await hold(KEY_A, 18)
	expect(room.canvas.point != departure and room.canvas.stride == 0, "Reduced motion retains locomotion and removes cosmetic stride")
	expect(JSON.stringify([app.game.rng.state, app.game.party, app.session.run_save.load_snapshot(), app.session.stats]) == before, "Walking, codex, shortcuts and input leave RNG, HP, checkpoint and stats untouched")
	app.registry["refuge.codex"].pressed.emit()
	expect(app.screens.top() == "refuge" and room.pointer_target == Space.STATIONS.codex.x, "Object activation starts walking instead of opening a remote panel")
	for i in range(330): await physics_frame
	await process_frame
	var under_settings: Vector2 = room.canvas.point
	expect(app.screens.top() == "codex", "Walking to an activated object opens its real panel on arrival")
	await key(KEY_A, true)
	app.registry["codex.back"].pressed.emit()
	await process_frame
	for i in range(8): await physics_frame
	expect(room.canvas.point == under_settings, "Held input from a modal cannot move the avatar on return")
	await key(KEY_A, false)
	await physics_frame
	await hold(KEY_A, 10)
	expect(room.canvas.point.x < under_settings.x, "Releasing then pressing re-arms movement")
	expect(not room.notice_label.visible and not app.registry.has("refuge.consult") and not app.registry.has("refuge.move_left"), "Room has no persistent instruction bar or movement buttons")
	app.registry["refuge.exit"].pressed.emit()
	await physics_frame
	expect(room.pointer_target > Space.EXIT, "Exit object requests a physical walk across the threshold")
	await hold(KEY_A, 2)
	expect(is_nan(room.pointer_target) and room.pointer_intent.is_empty(), "Direct movement cancels automatic approach")
	app.registry["refuge.codex"].pressed.emit()
	room._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	expect(is_nan(room.pointer_target) and not room.armed, "Application focus loss cancels pending object interaction")
	app.registry["refuge.exit"].pressed.emit()
	for i in range(360): await physics_frame
	expect(app.screens.top() == "journey", "Pointer approach crosses the right boundary into preparation")
	await button(JOY_BUTTON_B)
	for i in range(12): await physics_frame
	expect(app.screens.top() == "refuge", "Returning at the door does not reopen preparation automatically")
	app.registry["refuge.exit"].pressed.emit()
	for i in range(12): await physics_frame
	expect(app.screens.top() == "journey", "Explicit door activation works again after returning at its threshold")
	await button(JOY_BUTTON_B)
	app.registry["refuge.codex"].pressed.emit()
	await key(KEY_TAB, true)
	await key(KEY_TAB, false)
	expect(not room.has_focus() and is_nan(room.pointer_target), "Tab cancels an approach instead of leaving a resumable destination")
	var published: Array[Vector2] = []
	room.changed.connect(func(): published.append(room.canvas.point))
	room.grab_focus()
	room.armed = true
	room.canvas.point = Vector2(Space.LEFT + 1, Space.FLOOR_Y)
	room.elapsed = 0
	Input.action_press("umbral_refuge_left")
	room._physics_process(1.0 / 60)
	Input.action_release("umbral_refuge_left")
	expect(not published.is_empty() and published.back().x == Space.LEFT, "Boundary arrival publishes the exact final position between periodic updates")
	expect(JSON.stringify([app.game.rng.state, app.game.party, app.session.run_save.load_snapshot(), app.session.stats]) == before, "Pointer approaches, door re-entry and focus cancellation preserve gameplay and checkpoint state")
	app.audio.shutdown()
	app.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print(JSON.stringify({"suite": "refuge", "checks": checks, "failed": failed}))
	quit(1 if failed else 0)
