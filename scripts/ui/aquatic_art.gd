extends RefCounted
## Aquatic presentation only. Legacy species/form IDs and gameplay stay untouched.
const Assets = preload("res://scripts/assets/catalog.gd")
const BINDING: String = "characters/aquatic-family"
static var data: Dictionary = {}
static var regions: Dictionary = {}

static func supports(id: String) -> bool:
	return id in ["dew", "mareveu"]

static func load_data() -> void:
	if data.is_empty():
		data = JSON.parse_string(FileAccess.get_file_as_string(Assets.bound_file(BINDING, "atlas")))

static func region(id: String, role: String = "texture") -> Texture2D:
	load_data()
	var key: String = role + ":" + id
	if not regions.has(key):
		var rect: Array = data.spheres[id] if role == "spheres" else data.regions[id]
		var result := AtlasTexture.new()
		result.atlas = load(Assets.bound_file(BINDING, role))
		result.region = Rect2(rect[0], rect[1], rect[2], rect[3])
		result.filter_clip = true
		regions[key] = result
	return regions[key]

static func ground(id: String) -> Dictionary:
	load_data()
	return data.grounding[id]

static func definition(id: String) -> Dictionary:
	var baby: bool = id == "dew"
	return {"joints": {"head": [0.65, 0.40, 0.69, 0.28, 0.22, 0.29], "tail": [0.34, 0.70, 0.22, 0.53, 0.25, 0.33]}, "anatomy": {"family": "aquatic", "eye": [0.74, 0.28 if baby else 0.22], "mouth": [0.84, 0.38 if baby else 0.32]}}

static func pose(mode: String, clip: int, time: float) -> Array:
	var result: Array = [0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	if mode == "states" and clip == 0:
		result[5] = sin(time * TAU / 3.2) * 0.8
		result[9] = sin(time * TAU / 3.2) * 0.025
	elif mode == "reactions":
		var weight: float = sin(clampf(time / 0.65, 0, 1) * PI)
		result[0] = -5 * weight
		result[8] = 0.06 * weight
	elif mode == "attacks":
		var weight: float = sin(clampf(time / 2.6, 0, 1) * PI)
		result[8] = -0.07 * weight
		result[9] = 0.12 * weight
	else:
		result[8] = sin(clampf(time / 3.2, 0, 1) * PI) * -0.05
	return result

static func orb_center(rig: Node2D) -> Vector2:
	var anchor: Vector2 = Vector2(0.17, 0.21) if rig.form_id == "dew" else Vector2(0.81, 0.54)
	var center: Vector2 = rig.project(anchor)
	if rig.reduced_motion: return center
	var unit: float = maxf(rig.display_size.x, rig.display_size.y) / 166.0
	if rig.mode == "attacks" and rig.clip >= 6 and rig.clip <= 8:
		var spec: Dictionary = rig.Motion.spec(rig.clip)
		var release: float = float(spec.release)
		var contact: float = float(spec.contact)
		var end: float = float(spec.end)
		var progress: float = smoothstep(release, contact, rig.elapsed) if rig.elapsed <= contact else 1.0 - smoothstep(contact, end, rig.elapsed)
		var travel: Vector2 = rig.dash + Vector2(80 * unit, -50 * unit)
		if rig.flipped: travel.x = -travel.x
		# Dash is authored between ground anchors, not between orb homes.
		travel += rig.project(rig.foot) - center
		center += travel * progress
		center.y -= sin(progress * PI) * 18 * unit
	elif not rig.still:
		center.y += sin(rig.idle_time * 2.1) * 2.0 * unit
	return center

static func draw_orb(rig: Node2D) -> void:
	var diameter: float = minf(rig.display_size.x, rig.display_size.y) * (0.38 if rig.form_id == "dew" else 0.32)
	var dimensions: Vector2 = Vector2.ONE * diameter
	rig.draw_texture_rect(region("water", "spheres"), Rect2(orb_center(rig) - dimensions * 0.5, dimensions), false)
