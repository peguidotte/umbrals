extends Control
## Pietro's initial home. Legacy refuge IDs remain presentation compatibility only.
signal requested(intent: String)
signal changed
const TitleTheme = preload("res://scripts/ui/title_theme.gd")
const UI = preload("res://scripts/ui/kit.gd")
const Space = preload("res://scripts/ui/house_space.gd")
const Motion = preload("res://scripts/ui/house_motion.gd")
const Camera = preload("res://scripts/ui/house_camera.gd")
const Canvas = preload("res://scripts/ui/refuge_canvas.gd")
var camera: RefCounted = Camera.new()
var canvas: Node2D
var motion: RefCounted = Motion.new()
var active: bool = false
var armed: bool = false
var reduced: bool = false
var entered: bool = false
var device: String = "keyboard"
var elapsed: float = 0
var notice: String = ""
var notice_left: float = 0
var title_left: float = 0
var exit_ready: bool = true
var pointer_target: float = NAN
var pointer_intent: String = ""
var walking: bool = false
var hotspots: Dictionary = {}
var notice_label: Label
var room_label: Label
var title_button: Button

func build(kit: RefCounted, register: Callable) -> void:
	name = "PietroHouse"
	focus_mode = Control.FOCUS_ALL
	accessibility_name = "Casa de Pietro. A/D ou setas: caminhar. E: objeto próximo. Cima/baixo: escada. Tab: objetos. Esc: título."
	theme = TitleTheme.make_theme(kit.make_theme())
	canvas = Canvas.new()
	add_child(canvas)
	register.call(self, "refuge.walk", "refuge")
	for identity in Space.NAMES:
		var button = Button.new()
		button.flat = true
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.accessibility_name = Space.NAMES[identity]
		button.tooltip_text = Space.NAMES[identity]
		for state in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		var focus = StyleBoxFlat.new()
		focus.bg_color = Color.TRANSPARENT
		focus.border_color = TitleTheme.PAPER
		focus.set_border_width_all(2)
		focus.set_corner_radius_all(8)
		button.add_theme_stylebox_override("focus", focus)
		button.pressed.connect(_approach.bind(identity))
		add_child(button)
		hotspots[identity] = button
		register.call(button, "refuge." + identity, "refuge")
	notice_label = kit.paragraph("", 20, TitleTheme.PAPER)
	notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice_label.hide()
	add_child(notice_label)
	room_label = kit.label("", 26, TitleTheme.PAPER, true)
	room_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_label.hide()
	add_child(room_label)
	title_button = kit.button("···", _request.bind("return_menu"), "refuge.title")
	title_button.accessibility_name = "Voltar ao título"
	title_button.tooltip_text = "Título"
	for state in ["normal", "hover", "pressed"]:
		title_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	add_child(title_button)
	register.call(title_button, "refuge.title", "refuge")
	resized.connect(_layout)
	focus_exited.connect(_stop_walk)
	gui_input.connect(_pointed)
	_layout.call_deferred()

func enter() -> void:
	if not entered:
		entered = true
		canvas.room = "bedroom"
		canvas.facing = Vector2.RIGHT
		motion.wake(canvas, reduced)
	_clear_pointer()
	_notice("")
	camera.follow(canvas.point, 0, true)
	_room_changed()

func set_active(value: bool) -> void:
	if active != value:
		active = value
		armed = false
		_stop_walk()
	_update_objects()
	if is_instance_valid(notice_label): notice_label.visible = active and not notice.is_empty()

func apply_preferences(motion_reduced: bool, text_scale: float) -> void:
	reduced = motion_reduced
	notice_label.add_theme_font_size_override("font_size", int(20 * text_scale))
	room_label.add_theme_font_size_override("font_size", int(26 * text_scale))
	if reduced:
		canvas.stride = 0
		if motion.waking: motion.step(canvas, Vector2.ZERO, 0, true)
	_layout.call_deferred()
	canvas.queue_redraw()

func handle_input(event: InputEvent, current_device: String) -> bool:
	if not active: return false
	device = current_device
	if has_focus():
		for action in ["left", "right", "up", "down"]:
			if event.is_action("umbral_refuge_" + action): return true
		if event is InputEventKey and event.echo: return event.is_action("umbral_refuge_interact")
	if event.is_action_pressed("umbral_refuge_interact") and has_focus():
		if motion.waking: motion.step(canvas, Vector2.RIGHT, 0, reduced)
		elif armed: _interact(Space.nearest(canvas.point, motion.upper, motion.on_stairs))
		return true
	return false

