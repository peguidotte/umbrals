extends RefCounted
## Cosmetic tread contacts. Evaluation depends only on distance along the stairs:
## pausing freezes it and reversing retraces the same foot paths.
const Space = preload("res://scripts/ui/house_space.gd")

static func tread(index: float) -> Vector2:
	return Space.STAIR_BOTTOM.lerp(Space.STAIR_TOP, index / Space.STEPS)

static func sample(progress: float, definition: Dictionary, direction: float = 1) -> Dictionary:
	var distance: float = clampf(progress, 0, 1) * Space.STEPS
	var index: int = mini(int(distance), Space.STEPS - 1)
	var phase: float = distance - index
	var swing: int = index % 2
	var feet: Array[Vector2] = []
	var bases: Array[Vector2] = []
	var planted: Array[bool] = []
	var contacts: Array[int] = []
	for leg in range(2):
		var slot: Array = definition.slots[leg]
		var offset = Vector2(slot[0], slot[1])
		var from_index: int = maxi(index - 1, 0) if leg == swing else index
		var to_index: int = index + 1 if leg == swing else index
		var weight: float = smoothstep(0, float(definition.landing_phase), phase) if leg == swing else 0
		var start: Vector2 = tread(from_index) + offset
		var end: Vector2 = tread(to_index) + offset
		# Endpoints use the actual idle soles. The first leg transfers from floor
		# to tread; on the final tread the trailing leg gathers after touchdown.
		if from_index == 0: start = tread(0) + _neutral(leg, definition, direction)
		if to_index == Space.STEPS: end = tread(Space.STEPS) + _neutral(leg, definition, direction)
		if index == Space.STEPS - 1 and leg != swing:
			end = tread(Space.STEPS) + _neutral(leg, definition, direction)
			to_index = Space.STEPS
			weight = smoothstep(float(definition.gather_phase), 1, phase)
		var base: Vector2 = start.lerp(end, weight)
		var lift: float = sin(weight * PI) * float(definition.clearance) if weight > 0 and weight < 1 else 0
		bases.append(base)
		feet.append(base - Vector2(0, lift))
		planted.append(weight <= 0 or weight >= 1)
		contacts.append(to_index if weight >= 1 else from_index if weight <= 0 else -1)
	var mean: Vector2 = (bases[0] + bases[1]) * 0.5
	# Weight keeps travelling during double support. A pelvis driven only by
	# the soles would stop for the last third of every tread after touchdown.
	var slots_mean = Vector2((float(definition.slots[0][0]) + float(definition.slots[1][0])) * 0.5, (float(definition.slots[0][1]) + float(definition.slots[1][1])) * 0.5)
	var continuous: Vector2 = tread(distance - 0.5) + slots_mean
	var interior: float = smoothstep(1, 2, distance) * (1.0 - smoothstep(Space.STEPS - 1, Space.STEPS, distance))
	mean = mean.lerp(continuous, interior)
	var blend: float = smoothstep(0, 0.7, distance) * (1.0 - smoothstep(Space.STEPS - 0.5, Space.STEPS, distance))
	var neutral_mean: float = (_neutral(0, definition, direction).x + _neutral(1, definition, direction).x) * 0.5
	var hip_x: float = float(definition.idle_hip_x) * (1 if direction > 0 else -1)
	var root: Vector2 = mean - Vector2(neutral_mean - hip_x, lerpf(float(definition.idle_height), float(definition.climb_height), blend))
	return {"feet": feet, "planted": planted, "contacts": contacts, "root": root, "blend": blend, "swing": swing, "phase": phase, "distance": distance}

static func _neutral(leg: int, definition: Dictionary, direction: float) -> Vector2:
	var offset: Array = definition.neutral_soles[leg]
	if direction < 0:
		offset = definition.neutral_soles[1 - leg]
		return Vector2(-float(offset[0]), offset[1])
	return Vector2(offset[0], offset[1])
