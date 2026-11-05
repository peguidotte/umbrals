extends Node2D
## Bounded elemental drawing. World positions come from the actual posed actors.
const Assets = preload("res://scripts/assets/catalog.gd")
const Motion = preload("res://scripts/ui/battle_motion.gd")
const LeafBlades = preload("res://scripts/ui/leaf_blade_vfx.gd")
const COLORS: Array[Color] = [Color("ef987b"), Color("91c8a1"), Color("80d7e5"), Color("e8cf81"), Color("e8cf81")]
var index: int = -1
var clock: float = 0.0
var source_point: Vector2
var release_point: Vector2
var secondary_point: Vector2
var body_point: Vector2
var target_points: Array[Vector2] = []
var target_families: Array[String] = []
var display_scale: float = 1.0
var flashes: bool = false
var reduced_motion: bool = false
var atlas: Texture2D
var rectangles: Array[Rect2] = []
var presentation_profile: String = ""
var leaf_blades: RefCounted = LeafBlades.new()

func _ready() -> void:
	show_behind_parent = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	atlas = Assets.texture(Motion.BINDING)
	Motion.ensure_loaded()
	for value in Motion.choreography.rects: rectangles.append(Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3])))

func clear() -> void:
	index = -1
	presentation_profile = ""
	target_points.clear()
	queue_redraw()

func configure_presentation(profile: Dictionary) -> void:
	presentation_profile = ""
	if str(profile.get("profile", "")) == "leaf_blades" and index in [3, 4, 5] and leaf_blades.configure(profile):
		presentation_profile = "leaf_blades"

func _stamp(art: int, at: Vector2, dimensions: Vector2, rotation_angle: float = 0.0, opacity: float = 1.0, mirror: float = 1.0) -> void:
	if opacity <= 0 or dimensions.x < 1 or dimensions.y < 1: return
	draw_set_transform(at, rotation_angle, Vector2(mirror, 1))
	draw_texture_rect_region(atlas, Rect2(-dimensions * 0.5, dimensions), rectangles[clampi(art, 0, 15)], Color(1, 1, 1, opacity))
	draw_set_transform(Vector2.ZERO)

func _ribbon(art: int, points: PackedVector2Array, width: float, opacity: float = 1.0) -> void:
	if width < 1 or points.size() < 2 or opacity <= 0: return
	var region: Rect2 = rectangles[art]
	var upper: PackedVector2Array
	var lower: PackedVector2Array
	for i in range(points.size()):
		var direction: Vector2 = (points[mini(i + 1, points.size() - 1)] - points[maxi(0, i - 1)]).normalized()
		upper.append(points[i] + direction.orthogonal() * width * 0.5)
		lower.append(points[i] - direction.orthogonal() * width * 0.5)
	for i in range(points.size() - 1):
		if points[i].distance_squared_to(points[i + 1]) < 0.001: continue
		var x: float = region.position.x + region.size.x * float(i) / (points.size() - 1)
		var next_x: float = region.position.x + region.size.x * float(i + 1) / (points.size() - 1)
		var uv: PackedVector2Array = PackedVector2Array([Vector2(x, region.position.y), Vector2(next_x, region.position.y), Vector2(next_x, region.end.y), Vector2(x, region.end.y)])
		for k in range(uv.size()): uv[k] /= atlas.get_size()
		var corners: PackedVector2Array = PackedVector2Array([upper[i], upper[i + 1], lower[i + 1], lower[i]])
		for triangle in [[0, 1, 3], [1, 2, 3]]:
			var vertices: PackedVector2Array = PackedVector2Array([corners[triangle[0]], corners[triangle[1]], corners[triangle[2]]])
			if absf((vertices[1] - vertices[0]).cross(vertices[2] - vertices[0])) < 0.001: continue
			draw_polygon(vertices, PackedColorArray([Color(1, 1, 1, opacity)]), PackedVector2Array([uv[triangle[0]], uv[triangle[1]], uv[triangle[2]]]), atlas)

func _path(from: Vector2, to: Vector2, bend: float, wave: float = 0.0) -> PackedVector2Array:
	var points: PackedVector2Array
	for i in range(25):
		var u: float = float(i) / 24
		points.append(from.lerp(to, u) + Vector2(0, -sin(u * PI) * bend + sin(u * 8 - clock * 13) * wave * sin(u * PI)))
	return points

