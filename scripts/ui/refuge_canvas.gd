extends Node2D
const Assets = preload("res://scripts/assets/catalog.gd")
const Space = preload("res://scripts/ui/house_space.gd")
const ACTOR_SCALE_MULTIPLIER = 1.34
var point: Vector2 = Space.SPAWN
var facing: Vector2 = Vector2.RIGHT
var stride: float = 0
var nearby: String = ""
var room: String = "bedroom"
var rest_angle: float = 0
var house_regions: Dictionary = Assets.manifest("world/pietro-house", "1.0.0").metadata.rooms
var house: Texture2D = Assets.texture("world/pietro-house")
var background: Texture2D = Assets.texture("world/refuge-lateral")
var actor: Texture2D = Assets.texture("characters/refuge-traveler")
var poses: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Assets.file_path("characters/refuge-traveler", "1.0.0", "poses")))

func _draw() -> void:
	if room == "living":
		draw_texture_rect(background, Rect2(Vector2.ZERO, Space.SIZE), false)
	else:
		var region: Array = house_regions[room]
		draw_texture_rect_region(house, Rect2(Vector2.ZERO, Space.SIZE), Rect2(region[0], region[1], region[2], region[3]))
	# Soft contact shadow remains under the feet, independent of animation frame.
	if is_zero_approx(rest_angle):
		draw_set_transform(point + Vector2(0, 2), 0, Vector2(1, 0.2))
		draw_circle(Vector2.ZERO, 43, Color(0.01, 0.025, 0.035, 0.12))
		draw_circle(Vector2.ZERO, 30, Color(0.01, 0.025, 0.035, 0.32))
	draw_set_transform(point, rest_angle, Vector2(-1 if facing.x < 0 else 1, 1) * float(poses.source_scale) * ACTOR_SCALE_MULTIPLIER)
	var pose: Dictionary = current_pose()
	var region: Array = pose.region
	var rect = Rect2(float(region[0]), float(region[1]), float(region[2]), float(region[3]))
	draw_texture_rect_region(actor, Rect2(-Vector2(pose.pivot[0], pose.pivot[1]), rect.size), rect, Color(0.96, 0.98, 0.92))
	draw_set_transform(Vector2.ZERO)

func current_pose() -> Dictionary:
	var index: int = int(poses.walk[int(stride) % poses.walk.size()]) if stride > 0 else int(poses.idle)
	return poses.frames[index]

func actor_bounds() -> Rect2:
	# Conservative full atlas frame, including transparent padding around hair.
	var pose: Dictionary = current_pose()
	var region: Array = pose.region
	var transform = Transform2D(rest_angle, point)
	var actor_scale: float = float(poses.source_scale) * ACTOR_SCALE_MULTIPLIER
	transform.x *= (-1 if facing.x < 0 else 1) * actor_scale
	transform.y *= actor_scale
	return transform * Rect2(-Vector2(pose.pivot[0], pose.pivot[1]), Vector2(region[2], region[3]))
