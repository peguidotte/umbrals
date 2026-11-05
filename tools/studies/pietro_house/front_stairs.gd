extends Node2D
const Stairs = preload("res://scripts/ui/house_stairs.gd")
var presenter: Node2D
func _draw() -> void:
	if is_instance_valid(presenter) and presenter.candidate and presenter.on_stairs:
		Stairs.draw_layer(self,true)