func _ring(at: Vector2, radius: float, color: Color, opacity: float, flatten: float = 1.0) -> void:
	draw_set_transform(at, 0, Vector2(1, flatten))
	draw_arc(Vector2.ZERO, maxf(1, radius), 0, TAU, 32, Color(color, opacity), 1.5, true)
	draw_set_transform(Vector2.ZERO)

func _hash(value: int) -> float:
	return fposmod(sin(float(value) * 127.1 + 311.7) * 43758.5453, 1)

func _charge(spec: Dictionary, color: Color) -> void:
	var w: float = clampf((clock - 0.2) / (float(spec.release) - 0.2), 0, 1)
	var art: int = [0, 1, 2, 6, 5, 6, 8, 9, 10, 12, 13, 13, 14, 12, 13][index]
	_stamp(art, source_point, Vector2(12 + w * 26, 12 + w * 23) * display_scale, -0.5 if index == 1 else 0.0, w * 0.9)
	if index in [9, 13]:
		var points: PackedVector2Array = _path(source_point, secondary_point, 0, 4 * display_scale)
		draw_polyline(points, Color(color, w), 2, true)
	for k in range(5):
		var angle: float = float(k) * 2.4
		var at: Vector2 = source_point + Vector2(cos(angle), sin(angle)) * (1 - w) * 24 * display_scale
		draw_circle(at, 1.5 * display_scale, Color(color, w))

func _travel(to: Vector2, spec: Dictionary, opacity: float = 1.0) -> void:
	var u: float = pow(clampf((clock - float(spec.release)) / (float(spec.contact) - float(spec.release)), 0, 1), 0.85)
	var from: Vector2 = source_point if index in [3, 7, 9, 10, 11] else release_point
	var direction: float = 1.0 if to.x >= from.x else -1.0
	var bend: float = (60.0 if index == 1 else 39.0 if index == 2 else 0.0) * display_scale
	var point: Vector2 = from.lerp(to, u) - Vector2(0, sin(u * PI) * bend)
	var angle: float = (to - from - Vector2(0, bend * PI * cos(u * PI))).angle()
	match index:
		0, 1, 2, 6:
			var art: int = 8 if index == 6 else index
			var dimensions: Vector2 = Vector2(125, 56) if index == 0 else Vector2(82, 106) if index == 1 else Vector2(70, 70) if index == 2 else Vector2(112, 46)
			for tail in range(3, 0, -1):
				var f: float = maxf(0, u - tail * 0.035)
				var at: Vector2 = from.lerp(to, f) - Vector2(0, sin(f * PI) * bend)
				_stamp(art, at, dimensions * display_scale * (1 - tail * 0.11), clock * 5 if index == 2 else angle, (4 - tail) * 0.12)
			_stamp(art, point, dimensions * display_scale, clock * 5 if index == 2 else angle)
		3:
			var end: Vector2 = from.lerp(to, u)
			_ribbon(4, _path(from, end, 0, 24 * display_scale * (1 - u * 0.55)), 48 * display_scale, opacity)
		4:
			for k in range(9):
				var f: float = float(k) / 8
				var grow: float = smoothstep(0, 1, clampf((u - f * 0.78) / 0.22, 0, 1))
				var at: Vector2 = from.lerp(to + Vector2(0, 42 * display_scale), f)
				at.y -= 38 * grow * display_scale
				_stamp(5, at, Vector2(43 + f * 14, 77 * grow) * display_scale)
		5:
			for k in range(5):
				var at: Vector2 = from.lerp(to, maxf(0, u - k * 0.035)) + Vector2(-k * 5 * direction, (k - 2) * (7 + u * 9)) * display_scale
				_stamp(6, at, Vector2(68, 28) * display_scale, (k - 2) * 0.10, 1, direction)
		7:
			_ribbon(9, _path(from, point, 0, 22 * display_scale), 62 * display_scale * opacity, opacity)
		8:
			_stamp(10, point + Vector2(0, 20 * display_scale), Vector2(139, 99) * display_scale, 0, 1, direction)
		9:
			_ribbon(12, _path(source_point, to, 0, 4 * display_scale), 26 * display_scale)
			_ribbon(12, _path(secondary_point, to, 0, -4 * display_scale), 26 * display_scale)
		10:
			for k in range(2, -1, -1):
				_stamp(13, from.lerp(to, maxf(0, u - k * 0.09)), Vector2(43 + k * 5, 77 + k * 5) * display_scale, clock * 3, 0.9 - k * 0.2)
		11:
			_stamp(13, point, Vector2(67 + u * 24, 37 + u * 38) * display_scale, clock * 4)
		12, 13, 14:
			_stamp(13 if index == 14 else 14, body_point + Vector2(0 if index == 14 else 38 * direction * display_scale, 0), Vector2(150, 136) * display_scale if index == 14 else Vector2(82, 101) * display_scale, clock * 8 if index == 14 else 0.65 if index == 13 else 0.0, 0.95)

