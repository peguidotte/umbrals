extends RefCounted
const Space = preload("res://scripts/ui/house_space.gd")
const Motion = preload("res://scripts/ui/house_motion.gd")
const Canvas = preload("res://scripts/ui/refuge_canvas.gd")
const Camera = preload("res://scripts/ui/house_camera.gd")
const Contacts = preload("res://tests/support/pietro_contact_cases.gd")

static func run(expect: Callable) -> void:
	Contacts.run(expect)
	var actor: Node2D = Canvas.new()
	var motion: RefCounted = Motion.new()
	motion.wake(actor, false)
	expect.call(actor.pose_state().pose == "lying" and actor.rest_angle == 0, "Wake starts with a drawn lying pose and no sprite rotation")
	var names: Array[String] = []
	for phase in [0.05, 0.24, 0.42, 0.58, 0.76, 0.94]:
		motion.wake_time = phase * actor.wake_duration()
		motion.step(actor, Vector2.ZERO, 0, false)
		names.append(actor.pose_state().pose)
		expect.call(actor.pose_state().animation == "wake" and actor.rest_angle == 0, "Drawn wake pose %s keeps an upright render transform" % actor.pose_state().pose)
	expect.call(names == ["lying", "propped", "knees_seated", "edge_seated", "rising", "standing"], "Wake visits lying, propped, seated, rising and standing drawings")
	for phase in [0.76, 0.94]:
		actor.wake_phase = phase
		var sample: Dictionary = actor.current_sample()
		var sole: float = sample.anchor.y + (float(sample.pose.sole_y) - float(sample.pose.pivot[1])) * float(sample.scale)
		expect.call(absf(sole - Space.FLOOR_Y) < 0.01, "Grounded wake drawing %s keeps the boot sole on the floor" % sample.pose.name)
	motion.step(actor, Vector2.RIGHT, 0, false)
	expect.call(not motion.waking and actor.point == Space.SPAWN and actor.pose_state().animation == "idle", "Directional skip reaches exact floor idle without a rotated intermediate pose")
	motion.wake(actor, true)
	expect.call(not motion.waking and actor.wake_phase < 0 and actor.point == Space.SPAWN, "Reduced motion skips the whole wake sequence")
	motion.wake(actor, false)
	motion.step(actor, Vector2.ZERO, 0, true)
	expect.call(not motion.waking and actor.pose_state().animation == "idle", "Changing reduced motion during wake immediately selects floor idle")
	motion.use_stairs(actor)
	motion.progress = 0.271
	motion.step(actor, Vector2.UP, 0, false)
	var before: Dictionary = actor.pose_state()
	actor.stride += 321
	expect.call(before == actor.pose_state() and before.animation == "ascent", "Climbing chooses authored ascent by tread progress, not the walking clock")
	motion.cancel_approach()
	var point: Vector2 = actor.point
	motion.step(actor, Vector2.ZERO, 0.1, false)
	expect.call(actor.point == point and actor.pose_state() == before, "Paused stair traversal freezes the exact ascent drawing")
	motion.step(actor, Vector2.DOWN, 0.001, false)
	expect.call(actor.pose_state().animation == "descent" and actor.point.distance_to(point) < 3, "Reversing on stairs selects descent without repositioning the body")
	motion.step(actor, Vector2.DOWN, 0.1, true)
	expect.call(actor.pose_state().frame == 0 and actor.pose_state().animation == "descent", "Reduced motion holds a dedicated descent pose while retaining traversal")
	for viewport in [Vector2(1280, 720), Vector2(1440, 900), Vector2(1920, 1080), Vector2(1024, 768), Vector2(2560, 1080)]:
		var camera: RefCounted = Camera.new()
		camera.layout(viewport)
		var contained: bool = true
		for phase in [0.05, 0.24, 0.42, 0.58, 0.76, 0.94]:
			motion.wake(actor, false)
			motion.wake_time = phase * actor.wake_duration()
			motion.step(actor, Vector2.ZERO, 0, false)
			camera.follow(actor.point, 0, true)
			contained = contained and Rect2(Vector2.ZERO, viewport).grow(-32 * camera.zoom).encloses(camera.projection() * actor.actor_bounds())
		expect.call(contained, "Every full wake drawing retains camera margin at %dx%d" % [viewport.x, viewport.y])
	actor.free()
