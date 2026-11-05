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
	expect(identity < 0.001,"The assembled neutral rig starts at the original source geometry")
	var reach: float = 0
	var rigid_boot: float = 0
	for i in range(201):
		rig.pose(i/200.0,1)
		reach = maxf(reach,rig.reach_error)
		for leg in range(2):
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
	var a: bool = rig.feet[0].x < rig.feet[1].x
	rig.pose(1,1)
	expect(a and rig.feet[0].x > rig.feet[1].x,"The contact poses alternate which boot is ahead")
	rig.pose(0.75,1)
	a = rig.feet[0].y < 1126 and rig.feet[1].y == 1123
	rig.pose(1.25,1)
	expect(a and rig.feet[1].y < 1123 and rig.feet[0].y == 1126,"Each leg has its own lifted passing pose while the other supports")
	rig.pose(0.37,1)
	var before: Array[PackedVector2Array] = []
	for leg in range(2): before.append(rig.legs[leg].surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	rig.pose(1.37,1)
	var closure: float = 0
	for leg in range(2): closure = maxf(closure,_difference(before[leg],rig.legs[leg].surface_get_arrays(0)[Mesh.ARRAY_VERTEX]))
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
	print(JSON.stringify({"suite":"pietro_pixel_study","checks":checks,"failed":failed,"source_identity_delta":identity,"reach_error":reach,"boot_deformation":rigid_boot,"loop_delta":closure,"support_drift_source_px":drift}))
	quit(failed)
func _difference(a: PackedVector2Array,b: PackedVector2Array) -> float:
	var result: float = 0
	for i in range(a.size()): result = maxf(result,a[i].distance_to(b[i]))
	return result
