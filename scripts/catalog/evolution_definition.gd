extends Resource
## Outgoing transition; its target must be a form of the same species.
@export var transition_id: String
@export var target_form_id: String
@export var min_encounter: int = 0
@export var health_cost: int = 0
@export var required_passive: String = ""

func eligible(encounter: int, health: int, passive: String) -> bool:
	return encounter >= min_encounter and health > health_cost and (required_passive.is_empty() or passive == required_passive)
