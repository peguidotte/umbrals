extends Control
## A transient presentation space. Emits navigation intents; owns no game or save.
signal requested(intent: String)
signal changed
const UI = preload("res://scripts/ui/kit.gd")
const TitleTheme = preload("res://scripts/ui/title_theme.gd")
const Paths = preload("res://scripts/assets/binding_paths.gd")
const GOLD_FONT = preload(Paths.FONTS_GOLD_DISPLAY)
const Space = preload("res://scripts/ui/refuge_space.gd")
const Canvas = preload("res://scripts/ui/refuge_canvas.gd")
const NAMES = {"journey": "Expedição", "codex": "Grimório", "improvements": "Melhorias · futuras"}
var canvas: Node2D
var active: bool = false
var armed: bool = false
var reduced: bool = false
var text_scale_value: float = 1.0
var device: String = "keyboard"
var prompt: Label
var instructions: Label
var station_labels: Dictionary = {}
var header_shade: ColorRect
var footer_shade: ColorRect
var header: VBoxContainer
var shortcuts: HBoxContainer
var footer: VBoxContainer
var elapsed: float = 0
var notice: String = ""
var exit_ready: bool = true
var pointer_direction: float = 0
var consult: Button

func build(kit: RefCounted, register: Callable) -> void:
	name = "Refuge"
	focus_mode = Control.FOCUS_ALL
	accessibility_name = "Sala de repouso. Use A/D ou setas para caminhar. E para interagir. Tab para atalhos."
	theme = TitleTheme.make_theme(kit.make_theme())
	canvas = Canvas.new()
	add_child(canvas)
	header_shade = ColorRect.new()
	header_shade.color = Color(0.025, 0.055, 0.065, 0.8)
	header_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header_shade)
	header = UI.column(2)
	add_child(header)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(kit.label("REFÚGIO", 26, TitleTheme.PAPER))
	header.add_child(kit.paragraph("Antes do bosque", 16, Color("b9c9bb")))
	footer_shade = ColorRect.new()
	footer_shade.color = Color(0.025, 0.055, 0.065, 0.86)
	footer_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(footer_shade)
	footer = UI.column(4)
	add_child(footer)
	prompt = kit.label("", 24, TitleTheme.PAPER, false, true)
	footer.add_child(prompt)
	instructions = kit.label("", 17, Color("b9c9bb"), false, true)
	footer.add_child(instructions)
	shortcuts = UI.row(12)
	shortcuts.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_child(shortcuts)
	register.call(self, "refuge.walk", "refuge")
	for entry in [["←", -1.0, "move_left"], ["→", 1.0, "move_right"]]:
		var movement: Button = kit.button(entry[0], func(): pass, "refuge." + entry[2])
		movement.custom_minimum_size = Vector2(64, 48)
		movement.focus_mode = Control.FOCUS_NONE
		movement.accessibility_name = "Segure para caminhar " + ("à esquerda" if entry[1] < 0 else "à direita")
		movement.button_down.connect(_pointer_walk.bind(entry[1]))
		movement.button_up.connect(_pointer_walk.bind(0.0))
		shortcuts.add_child(movement)
		register.call(movement, "refuge." + entry[2], "refuge")
	consult = kit.button("Consultar", _interact, "refuge.consult")
	consult.custom_minimum_size = Vector2(150, 48)
	shortcuts.add_child(consult)
	register.call(consult, "refuge.consult", "refuge")
	for entry in [["Opções", "settings", "settings"], ["Título", "title", "return_menu"]]:
		var button: Button = kit.button(entry[0], _request.bind(entry[2]), "refuge." + entry[1])
		button.custom_minimum_size = Vector2(150, 48)
		shortcuts.add_child(button)
		register.call(button, "refuge." + entry[1], "refuge")
	for label in header.get_children(): label.add_theme_font_override("font", GOLD_FONT)
	prompt.add_theme_font_override("font", GOLD_FONT)
	for button in shortcuts.get_children():
		button.add_theme_font_override("font", GOLD_FONT)
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			var box: StyleBoxFlat = kit.style(Color("182a2b") if state == "normal" else Color("263a37"), Color("dec88d") if state in ["hover", "focus"] else Color("81744e"), 6)
			if state == "focus": box.bg_color = Color(0, 0, 0, 0)
			button.add_theme_stylebox_override(state, box)
		button.add_theme_color_override("font_color", TitleTheme.PAPER)
		button.add_theme_color_override("font_hover_color", TitleTheme.PAPER)
		button.add_theme_color_override("font_pressed_color", TitleTheme.PAPER)
		button.add_theme_color_override("font_focus_color", TitleTheme.PAPER)
	footer.minimum_size_changed.connect(_layout)
	resized.connect(_layout)
	gui_input.connect(_pointed)
	_layout.call_deferred()
	_update_prompt()

func enter() -> void:
	canvas.point = Space.SPAWN
	canvas.facing = Vector2.RIGHT
	exit_ready = true
	canvas.stride = 0
	canvas.nearby = ""
	notice = ""
	canvas.queue_redraw()
	changed.emit()

func set_active(value: bool) -> void:
	if active != value:
		active = value
		pointer_direction = 0
		armed = false
		canvas.stride = 0
		canvas.queue_redraw()
	_update_prompt()

