extends Node
## Opt-in read-only Web diagnostics; all gameplay interaction stays real input.
const Content = preload("res://scripts/content.gd")
const PowerCard = preload("res://scripts/ui/power_card.gd")
const Actor = preload("res://scripts/ui/actor.gd")
const Navigation = preload("res://scripts/ui/navigation.gd")
var enabled: bool = false
var visual_capture: bool = false
var navigation: Navigation
var snapshot: Callable
var geometry_queued: bool = false
var debug_queued: bool = false
var published_revision: int = 0
var input_serial: int = 0
var interaction_serial: int = 0
var last_interaction: String = ""

func configure(nav: Navigation, read_snapshot: Callable) -> void:
	navigation = nav
	snapshot = read_snapshot
	if OS.has_feature("web"):
		enabled = bool(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('test') === '1'"))
		visual_capture = bool(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('visual') === '1'"))
	navigation.changed.connect(queue_snapshot)
	navigation.geometry_changed.connect(queue_geometry_snapshot)
	navigation.activated.connect(func(key: String):
		if enabled:
			interaction_serial += 1
			last_interaction = key
			queue_snapshot())

func observe_input(event: InputEvent) -> void:
	if enabled and event.is_pressed():
		input_serial += 1
		queue_snapshot()

func queue_snapshot() -> void:
	if enabled and not debug_queued:
		debug_queued = true
		call_deferred("_publish")

func queue_geometry_snapshot() -> void:
	if enabled and not geometry_queued:
		geometry_queued = true
		get_tree().process_frame.connect(_geometry_ready, CONNECT_ONE_SHOT)

func _geometry_ready() -> void:
	geometry_queued = false
	queue_snapshot()

func _publish() -> void:
	debug_queued = false
	if not enabled: return
	var state: Dictionary = snapshot.call()
	var controls: Dictionary = {}
	for key in navigation.controls:
		var control = navigation.controls[key]
		if not is_instance_valid(control) or not control.is_inside_tree(): continue
		var center: Vector2 = control.get_global_transform() * (control.size * 0.5)
		var rect: Rect2 = control.get_global_rect()
		var data: Dictionary = {"x": rect.position.x, "y": rect.position.y, "w": control.size.x, "h": control.size.y, "cx": center.x, "cy": center.y, "visible": control.is_visible_in_tree() and _visible_rect(control).intersects(control.get_global_rect()), "fully_visible": _fully_visible(control), "active": control.get_meta("ui_screen", "") == str(state.screen), "disabled": control.disabled if control is BaseButton else false, "focused": control.has_focus()}
		if control is BaseButton: data["text"] = control.text
		data["instance_id"] = control.get_instance_id()
		if control is PowerCard:
			data["title_fits"] = control.title_fits()
			data["reduced_motion"] = control.reduced_motion
		if control is Button and not control is PowerCard and not control is Actor:
			var style: StyleBox = control.get_theme_stylebox("normal", "Button")
			if style is StyleBoxFlat and style.bg_color.a >= 0.95 and not control.disabled:
				var foreground: Color = control.get_theme_color("font_focus_color" if control.has_focus() else "font_color", "Button")
				data["foreground"] = [foreground.r, foreground.g, foreground.b]
				data["background"] = [style.bg_color.r, style.bg_color.g, style.bg_color.b]
		if control is Range: data["value"] = control.value
		if control is CheckButton: data["checked"] = control.button_pressed
		controls[key] = data
	var focus: Control = get_viewport().gui_get_focus_owner()
	published_revision += 1
	var order: Array[String] = []
	for control in navigation.focus_groups.get(str(state.screen), []):
		if is_instance_valid(control): order.append(str(control.get_meta("ui_id", "")))
	state.merge({"focus_order": order, "version": Content.VERSION, "revision": published_revision, "controls": controls, "focused": focus.get_meta("ui_id", "") if is_instance_valid(focus) else "", "node_count": get_tree().get_node_count(), "input_serial": input_serial, "interaction_serial": interaction_serial, "last_interaction": last_interaction})
	JavaScriptBridge.eval("window.umbralState = " + JSON.stringify(state), true)

func _visible_rect(control: Control) -> Rect2:
	var visible: Rect2 = get_viewport().get_visible_rect()
	var ancestor: Node = control.get_parent()
	while ancestor != null:
		if ancestor is Control and ancestor.clip_contents: visible = visible.intersection(ancestor.get_global_rect())
		ancestor = ancestor.get_parent()
	return visible

func _fully_visible(control: Control) -> bool:
	return _visible_rect(control).encloses(control.get_global_rect())
