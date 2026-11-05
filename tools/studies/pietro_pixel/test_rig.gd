extends SceneTree
const Rig = preload("res://tools/studies/pietro_pixel/rig.gd")
var checks: int = 0
var failed: int = 0
func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr(label)
func _init() -> void:
	var rig: RefCounted = Rig.new()
	expect(FileAccess.get_sha256(Rig.ROOT+"source.png") == "cc20c83377533cc93c79e141f6490bcc8e056f36a05013f28b66111956c0bbfa", "Approved isolated PNG remains byte-identical")
	rig.pose(0.5,0)
	var identity: float = 0
	for leg in range(2): identity = maxf(identity,_difference(rig.sources[leg],rig.legs[leg].surface_get_arrays(0)[Mesh.ARRAY_VERTEX]))
	identity = maxf(identity,_difference(rig.upper.source.vertices,rig.upper.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]))
	expect(identity < 0.001,"The assembled neutral rig starts at the original source geometry")
	var reach: float = 0
	var rigid_boot: float = 0
	var boot_gap: float = INF
	var max_drop: float = 0
	var support_bend: float = 0
	for i in range(201):
		rig.pose(i/200.0,1)
		reach = maxf(reach,rig.reach_error)
		max_drop = maxf(max_drop,rig.drop)
		boot_gap = minf(boot_gap,(rig.data.legs[1].boot_bounds[0]+rig.feet[1].x-rig.data.legs[1].sole[0])-(rig.data.legs[0].boot_bounds[2]+rig.feet[0].x-rig.data.legs[0].sole[0]))
		for leg in range(2):
			if fposmod(i/200.0+leg*0.5,1)<0.5:
				var source: Dictionary = rig.data.legs[leg]
				var ankle: Vector2 = rig.feet[leg]+Vector2(source.ankle[0]-source.sole[0],source.ankle[1]-source.sole[1])
				support_bend = maxf(support_bend,180-rad_to_deg(absf((rig.hips[leg]-rig.knees[leg]).angle_to(ankle-rig.knees[leg]))))
			var vertices: PackedVector2Array = rig.legs[leg].surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var sole: Array = rig.data.legs[leg].sole
			for j in range(vertices.size()):
				if rig.sources[leg][j].y > 1040:
					rigid_boot = maxf(rigid_boot,vertices[j].distance_to(rig.feet[leg]+rig.sources[leg][j]-Vector2(sole[0],sole[1])))
		for gather in [i/200.0,1-i/200.0]:
			rig.pose(0.5,gather)
			reach = maxf(reach,rig.reach_error)
	expect(reach < 0.01,"Every walk and gather sample stays within both original leg lengths")
	expect(rigid_boot < 0.001,"Boot pixels translate rigidly without rolling or stretching")
	rig.pose(0.5,1)
	var a: bool = rig.feet[0].x-rig.data.legs[0].sole[0] < rig.feet[1].x-rig.data.legs[1].sole[0]
	rig.pose(1,1)
	expect(a and rig.feet[0].x-rig.data.legs[0].sole[0] > rig.feet[1].x-rig.data.legs[1].sole[0],"Each anatomical foot alternates forward progress in its original three-quarter support lane")
	rig.pose(0.75,1)
	a = rig.feet[0].y < 1126 and rig.feet[1].y == 1123
	rig.pose(1.25,1)
	expect(a and rig.feet[1].y < 1123 and rig.feet[0].y == 1126,"Each leg has its own lifted passing pose while the other supports")
	rig.pose(0.37,1)
	var before: Array[PackedVector2Array] = []
	for leg in range(2): before.append(rig.legs[leg].surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	var body_before: PackedVector2Array = rig.upper.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	rig.pose(1.37,1)
	var closure: float = 0
	for leg in range(2): closure = maxf(closure,_difference(before[leg],rig.legs[leg].surface_get_arrays(0)[Mesh.ARRAY_VERTEX]))
	closure = maxf(closure,_difference(body_before,rig.upper.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]))
	expect(closure < 0.001,"The complete walking mesh closes after one cycle")
	var drift: float = 0
	for leg in range(2):
		var prior: Vector2 = Vector2.INF
		for i in range(46):
			var cycle: float = (1 if leg == 0 else 0.5)+i/100.0
			rig.pose(cycle,1)
			var world: Vector2 = rig.feet[leg]+Vector2((cycle-0.5)*4*float(rig.data.walk.amplitude),0)
			if prior != Vector2.INF: drift = maxf(drift,world.distance_to(prior))
			prior = world
	expect(drift < 0.001,"Support boot anchors remain fixed as the study character advances")
	expect(boot_gap>20,"Opaque boot bounds never cross or overlap in the projected view")
	expect(max_drop<12 and support_bend<30,"Stance knees avoid the previous crouch and deep folding")
	rig.pose(0,1)
	var local_motion: Array[float] = [0,0,0]
	var body_vertices: PackedVector2Array = rig.upper.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for part in range(3):
		for i in range(body_vertices.size()):
			if rig.upper.weights[part][i]>0.8:
				var local: Vector2 = rig.upper.transform.affine_inverse()*(body_vertices[i]-Vector2(0,rig.drop))
				local_motion[part] = maxf(local_motion[part],local.distance_to(rig.upper.source.vertices[i]))
	expect(local_motion[0]>8 and local_motion[1]>8 and local_motion[2]>2,"Both arms and the backpack move independently of the rigid torso transform")
	print(JSON.stringify({"suite":"pietro_pixel_study","checks":checks,"failed":failed,"source_identity_delta":identity,"reach_error":reach,"boot_deformation":rigid_boot,"loop_delta":closure,"support_drift_source_px":drift,"boot_gap_source_px":boot_gap,"pelvis_drop_source_px":max_drop,"stance_knee_bend_degrees":support_bend,"independent_part_motion_source_px":local_motion}))
	quit(failed)
func _difference(a: PackedVector2Array,b: PackedVector2Array) -> float:
	var result: float = 0
	for i in range(a.size()): result = maxf(result,a[i].distance_to(b[i]))
	return result
