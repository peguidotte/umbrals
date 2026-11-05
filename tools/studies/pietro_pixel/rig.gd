extends RefCounted
## Study-only 3/4 gait. Approved pixels are sampled without redrawing the PNG.
const Geometry = preload("res://tools/studies/pietro_pixel/texture_mesh.gd")
const Upper = preload("res://tools/studies/pietro_pixel/upper_rig.gd")
const ROOT: String = "res://assets/characters/pietro-pixel-pilot/versions/0.2.2/"
var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"rig.json"))
var texture: Texture2D = load(ROOT+"source.png") as Texture2D
var upper: RefCounted
var legs: Array[ArrayMesh] = []
var sources: Array[PackedVector2Array] = []
var triangles: Array[PackedInt32Array] = []
var knee_weights: Array[PackedFloat32Array] = []
var boot_weights: Array[PackedFloat32Array] = []
var waist_weights: Array[PackedFloat32Array] = []
var leg_uvs: Array[PackedVector2Array] = []
var feet: Array[Vector2] = []
var knees: Array[Vector2] = []
var hips: Array[Vector2] = []
var reach_error: float = 0
var drop: float = 0

func _init() -> void:
	upper = Upper.new(data.upper,data.body_mask)
	for source in data.legs:
		var grid: Dictionary = Geometry.grid(Geometry.points(source.mask),Rect2i(380,760,500,400),20)
		sources.append(grid.vertices)
		triangles.append(grid.indices)
		leg_uvs.append(grid.uv)
		var knees_weight: PackedFloat32Array = []
		var boots_weight: PackedFloat32Array = []
		var waist_weight: PackedFloat32Array = []
		for point in grid.vertices:
			# Broad transitions keep the inner knee from folding over itself.
			knees_weight.append(smoothstep(source.knee[1]-data.deformation.knee_half_width,source.knee[1]+data.deformation.knee_half_width,point.y))
			boots_weight.append(smoothstep(source.ankle[1]-data.deformation.boot_blend_above,source.ankle[1]+data.deformation.boot_blend_below,point.y))
			# Both panels share the same attachment at the belt and inner seam.
			# Let the thighs take over gradually without pulling those edges apart.
			var seam_distance: float = INF
			for i in range(data.waist.seam.size()-1):
				seam_distance = minf(seam_distance,point.distance_to(Geometry2D.get_closest_point_to_segment(point,_point(data.waist.seam[i]),_point(data.waist.seam[i+1]))))
			waist_weight.append(smoothstep(data.waist.blend_y[0],data.waist.blend_y[1],point.y)*smoothstep(0,data.waist.seam_blend_width,seam_distance))
		knee_weights.append(knees_weight)
		boot_weights.append(boots_weight)
		waist_weights.append(waist_weight)
		legs.append(Geometry.create(grid.vertices,grid.indices,grid.uv))

func pose(cycle: float, gather: float = 1.0) -> void:
	feet.clear()
	knees.clear()
	hips.clear()
	reach_error = 0
	drop = 0
	upper.prepare(cycle,gather)
	for leg in range(2):
		var source: Dictionary = data.legs[leg]
		var phase: float = fposmod(cycle+leg*0.5,1)
		var stride: float = float(data.walk.amplitude)
		var x: float = stride*(1-4*phase) if phase < 0.5 else lerpf(-stride,stride,smoothstep(0,1,(phase-0.5)*2))
		var lift: float = 0 if phase < 0.5 else sin((phase-0.5)*TAU)*float(data.walk.lift)
		var weight: float = smoothstep(0,0.5,gather) if leg == 0 else smoothstep(0.5,1,gather)
		# The approved three-quarter pose has two distinct support lanes.
		var sole: Vector2 = _point(source.sole)+Vector2(x,-lift)*weight
		if gather > 0 and gather < 1: sole.y -= sin(weight*PI)*8
		feet.append(sole)
		var hip: Vector2 = upper.transform*_point(source.hip)+Vector2(x*weight*float(data.walk.hip_follow),0)
		hips.append(hip)
		var ankle: Vector2 = sole+_point(source.ankle)-_point(source.sole)
		var length: float = _point(source.hip).distance_to(_point(source.knee))+_point(source.knee).distance_to(_point(source.ankle))-0.05
		var height: float = sqrt(maxf(0,length*length-pow(ankle.x-hip.x,2)))
		drop = maxf(drop,ankle.y-height-hip.y)
	upper.pose(drop)
	for leg in range(2): _leg(leg)

func _leg(leg: int) -> void:
	var source: Dictionary = data.legs[leg]
	var hip: Vector2 = hips[leg]+Vector2(0,drop)
	hips[leg] = hip
	var sole: Vector2 = feet[leg]
	var ankle: Vector2 = sole+_point(source.ankle)-_point(source.sole)
	var upper_length: float = _point(source.hip).distance_to(_point(source.knee))
	var lower_length: float = _point(source.knee).distance_to(_point(source.ankle))
	var delta: Vector2 = ankle-hip
	var distance: float = clampf(delta.length(),absf(upper_length-lower_length)+0.001,upper_length+lower_length-0.001)
	var along: float = (upper_length*upper_length-lower_length*lower_length+distance*distance)/(2*distance)
	var side: float = sqrt(maxf(0,upper_length*upper_length-along*along))
	var knee: Vector2 = hip+delta.normalized()*along+Vector2(delta.y,-delta.x).normalized()*side
	knees.append(knee)
	reach_error = maxf(reach_error,absf(knee.distance_to(ankle)-lower_length))
	var a: float = (knee-hip).angle()-(_point(source.knee)-_point(source.hip)).angle()
	var b: float = (ankle-knee).angle()-(_point(source.ankle)-_point(source.knee)).angle()
	var upper_transform: Transform2D = Transform2D(a,hip-_point(source.hip).rotated(a))
	var lower_transform: Transform2D = Transform2D(b,knee-_point(source.knee).rotated(b))
	var boot_offset: Vector2 = sole-_point(source.sole)
	var vertices: PackedVector2Array = []
	for i in range(sources[leg].size()):
		var point: Vector2 = sources[leg][i]
		var skinned: Vector2 = (upper_transform*point).lerp(lower_transform*point,knee_weights[leg][i])
		var pelvis: Vector2 = upper.transform*point+Vector2(0,drop)
		var attached: Vector2 = pelvis.lerp(skinned,waist_weights[leg][i])
		vertices.append(attached.lerp(point+boot_offset,boot_weights[leg][i]))
	legs[leg] = Geometry.create(vertices,triangles[leg],leg_uvs[leg])

func draw(canvas: CanvasItem, anchor: Vector2, original: bool = false) -> void:
	var scale_value: float = float(data.scale)
	canvas.draw_set_transform(anchor-_point(data.pivot)*scale_value,0,Vector2.ONE*scale_value)
	if original: canvas.draw_texture(texture,Vector2.ZERO)
	else:
		canvas.draw_mesh(legs[1],texture)
		canvas.draw_mesh(legs[0],texture)
		canvas.draw_mesh(upper.mesh,texture)
	canvas.draw_set_transform(Vector2.ZERO)

static func _point(value: Array) -> Vector2:
	return Geometry.point(value)
