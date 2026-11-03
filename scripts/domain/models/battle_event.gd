extends RefCounted
## Event snapshot detached from mutable battle state.
var kind: String:
	get: return _data.get("kind", "")
var actor_uid: int:
	get: return _data.get("actor_uid", 0)
var actor_side: String:
	get: return _data.get("actor_side", "")
var actor_slot: int:
	get: return _data.get("actor_slot", 0)
var target_uid: int:
	get: return _data.get("target_uid", 0)
var target_side: String:
	get: return _data.get("target_side", "")
var target_slot: int:
	get: return _data.get("target_slot", -1)
var power: String:
	get: return _data.get("power", "")
var amount: int:
	get: return _data.get("amount", 0)
var target_state: Dictionary:
	get: return _data.get("target_state", {}).duplicate(true)
var actor_name: String:
	get: return _data.get("actor_name", "")
var target_name: String:
	get: return _data.get("target_name", "")
var _data: Dictionary

static func try_from_dict(input: Variant) -> Dictionary:
	if not input is Dictionary: return {"ok": false, "error": "event must be a dictionary"}
	for field in ["kind", "actor_side", "target_side", "power", "actor_name", "target_name"]:
		if not input.get(field) is String: return {"ok": false, "error": "invalid " + field}
	if input.kind.is_empty() or not input.actor_side in ["ally", "enemy"] or not input.target_side in ["ally", "enemy"]: return {"ok": false, "error": "invalid event identity"}
	for field in ["actor_uid", "actor_slot", "target_uid", "target_slot", "amount"]:
		if not input.get(field) is int: return {"ok": false, "error": "invalid " + field}
	if input.actor_uid < -1 or input.target_uid < -1 or input.actor_slot < -1 or input.actor_slot > 2 or input.target_slot < -1 or input.target_slot > 2: return {"ok": false, "error": "invalid event location"}
	if not input.get("target_state") is Dictionary: return {"ok": false, "error": "invalid target state"}
	var value = new()
	value._data = input.duplicate(true)
	return {"ok": true, "value": value}

func to_dict() -> Dictionary:
	return _data.duplicate(true)
