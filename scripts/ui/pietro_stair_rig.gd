extends RefCounted
## Continuous two-leg skinning of the unchanged home idle drawing. No clock,
## gameplay state or generated pixels. UVs always reference the original atlas.
const Assets = preload("res://scripts/assets/catalog.gd")
const Gait = preload("res://scripts/ui/pietro_stair_gait.gd")
const BINDING: String = "characters/pietro-stair-contact"
var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Assets.bound_file(BINDING, "rig")))
var texture: Texture2D = load(Assets.dependency_file(BINDING, "characters/pietro-home", "texture")) as Texture2D
var mesh: ArrayMesh = ArrayMesh.new()
var uvs: PackedVector2Array = []
var source_points: PackedVector2Array = []
var parts: PackedInt32Array = []
var indices: PackedInt32Array = []
var cached_progress: float = -1
var cached_direction: float = 0
var bounds: Rect2
var state: Dictionary
var posed_legs: Array[Dictionary] = []

func _init() -> void:
	# Independent strips prevent triangles from joining the two knees across
	# the crotch. Paint the unchanged sleeves/hands/coat above the trouser hips.
	for leg in [1, 0]: _strip(data.legs[leg].strip, leg)
	var rect: Array = data.region
	var remaining: Array[PackedVector2Array] = [PackedVector2Array([Vector2(rect[0], rect[1]), Vector2(rect[0] + rect[2], rect[1]), Vector2(rect[0] + rect[2], rect[1] + rect[3]), Vector2(rect[0], rect[1] + rect[3])])]
	for leg in data.legs:
		var outline: PackedVector2Array = []
		for row in leg.strip: outline.append(Vector2(row[1], row[0]))
		var reversed: Array = leg.strip.duplicate()
		reversed.reverse()
		for row in reversed: outline.append(Vector2(row[2], row[0]))
		var next: Array[PackedVector2Array] = []
		for polygon in remaining: next.append_array(Geometry2D.clip_polygons(polygon, outline))
		remaining = next
	for outline in remaining:
		var offset: int = source_points.size()
		for point in outline:
			_append(point, 2)
		for index in Geometry2D.triangulate_polygon(outline): indices.append(index + offset)

func _strip(rows: Array, part: int) -> void:
	var offset: int = source_points.size()
	for row in rows:
		for column in range(5): _append(Vector2(lerpf(float(row[1]), float(row[2]), column / 4.0), row[0]), part)
	for row in range(rows.size() - 1):
		for column in range(4):
			var a: int = offset + row * 5 + column
			indices.append_array(PackedInt32Array([a, a + 1, a + 5, a + 1, a + 6, a + 5]))

func _append(point: Vector2, part: int) -> void:
	source_points.append(point)
	uvs.append(point / texture.get_size())
	parts.append(part)

func seek(progress: float, direction: float) -> void:
	if progress == cached_progress and direction == cached_direction: return
	cached_progress = progress
	cached_direction = direction
	state = Gait.sample(progress, data.gait, direction)
	# The world tracks remain identical when turning. Only which anatomical leg
	# occupies each track changes with the three-quarter facing.
	var flip: float = -1 if direction > 0 else 1
	var root: Vector2 = state.root
	posed_legs.clear()
	for leg in range(2):
		var source: Dictionary = data.legs[leg]
		var foot: Vector2 = state.feet[leg if direction > 0 else 1 - leg]
		posed_legs.append(_solve(source, root, foot, flip, state.blend))
	var vertices: PackedVector2Array = []
	for index in range(source_points.size()):
		vertices.append(_skin(source_points[index], parts[index], root, flip, posed_legs))
	bounds = Rect2(vertices[0], Vector2.ZERO)
	for point in vertices: bounds = bounds.expand(point)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

func _solve(source: Dictionary, root: Vector2, sole: Vector2, flip: float, blend: float) -> Dictionary:
	var hip: Vector2 = _point(source.hip)
	var knee: Vector2 = _point(source.knee)
	var ankle: Vector2 = _point(source.ankle)
	var rest_sole: Vector2 = _point(source.sole)
	var scale: Vector2 = Vector2(flip, 1) * float(data.scale)
	var at: Vector2 = root + (hip - _point(data.hip)) * scale
	var target: Vector2 = sole + (ankle - rest_sole) * scale
	var delta: Vector2 = target - at
	var upper: float = hip.distance_to(knee) * float(data.scale)
	var lower: float = knee.distance_to(ankle) * float(data.scale)
	var length: float = clampf(delta.length(), absf(upper - lower) + 0.001, upper + lower - 0.001)
	var along: float = (upper * upper - lower * lower + length * length) / (2 * length)
	var perpendicular: float = sqrt(maxf(0, upper * upper - along * along))
	var axis: Vector2 = delta.normalized()
	var bend: float = flip if blend > 0 else -flip
	var joint: Vector2 = at + axis * along + Vector2(axis.y, -axis.x) * perpendicular * bend
	return {"source": source, "hip": at, "knee": joint, "ankle": target, "sole": sole, "scale": scale, "blend": blend, "upper_angle": (joint - at).angle() - ((knee - hip) * scale).angle(), "lower_angle": (target - joint).angle() - ((ankle - knee) * scale).angle()}

func _skin(point: Vector2, part: int, root: Vector2, flip: float, legs: Array[Dictionary]) -> Vector2:
	var neutral: Vector2 = root + (point - _point(data.hip)) * Vector2(flip, 1) * float(data.scale)
	if part == 2: return neutral
	return neutral.lerp(_leg(point, legs[part]), smoothstep(237, 260, point.y))

func _leg(point: Vector2, leg: Dictionary) -> Vector2:
	var source: Dictionary = leg.source
	var hip: Vector2 = _point(source.hip)
	var knee: Vector2 = _point(source.knee)
	var ankle: Vector2 = _point(source.ankle)
	var sole: Vector2 = _point(source.sole)
	var upper: Vector2 = leg.hip + ((point - hip) * leg.scale).rotated(leg.upper_angle)
	var lower: Vector2 = leg.knee + ((point - knee) * leg.scale).rotated(leg.lower_angle)
	var boot: Vector2 = leg.sole + (point - sole) * leg.scale
	return upper.lerp(lower, smoothstep(knee.y - 12, knee.y + 12, point.y)).lerp(boot, smoothstep(ankle.y - 12, ankle.y + 6, point.y))

static func _point(value: Array) -> Vector2:
	return Vector2(value[0], value[1])
