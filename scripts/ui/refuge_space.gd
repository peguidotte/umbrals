extends RefCounted
## Presentation geometry only. Coordinates never enter a run checkpoint.
const SIZE = Vector2(1200, 680)
const SPAWN = Vector2(620, 475)
const FLOOR = Rect2(104, 265, 992, 345)
const RADIUS = 16.0
const SPEED = 245.0
const OBSTACLES = [Rect2(170, 280, 240, 82), Rect2(760, 280, 210, 82), Rect2(180, 480, 235, 85), Rect2(800, 485, 160, 65), Rect2(118, 270, 42, 30), Rect2(1040, 534, 44, 30)]
const STATIONS = {"codex": Vector2(320, 390), "improvements": Vector2(840, 390), "journey": Vector2(1030, 305)}

static func walk(point: Vector2, direction: Vector2, delta: float) -> Vector2:
	var displacement: Vector2 = direction.limit_length(1.0) * SPEED * minf(delta, 0.1)
	# Small axis-separated steps prevent tunnelling and allow sliding along furniture.
	var steps: int = maxi(1, ceili(displacement.length() / 6.0))
	for step in range(steps):
		var next: Vector2 = point + Vector2(displacement.x / steps, 0)
		if clear(next): point = next
		next = point + Vector2(0, displacement.y / steps)
		if clear(next): point = next
	return point

static func clear(point: Vector2) -> bool:
	if not FLOOR.grow(-RADIUS).has_point(point): return false
	for obstacle in OBSTACLES:
		if obstacle.grow(RADIUS).has_point(point): return false
	return true

static func nearest(point: Vector2) -> String:
	var best: String = ""
	var distance: float = 95.0
	for key in STATIONS:
		var candidate: float = point.distance_to(STATIONS[key])
		if candidate < distance:
			best = key
			distance = candidate
	return best
