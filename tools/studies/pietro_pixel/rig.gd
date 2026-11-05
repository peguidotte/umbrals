extends RefCounted
## Study-only rig. The approved PNG is sampled directly; no regenerated frames.
const ROOT: String = "res://assets/characters/pietro-pixel-pilot/versions/0.1.0/"
var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "rig.json"))
var texture: Texture2D = load(ROOT + "source.png") as Texture2D
var body: ArrayMesh
var legs: Array[ArrayMesh] = []
var sources: Array[PackedVector2Array] = []
var triangles: Array[PackedInt32Array] = []
var knee_weights: Array[PackedFloat32Array] = []
var boot_weights: Array[PackedFloat32Array] = []
var leg_uvs: Array[PackedVector2Array] = []
var feet: Array[Vector2] = []
var knees: Array[Vector2] = []
var reach_error: float = 0
var drop: float = 0

func _init() -> void:
	body = _mesh(_points(data.body_mask), Geometry2D.triangulate_polygon(_points(data.body_mask)))
	for source in data.legs:
		var vertices: PackedVector2Array = []
		var indices: PackedInt32Array = []
		var mask: PackedVector2Array = _points(source.mask)
		for y in range(760, 1160, 20):
			for x in range(380, 880, 20):
				var cell: PackedVector2Array = [Vector2(x,y),Vector2(x+20,y),Vector2(x+20,y+20),Vector2(x,y+20)]
				for polygon in Geometry2D.intersect_polygons(cell, mask):
					var offset: int = vertices.size()
					vertices.append_array(polygon)
					for index in Geometry2D.triangulate_polygon(polygon): indices.append(index + offset)
		sources.append(vertices)
		triangles.append(indices)
		var knees_weight: PackedFloat32Array = []
		var boots_weight: PackedFloat32Array = []
		var uv: PackedVector2Array = []
		for point in vertices:
			knees_weight.append(smoothstep(source.knee[1]-16,source.knee[1]+16,point.y))
			boots_weight.append(smoothstep(source.ankle[1]-8,source.ankle[1]+8,point.y))
			uv.append(point/1254.0)
		knee_weights.append(knees_weight)
		boot_weights.append(boots_weight)
		leg_uvs.append(uv)
		legs.append(_mesh(vertices, indices))

func pose(cycle: float, gather: float = 1.0) -> void:
	feet.clear()
	knees.clear()
	reach_error = 0
	drop = float(data.walk.body_drop) * gather
	for leg in range(2):
		var source: Dictionary = data.legs[leg]
		var phase: float = fposmod(cycle + leg * 0.5, 1)
		var stride: float = float(data.walk.amplitude)
		var x: float = stride * (1 - 4 * phase) if phase < 0.5 else lerpf(-stride, stride, smoothstep(0, 1, (phase - 0.5) * 2))
		var lift: float = 0 if phase < 0.5 else sin((phase - 0.5) * TAU) * float(data.walk.lift)
		var weight: float = smoothstep(0, 0.5, gather) if leg == 0 else smoothstep(0.5, 1, gather)
		var sole: Vector2 = _point(source.sole).lerp(Vector2(620 + x, source.sole[1] - lift), weight)
		if gather > 0 and gather < 1: sole.y -= sin(weight * PI) * 12
		feet.append(sole)
		var hip: Vector2 = _point(source.hip) + Vector2(0, drop)
		var ankle: Vector2 = sole + _point(source.ankle) - _point(source.sole)
		var upper: float = _point(source.hip).distance_to(_point(source.knee))
		var lower: float = _point(source.knee).distance_to(_point(source.ankle))
		var delta: Vector2 = ankle - hip
		var distance: float = clampf(delta.length(), absf(upper-lower)+0.001, upper+lower-0.001)
		var along: float = (upper*upper-lower*lower+distance*distance)/(2*distance)
		var side: float = sqrt(maxf(0, upper*upper-along*along))
		var knee: Vector2 = hip + delta.normalized()*along + Vector2(delta.y,-delta.x).normalized()*side
		knees.append(knee)
		reach_error = maxf(reach_error, absf(knee.distance_to(ankle)-lower))
		var vertices: PackedVector2Array = []
		var a: float = (knee-hip).angle()-(_point(source.knee)-_point(source.hip)).angle()
		var b: float = (ankle-knee).angle()-(_point(source.ankle)-_point(source.knee)).angle()
		var upper_transform: Transform2D = Transform2D(a,hip-_point(source.hip).rotated(a))
		var lower_transform: Transform2D = Transform2D(b,knee-_point(source.knee).rotated(b))
		var boot_offset: Vector2 = sole-_point(source.sole)
		for i in range(sources[leg].size()):
			var point: Vector2 = sources[leg][i]
			var skinned: Vector2 = (upper_transform*point).lerp(lower_transform*point,knee_weights[leg][i])
			vertices.append(skinned.lerp(point+boot_offset,boot_weights[leg][i]))
		legs[leg] = _mesh(vertices, triangles[leg], leg_uvs[leg])

func draw(canvas: CanvasItem, anchor: Vector2, original: bool = false) -> void:
	var scale_value: float = float(data.scale)
	var origin: Vector2 = anchor-_point(data.pivot)*scale_value
	canvas.draw_set_transform(origin,0,Vector2.ONE*scale_value)
	if original: canvas.draw_texture(texture,Vector2.ZERO)
	else:
		canvas.draw_mesh(legs[1],texture)
		canvas.draw_mesh(legs[0],texture)
		canvas.draw_mesh(body,texture,Transform2D(0,Vector2(0,drop)))
	canvas.draw_set_transform(Vector2.ZERO)

func _mesh(vertices: PackedVector2Array, indices: PackedInt32Array, prepared_uv: PackedVector2Array = []) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var uv: PackedVector2Array = prepared_uv
	if uv.is_empty():
		for point in vertices: uv.append(point/1254.0)
	arrays[Mesh.ARRAY_TEX_UV] = uv
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

static func _point(value: Array) -> Vector2:
	return Vector2(value[0],value[1])

static func _points(value: Array) -> PackedVector2Array:
	var result: PackedVector2Array = []
	for point in value: result.append(_point(point))
	return result
