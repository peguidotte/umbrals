extends SceneTree
const Space = preload("res://scripts/ui/house_space.gd")
const StairCases = preload("res://tests/support/house_stair_cases.gd")
const PietroCases = preload("res://tests/support/pietro_pose_cases.gd")
var app: Control
var room: Control
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

func settle(frames: int = 3) -> void:
	for i in range(frames): await physics_frame

func hold(code: int, frames: int) -> void:
	await key(code, true)
	await settle(frames)
	await key(code, false)
	await settle()

func button(code: int) -> void:
	for down in [true, false]:
		var event = InputEventJoypadButton.new()
		event.button_index = code
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame
	await settle()

func stick(value: float) -> void:
	var event = InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	Input.parse_input_event(event)
	await process_frame

func approach(identity: String, frames: int = 430) -> void:
	app.registry["refuge." + identity].pressed.emit()
	await settle(frames)

func snapshot() -> String:
	return JSON.stringify([app.game.rng.state, app.game.party, app.session.run_save.load_snapshot(), app.session.stats])

func _init() -> void:
	call_deferred("run")

func run() -> void:
	StairCases.resume_cases(expect)
	PietroCases.run(expect)
	var straight: Vector2 = Space.walk(Space.SPAWN, Vector2.RIGHT, 0.1)
	expect(straight == Space.walk(Space.SPAWN, Vector2.ONE, 0.1), "Floor walking retains one horizontal lane and speed")
	var wall: Vector2 = Space.SPAWN
	for i in range(150): wall = Space.walk(wall, Vector2.LEFT, 0.1)
	expect(wall.x == Space.LEFT and wall.y == Space.FLOOR_Y, "Left boundary cannot tunnel")
	for i in range(150): wall = Space.walk(wall, Vector2.RIGHT, 0.1)
	expect(wall.x == Space.RIGHT, "Right boundary cannot tunnel")
	var upper_edge: Vector2 = Vector2(Space.UPPER_RIGHT - 1, Space.UPPER_Y)
	upper_edge = Space.walk(upper_edge, Vector2.RIGHT, 1, true)
	expect(upper_edge == Space.STAIR_TOP, "Upper floor blocks walking into stair void")
	upper_edge = Space.walk(Vector2(Space.UPPER_LEFT + 1, Space.UPPER_Y), Vector2.LEFT, 1, true)
	expect(upper_edge.x == Space.UPPER_LEFT and upper_edge.y == Space.UPPER_Y, "Upper left wall retains its own floor height")
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.registry["menu.play"].pressed.emit()
	await process_frame
	room = app.screen_host.refuge_root
	StairCases.clearance_cases(room, expect)
	expect(app.screens.entries == ["refuge"] and room.has_focus(), "Play enters a focused spatial root")
	expect(room.canvas.room == "bedroom" and room.motion.waking and room.canvas.pose_state().pose == "lying" and room.canvas.rest_angle == 0, "First entry begins with the drawn lying pose on Pietro's bed")
	var before: String = snapshot()
	app.registry["refuge.exit"].pressed.emit()
	expect(app.screens.top() == "refuge" and is_nan(room.pointer_target), "Hidden objects cannot open remotely from another room")
	await settle(160)
	expect(not room.motion.waking and room.canvas.point == Space.SPAWN and room.canvas.rest_angle == 0, "Wake settles at the bed's floor without game-state changes")
	await key(KEY_E, true)
	await key(KEY_E, false)
	expect(app.screens.top() == "refuge", "Interact outside object range opens no panel")
	var continuous: bool = true
	var last_point: Vector2 = room.canvas.point
	for i in range(60):
		room.canvas.point = Space.walk(room.canvas.point, Vector2.RIGHT, 1.0 / 60)
		room._publish_motion(last_point, 1.0 / 60, room.canvas.room)
		continuous = continuous and room.canvas.point.distance_to(last_point) <= Space.SPEED / 60 + 0.01
		last_point = room.canvas.point
	expect(continuous and room.canvas.room == "living" and room.canvas.point.x > 900, "Crossing bedroom/living boundary preserves continuous world coordinates")
	expect(room.public_state().location == "pietro_house", "Initial home is separate from future portable shelter")
	var repeat = InputEventKey.new()
	repeat.keycode = KEY_UP
	repeat.physical_keycode = KEY_UP
	repeat.pressed = true
	repeat.echo = true
	Input.parse_input_event(repeat)
	await process_frame
	expect(room.has_focus(), "OS repeat does not move GUI focus away from walking")
	await key(KEY_UP, false)
	await hold(KEY_D, 30)
	expect(Space.nearest(room.canvas.point, false) == "codex", "Held keyboard movement reaches real reading desk")
	await key(KEY_E, true)
	await key(KEY_E, false)
	expect(app.screens.top() == "codex" and not room.active, "Proximity interaction opens the discovery codex")
	var paused: Vector2 = room.canvas.point
	await hold(KEY_D, 10)
	expect(room.canvas.point == paused, "Codex owns movement input")
	await key(KEY_ESCAPE, true)
	await key(KEY_ESCAPE, false)
	await settle()
	expect(room.has_focus() and room.canvas.point == paused, "Closing codex restores position and walking focus")
	await stick(0.1)
	await settle(10)
	expect(room.canvas.point == paused, "Analog deadzone prevents drift")
	await stick(1.0)
	await settle(18)
	await stick(0)
	expect(room.canvas.point.x > paused.x + 40, "Controller stick moves the avatar")
	await hold(KEY_D, 340)
	expect(room.canvas.room == "kitchen" and app.screens.top() == "refuge", "Continuous ground lane reaches kitchen without replacing the scene")
	await approach("stairs", 85)
	expect(room.motion.on_stairs and room.canvas.point.y < Space.FLOOR_Y, "Stair interaction walks onto visible treads")
	room._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var stair_pause: Vector2 = room.canvas.point
	await settle(10)
	expect(room.canvas.point == stair_pause and is_zero_approx(room.motion.automatic), "Focus loss pauses automatic stairs")
	await hold(KEY_DOWN, 12)
	expect(room.canvas.point.y > stair_pause.y, "Down explicitly reverses stair movement")
	await hold(KEY_UP, 260)
	expect(room.motion.upper and not room.motion.on_stairs and room.canvas.point == Space.STAIR_TOP, "Climbing joins upstairs floor at its physical endpoint")
	await hold(KEY_A, 55)
	expect(room.canvas.point.y == Space.UPPER_Y and room.canvas.point.x < Space.STAIR_TOP.x, "Mother bedroom is reachable by walking left along upper floor")
	await approach("stairs", 350)
	expect(not room.motion.upper and not room.motion.on_stairs and room.canvas.point == Space.STAIR_BOTTOM, "Stair descent returns to exact same ground endpoint")
	await hold(KEY_A, 110)
	await approach("improvements", 50)
	expect("indisponíveis" in room.notice, "Workbench makes no functional promise")
	await settle(220)
	expect(not room.notice_label.visible and not app.registry.has("refuge.move_left"), "No permanent instruction bar or movement controls")
	await button(JOY_BUTTON_B)
	expect(app.screens.top() == "menu", "Controller back reaches title")
	app.registry["menu.play"].pressed.emit()
	await settle()
	expect(room.canvas.room == "living" and not room.motion.waking, "Returning to home preserves session position without replaying wake")
	await hold(KEY_D, 300)
	expect(app.screens.top() == "journey" and app.registry["journey.continue"].disabled, "Physical exterior exit opens preparation without starting New")
	var departure: Vector2 = room.canvas.point
	await button(JOY_BUTTON_B)
	await settle(12)
	expect(room.canvas.point == departure and room.has_focus(), "Returning from preparation restores exact position and focus")
	expect(app.screens.top() == "refuge", "Standing at exit does not reopen preparation")
	app.preferences.set_value("reduced_motion", true)
	await process_frame
	await hold(KEY_A, 18)
	expect(room.canvas.point != departure and room.canvas.stride == 0, "Reduced motion retains walking and suppresses stride")
	await hold(KEY_A, 450)
	app.registry["refuge.codex"].pressed.emit()
	expect(not is_nan(room.pointer_target) and app.screens.top() == "refuge", "Visible distant object starts a walk before consultation")
	await settle(140)
	expect(app.screens.top() == "codex", "Approach opens codex only on arrival")
	var under_modal: Vector2 = room.canvas.point
	await key(KEY_A, true)
	app.registry["codex.back"].pressed.emit()
	await settle(8)
	expect(room.canvas.point == under_modal, "Held modal input is not inherited on return")
	await key(KEY_A, false)
	await settle()
	await hold(KEY_D, 10)
	expect(room.canvas.point.x > under_modal.x, "Release and press rearms walking")
	app.registry["refuge.exit"].pressed.emit()
	await hold(KEY_A, 2)
	expect(is_nan(room.pointer_target) and room.pointer_intent.is_empty(), "Direct movement cancels pointer approach")
	await hold(KEY_D, 550)
	expect(app.screens.top() == "journey", "Continuous walking crosses exterior threshold")
	await button(JOY_BUTTON_B)
	await approach("exit", 12)
	expect(app.screens.top() == "journey", "Explicit door re-entry works at its threshold")
	await button(JOY_BUTTON_B)
	app.registry["refuge.codex"].pressed.emit()
	await key(KEY_TAB, true)
	await key(KEY_TAB, false)
	expect(not room.has_focus() and is_nan(room.pointer_target), "Tab cancels any resumable automatic approach")
	var published: Array[Vector2] = []
	room.changed.connect(func(): published.append(room.canvas.point))
	room.grab_focus()
	room.armed = true
	room.canvas.room = "bedroom"
	room.canvas.point = Vector2(Space.LEFT + 1, Space.FLOOR_Y)
	room.elapsed = 0
	Input.action_press("umbral_refuge_left")
	room._physics_process(1.0 / 60)
	Input.action_release("umbral_refuge_left")
	expect(not published.is_empty() and published.back().x == Space.LEFT, "Boundary arrival publishes exact endpoint between periodic updates")
	room.motion.wake(room.canvas, false)
	room._room_changed()
	await key(KEY_E, true)
	await key(KEY_E, false)
	expect(not room.motion.waking and room.has_focus(), "Interact skips wake without stranding input")

	expect(snapshot() == before, "Wake, all rooms, stairs, codex and exits preserve gameplay RNG, roster, checkpoint and statistics")
	app.audio.shutdown()
	app.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print(JSON.stringify({"suite": "refuge", "checks": checks, "failed": failed}))
	quit(1 if failed else 0)
