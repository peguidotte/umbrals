extends RefCounted
## Validated individual snapshot; catalog membership is checked by the caller.
const Card = preload("res://scripts/domain/models/card_instance.gd")

var uid: int:
	get: return _data.get("uid", 0)
var species: String:
	get: return _data.get("species", "")
var passive: String:
	get: return _data.get("passive", "")
var form_id: String:
	get: return _data.get("form_id", "")
var slot: int:
	get: return _data.get("slot", 0)
var hp: int:
	get: return _data.get("hp", 0)
var max_hp: int:
	get: return _data.get("max_hp", 0)
var attack: int:
	get: return _data.get("attack", 0)
var defense: int:
	get: return _data.get("defense", 0)
var speed: int:
	get: return _data.get("speed", 0)
var block: int:
	get: return _data.get("block", 0)
var can_act_round: int:
	get: return _data.get("can_act_round", 0)
var statuses: Dictionary:
	get: return _data.get("statuses", {}).duplicate(true)
var status_sources: Dictionary:
	get: return _data.get("status_sources", {}).duplicate(true)
var known_powers: Array:
	get: return _data.get("known_powers", []).duplicate(true)
var cards: Array:
	get: return _data.get("cards", []).duplicate(true)
var _data: Dictionary

static func try_from_dict(input: Variant) -> Dictionary:
	if not input is Dictionary: return {"ok": false, "error": "individual must be a dictionary"}
	for key in ["uid", "slot", "hp", "max_hp", "attack", "defense", "speed", "block", "can_act_round"]:
		if not input.get(key) is int: return {"ok": false, "error": "invalid " + key}
	for key in ["species", "passive", "form_id"]:
		if not input.get(key) is String or (key != "passive" and input[key].is_empty()): return {"ok": false, "error": "invalid " + key}
	if input.uid < 1 or input.slot < -1 or input.slot > 2 or input.max_hp < 1 or input.hp < 0 or input.hp > input.max_hp: return {"ok": false, "error": "invalid individual bounds"}
	if input.attack < 0 or input.defense < 0 or input.speed < 0 or input.block < 0 or input.can_act_round < 1: return {"ok": false, "error": "invalid individual stats"}
	if not input.get("statuses") is Dictionary or not input.get("status_sources") is Dictionary or not input.get("known_powers") is Array or not input.get("cards") is Array: return {"ok": false, "error": "invalid individual collections"}
	for power in input.known_powers:
		if not power is String or power.is_empty(): return {"ok": false, "error": "invalid known power"}
	var ids: Dictionary = {}
	for card in input.cards:
		var parsed: Dictionary = Card.try_from_dict(card)
		if not parsed.ok: return {"ok": false, "error": "invalid owned card"}
		if parsed.value.owner != input.uid or ids.has(parsed.value.instance_id): return {"ok": false, "error": "invalid owned card identity"}
		ids[parsed.value.instance_id] = true
	var value = new()
	value._data = input.duplicate(true)
	return {"ok": true, "value": value}

func to_dict() -> Dictionary:
	return _data.duplicate(true)
