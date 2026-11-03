extends Resource
const Enemy = preload("res://scripts/catalog/enemy_definition.gd")
const EnvironmentDefinition = preload("res://scripts/catalog/environment_definition.gd")
const Rewards = preload("res://scripts/catalog/reward_table.gd")
@export var encounter_id: String
@export var subtitle: String
@export var enemy: Enemy
@export var environment: EnvironmentDefinition
@export var rewards: Rewards
# Read-only presentation compatibility; gameplay uses enemy.actions.
var name: String:
	get: return enemy.name
var hp: int:
	get: return enemy.hp
var art: String:
	get: return enemy.enemy_id
var intents: Array[int]:
	get:
		var values: Array[int] = []
		for action in enemy.actions:
			var total: int = 0
			for effect in action.effects:
				if effect.operation == "damage" and effect.target == "player": total += effect.amount
			values.append(total)
		return values
