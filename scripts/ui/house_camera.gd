extends RefCounted
## Shared world/screen projection, including inverse pointer coordinates.
const Space = preload("res://scripts/ui/house_space.gd")
var center: Vector2 = Vector2(800, 1070)
var viewport: Vector2 = Space.VIEW
var zoom: float = 1

func layout(size: Vector2) -> void:
	viewport = size
	zoom = maxf(0.1, minf(size.x / Space.VIEW.x, size.y / Space.VIEW.y))
	center = bounded(center)

func bounded(target: Vector2) -> Vector2:
	var half: Vector2 = viewport / zoom / 2
	return Vector2(clampf(target.x, half.x, Space.SIZE.x - half.x), clampf(target.y, half.y, Space.SIZE.y - half.y))

func follow(point: Vector2, delta: float, immediate: bool = false) -> void:
	var target: Vector2 = bounded(point - Vector2(0, 180))
	center = target if immediate else center.lerp(target, 1.0 - exp(-9.0 * delta))

func projection() -> Transform2D:
	return Transform2D(Vector2(zoom, 0), Vector2(0, zoom), viewport / 2 - center * zoom)

func visible_world() -> Rect2:
	return projection().affine_inverse() * Rect2(Vector2.ZERO, viewport)
