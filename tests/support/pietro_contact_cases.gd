extends RefCounted
const Gait = preload("res://scripts/ui/pietro_stair_gait.gd")
const Rig = preload("res://scripts/ui/pietro_stair_rig.gd")
const Space = preload("res://scripts/ui/house_space.gd")

static func run(expect: Callable) -> void:
	var rig: RefCounted = Rig.new()
	var definition: Dictionary = rig.data.gait
	var stationary: bool = true
	var on_tread: bool = true
	var support: bool = true
	var alternating: bool = true
	var previous: int = -1
	for step in range(2, Space.STEPS - 1):
		var a: Dictionary = Gait.sample((step + 0.15) / Space.STEPS, definition)
		var b: Dictionary = Gait.sample((step + 0.5) / Space.STEPS, definition)
		var planted: int = 1 - int(a.swing)
		stationary = stationary and a.feet[planted].distance_to(b.feet[planted]) < 0.001 and a.feet[a.swing].distance_to(b.feet[a.swing]) > 10
		alternating = alternating and a.swing != previous
		previous = a.swing
		for phase in [0.0, 0.15, 0.5, 0.68, 0.85, 0.999]:
			var sample: Dictionary = Gait.sample((step + phase) / Space.STEPS, definition)
			support = support and (sample.planted[0] or sample.planted[1])
			for leg in range(2):
				if not sample.planted[leg]: continue
				var foot: Vector2 = sample.feet[leg] - Gait.tread(sample.contacts[leg])
				on_tread = on_tread and Geometry2D.is_point_in_polygon(foot, PackedVector2Array([Vector2(-29, 0), Vector2(30, 0), Vector2(105, -20), Vector2(46, -20)]))
	expect.call(stationary, "A planted stair boot stays fixed as the opposite boot travels to its next tread")
	expect.call(alternating, "Successive stair risers alternate the two swing legs")
	expect.call(support, "Climbing never has both feet airborne between tread contacts")
	expect.call(on_tread, "Every interior planted sole lies on an actual house tread polygon")
	var settled: Dictionary = Gait.sample(0.4375, definition)
	var transfer: Dictionary = Gait.sample(0.4475, definition)
	expect.call(settled.feet == transfer.feet and settled.root.distance_to(transfer.root) > 5, "The pelvis keeps transferring weight during double support instead of stopping at each touchdown")
	var retraces: bool = true
	var soles: bool = true
	var reachable: bool = true
	for phase in [0.0, 0.023, 0.125, 0.271, 0.335, 0.529, 0.739, 0.863, 0.977, 1.0]:
		var up: Dictionary = Gait.sample(phase, definition, 1)
		var down: Dictionary = Gait.sample(phase, definition, -1)
		if phase > 0.1 and phase < 0.95:
			retraces = retraces and up.feet == down.feet
		for direction in [1, -1]:
			rig.seek(phase, direction)
			for leg in range(2):
				var pose: Dictionary = rig.posed_legs[leg]
				var source: Dictionary = rig.data.legs[leg]
				var actual: Vector2 = rig._leg(Rig._point(source.sole), pose)
				soles = soles and actual.distance_to(rig.state.feet[leg if direction > 0 else 1 - leg]) < 0.001
				var length: float = Rig._point(source.knee).distance_to(Rig._point(source.ankle)) * float(rig.data.scale)
				reachable = reachable and absf(pose.knee.distance_to(pose.ankle) - length) < 1
	expect.call(retraces, "Manual reversal retraces the same interior world foot contacts without a direction reset")
	expect.call(soles, "Skinned boot sole pixels use the actual gait contact anchors in both facings")
	expect.call(reachable, "Both knees can reach their ankle targets without extending a shin by more than one world pixel")
	var endpoints: bool = true
	for progress in [0.0, 1.0]:
		for direction in [1, -1]:
			rig.seek(progress, direction)
			var vertices: PackedVector2Array = rig.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var flip: float = -1 if direction > 0 else 1
			for index in range(vertices.size()):
				var expected: Vector2 = Gait.tread(progress * Space.STEPS) + (rig.source_points[index] - Vector2(220, 414)) * Vector2(flip, 1) * 1.3
				endpoints = endpoints and vertices[index].distance_to(expected) < 0.05
	expect.call(endpoints, "Both stair landings converge to the exact original idle drawing and foot pivots")
