extends RefCounted
## Ordered, sparse reaction rules. Selection is pure; the rules facade applies effects.
const DEFINITIONS = [
	{"id": "conduction", "name": "Condução", "condition": "wet", "nature": "lightning", "multiplier": 2.0, "consume": false},
	{"id": "sprouting", "name": "Brotação", "condition": "seed", "nature": "forest", "block": 6, "consume": true},
	{"id": "bloom", "name": "Floração", "condition": "seed", "nature": "water", "heal": 8, "consume": true},
	{"id": "wildfire", "name": "Incêndio", "condition": "seed", "nature": "fire", "burn": 4, "consume": true},
]

static func choose(power: Dictionary, target: Dictionary) -> Dictionary:
	if int(power.get("damage", 0)) <= 0: return {}
	for reaction in DEFINITIONS:
		if str(power.get("nature", "")) == reaction.nature and int(target.get("statuses", {}).get(reaction.condition, 0)) > 0:
			return reaction.duplicate(true)
	return {}
