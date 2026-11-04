class_name UmbralInputActions
extends RefCounted
## Bindings are data. Presentation reads actions, not raw keys.
const KEYS = {"cast": KEY_SPACE, "redraw": KEY_R, "inspect": KEY_C, "back": KEY_ESCAPE, "plan": KEY_P, "clear": KEY_BACKSPACE, "target_previous": KEY_Q, "target_next": KEY_E}
const PAD = {"cast": JOY_BUTTON_X, "redraw": JOY_BUTTON_RIGHT_SHOULDER, "inspect": JOY_BUTTON_Y, "back": JOY_BUTTON_B, "plan": JOY_BUTTON_LEFT_SHOULDER}

static func install() -> void:
	for action in KEYS:
		_register(action, KEYS[action], PAD.get(action, -1))
	for i in range(6): _register("card_%d" % i, KEY_1 + i, -1)
	_install_refuge()
	# Enter/A accepts focused controls; Space is reserved for casting, not a GUI double-fire.
	InputMap.action_erase_events("ui_accept")
	var enter = InputEventKey.new()
	enter.physical_keycode = KEY_ENTER
	InputMap.action_add_event("ui_accept", enter)
	var accept = InputEventJoypadButton.new()
	accept.button_index = JOY_BUTTON_A
	InputMap.action_add_event("ui_accept", accept)

static func _register(action: String, key: int, pad: int) -> void:
	var name: String = "umbral_" + action
	if not InputMap.has_action(name): InputMap.add_action(name, 0.2)
	InputMap.action_erase_events(name)
	var event = InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(name, event)
	if pad >= 0:
		var controller = InputEventJoypadButton.new()
		controller.button_index = pad
		InputMap.action_add_event(name, controller)


static func _install_refuge() -> void:
	_register("refuge_interact", KEY_E, JOY_BUTTON_A)
	var enter = InputEventKey.new()
	enter.physical_keycode = KEY_ENTER
	InputMap.action_add_event("umbral_refuge_interact", enter)
	var directions: Array = [
		["left", KEY_A, KEY_LEFT, JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0],
		["right", KEY_D, KEY_RIGHT, JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0],
		["up", KEY_W, KEY_UP, JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0],
		["down", KEY_S, KEY_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0]]
	for row in directions:
		var action: String = "refuge_" + row[0]
		_register(action, row[1], row[3])
		var arrow = InputEventKey.new()
		arrow.physical_keycode = row[2]
		InputMap.action_add_event("umbral_" + action, arrow)
		var stick = InputEventJoypadMotion.new()
		stick.axis = row[4]
		stick.axis_value = row[5]
		InputMap.action_add_event("umbral_" + action, stick)
