extends Resource
## Ordered pool; guarantee is used only until this species joins the party.
@export var table_id: String
@export var guaranteed_missing_species: String = ""
@export var capture_pool: PackedStringArray = []
@export var heal: int = 8
