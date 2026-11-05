extends RefCounted
## Source-space textured masks shared by the controlled study rigs.
static func grid(mask: PackedVector2Array, bounds: Rect2i, step: int) -> Dictionary:
	var vertices: PackedVector2Array = []
	var indices: PackedInt32Array = []
	for y in range(bounds.position.y,bounds.end.y,step):
		for x in range(bounds.position.x,bounds.end.x,step):
			var cell: PackedVector2Array = [Vector2(x,y),Vector2(x+step,y),Vector2(x+step,y+step),Vector2(x,y+step)]
			for polygon in Geometry2D.intersect_polygons(cell,mask):
				var offset: int = vertices.size()
				vertices.append_array(polygon)
				for index in Geometry2D.triangulate_polygon(polygon): indices.append(index+offset)
	var uv: PackedVector2Array = []
	for point in vertices: uv.append(point/1254.0)
	return {"vertices":vertices,"indices":indices,"uv":uv}

static func create(vertices: PackedVector2Array, indices: PackedInt32Array, uv: PackedVector2Array) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TEX_UV] = uv
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

static func point(value: Array) -> Vector2:
	return Vector2(value[0],value[1])

static func points(value: Array) -> PackedVector2Array:
	var result: PackedVector2Array = []
	for value_point in value: result.append(point(value_point))
	return result
