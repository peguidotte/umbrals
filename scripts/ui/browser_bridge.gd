extends RefCounted
## Browser automation protocol and platform-specific window information.
## Callers supply a snapshot of presentation/game data; this object never owns
## or reaches back into the session coordinator.

const PowerCard = preload("res://scripts/ui/power_card.gd")
const Actor = preload("res://scripts/ui/actor.gd")

static func query_flags() -> Dictionary:
	if not OS.has_feature("web"):
		return {"browser_test": false, "visual_capture": false}
	return {
		"browser_test": bool(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('test') === '1'")),
		"visual_capture": bool(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('visual') === '1'")),
	}

static func smoke_exit_requested() -> bool:
	return "--smoke-exit" in OS.get_cmdline_user_args()

static func audio_snapshot(voice_pool: int) -> Dictionary:
	return {"voice_pool": voice_pool, "music_muted": AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "music_db": AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))}

static func title_audio_snapshot(active: bool, navigation_count: int, awakening_count: int) -> Dictionary:
	return {"active": active, "navigation_count": navigation_count, "awakening_count": awakening_count, "ui_muted": AudioServer.is_bus_mute(AudioServer.get_bus_index("UI"))}

static func apply_safe_margin(margin: MarginContainer, logical_size: Vector2) -> void:
	var inset: int = 32
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var window: Vector2i = DisplayServer.window_get_size()
	var additional_left: int = 0
	var additional_right: int = 0
	if safe.size.x > 0 and safe.size.x <= window.x and safe.size.y <= window.y:
		var scale_x: float = logical_size.x / maxf(1, window.x)
		additional_left = int(maxi(0, safe.position.x) * scale_x)
		additional_right = int(maxi(0, window.x - safe.end.x) * scale_x)
	margin.add_theme_constant_override("margin_left", inset + additional_left)
	margin.add_theme_constant_override("margin_right", inset + additional_right)

static func public_individual(individual: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in ["uid", "species", "passive", "form_id", "name", "art", "hp", "max_hp", "attack", "defense", "speed", "block", "statuses", "status_sources", "resistances", "slot", "can_act_round"]:
		if individual.has(key): result[key] = individual[key].duplicate(true) if individual[key] is Dictionary or individual[key] is Array else individual[key]
	return result

static func controls_snapshot(registry: Dictionary, screen: String) -> Dictionary:
	var controls: Dictionary = {}
	for key in registry:
		var control = registry[key]
		if not is_instance_valid(control) or not control.is_inside_tree(): continue
		var center: Vector2 = control.get_global_transform() * (control.size * 0.5)
		var rect: Rect2 = control.get_global_rect()
		var clip: Rect2 = Rect2(Vector2.ZERO, control.get_viewport_rect().size)
		var ancestor: Node = control.get_parent()
		var scrollable: bool = false
		while ancestor != null:
			if ancestor is ScrollContainer: scrollable = true
			if ancestor is Control and ancestor.clip_contents: clip = clip.intersection(ancestor.get_global_rect())
			ancestor = ancestor.get_parent()
		var data: Dictionary = {"x": rect.position.x, "y": rect.position.y, "w": control.size.x, "h": control.size.y, "cx": center.x, "cy": center.y, "visible": control.is_visible_in_tree(), "active": control.get_meta("ui_screen", "") == screen, "disabled": control.disabled if control is BaseButton else false, "focused": control.has_focus()}
		data["center_visible"] = clip.has_point(center)
		data["scrollable"] = scrollable
		if control is BaseButton: data["text"] = control.text
		if control is Label: data["text"] = control.text
		data["instance_id"] = control.get_instance_id()
		if control is PowerCard:
			if control.fanned:
				# The owner plaque is the stable exposed activation area under a
				# raised neighbour. This is a real canvas point, not a test setter.
				var activation: Vector2 = control.get_global_transform() * (control.size * Vector2(.5, .9))
				data["activation_point"] = [activation.x, activation.y]
				data["moving"] = control.pose_in_motion
			data["nature"] = control.power.nature
			data["effect_text"] = control.tooltip_text
			data["title_fits"] = control.title_fits()
			data["reduced_motion"] = control.reduced_motion
			data["card_instance"] = control.card.get("instance_id", "")
			data["chosen"] = control.chosen
			data["blocked"] = control.blocked
		if control is Button and not control is PowerCard and not control is Actor:
			var style: StyleBox = control.get_theme_stylebox("normal", "Button")
			if style is StyleBoxFlat and style.bg_color.a >= 0.95 and not control.disabled:
				var foreground: Color = control.get_theme_color("font_focus_color" if control.has_focus() else "font_color", "Button")
				data["foreground"] = [foreground.r, foreground.g, foreground.b]
				data["background"] = [style.bg_color.r, style.bg_color.g, style.bg_color.b]
		if control is Range: data["value"] = control.value
		if control is CheckButton: data["checked"] = control.button_pressed
		controls[key] = data
	return controls

## The snapshot contains all protocol fields except controls and focused. Party,
## enemies, and optional journey_party are filtered here to the public schema.
static func publish(snapshot: Dictionary, registry: Dictionary, focus: Control) -> void:
	var state: Dictionary = snapshot.duplicate()
	for key in ["party", "enemies", "journey_party"]:
		if state.has(key): state[key] = state[key].map(public_individual)
	state["controls"] = controls_snapshot(registry, str(state["screen"]))
	state["focused"] = focus.get_meta("ui_id", "") if is_instance_valid(focus) else ""
	JavaScriptBridge.eval("window.umbralState = " + JSON.stringify(state), true)
