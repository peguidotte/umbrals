extends Node2D
const Art = preload("res://scripts/ui/refuge_art.gd")
const Space = preload("res://scripts/ui/refuge_space.gd")
var point: Vector2 = Space.SPAWN
var facing: Vector2 = Vector2.DOWN
var stride: float = 0
var nearby: String = ""

func _draw() -> void:
	Art.background(self)
	for key in Space.STATIONS:
		var center: Vector2 = Space.STATIONS[key]
		draw_arc(center, 24, 0, TAU, 32, Art.GOLD if key == nearby else Color("738a7b"), 3 if key == nearby else 1)
		draw_circle(center, 3, Art.GOLD)
	Art.avatar(self, point, facing, stride)
