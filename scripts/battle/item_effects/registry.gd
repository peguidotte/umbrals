extends RefCounted
## Pure item effects; registry entries make unsupported behaviors fail closed.

const PARAMETER_SCHEMAS = {"heal": {"heal": {"type": "integer", "min_exclusive": 0}}, "revive": {"revive_ratio": {"type": "number", "min_exclusive": 0, "max_inclusive": 1}}}
const HANDLERS = {"heal": preload("res://scripts/battle/item_effects/heal.gd"), "revive": preload("res://scripts/battle/item_effects/revive.gd")}

static func reason(effect_id: String, target: Dictionary) -> String:
	if not HANDLERS.has(effect_id): return "Item indisponível"
	return HANDLERS[effect_id].reason(target)

static func resolve(effect_id: String, target: Dictionary, definition: Dictionary) -> Dictionary:
	if not HANDLERS.has(effect_id): return {"valid": false}
	return HANDLERS[effect_id].resolve(target, definition)
