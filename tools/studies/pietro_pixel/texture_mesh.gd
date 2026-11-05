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

static func strips(mask: PackedVector2Array, bounds: Rect2i, step: int) -> Dictionary:
	# Include every authored boundary height. Each triangle then spans exactly
	# two rows, avoiding skinny grid-clipping chords across a curved deformation.
	var rows: Array[float] = []
	for y in range(bounds.position.y,bounds.end.y+1,step): rows.append(float(y))
	rows.append(float(bounds.end.y))
	for point in mask:
		if point.y>bounds.position.y and point.y<bounds.end.y: rows.append(point.y)
	rows.sort()
	var unique: Array[float] = []
	for y in rows:
		if unique.is_empty() or not is_equal_approx(unique.back(),y): unique.append(y)
	var vertices: PackedVector2Array = []
	var indices: PackedInt32Array = []
	for i in range(unique.size()-1):
		var strip: PackedVector2Array = [Vector2(bounds.position.x,unique[i]),Vector2(bounds.end.x,unique[i]),Vector2(bounds.end.x,unique[i+1]),Vector2(bounds.position.x,unique[i+1])]
		for polygon in Geometry2D.intersect_polygons(strip,mask):
			var offset: int = vertices.size()
			vertices.append_array(polygon)
			for index in Geometry2D.triangulate_polygon(polygon): indices.append(index+offset)
	var uv: PackedVector2Array = []
	for point in vertices: uv.append(point/1254.0)
	return {"vertices":vertices,"indices":indices,"uv":uv}

static func subdivided_strips(mask: PackedVector2Array, bounds: Rect2i, step: int, width: float, knots: PackedFloat32Array = PackedFloat32Array()) -> Dictionary:
	# Keep every authored row, then split wide trapezoids across the leg.
	# A single diagonal across an entire changing-width panel gives its two
	# triangles different tangents, even when the row projection is smooth.
	var base: Dictionary = strips(mask,bounds,step)
	var rows: Array[float] = []
	for point in base.vertices:
		if not rows.has(point.y): rows.append(point.y)
	for y in knots:
		if y>bounds.position.y and y<bounds.end.y and not rows.has(y): rows.append(y)
	rows.sort()
	var vertices: PackedVector2Array = []
	var indices: PackedInt32Array = []
	for row in range(rows.size()-1):
		var y0: float = rows[row]
		var y1: float = rows[row+1]
		var band: PackedVector2Array = [Vector2(bounds.position.x,y0),Vector2(bounds.end.x,y0),Vector2(bounds.end.x,y1),Vector2(bounds.position.x,y1)]
		for polygon in Geometry2D.intersect_polygons(band,mask):
			var left: Vector2 = Vector2(INF,INF)
			var right: Vector2 = Vector2(-INF,-INF)
			for point in polygon:
				if absf(point.y-y0)<0.01:
					left.x=minf(left.x,point.x); right.x=maxf(right.x,point.x)
				if absf(point.y-y1)<0.01:
					left.y=minf(left.y,point.x); right.y=maxf(right.y,point.x)
			if not left.is_finite() or not right.is_finite(): continue
			var slices: int = maxi(1,int(ceil(maxf(right.x-left.x,right.y-left.y)/width)))
			var offset: int = vertices.size()
			for i in range(slices+1):
				var fraction: float = float(i)/slices
				vertices.append(Vector2(lerpf(left.x,right.x,fraction),y0))
				vertices.append(Vector2(lerpf(left.y,right.y,fraction),y1))
			for i in range(slices):
				for triangle in [[offset+i*2,offset+(i+1)*2,offset+i*2+1],[offset+(i+1)*2,offset+(i+1)*2+1,offset+i*2+1]]:
					var a: Vector2 = vertices[triangle[0]]
					if absf((vertices[triangle[1]]-a).cross(vertices[triangle[2]]-a))>0.0001:
						indices.append_array(PackedInt32Array(triangle))
	var uv: PackedVector2Array = []
	for point in vertices: uv.append(point/1254.0)
	return {"vertices":vertices,"indices":indices,"uv":uv}

static func point(value: Array) -> Vector2:
	return Vector2(value[0],value[1])

static func points(value: Array) -> PackedVector2Array:
	var result: PackedVector2Array = []
	for value_point in value: result.append(point(value_point))
	return result
