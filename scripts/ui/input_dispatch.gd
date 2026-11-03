extends RefCounted
## Translate physical input to screen-scoped intents without mutating the session.

static func device(event: InputEvent, previous: String) -> String:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion: return "gamepad"
	if event is InputEventKey: return "keyboard"
	if event is InputEventMouseButton: return "mouse"
	return previous

static func ignored(event: InputEvent) -> bool:
	return (event is InputEventKey and event.echo) or (event is InputEventJoypadMotion and absf(event.axis_value) < 0.25)

static func intent(event: InputEvent, screen: String) -> Dictionary:
	if event.is_action_pressed("umbral_back"): return {"action": "back"}
	if screen != "battle": return {}
	for i in range(6):
		if event.is_action_pressed("umbral_card_%d" % i): return {"action": "card", "index": i}
	for action in ["cast", "redraw", "plan", "clear", "inspect"]:
		if event.is_action_pressed("umbral_" + action): return {"action": action}
	if event.is_action_pressed("umbral_target_previous"): return {"action": "target", "direction": -1}
	if event.is_action_pressed("umbral_target_next"): return {"action": "target", "direction": 1}
	return {}
