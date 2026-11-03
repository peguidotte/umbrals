extends Resource
## Additive once per active equipped UID, after power passives/traits, before link/status tick.
@export_enum("after_traits") var phase: String = "after_traits"
@export_enum("damage", "block", "heal") var operation: String = "damage"
@export var amount: int = 0
@export_enum("damage", "block", "heal") var requires_operation: String = "damage"
