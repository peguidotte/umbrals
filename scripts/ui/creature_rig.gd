extends Node2D
## One textured mesh per creature. The same deformation projects visible sockets.
const Motion = preload("res://scripts/ui/battle_motion.gd")
const Lifecycle = preload("res://scripts/ui/creature_lifecycle.gd")
const GRID: int = 14
const ANGLES: Dictionary = {"head": 8, "tail": 9, "fore": 10, "hind": 11, "crest": 12, "ear": 13, "jaw": 14, "wing": 15, "feeler": 16, "bough": 17, "fin": 18}
var form_id: String = ""
var source: Texture2D
var texture: Texture2D
var display_size: Vector2 = Vector2.ONE
var foot: Vector2 = Vector2(0.5, 1.0)
var flipped: bool = false
var reduced_motion: bool = false
var still: bool = false
var paused: bool = false
var managed: bool = false
var mode: String = "states"
var clip: int = 0
var elapsed: float = 0.0
var idle_time: float = 0.0
var dash: Vector2 = Vector2.ZERO
var pose: Array = []
var definition: Dictionary = {}
var mesh: ArrayMesh = ArrayMesh.new()
var uvs: PackedVector2Array
var indices: PackedInt32Array
var accumulator: float = 0.0
var reaction_weight: float = 1.0
var jump_scale: float = 1.0
var lifecycle: Node2D

func configure(image: Texture2D, id: String, dimensions: Vector2, pivot: Vector2, mirror: bool) -> void:
	var changed: bool = image != source or id != form_id
	source = image
	form_id = id
	definition = Motion.form(id)
	display_size = dimensions
	foot = pivot / dimensions
	flipped = mirror
	if not is_instance_valid(lifecycle):
		lifecycle = Lifecycle.new()
		add_child(lifecycle)
	lifecycle.configure(id, dimensions, pivot, mirror)
	texture = image.atlas if image is AtlasTexture else image
	if changed:
		reset()
		_build_topology()
	_refresh()

func reset() -> void:
	if is_instance_valid(lifecycle):
		lifecycle.cancel_transient()
		lifecycle.advance(0, paused, reduced_motion)
	mode = "states"
	clip = 0
	elapsed = 0
	managed = false
	dash = Vector2.ZERO
	reaction_weight = 1.0
	jump_scale = 1.0
	pose = Motion.neutral()

func seek_cast(index: int, time: float, world_dash: Vector2) -> void:
	if is_instance_valid(lifecycle): lifecycle.cancel_transient()
	managed = true
	mode = "attacks"
	clip = index
	elapsed = time
	dash = get_global_transform().basis_xform_inv(world_dash)
	if flipped: dash.x = -dash.x
	_refresh()

func seek_reaction(index: int, time: float) -> void:
	managed = true
	mode = "reactions"
	clip = index
	elapsed = time
	dash = Vector2.ZERO
	_refresh()

func play_state(state: int) -> void:
	if is_instance_valid(lifecycle): lifecycle.cancel_entry()
	if reduced_motion:
		reset()
		_refresh()
		return
	managed = false
	mode = "states"
	clip = state
	elapsed = 0
	dash = Vector2.ZERO
	_refresh()

func enter_field() -> void:
	if not reduced_motion and is_instance_valid(lifecycle): lifecycle.enter()
	queue_redraw()

func set_incapacitated(value: bool, animate: bool = true) -> void:
	if is_instance_valid(lifecycle):
		lifecycle.set_incapacitated(value, animate and not reduced_motion)
		lifecycle.advance(0, paused, reduced_motion)
	queue_redraw()

func _process(delta: float) -> void:
	if is_instance_valid(lifecycle):
		var was_active: bool = lifecycle.active()
		lifecycle.advance(delta, paused, reduced_motion)
		if was_active or lifecycle.active(): queue_redraw()
	if source == null or paused or managed: return
	if reduced_motion:
		if mode != "states" or clip != 0: reset()
		if pose != Motion.neutral():
			pose = Motion.neutral()
			_refresh()
		return
	if still and mode == "states" and clip == 0: return
	elapsed += delta
	idle_time += delta
	if (mode == "reactions" and elapsed >= 2.0) or (mode == "states" and clip != 0 and elapsed >= 3.2): reset()
	accumulator += delta
	if accumulator < 1.0 / 30: return
	accumulator = 0
	_refresh()

func _build_topology() -> void:
	uvs.clear()
	indices.clear()
	var region: Rect2 = source.region if source is AtlasTexture else Rect2(Vector2.ZERO, source.get_size())
	for row in range(GRID + 1):
		for column in range(GRID + 1):
			uvs.append((region.position + Vector2(float(column) / GRID, float(row) / GRID) * region.size) / texture.get_size())
	for row in range(GRID):
		for column in range(GRID):
			var a: int = row * (GRID + 1) + column
			indices.append_array(PackedInt32Array([a, a + 1, a + GRID + 1, a + 1, a + GRID + 2, a + GRID + 1]))

