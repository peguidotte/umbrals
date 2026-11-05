extends RefCounted
## Stateless foliage samples use the action clock; no timers or combat RNG live here.
const Assets = preload("res://scripts/assets/catalog.gd")
var atlas: Texture2D
var rectangles: Dictionary = {}
var variants: Array = []
var leaf_scale: float = 1.0
var impact_duration: float = 0.64
var maximum_fragments: int = 7
var binding: String = ""

func configure(profile: Dictionary) -> bool:
	leaf_scale = clampf(float(profile.get("blade_scale", 1.0)), 0.5, 1.7)
	var selected: String = str(profile.get("binding", "attacks/grass-leaf-blades"))
	if selected == binding and atlas != null: return true
	var manifest: Dictionary = Assets.bound_manifest(selected)
	var definition: Dictionary = manifest.get("metadata", {}).get("leaf_blades", {})
	if definition.is_empty(): return false
	var texture: Texture2D = Assets.texture(selected)
	if texture == null: return false
	var regions: Dictionary = {}
	for key: String in ["blade", "guard", "crescent", "impact"]:
		var value: Array = definition.get("rects", {}).get(key, [])
		if value.size() != 4: return false
		regions[key] = Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))
	var patterns: Array = definition.get("variants", [])
	if patterns.size() != 3: return false
	atlas = texture
	rectangles = regions
	variants = patterns.duplicate(true)
	impact_duration = clampf(float(definition.get("impact_duration", 0.64)), 0.1, 1.0)
	maximum_fragments = clampi(int(definition.get("maximum_fragments", 7)), 0, 9)
	binding = selected
	return true

func _stamp(canvas: Node2D, art: String, at: Vector2, dimensions: Vector2, angle: float, opacity: float = 1.0) -> void:
	if opacity <= 0.0: return
	canvas.draw_set_transform(at, angle)
	canvas.draw_texture_rect_region(atlas, Rect2(-dimensions * 0.5, dimensions), rectangles[art], Color(1, 1, 1, opacity))
	canvas.draw_set_transform(Vector2.ZERO)

func sample_blades(index: int, progress: float, from: Vector2, to: Vector2, display_scale: float) -> Array[Dictionary]:
	var pattern: Dictionary = variants[clampi(index - 3, 0, 2)]
	var count: int = clampi(int(pattern.get("blades", 1)), 1, 5)
	var u: float = clampf(progress, 0.0, 1.0)
	var eased: float = u * u * (3.0 - 2.0 * u)
	var direction: Vector2 = (to - from).normalized()
	var normal: Vector2 = direction.orthogonal()
	var arc: float = float(pattern.get("arc", 0.0)) * display_scale
	var spread: float = float(pattern.get("spread", 0.0)) * display_scale
	var result: Array[Dictionary] = []
	for k: int in range(count):
		var lane: float = float(k) - float(count - 1) * 0.5
		var bend: Vector2 = Vector2(0, -arc) + normal * lane * spread
		var point: Vector2 = from.lerp(to, eased) + bend * sin(eased * PI)
		var tangent: Vector2 = to - from + bend * PI * cos(eased * PI)
		result.append({"at": point, "angle": tangent.angle(), "lane": lane, "art": "guard" if index == 4 else "blade"})
	return result

func _charge(canvas: Node2D, clock: float, spec: Dictionary, source: Vector2, secondary: Vector2, to: Vector2, scale_factor: float) -> void:
	var w: float = smoothstep(float(spec.start), float(spec.release), clock)
	var facing: float = (to - source).angle()
	# Leaves gather at the actual posed forepaw, then align into its release direction.
	for k: int in range(3):
		var angle: float = float(k) * TAU / 3.0 + clock * 2.0
		var origin: Vector2 = secondary if k == 1 else source
		var at: Vector2 = origin + Vector2(cos(angle), sin(angle)) * (1.0 - w) * 17.0 * scale_factor
		_stamp(canvas, "blade", at, Vector2(15.0 + w * 15.0, 5.0 + w * 3.0) * scale_factor, lerp_angle(angle, facing, w), w * 0.8)
	_stamp(canvas, "guard", source, Vector2(18.0 + w * 33.0, 7.0 + w * 13.0) * scale_factor, facing, w)

func _travel(canvas: Node2D, index: int, progress: float, from: Vector2, to: Vector2, scale_factor: float) -> void:
	var samples: Array[Dictionary] = sample_blades(index, progress, from, to, scale_factor)
	for tail: int in range(2, 0, -1):
		for trail: Dictionary in sample_blades(index, maxf(0.0, progress - float(tail) * 0.055), from, to, scale_factor):
			var dimensions: Vector2 = Vector2(47, 15) if trail.art == "blade" else Vector2(43, 20)
			_stamp(canvas, str(trail.art), trail.at, dimensions * scale_factor, float(trail.angle), 0.13 / float(tail))
	for blade: Dictionary in samples:
		var dimensions: Vector2 = Vector2(47, 15) if blade.art == "blade" else Vector2(43, 20)
		_stamp(canvas, str(blade.art), blade.at, dimensions * scale_factor, float(blade.angle))

func _contact(canvas: Node2D, age: float, to: Vector2, facing: float, scale_factor: float, flashes: bool, reduced_motion: bool) -> void:
	if age < 0.0 or age >= impact_duration: return
	if reduced_motion:
		canvas.draw_arc(to, 21.0 * scale_factor, 0.0, TAU, 24, Color("b0cc60"), 1.5, true)
		return
	var progress: float = age / impact_duration
	var fade: float = pow(1.0 - progress, 1.5)
	var expansion: float = 0.65 + (1.0 - exp(-age * 17.0)) * 0.55
	_stamp(canvas, "crescent", to, Vector2(65, 65) * scale_factor * expansion, facing, fade)
	_stamp(canvas, "impact", to, Vector2(72, 54) * scale_factor * expansion, facing, fade * 0.85)
	for k: int in range(maximum_fragments):
		var angle: float = facing + (float(k) - float(maximum_fragments - 1) * 0.5) * 0.48
		var travel: float = (22.0 + float(k % 3) * 11.0) * (1.0 - exp(-age * 7.0))
		var at: Vector2 = to + (Vector2.from_angle(angle) * travel + Vector2(0, age * age * 32.0)) * scale_factor
		_stamp(canvas, "blade", at, Vector2(13, 4) * scale_factor, angle + age * 2.0, fade)
	if flashes and age < 0.07:
		canvas.draw_circle(to, 19.0 * scale_factor, Color(0.80, 0.94, 0.43, (1.0 - age / 0.07) * 0.12))

func draw_effect(canvas: Node2D, index: int, clock: float, spec: Dictionary, points: Dictionary, display_scale: float, flashes: bool, reduced_motion: bool) -> void:
	var scale_factor: float = display_scale * leaf_scale
	var targets: Array[Vector2] = points.targets
	if targets.is_empty(): return
	if clock >= float(spec.start) and clock < float(spec.release) and not reduced_motion:
		_charge(canvas, clock, spec, points.source, points.secondary, targets[0], scale_factor)
	for k: int in range(targets.size()):
		var delay: float = float(k) * 0.045
		var contact: float = float(spec.contact) + delay
		if clock >= float(spec.release) and clock < contact and not reduced_motion:
			var progress: float = (clock - float(spec.release)) / (contact - float(spec.release))
			_travel(canvas, index, progress, points.release, targets[k], scale_factor)
		_contact(canvas, clock - contact, targets[k], (targets[k] - Vector2(points.release)).angle(), scale_factor, flashes, reduced_motion)
