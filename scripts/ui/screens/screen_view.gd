extends Control
## Views emit intent; the coordinator owns commands. No view holds the coordinator.
signal action_requested(command: String, payload: Variant)
const UI = preload("res://scripts/ui/kit.gd")
const Ids = preload("res://scripts/domain/ids.gd")
const Preferences = preload("res://scripts/ui/preferences.gd")
const Navigation = preload("res://scripts/ui/navigation.gd")
var ui: UI
var preferences: Preferences
var navigation: Navigation

func configure(kit: UI, prefs: Preferences, nav: Navigation) -> void:
	ui = kit
	preferences = prefs
	navigation = nav

func request(command: String, payload: Variant = null) -> void:
	action_requested.emit(command, payload)

func _button(parent: Node, text: String, callback: Callable, key: String, screen: String, primary: bool = false) -> Button:
	var button: Button = ui.button(text, callback, key, primary)
	parent.add_child(button)
	navigation.register(button, key, screen)
	return button

func _full(node: Control, parent: Node) -> void:
	parent.add_child(node)
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _at(node: Control, parent: Control, anchor: Vector2, extent: Vector2) -> void:
	parent.add_child(node)
	node.anchor_left = anchor.x
	node.anchor_right = anchor.x
	node.anchor_top = anchor.y
	node.anchor_bottom = anchor.y
	node.offset_left = -extent.x * 0.5
	node.offset_right = extent.x * 0.5
	node.offset_top = -extent.y * 0.5
	node.offset_bottom = extent.y * 0.5
