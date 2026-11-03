extends Resource
## Full form variant. Compatibility accessors also support isolated authoring/test fixtures.
const Identity = preload("res://scripts/catalog/power_identity.gd")
const Effect = preload("res://scripts/catalog/effect_definition.gd")
const BURN: Resource = preload("res://content/statuses/burn.tres")
@export var identity: Identity = Identity.new()
@export var cost: int = 1
@export var effects: Array[Effect] = []
@export var signature: bool = false
var power_id: String:
	get: return identity.power_id
	set(value): identity.power_id = value
var name: String:
	get: return identity.name
	set(value): identity.name = value
var art_path: String:
	get: return identity.art_path
	set(value): identity.art_path = value
var action_id: String:
	get: return identity.action_id
	set(value): identity.action_id = value
var damage: int:
	get: return amount_for("damage")
	set(value): set_amount("damage", value)
var block: int:
	get: return amount_for("block")
	set(value): set_amount("block", value)
var heal: int:
	get: return amount_for("heal")
	set(value): set_amount("heal", value)
var burn: int:
	get: return amount_for("status")
	set(value): set_amount("status", value)

func amount_for(operation: String) -> int:
	var total: int = 0
	for effect in effects:
		if effect == null: continue
		if effect.operation == operation and effect.condition == "always" and (operation != "status" or (effect.status != null and effect.status.status_id == "burn")): total += effect.amount
	return total

func set_amount(operation: String, value: int) -> void:
	for effect in effects:
		if effect == null: continue
		if effect.operation == operation and effect.condition == "always":
			effect.amount = value
			return
	var effect = Effect.new()
	effect.operation = operation
	effect.target = "player" if operation in ["block", "heal", "draw"] else "enemy"
	effect.amount = value
	if operation == "status": effect.status = BURN
	effects.append(effect)
