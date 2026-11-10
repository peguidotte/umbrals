extends SceneTree
const Rig = preload("res://tools/studies/pietro_pixel/rig.gd")
const Coverage = preload("res://tools/studies/pietro_pixel/coverage.gd")
const Winding = preload("res://tools/studies/pietro_pixel/winding.gd")
const Volume = preload("res://tools/studies/pietro_pixel/volume_check.gd")
const ROOT: String = "res://assets/characters/pietro-pixel-pilot/versions/0.4.1/"
func _init() -> void:
	var rig: RefCounted = Rig.new(ROOT)
	var failed: int = 0
	var identity: float = 0
	var rigid: float = 0
	var reach: float = 0
	var foot_gap: float = INF
	var drop: float = 0
	var source_area_error: float = 0
	for leg in range(2):
		var mask: PackedVector2Array = []
		for p in rig.data.legs[leg].mask: mask.append(Vector2(p[0],p[1]))
		var mask_area: float = 0
		for i in range(mask.size()): mask_area += mask[i].cross(mask[(i+1)%mask.size()])*0.5
		var mesh_area: float = 0
		for i in range(0,rig.triangles[leg].size(),3):
			var a: Vector2 = rig.sources[leg][rig.triangles[leg][i]]
			mesh_area += absf((rig.sources[leg][rig.triangles[leg][i+1]]-a).cross(rig.sources[leg][rig.triangles[leg][i+2]]-a))*0.5
		source_area_error=maxf(source_area_error,absf(mesh_area-absf(mask_area))/absf(mask_area))
	rig.pose(0.5,0)
	for leg in range(2):
		var v: PackedVector2Array = rig.legs[leg].surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for i in range(v.size()): identity = maxf(identity,v[i].distance_to(rig.sources[leg][i]))
	for phase in range(1001):
		rig.pose(phase/1000.0,1)
		reach = maxf(reach,rig.reach_error)
		drop = maxf(drop,rig.drop)
		foot_gap = minf(foot_gap,rig.feet[1].x-rig.feet[0].x)
		for leg in range(2):
			var vertices: PackedVector2Array = rig.legs[leg].surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var sole: Vector2 = Vector2(rig.data.legs[leg].sole[0],rig.data.legs[leg].sole[1])
			for i in range(vertices.size()):
				if rig.sources[leg][i].y>=970: rigid = maxf(rigid,vertices[i].distance_to(rig.sources[leg][i]+rig.feet[leg]-sole))
	var waist: Dictionary = Coverage.sweep(rig,rig.texture.get_image())
	var winding: Dictionary = Winding.sweep(rig)
	var volume: Dictionary = Volume.sweep(rig)
	# Oriented areas alone passed the old X-shaped pinch. Prove this independent
	# source-UV cross-section measurement also detects that rejected candidate.
	var rejected_volume: Dictionary = Volume.at_pose(Rig.new("res://assets/characters/pietro-pixel-pilot/versions/0.3.0/"),[900,920,940,960],0,1)
	var sparse_rig: RefCounted = Rig.new("res://assets/characters/pietro-pixel-pilot/versions/0.4.0/")
	var sparse_false_pass: Dictionary = Volume.at_pose(sparse_rig,[900,920,940,960],0,1)
	var cuff_regression: Dictionary = Volume.at_pose(sparse_rig,[963,964],0,1)
	var review_case: Dictionary = Volume.at_pose(sparse_rig,[964],0,1)
	var corrected_case: Dictionary = Volume.at_pose(rig,[964],0,1)
	var contacts: Array[float] = []
	for i in range(5):
		var cycle: float = i*0.5
		rig.pose(cycle,1)
		var leg: int = i%2
		contacts.append(cycle*220+(rig.feet[leg].x-620)*0.5)
	var steps: Array[float] = []
	for i in range(contacts.size()-1): steps.append(contacts[i+1]-contacts[i])
	var values: Array[bool] = [FileAccess.get_sha256(ROOT+"source.png")=="cc20c83377533cc93c79e141f6490bcc8e056f36a05013f28b66111956c0bbfa",identity<0.001,reach<0.01,rigid<0.001,steps.min()>100 and steps.max()<120,waist.uncovered==0,winding.inverted==0 and winding.collapsed==0,volume.missing_bindings==0,volume.minimum_normal_width_ratio>=0.60,volume.minimum_vertical_scale>=0.80,rejected_volume.minimum_normal_width_ratio<0.10,source_area_error<0.00001,sparse_false_pass.minimum_normal_width_ratio>=0.60 and cuff_regression.minimum_normal_width_ratio<0.60,review_case.minimum_normal_width_ratio<0.60 and corrected_case.minimum_normal_width_ratio>=0.60]
	for value in values:
		if not value:failed += 1
	print(JSON.stringify({"suite":"pietro_house_long_stride","checks":values.size(),"failed":failed,"source_identity_delta":identity,"source_topology_relative_area_error":source_area_error,"reach_error":reach,"boot_deformation":rigid,"support_step_distances_world_px":steps,"min_projected_foot_center_order_source_px":foot_gap,"max_pelvis_drop_source_px":drop,"waist":waist,"winding":winding,"volume":volume,"rejected_0_3_volume":rejected_volume,"rejected_0_4_sparse_false_pass":sparse_false_pass,"rejected_0_4_cuff_regression":cuff_regression,"review_y964_before":review_case,"review_y964_after":corrected_case}))
	quit(failed)
