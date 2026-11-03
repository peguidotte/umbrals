extends RefCounted

static func reason(target: Dictionary) -> String:
	return "Requer um Umbral incapacitado" if int(target.hp) > 0 else ""

static func resolve(target: Dictionary, definition: Dictionary) -> Dictionary:
	if not reason(target).is_empty(): return {"valid": false}
	var hp: int = maxi(1, ceili(float(target.max_hp) * float(definition.revive_ratio)))
	return {"valid": true, "new_hp": hp, "event_kind": "revive", "event_power": "revive", "amount": hp, "revived": true}
