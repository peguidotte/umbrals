extends Control
const RefArt = preload("res://scripts/ui/reference_art.gd")
const Assets = preload("res://scripts/assets/catalog.gd")
var artwork: Texture2D
var active: bool = true
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	artwork = Assets.texture("ui/gold-codex-template")
	resized.connect(queue_redraw)
func _draw() -> void:
	if not active: return
	var sx = [292.0,307.0,452.0,468.0]
	var sy = [279.0,297.0,568.0,585.0]
	var dx = [0.0,17.0,size.x-17.0,size.x]
	var dy = [0.0,17.0,size.y-17.0,size.y]
	for y in range(3):
		for x in range(3):
			if x == 1 and y == 1: continue
			draw_texture_rect_region(artwork,Rect2(dx[x],dy[y],dx[x+1]-dx[x],dy[y+1]-dy[y]),Rect2(sx[x],sy[y],sx[x+1]-sx[x],sy[y+1]-sy[y]))
