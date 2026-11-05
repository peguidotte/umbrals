extends Node2D
const Assets = preload("res://scripts/assets/catalog.gd")
const Space = preload("res://scripts/ui/house_space.gd")
const Stairs = preload("res://scripts/ui/house_stairs.gd")
const PoseView = preload("res://scripts/ui/pietro_pose_view.gd")
var point: Vector2 = Space.SPAWN
var facing: Vector2 = Vector2.RIGHT
var stride: float = 0
var nearby: String = ""
# A derived semantic zone, never an asset selection or position reset.
var room: String = "bedroom"
var rest_angle: float = 0
var on_stairs: bool = false
var wake_phase: float = -1
var stair_progress: float = 0
var stair_direction: float = 1
var reduced_motion: bool = false
var background: Texture2D = Assets.texture("world/pietro-house-continuous")
var visual: RefCounted = PoseView.new()

func _draw() -> void:
	draw_texture_rect(background, Rect2(Vector2.ZERO, Space.SIZE), false)
	Stairs.draw_layer(self, false)
	if not on_stairs: Stairs.draw_layer(self, true)
	if wake_phase < 0 and not on_stairs:
		draw_set_transform(point + Vector2(0, 2), 0, Vector2(1, 0.2))
		draw_circle(Vector2.ZERO, 39, Color(0.01, 0.025, 0.035, 0.12))
		draw_circle(Vector2.ZERO, 26, Color(0.01, 0.025, 0.035, 0.3))
	var sample: Dictionary = current_sample()
	draw_set_transform(sample.anchor, 0, Vector2(-1 if sample.flip else 1, 1) * float(sample.scale))
	var pose: Dictionary = sample.pose
	var region: Array = pose.region
	var rect = Rect2(float(region[0]), float(region[1]), float(region[2]), float(region[3]))
	draw_texture_rect_region(sample.texture, Rect2(-Vector2(pose.pivot[0], pose.pivot[1]), rect.size), rect)
	draw_set_transform(Vector2.ZERO)
	if on_stairs: Stairs.draw_layer(self, true)

func current_pose() -> Dictionary:
	return current_sample().pose

func current_sample() -> Dictionary:
	return visual.sample(point, facing, stride, wake_phase, on_stairs, stair_progress, stair_direction, reduced_motion)

func wake_duration() -> float:
	return float(visual.data.duration)

func pose_state() -> Dictionary:
	var sample: Dictionary = current_sample()
	return {"animation": sample.clip, "frame": sample.index, "pose": sample.pose_name}

func actor_bounds() -> Rect2:
	var sample: Dictionary = current_sample()
	var pose: Dictionary = sample.pose
	var region: Array = pose.region
	var actor_transform = Transform2D(0, sample.anchor)
	actor_transform.x *= (-1 if sample.flip else 1) * float(sample.scale)
	actor_transform.y *= float(sample.scale)
	return actor_transform * Rect2(-Vector2(pose.pivot[0], pose.pivot[1]), Vector2(region[2], region[3]))