func _physics_process(delta: float) -> void:
	if not active: return
	if notice_left > 0:
		notice_left -= delta
		if notice_left <= 0: _notice("")
	if title_left > 0:
		title_left -= delta
		room_label.modulate.a = clampf(title_left, 0, 1)
		room_label.visible = title_left > 0
	if not has_focus(): return
	var direction = Vector2(Input.get_axis("umbral_refuge_left", "umbral_refuge_right"), Input.get_axis("umbral_refuge_up", "umbral_refuge_down"))
	var previous: Vector2 = canvas.point
	var arrived: bool = false
	var old_room: String = canvas.room
	if motion.waking:
		motion.step(canvas, direction, delta, reduced)
		_publish_motion(previous, delta, old_room)
		return
	if not armed:
		armed = direction.is_zero_approx() and not Input.is_action_pressed("umbral_refuge_interact")
		if armed: changed.emit()
		return
	if motion.on_stairs:
		motion.step(canvas, direction, delta, reduced)
		_publish_motion(previous, delta, old_room)
		return
	if not direction.is_zero_approx(): _clear_pointer()
	if not is_zero_approx(direction.y) and Space.nearest(canvas.point, motion.upper, motion.on_stairs) == "stairs":
		if (not motion.upper and direction.y < 0) or (motion.upper and direction.y > 0):
			var entry_x: float = Space.station("stairs", motion.upper)
			if not is_equal_approx(canvas.point.x, entry_x): canvas.facing = Vector2(signf(entry_x - canvas.point.x), 0)
			canvas.point.x = move_toward(canvas.point.x, entry_x, Space.SPEED * minf(delta, 0.1))
			if is_equal_approx(canvas.point.x, entry_x):
				motion.use_stairs(canvas)
				motion.automatic = 0
			_publish_motion(previous, delta, old_room)
			return
	if is_zero_approx(direction.x) and not is_nan(pointer_target): direction.x = signf(pointer_target - canvas.point.x)
	canvas.point = Space.walk(previous, direction, delta, motion.upper)
	if not is_nan(pointer_target) and absf(pointer_target - previous.x) <= absf(canvas.point.x - previous.x):
		canvas.point.x = pointer_target
		arrived = true
		var intent: String = pointer_intent
		_clear_pointer()
		if not intent.is_empty(): _interact(intent)
	if not is_zero_approx(direction.x): canvas.facing = Vector2(direction.x, 0)
	if not motion.upper and previous.x < Space.EXIT and canvas.point.x >= Space.EXIT and exit_ready:
		exit_ready = false
		_request("journey")
	if canvas.point.x < Space.EXIT - 65: exit_ready = true
	_publish_motion(previous, delta, old_room, arrived)

func _publish_motion(previous: Vector2, delta: float, old_room: String, arrived: bool = false) -> void:
	var moving: bool = not canvas.point.is_equal_approx(previous)
	var movement_changed: bool = moving != walking
	walking = moving
	if not motion.on_stairs and not motion.waking:
		canvas.stride = canvas.stride + delta * 9 if moving and not reduced else 0
	if not motion.on_stairs: canvas.room = Space.zone(canvas.point, motion.upper)
	var prior_camera: Vector2 = camera.center
	camera.follow(canvas.point, delta, reduced)
	_project()
	canvas.nearby = Space.nearest(canvas.point, motion.upper, motion.on_stairs)
	canvas.queue_redraw()
	if canvas.room != old_room: _room_changed()
	elapsed += delta
	if arrived or movement_changed or ((moving or camera.center.distance_to(prior_camera) > 0.01) and (elapsed >= 0.1 or canvas.point.x in [Space.LEFT, Space.RIGHT, Space.UPPER_LEFT, Space.UPPER_RIGHT])):
		elapsed = 0
		changed.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		armed = false
		_stop_walk()

func _clear_pointer() -> void:
	pointer_target = NAN
	pointer_intent = ""

func _stop_walk() -> void:
	_clear_pointer()
	motion.cancel_approach()
	if not is_instance_valid(canvas): return
	canvas.stride = 0
	walking = false
	canvas.queue_redraw()
	changed.emit()

func _approach(identity: String) -> void:
	if not active or not hotspots.has(identity) or not hotspots[identity].visible: return
	grab_focus()
	if motion.waking: motion.step(canvas, Vector2.RIGHT, 0, reduced)
	armed = true
	_notice("")
	if motion.on_stairs:
		if identity == "stairs": motion.use_stairs(canvas)
		return
	if identity == "exit": exit_ready = true
	pointer_target = Space.station(identity, motion.upper)
	pointer_intent = identity

