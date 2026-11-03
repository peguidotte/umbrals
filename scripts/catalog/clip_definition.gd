extends Resource
## A declared clip may use authored frames or an explicit procedural pose.
const ACTIONS = ["idle", "move", "attack_melee", "attack_ranged", "defend", "heal", "hurt", "defeat"]
@export var action_id: String
@export_enum("procedural", "frames") var mode: String = "procedural"
@export var frames: PackedStringArray = []
@export var duration: float = 0.3
@export var loop: bool = false
@export var pose_scale: Vector2 = Vector2.ONE
@export var pose_offset: Vector2 = Vector2.ZERO
@export var release_time: float = -1.0
@export var release_point: String = ""
