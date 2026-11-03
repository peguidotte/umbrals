extends Resource
const Power = preload("res://scripts/catalog/power_definition.gd")
const Evolution = preload("res://scripts/catalog/evolution_definition.gd")
const Presentation = preload("res://scripts/catalog/presentation_definition.gd")
@export var form_id: String
@export var display_name: String
@export_multiline var description: String
@export var trait_strength: int = 0
@export var copies_per_power: int = 2
@export var powers: Array[Power] = []
@export var evolutions: Array[Evolution] = []
@export var presentation: Presentation

func power(id: String) -> Power:
	for item in powers:
		if item.power_id == id: return item
	return null

func transition(id: String) -> Evolution:
	for item in evolutions:
		if item.transition_id == id: return item
	return null
