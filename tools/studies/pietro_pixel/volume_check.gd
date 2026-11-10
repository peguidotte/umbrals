extends RefCounted
## Measures actual deformed, textured leg sections through source-UV bindings.
static func sweep(rig: RefCounted) -> Dictionary:
	var rows: Array[int] = []
	# Every source pixel row from four pixels below the attachment through
	# the cloth/cuff join. The +/-4 tangent fits inside this source domain.
	# Includes y=964 from review; four 20px-spaced rows missed that minimum.
	for y in range(784,971): rows.append(y)
	var probes: Array = _probes(rig,rows)
	var report: Dictionary = _report(rows)
	if not _bindings_valid(probes,report): return report
	for i in range(401): _sample(rig,probes,report,i/400.0,1)
	for i in range(129): _sample(rig,probes,report,0.5,i/128.0)
	for g in range(1,16):
		for i in range(129): _sample(rig,probes,report,i/128.0,g/16.0)
	return report

static func at_pose(rig: RefCounted, rows: Array[int], cycle: float, gather: float) -> Dictionary:
	var probes: Array = _probes(rig,rows)
	var report: Dictionary = _report(rows)
	if _bindings_valid(probes,report): _sample(rig,probes,report,cycle,gather)
	return report

static func _probes(rig: RefCounted, rows: Array[int]) -> Array:
	var image: Image = rig.texture.get_image()
	var probes: Array = []
	for leg in range(2):
		var polygon: PackedVector2Array = []
		for p in rig.data.legs[leg].mask: polygon.append(Vector2(p[0],p[1]))
		var slope: float = float(rig.data.legs[leg].ankle[0]-rig.data.legs[leg].hip[0])/float(rig.data.legs[leg].ankle[1]-rig.data.legs[leg].hip[1])
		for y in rows:
			var runs: Array = []
			var start: int = -1
			for x in range(380,881):
				var solid: bool = image.get_pixel(x,y).a>=0.95 and Geometry2D.is_point_in_polygon(Vector2(x+0.5,y+0.5),polygon)
				if solid and start<0: start=x
				if not solid and start>=0:
					runs.append(Vector2i(start,x-1))
					start=-1
			if start>=0: runs.append(Vector2i(start,880))
			var longest: Vector2i = Vector2i.ZERO
			for run in runs:
				if run.y-run.x>longest.y-longest.x: longest=run
			var left: Vector2 = Vector2(longest.x+1.5,y+0.5)
			var right: Vector2 = Vector2(longest.y-0.5,y+0.5)
			var center: Vector2 = (left+right)*0.5
			var bindings: Array = []
			for point in [left,right,center-Vector2(slope*4,4),center+Vector2(slope*4,4)]:
				bindings.append(_bind(rig.sources[leg],rig.triangles[leg],point))
			probes.append({"leg":leg,"y":y,"bindings":bindings,"reference_width":(right.x-left.x)/sqrt(1+slope*slope)})
	return probes

static func _report(rows: Array[int]) -> Dictionary:
	var consecutive: bool = true
	for i in range(1,rows.size()): consecutive=consecutive and rows[i]==rows[i-1]+1
	return {"poses":0,"sections":0,"source_rows_per_leg":rows.size(),"source_y_range":[rows.min(),rows.max()],"source_y_values":rows if not consecutive else [],"source_y_step":1 if consecutive else 0,"sample_y_offset":0.5,"tangent_half_span":4,"partial_gather_phase_step":1.0/128,"minimum_normal_width_ratio":INF,"minimum_vertical_scale":INF,"worst_width":{},"worst_height":{},"missing_bindings":0,"limits":"Finite integer source rows and phase/gather grid; not a global continuous-volume proof."}

static func _bindings_valid(probes: Array, report: Dictionary) -> bool:
	for probe in probes:
		for binding in probe.bindings:
			if binding.is_empty(): report.missing_bindings+=1
	return report.missing_bindings==0

static func _bind(source: PackedVector2Array, indices: PackedInt32Array, point: Vector2) -> Array:
	for i in range(0,indices.size(),3):
		var a: Vector2 = source[indices[i]]
		var ab: Vector2 = source[indices[i+1]]-a
		var ac: Vector2 = source[indices[i+2]]-a
		var determinant: float = ab.cross(ac)
		if absf(determinant)<0.0001: continue
		var u: float = (point-a).cross(ac)/determinant
		var v: float = ab.cross(point-a)/determinant
		if u>=-0.00001 and v>=-0.00001 and u+v<=1.00001:
			return [indices[i],indices[i+1],indices[i+2],u,v]
	return []

static func _point(vertices: PackedVector2Array, binding: Array) -> Vector2:
	return vertices[binding[0]]*(1-binding[3]-binding[4])+vertices[binding[1]]*binding[3]+vertices[binding[2]]*binding[4]

static func _sample(rig: RefCounted, probes: Array, report: Dictionary, cycle: float, gather: float) -> void:
	rig.pose(cycle,gather)
	var vertices: Array = [rig.legs[0].surface_get_arrays(0)[Mesh.ARRAY_VERTEX],rig.legs[1].surface_get_arrays(0)[Mesh.ARRAY_VERTEX]]
	report.poses+=1
	for probe in probes:
		var points: Array[Vector2] = []
		for binding in probe.bindings: points.append(_point(vertices[probe.leg],binding))
		var tangent: Vector2 = points[3]-points[2]
		var normal: Vector2 = Vector2(tangent.y,-tangent.x).normalized()
		var width: float = absf((points[1]-points[0]).dot(normal))/probe.reference_width
		var height: float = (points[3].y-points[2].y)/8
		report.sections+=1
		if width<report.minimum_normal_width_ratio:
			report.minimum_normal_width_ratio=width
			report.worst_width={"leg":probe.leg,"source_y":probe.y,"cycle":cycle,"gather":gather}
		if height<report.minimum_vertical_scale:
			report.minimum_vertical_scale=height
			report.worst_height={"leg":probe.leg,"source_y":probe.y,"cycle":cycle,"gather":gather}
