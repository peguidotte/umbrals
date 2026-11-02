extends Control
## Nine-sliced original botanical artwork. Native controls remain independent.
const Assets = preload("res://scripts/assets/catalog.gd")
var corner: float = 52.0
var inset: float = 18.0
var artwork: Texture2D
func _ready() -> void:
	artwork = Assets.texture("ui/gold-frame")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	var texture: Texture2D = artwork
	if texture == null or size.x <= 0: return
	var ts: Vector2 = texture.get_size()
	var sx = [ts.x * 0.025, ts.x * 0.14, ts.x * 0.86, ts.x * 0.975]
	var sy = [ts.y * 0.05, ts.y * 0.36, ts.y * 0.64, ts.y * 0.95]
	var c: float = minf(corner, minf(size.x, size.y) * 0.42)
	var dx = [inset, inset + c, size.x - inset - c, size.x - inset]
	var dy = [inset, inset + c, size.y - inset - c, size.y - inset]
	for y in range(3):
		for x in range(3):
			if x == 1 and y == 1: continue
			var dest = Rect2(dx[x], dy[y], dx[x+1]-dx[x], dy[y+1]-dy[y])
			var source = Rect2(sx[x], sy[y], sx[x+1]-sx[x], sy[y+1]-sy[y])
			if dest.size.x > 0 and dest.size.y > 0: draw_texture_rect_region(texture, dest, source)
