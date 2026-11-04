extends Control
## Transient presentation only: walking and navigation never own game/save state.
signal requested(intent: String)
signal changed
const TitleTheme = preload("res://scripts/ui/title_theme.gd")
const Space = preload("res://scripts/ui/refuge_space.gd")
const Canvas = preload("res://scripts/ui/refuge_canvas.gd")
const OBJECTS = {
	"codex": Rect2(140, 510, 260, 160),
	"improvements": Rect2(990, 440, 370, 230),
	"exit": Rect2(1455, 300, 190, 420),
}
var canvas: Node2D
var active: bool = false
var armed: bool = false
var reduced: bool = false
var device: String = "keyboard"
var elapsed: float = 0
var notice: String = ""
var notice_left: float = 0
var exit_ready: bool = true
var pointer_target: float = NAN
var pointer_intent: String = ""
var walking: bool = false
var hotspots: Dictionary = {}
var notice_label: Label
var title_button: Button

func build(kit: RefCounted, register: Callable) -> void:
	name = "Refuge"
	focus_mode = Control.FOCUS_ALL
	accessibility_name = "Sala de repouso. A/D ou setas: caminhar. E: interagir. Tab: objetos. Esc: título."
	theme = TitleTheme.make_theme(kit.make_theme())
	canvas = Canvas.new()
	add_child(canvas)
	register.call(self, "refuge.walk", "refuge")
	for identity in OBJECTS:
		var button = Button.new()
		button.flat = true
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.accessibility_name = {"codex": "Grimório", "improvements": "Bancada de melhorias, ainda indisponíveis", "exit": "Saída para preparar expedição"}[identity]
		button.tooltip_text = {"codex": "Grimório", "improvements": "Bancada", "exit": "Saída"}[identity]
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
	notice_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	notice_label.add_theme_constant_override("shadow_outline_size", 5)
	notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice_label.hide()
	add_child(notice_label)
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
	canvas.point = Space.SPAWN
	canvas.facing = Vector2.RIGHT
	exit_ready = true
	canvas.stride = 0
	canvas.nearby = ""
	_clear_pointer()
	_notice("")
	canvas.queue_redraw()
	changed.emit()

func set_active(value: bool) -> void:
	if active != value:
		active = value
		_clear_pointer()
		armed = false
		canvas.stride = 0
		walking = false
		canvas.queue_redraw()
	if is_instance_valid(notice_label): notice_label.visible = active and not notice.is_empty()

func apply_preferences(motion_reduced: bool, text_scale: float) -> void:
	reduced = motion_reduced
	notice_label.add_theme_font_size_override("font_size", int(20 * text_scale))
	if reduced: canvas.stride = 0
	_layout.call_deferred()
	canvas.queue_redraw()

func handle_input(event: InputEvent, current_device: String) -> bool:
	if not active: return false
	device = current_device
	if has_focus():
		for action in ["left", "right", "up", "down"]:
			if event.is_action("umbral_refuge_" + action): return true
		if event is InputEventKey and event.echo:
			return event.is_action("umbral_refuge_interact")
	if event.is_action_pressed("umbral_refuge_interact") and has_focus():
		if armed: _interact(Space.nearest(canvas.point))
		return true
	return false

func _physics_process(delta: float) -> void:
	if not active: return
	if notice_left > 0:
		notice_left -= delta
		if notice_left <= 0: _notice("")
	if not has_focus(): return
	var direction = Vector2(Input.get_axis("umbral_refuge_left", "umbral_refuge_right"), 0)
	if not armed:
		armed = direction.is_zero_approx() and not Input.is_action_pressed("umbral_refuge_interact")
		if armed: changed.emit()
		return
	if not direction.is_zero_approx(): _clear_pointer()
	elif not is_nan(pointer_target):
		direction.x = signf(pointer_target - canvas.point.x)
	var previous: Vector2 = canvas.point
	var arrived: bool = false
	canvas.point = Space.walk(previous, direction, delta)
	if not is_nan(pointer_target) and absf(pointer_target - previous.x) <= absf(canvas.point.x - previous.x):
		canvas.point.x = pointer_target
		arrived = true
		var intent: String = pointer_intent
		_clear_pointer()
		if not intent.is_empty(): _interact(intent)
	if not direction.is_zero_approx(): canvas.facing = direction
	var moving: bool = not canvas.point.is_equal_approx(previous)
	var movement_changed: bool = moving != walking
	walking = moving
	canvas.stride = canvas.stride + delta * 9 if moving and not reduced else 0
	canvas.nearby = Space.nearest(canvas.point)
	canvas.queue_redraw()
	if canvas.point.x < Space.EXIT - 65: exit_ready = true
	if moving and canvas.point.x >= Space.EXIT and exit_ready:
		exit_ready = false
		_request("journey")
	elapsed += delta
	if arrived or movement_changed or (moving and (elapsed >= 0.1 or canvas.point.x in [Space.LEFT, Space.RIGHT])):
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
	canvas.stride = 0
	walking = false
	canvas.queue_redraw()
	changed.emit()

func _approach(identity: String) -> void:
	if not active: return
	grab_focus()
	armed = true
	_notice("")
	if identity == "exit": exit_ready = true
	pointer_target = Space.EXIT + 25 if identity == "exit" else Space.STATIONS[identity].x
	pointer_intent = "" if identity == "exit" else identity

func _interact(identity: String) -> void:
	if not active or not armed or identity != Space.nearest(canvas.point): return
	if identity == "improvements": _notice("Melhorias indisponíveis nesta versão.")
	elif not identity.is_empty(): _request(identity)

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
	if not active or not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT: return
	var target: Vector2 = canvas.transform.affine_inverse() * event.position
	if not Rect2(Vector2.ZERO, Space.SIZE).has_point(target): return
	grab_focus()
	armed = true
	pointer_target = clampf(target.x, Space.LEFT, Space.RIGHT)
	pointer_intent = ""
	_notice("")

func _layout() -> void:
	if not is_instance_valid(canvas): return
	var zoom: float = minf(size.x / Space.SIZE.x, size.y / Space.SIZE.y)
	canvas.scale = Vector2.ONE * zoom
	canvas.position = (size - Space.SIZE * zoom) / 2
	for identity in hotspots:
		hotspots[identity].position = canvas.position + OBJECTS[identity].position * zoom
		hotspots[identity].size = OBJECTS[identity].size * zoom
	var pixel_scale: float = float(DisplayServer.window_get_size().y) / maxf(1, size.y)
	var target_size: float = maxf(48, 44 / maxf(0.1, pixel_scale))
	title_button.position = Vector2(size.x - target_size - 20, 16)
	title_button.size = Vector2.ONE * target_size
	notice_label.position = canvas.position + Vector2(990, 400) * zoom
	notice_label.size = Vector2(400 * zoom, 70)

func public_state() -> Dictionary:
	return {"position": [canvas.point.x, canvas.point.y], "nearby": Space.nearest(canvas.point), "active": active, "armed": armed, "notice": notice, "stride": canvas.stride, "exit_ready": exit_ready, "pointer_walking": not is_nan(pointer_target), "scene_origin": [canvas.position.x, canvas.position.y], "scene_scale": canvas.scale.x}

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("10272a"))
