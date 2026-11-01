extends Control
## Decorative original grove and route. Only public map geometry is supplied.
const Paths = preload("res://scripts/assets/binding_paths.gd")
const FOREST = preload(Paths.WORLD_MOONLIT_CLEARING)
const UI = preload("res://scripts/ui/kit.gd")
var nodes: Dictionary = {}
var selected: String = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x <= 1 or size.y <= 1: return
	draw_rect(Rect2(Vector2.ZERO, size), UI.INK)
	var cover: float = maxf(size.x / FOREST.get_width(), size.y / FOREST.get_height())
	var source_size: Vector2 = size / cover
	draw_texture_rect_region(FOREST, Rect2(Vector2.ZERO, size), Rect2((FOREST.get_size() - source_size) * 0.5, source_size), Color(0.45, 0.50, 0.78, 0.55))
	# Deterministic visual pattern; never touches the run's random stream.
	for i in range(18):
		var point := Vector2(fposmod(i * 0.618 + 0.04, 1) * size.x, fposmod(sin(i * 12.9898 + 2) * 43758.5453, 1) * size.y)
		var height: float = 5 + (i % 3) * 3
		var crystal := PackedVector2Array([point + Vector2(0, -height), point + Vector2(4, -2), point + Vector2(0, 3), point + Vector2(-4, -2), point + Vector2(0, -height)])
		draw_colored_polygon(crystal, UI.RAISED)
		draw_polyline(crystal, Color(UI.CRYSTAL, 0.5), 1)
	for pair in [["clearing", "thicket"], ["clearing", "spring"], ["thicket", "boss"], ["spring", "boss"]]:
		if not nodes.has(pair[0]) or not nodes.has(pair[1]): continue
		var a: Vector2 = nodes[pair[0]].get_global_rect().get_center() - global_position
		var b: Vector2 = nodes[pair[1]].get_global_rect().get_center() - global_position
		# Layout may not yet have assigned distinct centers during a rebuild.
		if a.distance_squared_to(b) < 1.0: continue
		var curve := Curve2D.new()
		curve.add_point(a, Vector2.ZERO, Vector2((b.x - a.x) * 0.4, 0))
		curve.add_point(b, Vector2((a.x - b.x) * 0.4, 0), Vector2.ZERO)
		var path: PackedVector2Array = curve.tessellate()
		draw_polyline(path, Color("283654"), 14)
		draw_polyline(path, UI.BORDER, 2)
		for j in range(1, 12):
			var position: Vector2 = curve.sample_baked(curve.get_baked_length() * j / 12.0)
			draw_rect(Rect2(position - Vector2.ONE * 2, Vector2.ONE * 4), UI.GOLD if selected in pair else UI.MUTED)
