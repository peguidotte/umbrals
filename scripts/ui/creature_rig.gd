extends Node2D
## One textured mesh per creature. The same deformation projects visible sockets.
const Motion = preload("res://scripts/ui/battle_motion.gd")
const Skinning = preload("res://scripts/ui/creature_skin.gd")
const Presentation = preload("res://scripts/ui/creature_presentation.gd")
const Assets = preload("res://scripts/assets/catalog.gd")
const Lifecycle = preload("res://scripts/ui/creature_lifecycle.gd")
const GRID: int = 14
const ANGLES: Dictionary = {"head": 8, "tail": 9, "fore": 10, "hind": 11, "crest": 12, "ear": 13, "jaw": 14, "wing": 15, "feeler": 16, "bough": 17, "fin": 18, "wing_far": 16, "leg_far": 16, "arm_far": 17}
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
var incapacitated: bool = false
var ko_elapsed: float = 0.0
var recovery_elapsed: float = -1.0
var ko_texture: Texture2D
var ko_mix: float = 0.0
var skin_bindings: Array = []
var pose_rotations: Dictionary = {}
var walk_offsets: Array = []
var projection_transform: Transform2D = Transform2D.IDENTITY
var projection_bob: float = 0.0

func set_incapacitated(value: bool, animate: bool = true) -> void:
	if incapacitated != value:
		incapacitated = value
		ko_elapsed = 0.0 if animate and not reduced_motion else .75
		recovery_elapsed = 0.0 if not value and animate and ko_texture != null and not reduced_motion else -1.0
		# Reset transient mesh motion before starting a lifecycle recovery clip.
		reset()
	if is_instance_valid(lifecycle):
		lifecycle.set_incapacitated(value, animate and not reduced_motion)
		lifecycle.advance(0, paused, reduced_motion)
	_refresh()

func configure(image: Texture2D, id: String, dimensions: Vector2, pivot: Vector2, mirror: bool) -> void:
	var changed: bool = image != source or id != form_id or mirror != flipped
	source = image
	form_id = id
	definition = Motion.form(id)
	display_size = dimensions
	foot = pivot / dimensions
	flipped = mirror
	if not is_instance_valid(lifecycle):
		lifecycle = Lifecycle.new()
		add_child(lifecycle)
	var authored: Dictionary = Assets.bound_manifest("characters/lifecycle-" + id)
	var reference: Dictionary = {"id": authored.id, "version": authored.version} if not authored.is_empty() else {}
	lifecycle.configure(id, dimensions, pivot, mirror, reference)
	texture = image.atlas if image is AtlasTexture else image
	if changed:
		ko_texture = Presentation.ko_texture(id, mirror)
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
	if is_instance_valid(lifecycle): lifecycle.cancel_transient()
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

func _process(delta: float) -> void:
	if is_instance_valid(lifecycle):
		var was_active: bool = lifecycle.active()
		lifecycle.advance(delta, paused, reduced_motion)
		if was_active or lifecycle.active(): queue_redraw()
		if lifecycle.active() and lifecycle.mesh_weight() <= 0.0: return
	if source == null or paused: return
	if ko_texture != null and (incapacitated or recovery_elapsed >= 0.0):
		if incapacitated:
			if ko_elapsed >= .75: return
			ko_elapsed = minf(ko_elapsed + delta, .75)
		else:
			recovery_elapsed += delta
			if recovery_elapsed >= .8: recovery_elapsed = -1.0
		_refresh()
		return
	if incapacitated and definition.get("states", {}).has("7"):
		ko_elapsed = minf(ko_elapsed + delta, 3.2)
		_refresh()
		return
	if managed: return
	if reduced_motion:
		if mode != "states" or clip != 0: reset()
		if pose != Motion.neutral():
			pose = Motion.neutral()
			_refresh()
		return
	if still and mode == "states" and clip == 0: return
	elapsed += delta
	idle_time += delta
	if (mode == "reactions" and elapsed >= 2.0) or (mode == "states" and clip not in [0, 6] and elapsed >= 3.2): reset()
	accumulator += delta
	if accumulator < 1.0 / 30: return
	accumulator = 0
	_refresh()

