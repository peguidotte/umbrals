extends Resource
const Effect = preload("res://scripts/catalog/effect_definition.gd")
const Modifier = preload("res://scripts/catalog/modifier_definition.gd")
@export var item_id: String
@export var display_name: String
@export_multiline var description: String
@export_enum("consumable", "relic") var kind: String = "consumable"
@export var starting_quantity: int = 1
@export var effects: Array[Effect] = []
@export var modifiers: Array[Modifier] = []
