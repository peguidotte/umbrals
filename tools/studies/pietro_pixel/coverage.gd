extends RefCounted
## Texture-aware coverage probes, independent of the rig's deformation weights.
const CELL: int = 12
# Opaque interior below the belt, above the natural opening between the legs.
# UV sampling excludes transparent source texels from the rendered coverage.
const REGION: Rect2i = Rect2i(580,786,142,80)

static func sample(rig: RefCounted, image: Image, step: int = 2) -> Dictionary:
	var probes: Array[Vector2] = []
	var bounds: Rect2 = Rect2()
	for y in range(REGION.position.y,REGION.end.y,step):
		for x in range(REGION.position.x,REGION.end.x,step):
			if image.get_pixel(x,y).a < 0.95: continue
			var world: Vector2 = rig.upper.transform*Vector2(x+0.5,y+0.5)+Vector2(0,rig.drop)
			probes.append(world)
			bounds = Rect2(world,Vector2.ZERO) if probes.size()==1 else bounds.expand(world)
	var bins: Dictionary = {}
	var meshes: Array[ArrayMesh] = [rig.legs[0],rig.legs[1],rig.upper.mesh]
	for mesh_index in range(meshes.size()):
		var arrays: Array = meshes[mesh_index].surface_get_arrays(0)
		var vertices: PackedVector2Array = arrays[Mesh.ARRAY_VERTEX]
		var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for i in range(0,indices.size(),3):
			var a: Vector2 = vertices[indices[i]]
			var b: Vector2 = vertices[indices[i+1]]
			var c: Vector2 = vertices[indices[i+2]]
			var box: Rect2 = Rect2(a,Vector2.ZERO).expand(b).expand(c)
			if not box.grow(0.01).intersects(bounds): continue
			var determinant: float = (b-a).cross(c-a)
			if absf(determinant)<0.000001: continue
			var triangle: Array = [a,b-a,c-a,uv[indices[i]],uv[indices[i+1]]-uv[indices[i]],uv[indices[i+2]]-uv[indices[i]],determinant,mesh_index]
			for by in range(int(floor(box.position.y/CELL)),int(floor(box.end.y/CELL))+1):
				for bx in range(int(floor(box.position.x/CELL)),int(floor(box.end.x/CELL))+1):
					var key: Vector2i = Vector2i(bx,by)
					if not bins.has(key): bins[key] = []
					bins[key].append(triangle)
	var minimum: float = 1
	var uncovered: int = 0
	var worst: Vector2 = Vector2.ZERO
	for point in probes:
		var alpha: Array[float] = [0,0,0]
		var key: Vector2i = Vector2i(int(floor(point.x/CELL)),int(floor(point.y/CELL)))
		for triangle in bins.get(key,[]):
			var delta: Vector2 = point-triangle[0]
			var u: float = delta.cross(triangle[2])/triangle[6]
			var v: float = triangle[1].cross(delta)/triangle[6]
			if u < -0.000001 or v < -0.000001 or u+v > 1.000001: continue
			var texture: Vector2 = triangle[3]+triangle[4]*u+triangle[5]*v
			var value: float = image.get_pixel(clampi(int(floor(texture.x*image.get_width())),0,image.get_width()-1),clampi(int(floor(texture.y*image.get_height())),0,image.get_height()-1)).a
			alpha[triangle[7]] = maxf(alpha[triangle[7]],value)
		var coverage: float = 1-(1-alpha[0])*(1-alpha[1])*(1-alpha[2])
		if coverage < 0.95: uncovered += 1
		if coverage < minimum:
			minimum = coverage
			worst = point
	return {"probes":probes.size(),"uncovered":uncovered,"minimum_alpha":minimum,"worst_source_position":[worst.x,worst.y]}

static func sweep(rig: RefCounted, image: Image) -> Dictionary:
	var report: Dictionary = {"poses":0,"probes":0,"uncovered":0,"minimum_alpha":1.0,"worst_cycle":0.0,"worst_gather":0.0,"worst_source_position":[]}
	for i in range(129):
		var cycle: float = i/128.0
		rig.pose(cycle,1)
		_merge(report,sample(rig,image),cycle,1)
	for i in range(33):
		var gather: float = i/32.0
		rig.pose(0.5,gather)
		_merge(report,sample(rig,image),0.5,gather)
	return report

static func _merge(report: Dictionary, value: Dictionary, cycle: float, gather: float) -> void:
	report.poses += 1
	report.probes += value.probes
	report.uncovered += value.uncovered
	if value.minimum_alpha < report.minimum_alpha:
		report.minimum_alpha = value.minimum_alpha
		report.worst_cycle = cycle
		report.worst_gather = gather
		report.worst_source_position = value.worst_source_position
