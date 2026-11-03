extends Resource
## Pure primitive request. Conditions read the start-of-cast state, never selection order.
const Status = preload("res://scripts/catalog/status_definition.gd")
@export_enum("damage", "block", "heal", "status", "draw") var operation: String = "damage"
@export_enum("enemy", "player") var target: String = "enemy"
@export var amount: int = 0
@export_enum("always", "target_burning", "target_wounded") var condition: String = "always"
@export var status: Status

func enabled(burning: bool, wounded: bool) -> bool:
	return condition == "always" or (condition == "target_burning" and burning) or (condition == "target_wounded" and wounded)
