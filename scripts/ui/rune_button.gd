class_name UmbralRuneButton
extends Button
## Focus is signalled by shape and outline as well as color.
var accent: Color = Color("dec88d")

func _ready() -> void:
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func _draw() -> void:
	var color: Color = accent if not disabled else Color("65726b")
	var middle: float = size.y * 0.5
	var x: float = 13.0
	if has_focus() or is_hovered():
		draw_colored_polygon(PackedVector2Array([Vector2(x, middle - 5), Vector2(x + 5, middle), Vector2(x, middle + 5), Vector2(x - 5, middle)]), color)
	for side in [-1, 1]:
		var edge: float = 3 if side == -1 else size.x - 3
		draw_line(Vector2(edge, 9), Vector2(edge, size.y - 9), Color(color, 0.65), 1)

