extends RefCounted
## Presentation-only horizontal lane. Never persisted in a run.
const SIZE = Vector2(1672, 941)
const FLOOR_Y = 788.0
const SPAWN = Vector2(700, FLOOR_Y)
const SPEED = 245.0
# Reserve the enlarged walk poses' 88px extent at both edges.
const LEFT = 100.0
const RIGHT = 1570.0
const EXIT = 1500.0
const STATIONS = {"codex": Vector2(270, FLOOR_Y), "improvements": Vector2(1170, FLOOR_Y)}

static func walk(point: Vector2, direction: Vector2, delta: float) -> Vector2:
	return Vector2(clampf(point.x + clampf(direction.x, -1, 1) * SPEED * minf(delta, 0.1), LEFT, RIGHT), FLOOR_Y)

static func clear(point: Vector2) -> bool:
	return point.x >= LEFT and point.x <= RIGHT and is_equal_approx(point.y, FLOOR_Y)

static func nearest(point: Vector2) -> String:
	for key in STATIONS:
		if absf(point.x - STATIONS[key].x) < 105: return key
	return ""
