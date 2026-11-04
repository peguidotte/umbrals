extends RefCounted
## Public roster and intent projections; no plan mutation or RNG.
const Targeting = preload("res://scripts/battle/targeting.gd")
const Conditions = preload("res://scripts/battle/conditions.gd")

static func active_party(party: Array, only_able: bool = false) -> Array:
	var result: Array = []
	for individual in party:
		if int(individual.get("slot", -1)) >= 0 and (not only_able or int(individual.get("hp", 0)) > 0): result.append(individual)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.slot) < int(b.slot))
	return result

static func reserves(party: Array) -> Array:
	var result: Array = []
	for individual in party:
		if int(individual.get("slot", -1)) < 0 and int(individual.get("hp", 0)) > 0: result.append(individual)
	return result

static func by_uid(roster: Array, uid: int) -> Dictionary:
	for individual in roster:
		if int(individual.uid) == uid: return individual
	return {}

static func public_intents(enemy_plan: Array, enemies: Array, information_mode: String, mode: String = "") -> Array:
	var visibility: String = information_mode if mode.is_empty() else mode
	var result: Array = []
	for entry in enemy_plan:
		var projection: Dictionary = {"slot": int(entry.actor_slot), "category": "unknown" if visibility == "hidden" else str(entry.category)}
		if visibility == "full":
			for key in ["power", "scope", "target_slot", "damage", "block", "heal", "wet", "priority", "charge", "nature", "conditions"]:
				var value: Variant = entry.get(key, 0)
				projection[key] = value.duplicate(true) if value is Dictionary or value is Array else value
			var opponent: Dictionary = by_uid(enemies, int(entry.actor_uid))
			if int(entry.get("damage", 0)) > 0: projection.damage = floori(float(maxi(0, int(entry.damage) + int(opponent.get("attack", 10)) - 10) + int(opponent.statuses.get("charge", 0))) * Conditions.attack_multiplier(opponent))
		result.append(projection)
	return result


static func hand_capacity(party: Array, relics: Array, hand_size_modifier: int, base_capacity: int) -> int:
	var capacity: int = base_capacity + hand_size_modifier
	for relic in relics:
		if relic is Dictionary: capacity += int(relic.get("hand_modifier", 0))
	for individual in active_party(party, true): capacity += int(individual.get("hand_modifier", 0))
	return clampi(capacity, 1, 24)

static func action_budget(relics: Array, action_modifier: int, base_budget: int) -> int:
	var budget: int = base_budget + action_modifier
	for relic in relics:
		if relic is Dictionary: budget += int(relic.get("action_modifier", 0))
	return maxi(1, budget)


static func needs_replacement(party: Array, declined_replacements: Dictionary) -> bool:
	if reserves(party).is_empty(): return false
	if active_party(party, true).is_empty(): return true
	for individual in active_party(party):
		if int(individual.hp) <= 0 and not declined_replacements.has(int(individual.uid)): return true
	return false


static func compatibility(party: Array, enemies: Array) -> Dictionary:
	var max_hp: int = 0
	var player_hp: int = 0
	for individual in active_party(party):
		max_hp += int(individual.max_hp)
		player_hp += int(individual.hp)
	var enemy_hp: int = 0
	var enemy_burn: int = 0
	for opponent in enemies:
		enemy_hp += int(opponent.hp)
		enemy_burn += int(opponent.statuses.get("burn", 0))

	return {"max_hp": max_hp, "player_hp": player_hp, "enemy_hp": enemy_hp, "enemy_burn": enemy_burn}

static func first_living_slot(roster: Array, max_active: int) -> int:
	for slot in range(max_active):
		var individual: Dictionary = Targeting.at_slot(roster, slot)
		if not individual.is_empty() and int(individual.get("hp", 0)) > 0: return slot
	return 1


static func selected_cards(selected: Array[int], hand: Array) -> Array:
	var cards: Array = []
	for index in selected:
		if index >= 0 and index < hand.size(): cards.append(hand[index])
	return cards

