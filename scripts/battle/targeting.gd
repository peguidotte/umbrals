extends RefCounted
## Shared slot semantics for validation, resolution and selectors. No scene or RNG access.
const SLOT_NAMES = ["superior", "central", "inferior"]
const SCOPE_NAMES = {"single": "Individual", "upper_pair": "Superior + centro", "lower_pair": "Centro + inferior", "all": "Todos"}

static func slots(scope: String, target_slot: int) -> Array:
	match scope:
		"upper_pair": return [0, 1]
		"lower_pair": return [1, 2]
		"all": return [0, 1, 2]
	return [target_slot] if target_slot in [0, 1, 2] else []

static func at_slot(roster: Array, slot: int) -> Dictionary:
	for individual in roster:
		if int(individual.get("slot", -1)) == slot: return individual
	return {}

static func options(power: Dictionary, owner: Dictionary, allies: Array, enemies: Array) -> Array[int]:
	var result: Array[int] = []
	var roster: Array = enemies if power.get("target", "enemy") == "enemy" else allies
	var scope: String = str(power.get("scope", "single"))
	for slot in range(3):
		if power.get("target", "enemy") == "self" and slot != int(owner.get("slot", -1)): continue
		var individual: Dictionary = at_slot(roster, slot)
		if not individual.is_empty() and int(individual.get("hp", 0)) > 0 and slot in slots(scope, slot): result.append(slot)
	return result
