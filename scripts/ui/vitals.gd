class_name UmbralVitals
extends Control
const UI = preload("res://scripts/ui/kit.gd")
var current: int = 0
var maximum: int = 1
var predicted: int = -1
var displayed: float = 0.0
var caption: String = "FÔLEGO"
var tint: Color = UI.tokens.fire
var text_scale: float = 1.0
var motion: Tween

func update_health(value: int, limit: int, preview_value: int = -1, animate: bool = false) -> void:
	current = value
	maximum = maxi(1, limit)
	predicted = preview_value
	if is_instance_valid(motion): motion.kill()
	if animate:
		motion = create_tween()
		motion.tween_method(_set_display, displayed, float(current), UI.tokens.motion.health).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else: _set_display(float(current))
	queue_redraw()

func _set_display(value: float) -> void:
	displayed = value
	queue_redraw()

func _draw() -> void:
	var font_size: int = int(UI.tokens.vitals_value_size * text_scale)
	var label_size: int = int(UI.tokens.vitals_caption_size * text_scale)
	draw_string(UI.tokens.body, Vector2(4, 19), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, UI.tokens.muted)
	var value: String = "%d / %d" % [int(round(displayed)), maximum]
	draw_string(UI.tokens.display, Vector2(2, 53), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UI.tokens.paper)
	var bar: Rect2 = Rect2(1, 64, maxf(1, size.x - 2), 8)
	draw_rect(bar, UI.tokens.health_track)
	draw_rect(bar, Color(UI.tokens.gold, 0.5), false, 1)
	var ratio: float = clampf(displayed / maximum, 0, 1)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), tint)
	if predicted >= 0 and predicted < current:
		var start: float = bar.size.x * predicted / float(maximum)
		draw_rect(Rect2(bar.position + Vector2(start, 0), Vector2(bar.size.x * maxf(0, ratio - predicted / float(maximum)), bar.size.y)), Color(1, 0.91, 0.68, 0.52))
