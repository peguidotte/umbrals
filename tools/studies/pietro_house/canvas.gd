extends "res://scripts/ui/refuge_canvas.gd"
## Experimental renderer only. The real room still owns movement and camera.
const PixelRig = preload("res://tools/studies/pietro_pixel/rig.gd")
const PILOT_SCALE: float = 0.5
const PILOT_ROOT: String = "res://assets/characters/pietro-pixel-pilot/versions/0.4.1/"
var pilot: RefCounted = PixelRig.new(PILOT_ROOT)
var candidate: bool = true
var cycle: float = 0.5
var gather: float = 0
var last_point: Vector2 = Vector2.ZERO
var initialized: bool = false
var travelled: float = 0
var cycles_advanced: float = 0
var moving_time: float = 0
var soft_hair: bool = true
var actor_layer: Node2D
var front_layer: Node2D

func _ready() -> void:
	actor_layer = preload("res://tools/studies/pietro_house/pietro_layer.gd").new()
	actor_layer.presenter = self
	var hair: ShaderMaterial = ShaderMaterial.new()
	hair.shader = load(PILOT_ROOT+"hair_light.gdshader")
	actor_layer.material = hair
	add_child(actor_layer)
	front_layer = preload("res://tools/studies/pietro_house/front_stairs.gd").new()
	front_layer.presenter = self
	front_layer.z_index = 10
	add_child(front_layer)
	sync_layers()

func sync_layers() -> void:
	if not is_instance_valid(actor_layer): return
	actor_layer.visible = candidate
	actor_layer.position = point
	actor_layer.material.set_shader_parameter("softness",0.65 if soft_hair else 0.0)
	actor_layer.queue_redraw()
	front_layer.visible = candidate and on_stairs
	front_layer.queue_redraw()

func _init() -> void:
	pilot.data.scale = PILOT_SCALE
	pilot.pose(cycle,0)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func advance(delta: float, reduced: bool = false) -> void:
	if not initialized:
		last_point = point
		initialized = true
	var distance: float = absf(point.x-last_point.x)
	last_point = point
	travelled += distance
	# No new waking or stair animation is claimed by this experiment.
	if reduced or on_stairs or not is_zero_approx(rest_angle):
		gather = 0
		cycle = 0.5
	elif distance>0.0001:
		var advance_cycles: float = distance/(4*float(pilot.data.walk.amplitude)*PILOT_SCALE)
		cycle += advance_cycles
		cycles_advanced += advance_cycles
		moving_time += delta
		gather = move_toward(gather,1,delta/0.2)
	else:
		gather = move_toward(gather,0,delta/0.2)
		if is_zero_approx(gather): cycle = 0.5
	pilot.pose(cycle,gather)
	sync_layers()
	queue_redraw()

func _draw() -> void:
	if not candidate:
		super._draw()
		return
	draw_texture_rect(background,Rect2(Vector2.ZERO,Space.SIZE),false)
	Stairs.draw_layer(self,false)
	if not on_stairs: Stairs.draw_layer(self,true)
	draw_set_transform(point+Vector2(0,2),0,Vector2(1,0.2))
	draw_circle(Vector2.ZERO,50,Color(0.01,0.025,0.035,0.12))
	draw_circle(Vector2.ZERO,30,Color(0.01,0.025,0.035,0.3))
	draw_set_transform(Vector2.ZERO)

func actor_bounds() -> Rect2:
	if not candidate: return super.actor_bounds()
	var rect: Rect2 = Rect2()
	for mesh in [pilot.legs[0],pilot.legs[1],pilot.upper.mesh]:
		var box: AABB = mesh.get_aabb()
		var part: Rect2 = Rect2(Vector2(box.position.x,box.position.y),Vector2(box.size.x,box.size.y))
		rect = part if rect.size.is_zero_approx() else rect.merge(part)
	var factor: Vector2 = Vector2(-1 if facing.x<0 else 1,1)*PILOT_SCALE
	var transform_actor: Transform2D = Transform2D(Vector2(factor.x,0),Vector2(0,factor.y),point-Vector2(pilot.data.pivot[0],pilot.data.pivot[1])*factor)
	return transform_actor*rect
