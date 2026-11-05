extends RefCounted
## Transient locomotion only: no domain, storage, RNG or commands.
const Space = preload("res://scripts/ui/house_space.gd")
var waking: bool = false
var wake_time: float = 0
var upper: bool = false
var on_stairs: bool = false
var progress: float = 0
var automatic: float = 0
var stair_direction: float = 1

func wake(canvas: Node2D, reduced: bool) -> void:
	waking = not reduced
	wake_time = 0
	upper = false
	on_stairs = false
	canvas.point = Space.BED if waking else Space.SPAWN
	canvas.rest_angle = -PI / 2 if waking else 0.0

func cancel_approach() -> void:
	automatic = 0

func use_stairs(canvas: Node2D) -> void:
	if on_stairs:
		automatic = stair_direction
		return
	progress = 1.0 if upper else 0.0
	stair_direction = -1 if upper else 1
	on_stairs = true
	automatic = stair_direction
	canvas.point = Space.stair_point(progress)

func step(canvas: Node2D, direction: Vector2, delta: float, reduced: bool) -> bool:
	if waking:
		wake_time += delta
		if not direction.is_zero_approx() or reduced: wake_time = 1.4
		var weight: float = smoothstep(0, 1, clampf((wake_time - 0.5) / 0.9, 0, 1))
		canvas.point = Space.BED.lerp(Space.SPAWN, weight)
		canvas.rest_angle = lerpf(-PI / 2, 0, weight)
		waking = wake_time < 1.4
		return true
	if not on_stairs: return false
	if not direction.is_zero_approx(): automatic = 0
	var travel: float = -direction.y if not is_zero_approx(direction.y) else automatic
	if not is_zero_approx(travel): stair_direction = signf(travel)
	progress = clampf(progress + travel * Space.SPEED * minf(delta, 0.1) / Space.STAIR_BOTTOM.distance_to(Space.STAIR_TOP), 0, 1)
	canvas.point = Space.stair_point(progress)
	canvas.facing = Vector2(-travel, 0) if not is_zero_approx(travel) else canvas.facing
	canvas.stride = canvas.stride + delta * 9 if not is_zero_approx(travel) and not reduced else 0
	if progress >= 1 and travel > 0:
		upper = true
		on_stairs = false
	elif progress <= 0 and travel < 0:
		upper = false
		on_stairs = false
	return true

func public_state() -> Dictionary:
	return {"waking": waking, "upper_floor": upper, "on_stairs": on_stairs, "stair_progress": progress, "stair_automatic": automatic, "stair_direction": stair_direction}
