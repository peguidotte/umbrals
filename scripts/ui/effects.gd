class_name UmbralEffects
extends Control
## A bounded presentation-only particle pool. Visual randomness never touches combat RNG.
const POPUP_FONT_SIZE = 22
const UI = preload("res://scripts/ui/kit.gd")
var particles: Array = []
var projectiles: Array = []
var popups: Array = []
var rng = RandomNumberGenerator.new()
var trauma: float = 0.0
var clock: float = 0.0
var reduced_motion: bool = false
var visual_layer: Control
var bursts: int = 0
var hits: int = 0
var flights: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rng.seed = 9127

func clear() -> void:
	particles.clear()
	projectiles.clear()
	popups.clear()
	trauma = 0
	if is_instance_valid(visual_layer): visual_layer.position = Vector2.ZERO
	queue_redraw()

func flight(from: Vector2, to: Vector2, color: Color, element: String = "") -> void:
	flights += 1
	if reduced_motion: return
	if projectiles.size() < 9:
		projectiles.append({"from": from, "to": to, "color": color, "element": element, "age": 0.0, "duration": 0.22})

func _popup_rect(label: Dictionary) -> Rect2:
	var width: float = UI.BODY.get_string_size(str(label.text), HORIZONTAL_ALIGNMENT_LEFT, -1, POPUP_FONT_SIZE).x
	var rise: float = UI.BODY.get_ascent(POPUP_FONT_SIZE) + 6
	var descent: float = UI.BODY.get_descent(POPUP_FONT_SIZE) + 6
	return Rect2(label.at - Vector2(width * 0.5 + 6, rise + float(label.travel)), Vector2(width + 12, rise + descent + float(label.travel)))

func popup(at: Vector2, text: String, color: Color = Color("f3e6c5")) -> void:
	var travel: float = 0.0 if reduced_motion else 28.0
	var label: Dictionary = {"at": at, "text": text, "color": color, "age": 0.0, "duration": 0.7, "travel": travel}
	var bounds: Rect2 = _popup_rect(label)
	var extent: Vector2 = size if size.x > 0 and size.y > 0 else get_viewport_rect().size
	var center_x: float = clampf(at.x, bounds.size.x * 0.5 + 10, extent.x - bounds.size.x * 0.5 - 10)
	var minimum_y: float = bounds.size.y - UI.BODY.get_descent(POPUP_FONT_SIZE) - 6 + 10
	var maximum_y: float = extent.y - UI.BODY.get_descent(POPUP_FONT_SIZE) - 16
	if popups.size() >= 18: popups.pop_front()
	# Reserve the complete path, so rapidly arriving messages remain separate
	# even as they rise. If the screen is full, retire the oldest message.
	while true:
		for lane in range(37):
			var offset: float = ceilf(float(lane) * 0.5) * (bounds.size.y + 8) * (-1 if lane % 2 else 1)
			label.at = Vector2(center_x, clampf(at.y + offset, minimum_y, maximum_y))
			var candidate: Rect2 = _popup_rect(label)
			if popups.any(func(existing: Dictionary) -> bool: return candidate.intersects(_popup_rect(existing))): continue
			popups.append(label)
			queue_redraw()
			return
		if not popups.is_empty(): popups.pop_front()

func burst(at: Vector2, color: Color, count: int = 14) -> void:
	bursts += 1
	if reduced_motion: return
	for i in range(mini(count, 64 - particles.size())):
		var angle: float = rng.randf_range(0, TAU)
		var velocity = Vector2(cos(angle), sin(angle)) * rng.randf_range(45, 160)
		particles.append({"p": at, "v": velocity, "life": rng.randf_range(0.25, 0.52), "age": 0.0, "color": color, "radius": rng.randf_range(1.5, 4)})

func impact(at: Vector2, magnitude: int) -> void:
	hits += 1
	trauma = minf(1, trauma + (0.60 if magnitude >= 35 else 0.30)) if not reduced_motion else 0.0
	burst(at, Color("edc986"), 24 if magnitude >= 35 else 12)

func _process(delta: float) -> void:
	var had_feedback: bool = trauma > 0 or not particles.is_empty() or not projectiles.is_empty() or not popups.is_empty()
	clock += delta
	trauma = maxf(0, trauma - delta * 2.5)
	if is_instance_valid(visual_layer):
		visual_layer.position = Vector2(sin(clock * 39), sin(clock * 51)) * 7 * trauma * trauma
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p.age += delta
		p.p += p.v * delta
		p.v *= pow(0.25, delta)
		if p.age >= p.life: particles.remove_at(i)
	for i in range(projectiles.size() - 1, -1, -1):
		projectiles[i].age += delta
		if projectiles[i].age >= projectiles[i].duration: projectiles.remove_at(i)
	for i in range(popups.size() - 1, -1, -1):
		popups[i].age += delta
		if popups[i].age >= popups[i].duration: popups.remove_at(i)
	if had_feedback or trauma > 0 or not particles.is_empty() or not projectiles.is_empty(): queue_redraw()

func _draw() -> void:
	for p in particles:
		var opacity: float = 1.0 - p.age / p.life
		var extent: float = maxf(1, p.radius * opacity)
		draw_rect(Rect2(p.p - Vector2.ONE * extent, Vector2.ONE * extent * 2), Color(p.color, opacity))
	for bolt in projectiles:
		var fraction: float = bolt.age / bolt.duration
		var eased: float = fraction * fraction * (3 - 2 * fraction)
		var point: Vector2 = bolt.from.lerp(bolt.to, eased) - Vector2(0, sin(fraction * PI) * 54)
		var direction: Vector2 = (bolt.to - bolt.from).normalized()
		if bolt.element in ["Raio", "lightning", "volt"]:
			var points = PackedVector2Array()
			var normal: Vector2 = direction.orthogonal()
			for i in range(7):
				points.append(point - direction * (6 - i) * 9 + normal * (8 if i % 2 == 0 else -8))
			draw_polyline(points, Color(bolt.color, 0.25), 10, true)
			draw_polyline(points, bolt.color, 3, true)
		else:
			for i in range(4):
				var tail: Vector2 = point - direction * i * 9
				draw_circle(tail, 9 - i * 1.7, Color(bolt.color, 0.8 - i * 0.15))
			draw_circle(point, 17, Color(bolt.color, 0.15))
			draw_circle(point, 3, Color("fff4ca"))
	for label in popups:
		var progress: float = label.age / label.duration
		var offset: float = -float(label.travel) * (1 - pow(1 - progress, 2))
		var font_size: int = POPUP_FONT_SIZE
		var width: float = UI.BODY.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var at: Vector2 = label.at + Vector2(-width * 0.5, offset)
		var opacity: float = minf(1, (1 - progress) * 4)
		draw_string_outline(UI.BODY, at, label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, Color(0.02, 0.04, 0.07, opacity))
		draw_string(UI.BODY, at, label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(label.color, opacity))
