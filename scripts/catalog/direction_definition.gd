extends Resource
const Clip = preload("res://scripts/catalog/clip_definition.gd")
@export_file("*.svg", "*.png") var portrait_path: String
@export var mirror: bool = false
@export var anchors: Dictionary[String, Vector2] = {}
@export var clips: Array[Clip] = []

func clip(action: String) -> Clip:
	for item in clips:
		if item.action_id == action: return item
	return null
