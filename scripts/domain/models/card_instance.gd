extends RefCounted
## Validated value at a dictionary boundary. The live Rules dictionary remains authoritative.

var instance_id: String:
	get: return _data.get("instance_id", "")
var owner: int:
	get: return _data.get("owner", 0)
var power: String:
	get: return _data.get("power", "")
var target_slot: int:
	get: return _data.get("target_slot", -1)
var _data: Dictionary

static func try_from_dict(input: Variant) -> Dictionary:
	if not input is Dictionary: return {"ok": false, "error": "card must be a dictionary"}
	if not input.get("instance_id") is String or input.instance_id.is_empty(): return {"ok": false, "error": "invalid instance_id"}
	if not input.get("owner") is int or input.owner < 1: return {"ok": false, "error": "invalid owner"}
	if not input.get("power") is String or input.power.is_empty(): return {"ok": false, "error": "invalid power"}
	if input.has("target_slot") and (not input.target_slot is int or input.target_slot < 0 or input.target_slot > 2): return {"ok": false, "error": "invalid target_slot"}
	var value = new()
	value._data = input.duplicate(true)
	return {"ok": true, "value": value}

func to_dict() -> Dictionary:
	return _data.duplicate(true)
