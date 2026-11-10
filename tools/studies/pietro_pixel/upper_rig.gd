extends RefCounted
const Geometry = preload("res://tools/studies/pietro_pixel/texture_mesh.gd")
var data: Dictionary
var source: Dictionary
var weights: Array[PackedFloat32Array] = []
var mesh: ArrayMesh
var transform: Transform2D = Transform2D.IDENTITY
var angles: Array[float] = [0,0,0]

func _init(config: Dictionary, mask: Array) -> void:
	data = config
	var bounds: Array = config.bounds
	source = Geometry.grid(Geometry.points(mask),Rect2i(bounds[0],bounds[1],bounds[2]-bounds[0],bounds[3]-bounds[1]),int(config.grid))
	for key in ["near_arm_mask","far_arm_mask","bag_mask"]:
		var polygon: PackedVector2Array = Geometry.points(config[key])
		var values: PackedFloat32Array = []
		for point in source.vertices:
			var inside: bool = Geometry2D.is_point_in_polygon(point,polygon)
			values.append(smoothstep(450,590,point.y) if key != "bag_mask" and inside else 1.0 if inside else 0.0)
		weights.append(values)
	mesh = Geometry.create(source.vertices,source.indices,source.uv)

func prepare(cycle: float, amount: float) -> void:
	var lean: float = deg_to_rad(float(data.lean_degrees)+cos(cycle*TAU)*float(data.sway_degrees))*amount
	var pivot: Vector2 = Geometry.point(data.pivot)
	var bob: float = -float(data.bob)*(1-cos(cycle*TAU*2))*amount
	transform = Transform2D(lean,pivot-pivot.rotated(lean)+Vector2(0,bob))
	angles = [deg_to_rad(float(data.arm_degrees))*cos(cycle*TAU)*amount,-deg_to_rad(float(data.arm_degrees))*cos(cycle*TAU)*amount,-deg_to_rad(float(data.bag_degrees))*cos(cycle*TAU-float(data.bag_lag))*amount]

func pose(drop: float) -> void:
	var pivots: Array = [data.near_shoulder,data.far_shoulder,data.bag_pivot]
	var deltas: Array[Transform2D] = []
	for i in range(3):
		var pivot: Vector2 = Geometry.point(pivots[i])
		deltas.append(Transform2D(angles[i],pivot-pivot.rotated(angles[i])))
	var vertices: PackedVector2Array = []
	for i in range(source.vertices.size()):
		var original: Vector2 = source.vertices[i]
		var point: Vector2 = original
		for part in range(3):
			if weights[part][i] > 0: point += (deltas[part]*original-original)*weights[part][i]
		vertices.append(transform*point+Vector2(0,drop))
	mesh = Geometry.create(vertices,source.indices,source.uv)
