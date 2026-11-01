class_name UmbralTitleMenu
extends Control
## Original card pixels are separate runtime polygons, never a warped full-screen plate.
const Assets = preload("res://scripts/assets/catalog.gd")
const Magic = preload("res://scripts/ui/title_magic.gdshader")
const PlateButton = preload("res://scripts/ui/title_button.gd")
const ART_SIZE = Vector2(1672, 941)
const KEYS = ["menu.play", "menu.codex", "menu.settings", "menu.help"]
const LABELS = ["JOGAR", "GRIMÓRIO", "OPÇÕES", "COMO JOGAR"]
const RECTS = [Rect2(94, 344, 505, 103), Rect2(94, 466, 505, 98), Rect2(94, 585, 505, 98), Rect2(94, 703, 505, 98)]
signal card_awakened
signal navigation_requested
var buttons: Array[Button] = []
var cards: Array[Polygon2D] = []
var card_centers: Array[Vector2] = []
var card_bases: Array[Vector2] = []
var card_quads: Array[PackedVector2Array] = [
	PackedVector2Array([Vector2(1030, 246), Vector2(1048, 244), Vector2(1332, 321), Vector2(1344, 336), Vector2(1303, 797), Vector2(1294, 810), Vector2(935, 706), Vector2(929, 690)]),
	PackedVector2Array([Vector2(764, 535), Vector2(918, 475), Vector2(970, 645), Vector2(930, 696), Vector2(1002, 720), Vector2(849, 761), Vector2(835, 750)]),
	PackedVector2Array([Vector2(1504, 479), Vector2(1626, 521), Vector2(1630, 532), Vector2(1564, 727), Vector2(1555, 735), Vector2(1401, 693)])]
var art: TextureRect
var logo: TextureRect
var composition: Control
var magic: ShaderMaterial
var reduced_motion: bool = false
var frozen: bool = false
var input_active: bool = true
var elapsed: float = 0.0
var pulse_age: float = 10.0
var awakenings: int = 0
var text_scale: float = 1.0
var selected_menu: int = 0

func build(callbacks: Array[Callable], register: Callable) -> void:
	name = "TitleScreen"
	mouse_filter = Control.MOUSE_FILTER_PASS
	art = TextureRect.new()
	art.texture = Assets.texture("world/title-forest")
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.show_behind_parent = true
	add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	magic = ShaderMaterial.new()
	magic.shader = Magic
	art.material = magic
	composition = Control.new()
	composition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	composition.size = ART_SIZE
	add_child(composition)
	for i in range(card_quads.size()):
		var card = Polygon2D.new()
		var center = Vector2.ZERO
		for point in card_quads[i]: center += point
		center /= card_quads[i].size()
		card_centers.append(center)
		var local = PackedVector2Array()
		for point in card_quads[i]: local.append(point - center)
		card.polygon = local
		card.uv = card_quads[i]
		card.texture = Assets.texture("ui/title-menu")
		card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		card.position = center
		card.z_index = 2 if i == 0 else 1
		composition.add_child(card)
		cards.append(card)
	logo = TextureRect.new()
	var logo_region = AtlasTexture.new()
	logo_region.atlas = Assets.texture("ui/title-logo")
	logo_region.region = Rect2(115, 150, 1820, 495)
	logo.texture = logo_region
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)
	for i in range(KEYS.size()):
		var button = PlateButton.new()
		var region = AtlasTexture.new()
		region.atlas = Assets.texture("ui/title-menu")
		region.region = RECTS[i]
		button.plate_texture = region
		button.text = LABELS[i]
		button.accessibility_name = LABELS[i].capitalize()
		button.focus_mode = Control.FOCUS_ALL
		add_child(button)
		buttons.append(button)
		register.call(button, KEYS[i], "menu")
		button.pressed.connect(callbacks[i])
		button.focus_entered.connect(_select.bind(i))
		button.mouse_entered.connect(_select.bind(i))
	resized.connect(_layout)
	_layout()
	apply_preferences(false, false, 1.0)

func _layout() -> void:
	if not is_instance_valid(composition): return
	var portrait: bool = size.x / maxf(1.0, size.y) < 1.15
	var factor: float = minf(size.x / ART_SIZE.x, size.y / ART_SIZE.y)
	composition.scale = Vector2.ONE * factor
	composition.position = (size - ART_SIZE * factor) * 0.5
	var menu_origin: Vector2 = composition.position
	var menu_factor: float = factor
	if portrait:
		# Keep the illustrated trio above the menu; never shrink the menu into a letterbox.
		factor = size.x / 1050.0
		composition.scale = Vector2.ONE * factor
		composition.position = Vector2(size.x * 0.5 - 1190 * factor, size.y * 0.155 - 245 * factor)
		menu_factor = minf(size.x / 680.0, size.y / 1550.0)
		menu_origin = Vector2((size.x - 690 * menu_factor) * 0.5, size.y * 0.52 - 300 * menu_factor)
	logo.position = menu_origin + Vector2(94, 139) * menu_factor
	logo.size = Vector2(650, 177) * menu_factor
	if portrait:
		logo.position = Vector2((size.x - 600 * menu_factor) * 0.5, size.y * 0.035)
		logo.size = Vector2(600, 163) * menu_factor
	var window: Vector2 = Vector2(DisplayServer.window_get_size())
	var minimum_hit: float = 44.0 * size.y / maxf(1.0, window.y)
	for i in range(buttons.size()):
		var rect: Rect2 = RECTS[i]
		var visual: Vector2 = rect.size * menu_factor * text_scale
		var hit: Vector2 = visual + Vector2(12, 12) * menu_factor
		hit.y = minf(117 * menu_factor, maxf(hit.y, minimum_hit))
		buttons[i].plate_size = visual
		buttons[i].position = menu_origin + rect.get_center() * menu_factor - hit * 0.5
		buttons[i].size = hit
		buttons[i].queue_redraw()
	card_bases = card_centers.duplicate()
	_pose_cards()

