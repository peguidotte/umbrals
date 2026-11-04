extends Control
## A transient presentation space. Emits navigation intents; owns no game or save.
signal requested(intent: String)
signal changed
const UI = preload("res://scripts/ui/kit.gd")
const TitleTheme = preload("res://scripts/ui/title_theme.gd")
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
var header: VBoxContainer
var shortcuts: HBoxContainer
var footer: VBoxContainer
var elapsed: float = 0
var notice: String = ""

func build(kit: RefCounted, register: Callable) -> void:
	name = "Refuge"
	focus_mode = Control.FOCUS_ALL
	accessibility_name = "Sala de repouso. Use WASD ou setas para caminhar. E para interagir. Tab para atalhos."
	theme = TitleTheme.make_theme(kit.make_theme())
	canvas = Canvas.new()
	add_child(canvas)
	header = UI.column(2)
	add_child(header)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(kit.label("REFÚGIO", 34, TitleTheme.PAPER))
	header.add_child(kit.paragraph("Um lugar para respirar antes do bosque.", 19, Color("b9c9bb")))
	footer = UI.column(8)
	add_child(footer)
	prompt = kit.label("", 24, TitleTheme.PAPER, false, true)
	footer.add_child(prompt)
	instructions = kit.label("", 17, Color("b9c9bb"), false, true)
	footer.add_child(instructions)
	shortcuts = UI.row(12)
	shortcuts.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_child(shortcuts)
	register.call(self, "refuge.walk", "refuge")
	for entry in [["Partida", "departure", "journey"], ["Grimório", "codex", "codex"], ["Opções", "settings", "settings"], ["Título", "title", "return_menu"]]:
		var button: Button = kit.button(entry[0], _request.bind(entry[2]), "refuge." + entry[1])
		button.custom_minimum_size = Vector2(150, 48)
		shortcuts.add_child(button)
		register.call(button, "refuge." + entry[1], "refuge")
	for key in Space.STATIONS:
		var label: Label = kit.label(NAMES[key], 18, TitleTheme.PAPER, false, true)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
		station_labels[key] = label
	var provisional: Label = kit.label("Arte provisória original", 14, Color("a6b8ad"))
	header.add_child(provisional)
	footer.minimum_size_changed.connect(_layout)
	resized.connect(_layout)
	gui_input.connect(_pointed)
	_layout.call_deferred()
	_update_prompt()

func enter() -> void:
	canvas.point = Space.SPAWN
	canvas.facing = Vector2.DOWN
	canvas.stride = 0
	canvas.nearby = ""
	notice = ""
	canvas.queue_redraw()
	changed.emit()

func set_active(value: bool) -> void:
	if active != value:
		active = value
		armed = false
		canvas.stride = 0
		canvas.queue_redraw()
	_update_prompt()

func apply_preferences(motion_reduced: bool, text_scale: float) -> void:
	reduced = motion_reduced
	text_scale_value = text_scale
	for i in range(header.get_child_count()):
		header.get_child(i).add_theme_font_size_override("font_size", int([34, 19, 14][i] * text_scale))
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
		var nearby: String = Space.nearest(canvas.point)
		if nearby == "improvements":
			notice = "Melhorias indisponíveis nesta versão."
			_update_prompt()
			changed.emit()
		elif not nearby.is_empty(): _request(nearby)
		return true
	return false

func _physics_process(delta: float) -> void:
	if not active or not has_focus(): return
	var direction: Vector2 = Input.get_vector("umbral_refuge_left", "umbral_refuge_right", "umbral_refuge_up", "umbral_refuge_down", 0.25)
	if not armed:
		armed = direction.is_zero_approx() and not Input.is_action_pressed("umbral_refuge_interact")
		if armed: changed.emit()
		return
	var previous: Vector2 = canvas.point
	canvas.point = Space.walk(previous, direction, delta)
	if not direction.is_zero_approx(): canvas.facing = direction
	var moving: bool = not canvas.point.is_equal_approx(previous)
	canvas.stride = canvas.stride + delta * 14 if moving and not reduced else 0
	if moving:
		notice = ""
		canvas.nearby = Space.nearest(canvas.point)
		_update_prompt()
	canvas.queue_redraw()
	elapsed += delta
	if elapsed >= 0.1 and moving:
		elapsed = 0
		changed.emit()

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
	var key: String = "A" if device == "gamepad" else "E / Enter"
	prompt.text = notice if not notice.is_empty() else ("%s · %s" % [key, NAMES[nearby]] if not nearby.is_empty() else "Aproxime-se da mesa ou da saída")
	instructions.text = "Analógico / direcional: caminhar · A: interagir · B: voltar" if device == "gamepad" else "WASD / setas: caminhar · E: interagir · Esc: título · Tab: atalhos"

func _layout() -> void:
	if not is_instance_valid(canvas): return
	var pixel_scale: float = float(DisplayServer.window_get_size().y) / maxf(1, size.y)
	for button in shortcuts.get_children():
		button.custom_minimum_size.y = maxf(48, 44 / maxf(0.1, pixel_scale))
		button.add_theme_font_size_override("font_size", maxi(int(21 * text_scale_value), ceili(14 / maxf(0.1, pixel_scale))))
	header.position = Vector2(48, 24)
	header.size.x = size.x - 96
	footer.size = Vector2(size.x - 64, 0)
	footer.position = Vector2(32, size.y - footer.get_combined_minimum_size().y - 22)
	var available: Vector2 = Vector2(size.x - 48, maxf(200, footer.position.y - 112))
	var zoom: float = minf(available.x / Space.SIZE.x, available.y / 540.0)
	canvas.scale = Vector2.ONE * zoom
	canvas.position = Vector2((size.x - Space.SIZE.x * zoom) / 2, 112 - 110 * zoom)
	for key in station_labels:
		var label: Label = station_labels[key]
		label.size = Vector2(240, 30)
		label.position = canvas.position + (Space.STATIONS[key] + Vector2(0, 30)) * zoom - Vector2(120, 0)

func public_state() -> Dictionary:
	return {"position": [canvas.point.x, canvas.point.y], "nearby": Space.nearest(canvas.point), "active": active, "armed": armed, "notice": notice, "stride": canvas.stride}

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("10272a"))
