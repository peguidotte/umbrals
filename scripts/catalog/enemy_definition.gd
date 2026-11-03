extends Resource
const Action = preload("res://scripts/catalog/enemy_action.gd")
@export var enemy_id: String
@export var name: String
@export var hp: int = 1
@export_file("*.svg", "*.png") var art_path: String
@export var actions: Array[Action] = []
