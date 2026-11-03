extends Resource
const Effect = preload("res://scripts/catalog/effect_definition.gd")
@export var action_id: String
@export var display_name: String = "Ataque"
@export var effects: Array[Effect] = []
