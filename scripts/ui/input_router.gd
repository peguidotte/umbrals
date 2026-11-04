extends RefCounted
## Route physical events to semantic screen and battle intents. The caller marks
## handled input using the returned value; no scene or game command is held here.
signal debug_requested
signal selection_refresh_requested
signal finish_replacements_requested
signal screen_requested(screen: String)
signal screen_pop_requested
signal return_menu_requested
signal card_requested(index: int)
signal cast_requested
signal redraw_requested
signal plan_requested
signal inspect_requested
signal clear_requested
signal target_requested(direction: int)

const InputDispatch = preload("res://scripts/ui/input_dispatch.gd")

var last_device: String = "keyboard"
var input_serial: int = 0

func route(event: InputEvent, screen: String, session_active: bool, browser_test: bool) -> bool:
	if InputDispatch.ignored(event): return false
	if browser_test and event.is_pressed():
		input_serial += 1
		debug_requested.emit()
	var device: String = InputDispatch.device(event, last_device)
	if device != last_device:
		last_device = device
		if session_active: selection_refresh_requested.emit()
	var intent: Dictionary = InputDispatch.intent(event, screen)
	if intent.is_empty(): return false
	match intent.action:
		"back":
			if screen == "ko_replacement": finish_replacements_requested.emit()
			elif screen in ["battle", "map"]: screen_requested.emit("pause")
			elif screen in ["victory", "defeat", "refuge"]: return_menu_requested.emit()
			elif screen != "menu": screen_pop_requested.emit()
		"card": card_requested.emit(int(intent.index))
		"cast": cast_requested.emit()
		"redraw": redraw_requested.emit()
		"plan": plan_requested.emit()
		"inspect": inspect_requested.emit()
		"clear": clear_requested.emit()
		"target": target_requested.emit(int(intent.direction))
	return true
