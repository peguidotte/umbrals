class_name UmbralWorld
extends Control
## Only scenery animates here. No gameplay state is polled or mutated.
const BACKGROUND = preload("res://assets/world/clearing.png")
var clock: float = 0.0
var still: bool = false
var title_mode: bool = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

func _process(delta: float) -> void:
	if still: return
	clock += delta
	queue_redraw()

func _draw() -> void:
	var ratio: float = BACKGROUND.get_width() / float(BACKGROUND.get_height())
	var coverage: Vector2 = Vector2(size.x, size.x / ratio) if size.x / maxf(1, size.y) > ratio else Vector2(size.y * ratio, size.y)
	draw_texture_rect(BACKGROUND, Rect2((size - coverage) * 0.5, coverage), false)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.018, 0.038, 0.05, 0.10))
	for i in range(18):
		var y: float = size.y * (0.55 + i * 0.025)
		draw_rect(Rect2(0, y, size.x, size.y * 0.026), Color(0.015, 0.03, 0.045, i * 0.033))
	if title_mode:
		for i in range(12):
			draw_rect(Rect2(size.x * i / 24.0, 0, size.x / 24.0 + 1, size.y), Color(0.015, 0.03, 0.04, 0.68 - i * 0.035))
	else:
		var shade_height: float = minf(130, size.y * 0.14)
		for i in range(12):
			draw_rect(Rect2(0, i * shade_height / 12, size.x, shade_height / 12 + 1), Color(0.015, 0.03, 0.04, 0.48 * (1 - i / 12.0)))
	for i in range(22):
		var x: float = size.x * fposmod(i * 0.173 + 0.05, 1) + sin(clock * 0.23 + i) * 12
		var y: float = size.y * (0.18 + fposmod(i * 0.13, 0.5)) + sin(clock * 0.33 + i * 0.7) * 7
		var opacity: float = 0.25 + 0.22 * sin(clock * 0.6 + i)
		draw_circle(Vector2(x, y), 6, Color(0.94, 0.81, 0.48, opacity * 0.10))
		draw_circle(Vector2(x, y), 1.7, Color(0.98, 0.87, 0.57, opacity))
