extends Resource
## Duration -1 lasts while stacks remain. Tick happens after cast, before retaliation.
@export var status_id: String
@export var display_name: String
@export_enum("damage", "heal") var tick_operation: String = "damage"
@export var per_stack: int = 1
@export var duration: int = -1
@export var decay: int = 0
@export_enum("add", "max", "replace") var stacking: String = "add"
@export var max_stacks: int = 999
@export_enum("after_cast", "after_retaliation") var timing: String = "after_cast"
