extends RefCounted
const Space = preload("res://scripts/ui/house_space.gd")
const Motion = preload("res://scripts/ui/house_motion.gd")
const Canvas = preload("res://scripts/ui/refuge_canvas.gd")
const Camera = preload("res://scripts/ui/house_camera.gd")

static func resume_cases(expect: Callable) -> void:
	var actor: Node2D = Canvas.new()
	var motion: RefCounted = Motion.new()
	actor.point = Space.STAIR_BOTTOM
	motion.use_stairs(actor)
	motion.progress = 0.739
	motion.step(actor, Vector2.UP, 0.001, false)
	motion.cancel_approach()
	var paused: float = motion.progress
	motion.use_stairs(actor)
	motion.step(actor, Vector2.ZERO, 0.1, false)
	expect.call(motion.progress > paused, "E resumes paused 73.9% ascent in its previous direction")
	motion.step(actor, Vector2.DOWN, 0.1, false)
	var reversed: float = motion.progress
	motion.step(actor, Vector2.DOWN, 0.1, false)
	expect.call(motion.progress < reversed, "Explicit down reverses ascent")
	motion.progress = 0.25
	motion.step(actor, Vector2.DOWN, 0.001, true)
	motion.cancel_approach()
	paused = motion.progress
	motion.use_stairs(actor)
	motion.step(actor, Vector2.ZERO, 0.1, true)
	expect.call(motion.progress < paused and actor.stride == 0, "Lower-half descent resumes down with reduced motion")
	motion.progress = 0.9999
	motion.step(actor, Vector2.UP, 0.1, false)
	expect.call(actor.point == Space.STAIR_TOP and motion.upper and not motion.on_stairs, "Stair arrival retains exact world coordinates on upper floor")
	actor.free()

static func clearance_cases(room: Control, expect: Callable) -> void:
	var actor: Node2D = room.canvas
	var old_point: Vector2 = actor.point
	var old_stride: float = actor.stride
	var old_facing: Vector2 = actor.facing
	var old_angle: float = actor.rest_angle
	actor.rest_angle = 0
	for viewport in [Vector2(1280, 720), Vector2(1440, 900), Vector2(1920, 1080), Vector2(1024, 768), Vector2(2560, 1080)]:
		var camera: RefCounted = Camera.new()
		camera.layout(viewport)
		var safe: Rect2 = Rect2(Vector2.ZERO, viewport).grow(-32 * camera.zoom)
		var contained: bool = true
		for progress in [0.0, 0.25, 0.739, 0.95, 1.0]:
			actor.point = Space.stair_point(progress)
			camera.follow(actor.point, 0, true)
			for direction in [-1, 1]:
				actor.facing = Vector2(direction, 0)
				for stride in range(7):
					actor.stride = stride
					contained = contained and safe.encloses(camera.projection() * actor.actor_bounds())
			expect.call((camera.projection().affine_inverse() * (camera.projection() * actor.point)).distance_to(actor.point) < 0.01, "Pointer projection round-trips on stairs at %dx%d" % [viewport.x, viewport.y])
		expect.call(contained, "Full atlas frames retain camera margin across stairs at %dx%d" % [viewport.x, viewport.y])
	actor.point = old_point
	actor.stride = old_stride
	actor.facing = old_facing
	actor.rest_angle = old_angle
