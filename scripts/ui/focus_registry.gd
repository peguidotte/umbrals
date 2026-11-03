extends RefCounted
## Tracks screen focus independently of the views that create controls.
const UI = preload("res://scripts/ui/kit.gd")
var controls: Dictionary
var memory: Dictionary = {}
var groups: Dictionary = {}

func _init(registered: Dictionary) -> void:
	controls = registered

func remember(screen: String, focused: Control) -> void:
	if is_instance_valid(focused): memory[screen] = focused.get_meta("ui_id", "")

func set_group(screen: String) -> void:
	var group: Array = []
	for key in controls:
		var control = controls[key]
		if is_instance_valid(control) and control.is_inside_tree() and control.get_meta("ui_screen", "") == screen and control.is_visible_in_tree():
			if control.focus_mode == Control.FOCUS_NONE or (control is BaseButton and control.disabled): continue
			group.append(control)
	groups[screen] = group
	UI.focus_chain(group, screen in ["battle", "reward", "replacement"])

func restore(key: String, screen: String, cards: Array) -> void:
	if controls.has(key) and is_instance_valid(controls[key]) and controls[key].is_visible_in_tree():
		var target: Control = controls[key]
		if not (target is BaseButton and target.disabled):
			target.grab_focus()
			return
	var group: Array = groups.get(screen, [])
	if not group.is_empty():
		var target: Control = group[0]
		if screen == "battle":
			for card in cards:
				if is_instance_valid(card) and card.is_visible_in_tree() and not card.disabled:
					target = card
					break
		if is_instance_valid(target): target.grab_focus()