func apply_preferences(motion_reduced: bool, text_scale: float) -> void:
	reduced = motion_reduced
	text_scale_value = text_scale
	for i in range(header.get_child_count()):
		header.get_child(i).add_theme_font_size_override("font_size", int([26, 16, 14][i] * text_scale))
	for label in station_labels.values(): label.add_theme_font_size_override("font_size", int(18 * text_scale))
	for button in shortcuts.get_children(): button.add_theme_font_size_override("font_size", int(21 * text_scale))
	prompt.add_theme_font_size_override("font_size", int(24 * text_scale))
	instructions.add_theme_font_size_override("font_size", int(17 * text_scale))
	if reduced: canvas.stride = 0
	_layout.call_deferred()
	canvas.queue_redraw()

func handle_input(event: InputEvent, current_device: String) -> bool:
	if not active: return false
	if device != current_device:
		device = current_device
		_update_prompt()
	if has_focus():
		for action in ["left", "right", "up", "down"]:
			if event.is_action("umbral_refuge_" + action): return true
		if event is InputEventKey and event.echo:
			return event.is_action("umbral_refuge_interact")
	if event.is_action_pressed("umbral_refuge_interact") and has_focus():
		if not armed: return true
		_interact()
		return true
	return false

func _physics_process(delta: float) -> void:
	if not active or not has_focus(): return
	var direction: Vector2 = Vector2(clampf(Input.get_axis("umbral_refuge_left", "umbral_refuge_right") + pointer_direction, -1, 1), 0)
	if not armed:
		armed = direction.is_zero_approx() and not Input.is_action_pressed("umbral_refuge_interact")
		if armed: changed.emit()
		return
	var previous: Vector2 = canvas.point
	canvas.point = Space.walk(previous, direction, delta)
	if not direction.is_zero_approx(): canvas.facing = direction
	var moving: bool = not canvas.point.is_equal_approx(previous)
	canvas.stride = canvas.stride + delta * 9 if moving and not reduced else 0
	if moving:
		notice = ""
		canvas.nearby = Space.nearest(canvas.point)
		_update_prompt()
	canvas.queue_redraw()
	if canvas.point.x < Space.EXIT - 65: exit_ready = true
	if moving and canvas.point.x >= Space.EXIT and exit_ready:
		exit_ready = false
		_request("journey")
	elapsed += delta
	if elapsed >= 0.1 and moving:
		elapsed = 0
		changed.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		pointer_direction = 0
		armed = false

func _pointer_walk(value: float) -> void:
	pointer_direction = value if active else 0.0
	if active and value != 0:
		grab_focus()
		armed = true

func _interact() -> void:
	if not active or not armed: return
	var nearby: String = Space.nearest(canvas.point)
	if nearby == "improvements":
		notice = "Melhorias indisponíveis nesta versão."
		_update_prompt()
		changed.emit()
	elif not nearby.is_empty(): _request(nearby)

func _request(intent: String) -> void:
	if not active: return
	requested.emit(intent)

func _pointed(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		grab_focus()
		armed = false

func _update_prompt() -> void:
	if not is_instance_valid(prompt): return
	var nearby: String = Space.nearest(canvas.point)
	if is_instance_valid(consult): consult.disabled = nearby.is_empty()
	var key: String = "A" if device == "gamepad" else "E / Enter"
	prompt.text = notice if not notice.is_empty() else ("%s · %s" % [key, NAMES[nearby]] if not nearby.is_empty() else "Caminhe até a mesa ou siga à direita para partir")
	instructions.text = "Analógico / direcional: caminhar · A: consultar · B: título" if device == "gamepad" else "A/D ou ← →: caminhar · E: consultar · Esc: título"

func _layout() -> void:
	if not is_instance_valid(canvas): return
	var pixel_scale: float = float(DisplayServer.window_get_size().y) / maxf(1, size.y)
	for button in shortcuts.get_children():
		if str(button.get_meta("ui_id", "")).begins_with("refuge.move_"):
			button.custom_minimum_size.x = maxf(64, 44 / maxf(0.1, pixel_scale))
		button.custom_minimum_size.y = maxf(48, 44 / maxf(0.1, pixel_scale))
		button.add_theme_font_size_override("font_size", maxi(int(21 * text_scale_value), ceili(14 / maxf(0.1, pixel_scale))))
	prompt.add_theme_font_size_override("font_size", maxi(int(24 * text_scale_value), ceili(14 / maxf(0.1, pixel_scale))))
	instructions.add_theme_font_size_override("font_size", maxi(int(17 * text_scale_value), ceili(12 / maxf(0.1, pixel_scale))))
	header.position = Vector2(36, 20)
	header.size.x = 250
	header_shade.position = Vector2(22, 12)
	header_shade.size = Vector2(280, 76 * text_scale_value)
	footer.size = Vector2(size.x - 64, 0)
	footer.position = Vector2(32, size.y - footer.get_combined_minimum_size().y - 18)
	var available: Vector2 = Vector2(size.x, minf(size.y, (footer.position.y - 12) * Space.SIZE.y / Space.FLOOR_Y))
	var zoom: float = minf(available.x / Space.SIZE.x, available.y / Space.SIZE.y)
	canvas.scale = Vector2.ONE * zoom
	canvas.position = Vector2((size.x - Space.SIZE.x * zoom) / 2, (available.y - Space.SIZE.y * zoom) / 2)
	footer_shade.position = Vector2(0, footer.position.y - 8)
	footer_shade.size = Vector2(size.x, size.y - footer.position.y + 8)

func public_state() -> Dictionary:
	return {"position": [canvas.point.x, canvas.point.y], "nearby": Space.nearest(canvas.point), "active": active, "armed": armed, "notice": notice, "stride": canvas.stride, "exit_ready": exit_ready}

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("10272a"))
