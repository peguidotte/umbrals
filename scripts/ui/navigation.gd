extends RefCounted
signal geometry_changed
signal changed
signal activated(key: String)
signal card_focused(index: int)
const UI = preload("res://scripts/ui/kit.gd")
const Ids = preload("res://scripts/domain/ids.gd")
var controls: Dictionary[String, Control] = {}
var focus_memory: Dictionary[String, String] = {}
var focus_groups: Dictionary[String, Array] = {}
var watched_scrolls: Dictionary[int, bool] = {}
var viewport: Viewport

func _init(root_viewport: Viewport) -> void:
	viewport = root_viewport

func register(node: Control, key: String, screen: String) -> Control:
	node.set_meta("ui_id", key)
	node.set_meta("ui_screen", screen)
	controls[key] = node
	node.tree_exiting.connect(func():
		if controls.get(key) == node: controls.erase(key)
		if focus_groups.has(screen): focus_groups[screen].erase(node))
	node.focus_entered.connect(changed.emit)
	node.focus_entered.connect(geometry_changed.emit)
	_watch_scroll_ancestors(node)
	node.item_rect_changed.connect(changed.emit)
	if key.begins_with("hand."):
		var index: int = int(key.get_slice(".", 1))
		node.focus_entered.connect(func(): card_focused.emit(index))
		node.mouse_entered.connect(func(): card_focused.emit(index))
	if node is BaseButton:
		node.pressed.connect(func(): activated.emit(key))
	return node

func remember(screen: String) -> void:
	var focused: Control = viewport.gui_get_focus_owner()
	if is_instance_valid(focused): focus_memory[screen] = focused.get_meta("ui_id", "")

func set_group(screen: String) -> void:
	var group: Array = []
	for key in controls:
		var control = controls[key]
		if is_instance_valid(control) and control.is_inside_tree() and control.get_meta("ui_screen", "") == screen and control.is_visible_in_tree():
			if control is BaseButton and control.disabled: continue
			group.append(control)
	focus_groups[screen] = group
	UI.focus_chain(group, screen in [Ids.BATTLE, Ids.REWARD, Ids.REPLACEMENT])

func focus(key: String, screen: String) -> void:
	if controls.has(key) and is_instance_valid(controls[key]) and controls[key].is_visible_in_tree():
		var target: Control = controls[key]
		if not (target is BaseButton and target.disabled):
			target.grab_focus()
			changed.emit()
			return
	var group: Array = focus_groups.get(screen, [])
	if not group.is_empty():
		var target: Control = controls.get("hand.0") if screen == Ids.BATTLE and controls.has("hand.0") else group[0]
		if is_instance_valid(target): target.grab_focus()
	changed.emit()

func _watch_scroll_ancestors(node: Control) -> void:
	var ancestor: Node = node.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			var id: int = ancestor.get_instance_id()
			if not watched_scrolls.has(id):
				watched_scrolls[id] = true
				ancestor.get_h_scroll_bar().value_changed.connect(_scroll_changed)
				ancestor.get_v_scroll_bar().value_changed.connect(_scroll_changed)
				ancestor.tree_exiting.connect(func(): watched_scrolls.erase(id))
		ancestor = ancestor.get_parent()

func _scroll_changed(_value: float) -> void:
	geometry_changed.emit()