func apply_preferences(reduced: bool, freeze: bool, scale_value: float) -> void:
	reduced_motion = reduced
	frozen = freeze
	text_scale = scale_value
	if reduced_motion or frozen:
		elapsed = 0.0
		pulse_age = 10.0
		magic.set_shader_parameter("clock", 0.0)
		magic.set_shader_parameter("pulse_age", 10.0)
	art.material = null if reduced_motion or frozen else magic
	magic.set_shader_parameter("motion", 0.0 if reduced_motion or frozen else 1.0)
	for button in buttons: button.reduced_motion = reduced_motion or frozen
	_layout()
	queue_redraw()

func _process(delta: float) -> void:
	if not visible or not input_active or reduced_motion or frozen: return
	elapsed = fmod(elapsed + delta, 1800.0)
	pulse_age = minf(pulse_age + delta, 10.0)
	magic.set_shader_parameter("clock", elapsed)
	magic.set_shader_parameter("pulse_age", pulse_age)
	_pose_cards()
	queue_redraw()

func _pose_cards() -> void:
	for i in range(cards.size()):
		var phase: float = elapsed * (0.62 + i * 0.11)
		var moving: bool = not reduced_motion and not frozen
		var offset: Vector2 = Vector2(sin(phase * 0.7 + i) * 3.0, sin(phase + i * 1.9) * (5.5 + i)) if moving else Vector2.ZERO
		cards[i].position = card_centers[i] + offset
		cards[i].rotation = sin(phase * 0.6 + i * 2.1) * 0.009 if moving else 0.0
		var pulse: float = maxf(0.0, 1.0 - pulse_age / 0.7) if moving else 0.0
		cards[i].scale = Vector2.ONE * (1.0 + sin(pulse * PI) * 0.014)

func _draw() -> void:
	if not is_instance_valid(composition): return
	# Two restrained warm ribbons and a bounded trail replace the baked orange swirls.
	var moving: bool = not reduced_motion and not frozen
	var clock: float = elapsed if moving else 0.0
	for band in range(2):
		var points = PackedVector2Array()
		for n in range(71):
			var angle: float = float(n) / 70.0 * TAU + clock * 0.22 + band * PI
			var point = Vector2(1190 + cos(angle) * 330, 550 + sin(angle) * 115 + cos(angle) * 90 + band * 35)
			points.append(composition.position + point * composition.scale)
		draw_polyline(points, Color(1.0, 0.27, 0.04, 0.09), 12 * composition.scale.x, true)
		draw_polyline(points, Color(1.0, 0.52, 0.13, 0.5), 2 * composition.scale.x, true)
	if moving:
		for i in range(12):
			var life: float = fmod(clock * 0.13 + i * 0.08333, 1.0)
			var point = Vector2(800 + i * 66 + sin(life * 5 + i) * 18, 790 - life * 420)
			draw_circle(composition.position + point * composition.scale, 1.8 * composition.scale.x, Color(1.0, 0.62, 0.19, sin(life * PI) * 0.7))

func _select(index: int) -> void:
	if input_active and selected_menu != index:
		selected_menu = index
		navigation_requested.emit()

func _gui_input(event: InputEvent) -> void:
	if not input_active: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var point: Vector2 = (event.position - composition.position) / composition.scale
		for card in cards:
			var local: Vector2 = card.transform.affine_inverse() * point
			if not Geometry2D.is_point_in_polygon(local, card.polygon): continue
			awakenings += 1
			if not reduced_motion and not frozen:
				pulse_age = 0.0
				magic.set_shader_parameter("pulse_origin", event.position / size)
				magic.set_shader_parameter("pulse_age", pulse_age)
			card_awakened.emit()
			accept_event()
			return

func effect_state() -> Dictionary:
	var poses: Array = []
	for card in cards: poses.append({"x": card.position.x, "y": card.position.y, "rotation": card.rotation})
	return {"reduced_motion": reduced_motion, "frozen": frozen, "clock": elapsed, "pulse_age": pulse_age, "awakenings": awakenings, "card_poses": poses, "background": "world/title-forest", "portrait": size.x / maxf(1.0, size.y) < 1.15}
