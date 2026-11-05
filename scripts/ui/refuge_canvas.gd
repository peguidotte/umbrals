extends Node2D
const Assets = preload("res://scripts/assets/catalog.gd")
const Space = preload("res://scripts/ui/house_space.gd")
const Stairs = preload("res://scripts/ui/house_stairs.gd")
var point: Vector2 = Space.SPAWN
var facing: Vector2 = Vector2.RIGHT
var stride: float = 0
var nearby: String = ""
# A derived semantic zone, never an asset selection or position reset.
var room: String = "bedroom"
var rest_angle: float = 0
var on_stairs: bool = false
var background: Texture2D = Assets.texture("world/pietro-house-continuous")
var actor: Texture2D = Assets.texture("characters/pietro-home")
var poses: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Assets.bound_file("characters/pietro-home", "poses")))

func _draw() -> void:
	draw_texture_rect(background, Rect2(Vector2.ZERO, Space.SIZE), false)
	Stairs.draw_layer(self, false)
	if not on_stairs: Stairs.draw_layer(self, true)
	if is_zero_approx(rest_angle):
		draw_set_transform(point + Vector2(0, 2), 0, Vector2(1, 0.2))
		draw_circle(Vector2.ZERO, 39, Color(0.01, 0.025, 0.035, 0.12))
		draw_circle(Vector2.ZERO, 26, Color(0.01, 0.025, 0.035, 0.3))
	draw_set_transform(point, rest_angle, Vector2(-1 if facing.x < 0 else 1, 1) * float(poses.source_scale))
	var pose: Dictionary = current_pose()
	var region: Array = pose.region
	var rect = Rect2(float(region[0]), float(region[1]), float(region[2]), float(region[3]))
	draw_texture_rect_region(actor, Rect2(-Vector2(pose.pivot[0], pose.pivot[1]), rect.size), rect)
	draw_set_transform(Vector2.ZERO)
	if on_stairs: Stairs.draw_layer(self, true)

func current_pose() -> Dictionary:
	var index: int = int(poses.walk[int(stride) % poses.walk.size()]) if stride > 0 else int(poses.idle)
	return poses.frames[index]

func actor_bounds() -> Rect2:
	var pose: Dictionary = current_pose()
	var region: Array = pose.region
	var actor_transform = Transform2D(rest_angle, point)
	actor_transform.x *= (-1 if facing.x < 0 else 1) * float(poses.source_scale)
	actor_transform.y *= float(poses.source_scale)
	return actor_transform * Rect2(-Vector2(pose.pivot[0], pose.pivot[1]), Vector2(region[2], region[3]))
