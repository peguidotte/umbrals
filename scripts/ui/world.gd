class_name UmbralWorld
extends Control
## Only scenery animates here. No gameplay state is polled or mutated.
const Paths = preload("res://scripts/assets/binding_paths.gd")
const BACKGROUND = preload(Paths.WORLD_MOONLIT_CLEARING)
const BATTLE_BACKGROUND_PATH = Paths.WORLD_BATTLE_CLEARING_DEPTH
var battle_background: Texture2D
var battle_bottom_inset: float = 254.0
var clock: float = 0.0
var still: bool = false
var title_mode: bool = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	if ResourceLoader.exists(BATTLE_BACKGROUND_PATH):
		battle_background = load(BATTLE_BACKGROUND_PATH)

func _process(delta: float) -> void:
	if still: return
	clock += delta
	queue_redraw()

func _draw() -> void:
	var scenery: Texture2D = battle_background if not title_mode and is_instance_valid(battle_background) else BACKGROUND
	var field: Rect2 = Rect2(Vector2.ZERO, size if title_mode else Vector2(size.x, maxf(1, size.y - battle_bottom_inset)))
	if title_mode:
		var factor: float = maxf(field.size.x / scenery.get_width(), field.size.y / scenery.get_height())
		var source_size: Vector2 = field.size / factor
		var source_origin: Vector2 = (scenery.get_size() - source_size) * 0.5
		draw_texture_rect_region(scenery, field, Rect2(source_origin, source_size))
	else:
		# A width-based cover zoom lifts the shore under the upper actors on ultrawide.
		# Fit height instead: narrow windows crop sides, wide windows extend the edges.
		# Trim a little empty sky while keeping the moon; all six supports stay on land.
		var sky_trim: float = scenery.get_height() * 0.04
		var source: Rect2 = Rect2(0, sky_trim, scenery.get_width(), scenery.get_height() - sky_trim)
		var width: float = scenery.get_width() * field.size.y / source.size.y
		var left: float = (field.size.x - width) * 0.5
		var image_rect: Rect2 = Rect2(0, 0, width, field.size.y)
		if left > 0:
			draw_set_transform(Vector2(left, 0), 0, Vector2(-1, 1))
			draw_texture_rect_region(scenery, image_rect, source)
			draw_set_transform(Vector2(left + width * 2, 0), 0, Vector2(-1, 1))
			draw_texture_rect_region(scenery, image_rect, source)
			draw_set_transform(Vector2.ZERO)
		draw_texture_rect_region(scenery, Rect2(left, 0, width, field.size.y), source)
	draw_rect(field, Color(0.018, 0.038, 0.05, 0.05 if not title_mode else 0.10))
	if title_mode:
		for i in range(10):
			var y: float = size.y * (0.72 + i * 0.028)
			draw_rect(Rect2(0, y, size.x, size.y * 0.03), Color(0.015, 0.03, 0.045, i * 0.035))
		for i in range(12):
			draw_rect(Rect2(size.x * i / 24.0, 0, size.x / 24.0 + 1, size.y), Color(0.015, 0.03, 0.04, 0.68 - i * 0.035))
	for i in range(22):
		var x: float = size.x * fposmod(i * 0.173 + 0.05, 1) + sin(clock * 0.23 + i) * 12
		var y: float = size.y * (0.18 + fposmod(i * 0.13, 0.5)) + sin(clock * 0.33 + i * 0.7) * 7
		var opacity: float = 0.25 + 0.22 * sin(clock * 0.6 + i)
		draw_circle(Vector2(x, y), 6, Color(0.94, 0.81, 0.48, opacity * 0.10))
		draw_circle(Vector2(x, y), 1.7, Color(0.98, 0.87, 0.57, opacity))
