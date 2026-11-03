extends Resource
const Form = preload("res://scripts/catalog/form_definition.gd")
@export var species_id: String
@export_multiline var description: String
@export var element: String
@export var color: Color = Color.WHITE
@export var initial_form_id: String
@export var passive_pool: PackedStringArray = []
@export var trait_id: String
@export var trait_name: String
@export var trait_description: String
@export var trait_script: Script
@export var forms: Array[Form] = []
@export var ready_for_play: bool = false

func form(id: String) -> Form:
	for item in forms:
		if item.form_id == id: return item
	return null