func _interact(identity: String) -> void:
	if not active or not armed or identity.is_empty() or identity != Space.nearest(canvas.point, motion.upper, motion.on_stairs): return
	if identity == "stairs":
		if not motion.on_stairs and absf(canvas.point.x - Space.station("stairs", motion.upper)) > 0.1:
			pointer_target = Space.station("stairs", motion.upper)
			pointer_intent = "stairs"
		else: motion.use_stairs(canvas)
	elif identity == "improvements": _notice("Melhorias indisponíveis nesta versão.")
	elif identity == "codex": _request(identity)
	elif identity == "exit":
		exit_ready = false
		_request("journey")

func _room_changed() -> void:
	room_label.text = Space.TITLES[canvas.room]
	room_label.modulate.a = 1
	room_label.show()
	title_left = 2.5
	accessibility_name = room_label.text + ". A/D: caminhar. E: objeto próximo. Cima/baixo: escada. Tab: objetos."
	_update_objects()
	_project()
	canvas.queue_redraw()
	changed.emit()

func _update_objects() -> void:
	if not is_instance_valid(canvas): return
	var chain: Array = [self]
	for identity in hotspots:
		var rect: Rect2 = Space.object_rect(identity, motion.upper, motion.on_stairs, canvas.point)
		var shown: bool = rect.intersection(camera.visible_world()).size.x >= 80 and rect.intersection(camera.visible_world()).size.y >= 80
		hotspots[identity].visible = shown
		hotspots[identity].disabled = not active or not shown
		if shown: chain.append(hotspots[identity])
	if is_instance_valid(title_button): chain.append(title_button)
	UI.focus_chain(chain)

func _notice(value: String) -> void:
	notice = value
	notice_left = 3.5 if not value.is_empty() else 0
	if is_instance_valid(notice_label):
		notice_label.text = value
		notice_label.visible = active and not value.is_empty()
	changed.emit()

func _request(intent: String) -> void:
	if active: requested.emit(intent)

func _pointed(event: InputEvent) -> void:
	if not active or motion.waking or not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT: return
	var target: Vector2 = canvas.transform.affine_inverse() * event.position
	var floor_y: float = Space.UPPER_Y if motion.upper else Space.FLOOR_Y
	if absf(target.y - floor_y) > 95: return
	grab_focus()
	armed = true
	if motion.on_stairs: return
	pointer_target = clampf(target.x, Space.UPPER_LEFT if motion.upper else Space.LEFT, Space.UPPER_RIGHT if motion.upper else Space.RIGHT)
	pointer_intent = ""
	_notice("")

func _layout() -> void:
	if not is_instance_valid(canvas): return
	camera.layout(size)
	camera.follow(canvas.point, 0, true)
	_project()
	var pixel_scale: float = float(DisplayServer.window_get_size().y) / maxf(1, size.y)
	var target_size: float = maxf(48, 44 / maxf(0.1, pixel_scale))
	title_button.position = Vector2(size.x - target_size - 20, 16)
	title_button.size = Vector2.ONE * target_size
	notice_label.position = Vector2(size.x * 0.5, 90)
	notice_label.size = Vector2(size.x * 0.45, 90)
	room_label.position = Vector2(36, 38)
	room_label.size = Vector2(size.x - 110, 70)

func _project() -> void:
	canvas.transform = camera.projection()
	for identity in hotspots:
		var rect: Rect2 = Space.object_rect(identity, motion.upper, motion.on_stairs, canvas.point)
		rect = rect.intersection(camera.visible_world())
		var projected: Rect2 = canvas.transform * rect
		hotspots[identity].position = projected.position
		hotspots[identity].size = projected.size
	_update_objects()

func public_state() -> Dictionary:
	var frame: Rect2 = canvas.transform * canvas.actor_bounds()
	var state: Dictionary = {"location": "pietro_house", "room": canvas.room, "position": [canvas.point.x, canvas.point.y], "nearby": Space.nearest(canvas.point, motion.upper, motion.on_stairs), "active": active, "armed": armed, "notice": notice, "stride": canvas.stride, "exit_ready": exit_ready, "pointer_walking": not is_nan(pointer_target), "scene_origin": [canvas.position.x, canvas.position.y], "scene_scale": canvas.scale.x, "world_size": [Space.SIZE.x, Space.SIZE.y], "camera_center": [camera.center.x, camera.center.y], "viewport": [size.x, size.y], "actor_frame": [frame.position.x, frame.position.y, frame.size.x, frame.size.y]}
	state.merge(motion.public_state())
	return state

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("10272a"))
