extends Node2D
## Only this node receives the hair material; house, floor and Brasa do not.
var presenter: Node2D
func _draw() -> void:
	if is_instance_valid(presenter):
		presenter.pilot.draw(self,Vector2.ZERO,presenter.gather<=0,presenter.facing.x)
