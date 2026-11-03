extends Resource
const Direction = preload("res://scripts/catalog/direction_definition.gd")
@export var left: Direction
@export var right: Direction
@export var sound_id: String = "fire"
@export_multiline var authoring_notes: String

func direction(facing: String) -> Direction:
	return left if facing == "left" else right