func _build_topology() -> void:
	mesh.clear_surfaces()
	uvs.clear()
	indices.clear()
	skin_bindings.clear()
	var region: Rect2 = source.region if source is AtlasTexture else Rect2(Vector2.ZERO, source.get_size())
	for row in range(GRID + 1):
		for column in range(GRID + 1):
			var uv: Vector2 = Vector2(float(column) / GRID, float(row) / GRID)
			uvs.append((region.position + uv * region.size) / texture.get_size())
			skin_bindings.append(_bind_skin(uv))
	for row in range(GRID):
		for column in range(GRID):
			var a: int = row * (GRID + 1) + column
			indices.append_array(PackedInt32Array([a, a + 1, a + GRID + 1, a + 1, a + GRID + 2, a + GRID + 1]))
	if not definition.get("walk_contacts", []).is_empty():
		var points: PackedVector2Array = PackedVector2Array()
		for binding in skin_bindings: points.append(binding.uv)
		for point in definition.walk_contacts:
			var uv: Vector2 = Vector2(float(point[0]), float(point[1]))
			if points.has(uv): continue
			points.append(uv)
			uvs.append((region.position + uv * region.size) / texture.get_size())
			skin_bindings.append(_bind_skin(uv))
		# A continuous socket calculation alone cannot lock a rendered paw inside
		# a coarse triangle. Put each support point on the actual textured mesh.
		indices = Geometry2D.triangulate_delaunay(points)

func _bind_skin(uv: Vector2) -> Dictionary:
	return Skinning.bind(uv, definition, foot)

# The root transform is identical for every vertex. Sockets retain project()
# below as the direct reference; the mesh applies this equivalent cached affine.
func _prepare_projection() -> void:
	var unit: float = maxf(display_size.x, display_size.y) / 166.0
	projection_bob = float(pose[5]) * unit
	var root: Vector2 = Vector2(float(pose[0]), float(pose[1]))
	var travel: Vector2 = Vector2.ZERO
	if mode == "attacks" and clip >= 12:
		root.x -= 300 * float(pose[19])
		if clip == 13: root.y *= jump_scale
		if clip == 14:
			var center: float = 66.0 if float(definition.get("profile", {}).get("mass", 1.2)) > 1.0 else 55.0
			var correction: float = center * (cos(float(pose[2])) - 1)
			root.y = correction + (root.y - correction) * jump_scale
		travel = dash * float(pose[19])
	var direction: Vector2 = Vector2(-1, 1) if flipped else Vector2.ONE
	var pivot: Vector2 = foot * display_size
	if flipped: pivot.x = display_size.x - pivot.x
	var rotation: Transform2D = Transform2D(float(pose[2]), Vector2.ZERO)
	var scale_pose: Vector2 = Vector2(float(pose[3]), float(pose[4])) * direction
	projection_transform = Transform2D(rotation.x * scale_pose, rotation.y * scale_pose, pivot + (root * unit + travel) * direction)

func _project_cached(binding: Dictionary) -> Vector2:
	var local: Vector2 = (_cached_skin(binding) - foot) * display_size
	local.y += float(binding.bob_weight) * projection_bob
	for index in range(walk_offsets.size()): local += walk_offsets[index] * float(binding.plant[index])
	return projection_transform * local

func _plant_weights(uv: Vector2) -> Array:
	return Skinning.plant_weights(uv, definition)

func _walk_offsets() -> void:
	walk_offsets.clear()
	if reduced_motion or mode != "states" or clip != 6: return
	var unit: float = maxf(display_size.x, display_size.y) / 166.0
	for point in definition.get("walk_contacts", []):
		var at: Vector2 = Vector2(float(point[0]), float(point[1]))
		var phase: float = fposmod(elapsed / .8 + float(point[2]), 1.0)
		var swing: float = clampf((phase - .6) / .4, 0, 1)
		var desired: Vector2 = at * display_size
		desired += Vector2(.035 * sin(swing * TAU) * sin(swing * PI), -.055 * pow(sin(swing * PI), 2)) * display_size
		var actual: Vector2 = _skin(at) * display_size
		actual.y += float(pose[5]) * unit * pow(clampf((foot.y - at.y) / maxf(.01, foot.y), 0, 1), .7)
		walk_offsets.append(desired - actual)

