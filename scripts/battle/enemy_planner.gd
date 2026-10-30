extends RefCounted
## Plans once at round start, against current bodies only. Never reads player selections.

static func build(enemies: Array, party: Array, round_number: int, rng: RandomNumberGenerator) -> Array:
	var plan: Array = []
	var living: Array = party.filter(func(unit: Dictionary) -> bool: return int(unit.get("slot", -1)) >= 0 and int(unit.hp) > 0)
	for opponent in enemies:
		if int(opponent.hp) <= 0: continue
		var pattern: Array = opponent.get("pattern", opponent.get("intents", []))
		var entry: Dictionary = {"category": "attack", "damage": 5, "block": 0, "heal": 0, "wet": 0, "scope": "single", "priority": 0}
		if not pattern.is_empty():
			var intent: Variant = pattern[(round_number - 1) % pattern.size()]
			if intent is Dictionary: entry.merge(intent, true)
			else: entry.damage = int(intent)
		entry.actor_uid = int(opponent.uid)
		entry.actor_slot = int(opponent.slot)
		entry.power = str(entry.get("power", "enemy_" + str(entry.category)))
		if not entry.has("target_slot"):
			var candidates: Array = living
			if entry.get("target_policy", "random") == "weakest" and not living.is_empty():
				var lowest_hp: int = 2147483647
				for unit in living: lowest_hp = mini(lowest_hp, int(unit.hp))
				candidates = living.filter(func(unit: Dictionary) -> bool: return int(unit.hp) == lowest_hp)
			entry.target_slot = int(candidates[rng.randi_range(0, candidates.size() - 1)].slot) if not candidates.is_empty() else 1
		entry.priority = int(entry.get("priority", 1 if entry.category == "defend" else 0))
		plan.append(entry)
	return plan
