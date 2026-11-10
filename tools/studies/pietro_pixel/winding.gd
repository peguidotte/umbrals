extends RefCounted
## Compare every posed triangle to its own source orientation, including masks.
const NAMES: Array[String] = ["near_leg","far_leg","upper_body"]

static func sweep(rig: RefCounted) -> Dictionary:
	var source: Array = [rig.sources[0],rig.sources[1],rig.upper.source.vertices]
	var indices: Array = [rig.triangles[0],rig.triangles[1],rig.upper.source.indices]
	if rig.pelvis!=null:
		source.append(rig.pelvis_source.vertices)
		indices.append(rig.pelvis_source.indices)
	var reference: Array = []
	var report: Dictionary = {"poses":0,"triangle_samples":0,"inverted":0,"collapsed":0,"minimum_area_ratio":INF,"per_part_inversions":[0,0,0],"source_degenerate_triangles":0,"triangles_per_pose":[],"worst":{}}
	for part in range(source.size()):
		var triangles: Array = []
		for i in range(0,indices[part].size(),3):
			var a: int = indices[part][i]
			var b: int = indices[part][i+1]
			var c: int = indices[part][i+2]
			var area: float = (source[part][b]-source[part][a]).cross(source[part][c]-source[part][a])
			if absf(area)<0.0001:
				report.source_degenerate_triangles += 1
				continue
			triangles.append([a,b,c,area,i/3])
		reference.append(triangles)
		report.triangles_per_pose.append(triangles.size())
	if rig.pelvis!=null: report.per_part_inversions.append(0)
	# Dense full-cycle samples include the independent review's exact q=0.22.
	for i in range(1001): _sample(rig,reference,report,i/1000.0,1)
	# Entry and exit traverse this same gather path in opposite directions.
	for i in range(129): _sample(rig,reference,report,0.5,i/128.0)
	# Also exercise partial gather at other phases, rather than just endpoints.
	for g in range(1,16):
		for i in range(257): _sample(rig,reference,report,i/256.0,g/16.0)
	return report

static func _sample(rig: RefCounted, reference: Array, report: Dictionary, cycle: float, gather: float) -> void:
	rig.pose(cycle,gather)
	var meshes: Array = [rig.legs[0],rig.legs[1],rig.upper.mesh]
	if rig.pelvis!=null: meshes.append(rig.pelvis)
	report.poses += 1
	for part in range(meshes.size()):
		var vertices: PackedVector2Array = meshes[part].surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for triangle in reference[part]:
			var area: float = (vertices[triangle[1]]-vertices[triangle[0]]).cross(vertices[triangle[2]]-vertices[triangle[0]])
			var ratio: float = area/triangle[3]
			report.triangle_samples += 1
			if ratio<=0:
				report.inverted += 1
				report.per_part_inversions[part] += 1
			if ratio<=0.05: report.collapsed += 1
			if ratio<report.minimum_area_ratio:
				report.minimum_area_ratio = ratio
				report.worst = {"part":NAMES[part] if part<3 else "pelvis","cycle":cycle,"gather":gather,"triangle":triangle[4],"source_doubled_area":triangle[3],"posed_doubled_area":area}