func _cached_skin(binding: Dictionary) -> Vector2:
	return Skinning.sample(binding, pose, pose_rotations)

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

func project(uv: Vector2, skinned: Variant = null, plant: Variant = null) -> Vector2:
	if pose.is_empty(): pose = Motion.neutral()
	var local: Vector2 = ((_skin(uv) if skinned == null else skinned) - foot) * display_size
	var unit: float = maxf(display_size.x, display_size.y) / 166.0
	if not is_zero_approx(float(pose[5])):
		local.y += float(pose[5]) * unit * pow(clampf((foot.y - uv.y) / maxf(0.01, foot.y), 0, 1), 0.7)
	if not walk_offsets.is_empty():
		var weights: Array = _plant_weights(uv) if plant == null else plant
		for index in range(walk_offsets.size()): local += walk_offsets[index] * float(weights[index])
	if not is_zero_approx(float(pose[2])): local = local.rotated(float(pose[2]))
	if not is_equal_approx(float(pose[3]), 1.0) or not is_equal_approx(float(pose[4]), 1.0):
		local *= Vector2(float(pose[3]), float(pose[4]))
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
		var point: Array = definition.anatomy.get("secondary", definition.anatomy.get("antennaB", [uv.x, uv.y]))
		uv = Vector2(float(point[0]), float(point[1]))
	return to_global(project(uv))

func _refresh() -> void:
	if texture == null or indices.is_empty(): return
	pose = Motion.neutral() if reduced_motion else Motion.sample(form_id, mode, clip, fposmod(idle_time, 3.2) if mode == "states" and clip == 0 else elapsed)
	if not reduced_motion and mode == "states" and clip == 6:
		pose = Motion.sample(form_id, mode, clip, fposmod(elapsed, 3.2))
	var ko_pose: bool = incapacitated and definition.get("states", {}).has("7")
	if ko_pose:
		pose = Motion.sample(form_id, "states", 7, 3.2 if reduced_motion else ko_elapsed)
	ko_mix = 0.0
	if ko_texture != null and (incapacitated or recovery_elapsed >= 0.0):
		if incapacitated:
			pose = Motion.sample(form_id, "states", 3, ko_elapsed) if not reduced_motion else Motion.neutral()
			ko_mix = 1.0 if reduced_motion else smoothstep(.12, .6, ko_elapsed)
		else:
			pose = Motion.neutral()
			ko_mix = 0.0 if reduced_motion else 1.0 - smoothstep(0.0, .8, recovery_elapsed)
	if not ko_pose and mode == "reactions" and not is_equal_approx(reaction_weight, 1.0):
		var rest: Array = Motion.neutral()
		for channel in range(pose.size()): pose[channel] = lerpf(float(rest[channel]), float(pose[channel]), reaction_weight)
	var vertices: PackedVector2Array = PackedVector2Array()
	_walk_offsets()
	pose_rotations.clear()
	for channel in range(8, 19):
		if not is_zero_approx(float(pose[channel])): pose_rotations[channel] = Transform2D(float(pose[channel]), Vector2.ZERO)
	_prepare_projection()
	for binding in skin_bindings: vertices.append(_project_cached(binding))
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
	if mesh.get_surface_count() > 0:
		if ko_mix < 1.0: draw_mesh(mesh, texture, Transform2D.IDENTITY, Color(1, 1, 1, weight * (1.0 - ko_mix)))
		if ko_texture != null and ko_mix > 0.0: draw_mesh(mesh, ko_texture, Transform2D.IDENTITY, Color(1, 1, 1, weight * ko_mix))
	if ko_mix > .2 or (is_instance_valid(lifecycle) and lifecycle.active()): return
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
