extends Control
const UI = preload("res://scripts/ui/kit.gd")
const Actor = preload("res://scripts/ui/actor.gd")
var actor: Actor

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(actor) or actor.motion.definition == null: return
	var index: int = 0
	for id in actor.motion.definition.anchors:
		var point: Vector2 = get_global_transform().affine_inverse() * actor.emission_point(id)
		draw_circle(point, 5, UI.tokens.gold)
		var destination: Vector2 = actor.get_global_rect().position + Vector2(actor.size.x + 18, 22 + index * 28)
		destination = get_global_transform().affine_inverse() * destination
		draw_line(point, destination - Vector2(8, 6), Color(UI.tokens.gold, 0.6), 1, true)
		draw_string(UI.tokens.body, destination, id, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UI.tokens.paper)
		index += 1
