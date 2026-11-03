extends RefCounted
## A validated initiative entry. Optional payloads retain the existing DTO schema.
const Card = preload("res://scripts/domain/models/card_instance.gd")

var kind: String:
	get: return _data.get("kind", "")
var side: String:
	get: return _data.get("side", "")
var actor_uid: int:
	get: return _data.get("actor_uid", 0)
var actor_slot: int:
	get: return _data.get("actor_slot", 0)
var priority: int:
	get: return _data.get("priority", 0)
var speed: int:
	get: return _data.get("speed", 0)
var key: String:
	get: return _data.get("key", "")
var card: Dictionary:
	get: return _data.get("card", {}).duplicate(true)
var swap: Dictionary:
	get: return _data.get("swap", {}).duplicate(true)
var order: Dictionary:
	get: return _data.get("order", {}).duplicate(true)
var intent: Dictionary:
	get: return _data.get("intent", {}).duplicate(true)
var _data: Dictionary

static func try_from_dict(input: Variant) -> Dictionary:
	if not input is Dictionary: return {"ok": false, "error": "command must be a dictionary"}
	if not input.get("kind") is String or not input.kind in ["power", "swap", "item", "enemy"]: return {"ok": false, "error": "invalid command kind"}
	if not input.get("side") is String or input.side != ("enemy" if input.kind == "enemy" else "ally"): return {"ok": false, "error": "invalid command side"}
	for field in ["actor_uid", "actor_slot", "priority", "speed"]:
		if not input.get(field) is int: return {"ok": false, "error": "invalid " + field}
	if not input.get("key") is String or input.key.is_empty(): return {"ok": false, "error": "invalid key"}
	if input.actor_slot < -1 or input.actor_slot > 2: return {"ok": false, "error": "invalid actor slot"}
	if input.kind == "item":
		if input.actor_uid != -1 or input.actor_slot != -1 or not input.get("order") is Dictionary or (not input.get("item_index") is int or input.item_index < 0): return {"ok": false, "error": "invalid item command"}
	elif input.actor_uid < 1 and not (input.kind == "swap" and input.actor_uid == -1):
		return {"ok": false, "error": "invalid actor"}
	if input.kind == "power":
		var card: Dictionary = Card.try_from_dict(input.get("card"))
		if not card.ok or card.value.owner != input.actor_uid: return {"ok": false, "error": "invalid command card"}
	if input.kind == "swap" and not _valid_swap(input.get("swap"), input.actor_uid, input.actor_slot): return {"ok": false, "error": "invalid swap"}
	if input.kind == "item" and not _valid_item(input.order): return {"ok": false, "error": "invalid item order"}
	if input.kind == "enemy" and not _valid_intent(input.get("intent"), input.actor_uid, input.actor_slot): return {"ok": false, "error": "invalid intent"}
	for field in ["tie", "execution_order"]:
		if input.has(field) and not input[field] is int: return {"ok": false, "error": "invalid " + field}
	var value = new()
	value._data = input.duplicate(true)
	return {"ok": true, "value": value}

func to_dict() -> Dictionary:
	return _data.duplicate(true)

static func _valid_swap(payload: Variant, actor_uid: int, actor_slot: int) -> bool:
	if not payload is Dictionary: return false
	for field in ["slot", "out_uid", "in_uid"]:
		if not payload.get(field) is int: return false
	return payload.slot >= 0 and payload.slot <= 2 and payload.slot == actor_slot and payload.out_uid == actor_uid and (payload.out_uid == -1 or payload.out_uid > 0) and payload.in_uid > 0 and payload.in_uid != payload.out_uid

static func _valid_item(payload: Variant) -> bool:
	return payload is Dictionary and payload.get("item") is String and not payload.item.is_empty() and payload.get("uid") is int and payload.uid > 0

static func _valid_intent(payload: Variant, actor_uid: int, actor_slot: int) -> bool:
	if not payload is Dictionary: return false
	for field in ["actor_uid", "actor_slot", "target_slot", "damage", "block", "heal", "wet", "priority"]:
		if not payload.get(field) is int: return false
	if payload.actor_uid != actor_uid or payload.actor_slot != actor_slot or actor_slot < 0 or payload.target_slot < 0 or payload.target_slot > 2: return false
	for field in ["damage", "block", "heal", "wet"]:
		if payload[field] < 0: return false
	if not payload.get("category") is String or not payload.category in ["attack", "defend", "support", "prepare"]: return false
	if not payload.get("power") is String or payload.power.is_empty(): return false
	if not payload.get("scope") is String or not payload.scope in ["single", "upper_pair", "lower_pair", "all"]: return false
	for field in ["charge", "burn"]:
		if payload.has(field) and (not payload[field] is int or payload[field] < 0): return false
	if payload.has("conditions"):
		if not payload.conditions is Dictionary: return false
		for condition in payload.conditions:
			if not condition is String or not payload.conditions[condition] is int or payload.conditions[condition] < 0: return false
	return true