func _contact(to: Vector2, spec: Dictionary, delay: float, family: String) -> void:
	var raw: float = clock - float(spec.contact) - delay
	if raw < 0 or raw > 1.30: return
	var group: int = index / 3
	var color: Color = COLORS[group]
	if reduced_motion:
		_ring(to, 28 * display_scale, color, 0.8)
		return
	var age: float = maxf(0, raw - float(spec.hold))
	var fade: float = pow(1 - clampf(age / 0.82, 0, 1), 1.5)
	var grow: float = 0.62 + 0.48 * (1 - exp(-age * 9))
	var art: int = [3, 7, 11, 15, 15][group]
	var dimensions: Vector2 = Vector2(149, 149) if group == 4 else Vector2(91, 91) if group == 1 else Vector2(127, 109 if group == 2 else 127)
	if index == 1:
		art = 1
		dimensions = Vector2(91, 140)
	elif index == 2:
		art = 2
		dimensions = Vector2(137, 137)
	elif index == 4:
		art = 5
		dimensions = Vector2(99, 130)
	_stamp(art, to, dimensions * display_scale * grow, -0.6 if index == 1 else 0.0, fade)
	for k in range(15):
		var angle: float = (_hash(k + index * 9) - 0.5) * 5.2
		var distance: float = 28 + _hash(k + 12) * 65
		var at: Vector2 = to + (Vector2(cos(angle), sin(angle)) * distance * (1 - exp(-age * 5)) + Vector2(0, 55 * age * age - age * 20)) * display_scale
		var fragment_color: Color = color if k < 10 else Color("a6bf76") if family == "moss" else Color("a2edf3") if family == "dew" else Color("f0c373")
		draw_line(at, at - Vector2(cos(angle) * 5, sin(angle) * 5) * display_scale * fade, Color(fragment_color, fade), (2 if k % 3 else 3) * display_scale, true)
	if index in [5, 7]:
		for beat in spec.beats:
			var beat_age: float = clock - float(beat)
			if beat_age >= 0 and beat_age < 0.24: _stamp(7 if index == 5 else 11, to, Vector2(70, 70) * display_scale, 0, (1 - beat_age / 0.24) * 0.6)
	if group == 2: _ring(to + Vector2(0, 59 * display_scale), (10 + grow * 38) * display_scale, color, fade * 0.45, 0.16)
	if flashes and raw < 0.08: draw_circle(to, 24 * display_scale, Color(color, (1 - raw / 0.08) * 0.16))

func _draw() -> void:
	if index < 0 or atlas == null: return
	var spec: Dictionary = Motion.spec(index)
	if presentation_profile == "leaf_blades":
		leaf_blades.draw_effect(self, index, clock, spec, {"source": source_point, "release": release_point, "secondary": secondary_point, "targets": target_points}, display_scale, flashes, reduced_motion)
		return
	if clock >= 0.2 and clock < float(spec.release) and not reduced_motion: _charge(spec, COLORS[index / 3])
	for k in range(target_points.size()):
		var to: Vector2 = target_points[k]
		if not reduced_motion:
			if clock >= float(spec.release) and clock < float(spec.contact): _travel(to, spec)
			elif index in [3, 7] and clock >= float(spec.contact) and clock < float(spec.contact) + 0.45:
				_travel(to, spec, 1 - smoothstep(0, 0.45, clock - float(spec.contact)))
		_contact(to, spec, float(k) * 0.045, target_families[k] if k < target_families.size() else "")