func _skin(uv: Vector2) -> Vector2:
	var displacement: Vector2 = Vector2.ZERO
	for joint in definition.get("joints", {}):
		var angle: float = float(pose[int(ANGLES.get(joint, 8))])
		if is_zero_approx(angle): continue
		var bone: Array = definition.joints[joint]
		var pivot: Vector2 = Vector2(float(bone[0]), float(bone[1]))
		var center: Vector2 = Vector2(float(bone[2]), float(bone[3]))
		var radius: Vector2 = Vector2(float(bone[4]), float(bone[5]))
		var weight: float = exp(-((uv - center) / radius).length_squared() * 1.35)
		if weight < 0.005: continue
		displacement += ((uv - pivot).rotated(angle) - (uv - pivot)) * weight
	if not is_zero_approx(float(pose[6])):
		var family: String = str(definition.get("anatomy", {}).get("family", ""))
		var center: Vector2 = Vector2(0.40, 0.37) if family == "dew" else Vector2(0.44, 0.46) if family == "volt" else Vector2(0.62, 0.61)
		var weight: float = exp(-((uv - center) / Vector2(0.35, 0.38)).length_squared())
		displacement += (uv - center) * float(pose[6]) * weight
	if float(pose[7]) > 0 and definition.has("anatomy"):
		var eye: Array = definition.anatomy.get("eye", [0.7, 0.5])
		var center: Vector2 = Vector2(float(eye[0]), float(eye[1]))
		displacement.y += (center.y - uv.y) * float(pose[7]) * 0.90 * exp(-((uv - center) / Vector2(0.065, 0.055)).length_squared() * 1.7)
	return uv + displacement

func project(uv: Vector2) -> Vector2:
	if pose.is_empty(): pose = Motion.neutral()
	var local: Vector2 = (_skin(uv) - foot) * display_size
	var unit: float = maxf(display_size.x, display_size.y) / 166.0
	local.y += float(pose[5]) * unit * pow(clampf((foot.y - uv.y) / maxf(0.01, foot.y), 0, 1), 0.7)
	local = local.rotated(float(pose[2])) * Vector2(float(pose[3]), float(pose[4]))
	var root: Vector2 = Vector2(float(pose[0]), float(pose[1]))
	if mode == "attacks" and clip >= 12:
		root.x -= 300 * float(pose[19])
		if clip == 13: root.y *= jump_scale
		if clip == 14:
			var center: float = 66.0 if float(definition.get("profile", {}).get("mass", 1.2)) > 1.0 else 55.0
			var pivot_correction: float = center * (cos(float(pose[2])) - 1)
			root.y = pivot_correction + (root.y - pivot_correction) * jump_scale
		local += dash * float(pose[19])
	local += root * unit
	var pivot: Vector2 = foot * display_size
	if flipped:
		local.x = -local.x
		pivot.x = display_size.x - pivot.x
	return pivot + local

func socket(index: int, secondary: bool = false) -> Vector2:
	var uv: Vector2 = Motion.socket(form_id, index)
	if secondary and definition.has("anatomy"):
		var point: Array = definition.anatomy.get("antennaB", [uv.x, uv.y])
		uv = Vector2(float(point[0]), float(point[1]))
	return to_global(project(uv))

func _refresh() -> void:
	if texture == null or indices.is_empty(): return
	pose = Motion.neutral() if reduced_motion else Motion.sample(form_id, mode, clip, fposmod(idle_time, 3.2) if mode == "states" and clip == 0 else elapsed)
	if mode == "reactions" and not is_equal_approx(reaction_weight, 1.0):
		var rest: Array = Motion.neutral()
		for channel in range(pose.size()): pose[channel] = lerpf(float(rest[channel]), float(pose[channel]), reaction_weight)
	var vertices: PackedVector2Array = PackedVector2Array()
	for row in range(GRID + 1):
		for column in range(GRID + 1): vertices.append(project(Vector2(float(column) / GRID, float(row) / GRID)))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	queue_redraw()

func _draw() -> void:
	var weight: float = lifecycle.mesh_weight() if is_instance_valid(lifecycle) else 1.0
	if weight <= 0: return
	if mesh.get_surface_count() > 0: draw_mesh(mesh, texture, Transform2D.IDENTITY, Color(1, 1, 1, weight))
	if is_instance_valid(lifecycle) and lifecycle.active(): return
	if reduced_motion or pose.is_empty() or not definition.has("anatomy"): return
	var anatomy: Dictionary = definition.anatomy
	var unit: float = maxf(display_size.x, display_size.y) / 166.0
	if float(pose[7]) > 0.45:
		var eye: Array = anatomy.eye
		var at: Vector2 = project(Vector2(float(eye[0]), float(eye[1])))
		var color: Color = Color("58afc0") if anatomy.family == "dew" else Color("9c804c") if anatomy.family == "moss" else Color("413336")
		draw_line(at + Vector2(-3, 0) * unit, at + Vector2(4, 1) * unit, color, 2 * unit, true)
	if float(pose[14]) > 0.1:
		var mouth: Array = anatomy.mouth
		var at: Vector2 = project(Vector2(float(mouth[0]), float(mouth[1])))
		var direction: float = -1.0 if flipped else 1.0
		draw_set_transform(at + Vector2(-2 * direction, 1) * unit, 0, Vector2(3 + 5 * float(pose[14]), 1 + 6 * float(pose[14])) * unit)
		draw_circle(Vector2.ZERO, 1, Color("241c25"))
		draw_set_transform(Vector2.ZERO)
		draw_line(at + Vector2(-5 * direction, -1) * unit, at + Vector2(2 * direction, -1) * unit, Color("f5e7c6"), unit, true)
