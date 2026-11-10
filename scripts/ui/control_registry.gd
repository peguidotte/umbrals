extends RefCounted
## Registers focusable controls and emits semantic UI activity.
signal debug_requested
signal card_pointed(index: int)
signal interaction(key: String)
var registry: Dictionary
var screens: RefCounted
var audio: Node
var browser_test: bool

func configure(controls: Dictionary, screen_stack: RefCounted, sound: Node, testing: bool) -> void:
	registry = controls
	screens = screen_stack
	audio = sound
	browser_test = testing

func register(node: Control, key: String, screen: String) -> Control:
	node.set_meta("ui_id", key)
	node.set_meta("ui_screen", screen)
	registry[key] = node
	node.focus_entered.connect(debug_requested.emit)
	node.focus_entered.connect(_reveal.bind(node))
	node.item_rect_changed.connect(debug_requested.emit)
	if key.begins_with("hand."):
		node.pose_settled.connect(debug_requested.emit)
		var index: int = int(key.get_slice(".", 1))
		node.focus_entered.connect(func(): card_pointed.emit(index))
		node.mouse_entered.connect(func(): card_pointed.emit(index))
	if node is BaseButton:
		node.pressed.connect(func():
			if screens.root() == "menu": audio.confirm()
			else: audio.play("hover", true))
		if screens.root() == "menu" and screen != "menu":
			node.focus_entered.connect(audio.navigate)
			node.mouse_entered.connect(audio.navigate)
		if browser_test:
			node.pressed.connect(func(): interaction.emit(key))
	return node

func _reveal(control: Control) -> void:
	# Focus can be restored before the new modal has its final layout.
	await control.get_tree().process_frame
	if not is_instance_valid(control) or not control.is_inside_tree() or not control.has_focus(): return
	var parent: Node = control.get_parent()
	while parent != null:
		if parent is ScrollContainer: parent.ensure_control_visible(control)
		parent = parent.get_parent()
	debug_requested.emit()
