class_name UmbralInputActions
extends RefCounted
## Bindings are data. Presentation reads actions, not raw keys.
const KEYS = {"cast": KEY_SPACE, "redraw": KEY_R, "inspect": KEY_C, "back": KEY_ESCAPE, "plan": KEY_P, "clear": KEY_BACKSPACE, "target_previous": KEY_Q, "target_next": KEY_E}
const PAD = {"cast": JOY_BUTTON_X, "redraw": JOY_BUTTON_RIGHT_SHOULDER, "inspect": JOY_BUTTON_Y, "back": JOY_BUTTON_B, "plan": JOY_BUTTON_LEFT_SHOULDER}

static func install() -> void:
	for action in KEYS:
		_register(action, KEYS[action], PAD.get(action, -1))
	for i in range(6): _register("card_%d" % i, KEY_1 + i, -1)
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
