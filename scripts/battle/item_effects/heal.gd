extends RefCounted

static func reason(target: Dictionary) -> String:
	if int(target.hp) <= 0 or int(target.hp) >= int(target.max_hp): return "Requer um Umbral ferido e apto"
	return ""

static func resolve(target: Dictionary, definition: Dictionary) -> Dictionary:
	if int(target.hp) <= 0: return {"valid": false}
	var amount: int = mini(int(definition.heal), int(target.max_hp) - int(target.hp))
	return {"valid": true, "new_hp": int(target.hp) + amount, "event_kind": "heal", "event_power": "potion", "amount": amount, "revived": false}
