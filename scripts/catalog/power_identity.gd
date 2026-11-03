extends Resource
## Species-wide identity; forms author only their explicit numerical variants.
@export var power_id: String
@export var name: String
@export_multiline var description: String
@export_file("*.svg", "*.png") var art_path: String
@export_enum("attack_ranged", "attack_melee", "defend", "heal") var action_id: String = "attack_ranged"
