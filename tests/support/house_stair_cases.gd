extends RefCounted
## Regression cases for the actual room layout and resumable stair presentation.
const Space = preload("res://scripts/ui/house_space.gd")
const Motion = preload("res://scripts/ui/house_motion.gd")
const Canvas = preload("res://scripts/ui/refuge_canvas.gd")

static func resume_cases(expect: Callable) -> void:
	var actor: Node2D = Canvas.new()
	actor.room = "kitchen"
	actor.point = Space.STAIR_BOTTOM
	var motion: RefCounted = Motion.new()
	motion.use_stairs(actor)
	motion.progress = 0.739
	motion.step(actor, Vector2.UP, 0.001, false)
	motion.cancel_approach()
	var paused: float = motion.progress
	motion.use_stairs(actor)
	motion.step(actor, Vector2.ZERO, 0.1, false)
	expect.call(motion.progress > paused, "Interacting at a paused 73.9% ascent resumes up, rather than choosing down by position")
	motion.step(actor, Vector2.DOWN, 0.1, false)
	var reversed: float = motion.progress
	motion.step(actor, Vector2.DOWN, 0.1, false)
	expect.call(motion.progress < reversed, "Explicit down input reverses a resumed ascent")
	motion.progress = 0.25
	motion.step(actor, Vector2.DOWN, 0.001, true)
	motion.cancel_approach()
	paused = motion.progress
	motion.use_stairs(actor)
	motion.step(actor, Vector2.ZERO, 0.1, true)
	expect.call(motion.progress < paused and actor.stride == 0, "A paused descent below halfway resumes down with reduced motion")
	actor.free()

static func clearance_cases(room: Control, expect: Callable) -> void:
	var original_size: Vector2 = room.size
	var original_point: Vector2 = room.canvas.point
	var original_room: String = room.canvas.room
	var original_facing: Vector2 = room.canvas.facing
	var original_stride: float = room.canvas.stride
	var original_angle: float = room.canvas.rest_angle
	room.canvas.room = "kitchen"
	room.canvas.rest_angle = 0
	for viewport in [Vector2(1280, 720), Vector2(1440, 900), Vector2(1920, 1080), Vector2(1024, 768), Vector2(2560, 1080)]:
		room.size = viewport
		room._layout()
		var scene: Rect2 = Rect2(room.canvas.position, Space.SIZE * room.canvas.scale.x)
		var safe: Rect2 = scene.grow(-32 * room.canvas.scale.x)
		var contained: bool = true
		for progress in [0.0, 0.25, 0.739, 0.95, 1.0]:
			room.canvas.point = Space.STAIR_BOTTOM.lerp(Space.STAIR_TOP, progress)
			for direction in [-1, 1]:
				room.canvas.facing = Vector2(direction, 0)
				for stride in range(7):
					room.canvas.stride = stride
					var projected: Rect2 = room.canvas.transform * room.canvas.actor_bounds()
					contained = contained and safe.encloses(projected)
		expect.call(contained, "All idle/walk poses retain a 32-reference-pixel room margin across the stairs at %dx%d" % [viewport.x, viewport.y])
	room.canvas.point = original_point
	room.canvas.room = original_room
	room.canvas.facing = original_facing
	room.canvas.stride = original_stride
	room.canvas.rest_angle = original_angle
	room.size = original_size
	room._layout()
