extends RefCounted
## Reward destination and card collection operations over explicit roster data.
const Targeting = preload("res://scripts/battle/targeting.gd")

static func by_uid(roster: Array, uid: int) -> Dictionary:
	for individual in roster:
		if int(individual.uid) == uid: return individual
	return {}

static func active_party(party: Array) -> Array:
	var active: Array = []
	for individual in party:
		if int(individual.get("slot", -1)) >= 0: active.append(individual)
	active.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.slot) < int(b.slot))
	return active

static func capture_destinations(offer_index: int, replace_uid: int, phase: String, reward_offers: Array, party: Array) -> Array[int]:
	var result: Array[int] = []
	if phase != "reward" or offer_index < 0 or offer_index >= reward_offers.size() or reward_offers[offer_index].kind != "capture": return result
	if party.size() < 6 and replace_uid != -1: return result
	if party.size() >= 6 and by_uid(party, replace_uid).is_empty(): return result
	# Never leave a new encounter with no field body that can act or be replaced.
	for individual in active_party(party):
		if int(individual.uid) != replace_uid:
			result.append(-1)
			break
	for slot in range(3):
		var occupant: Dictionary = Targeting.at_slot(party, slot)
		if occupant.is_empty() or int(occupant.uid) == replace_uid: result.append(slot)
	return result

static func persist_card_collection(party: Array, hand: Array, deck: Array, discard_pile: Array, suspended_cards: Dictionary) -> void:
	# Zones, rather than species defaults, own the current edited deck. Learning,
	# thinning and evolving preserve precisely these physical card instances.
	var cards: Array = hand + deck + discard_pile
	for suspended in suspended_cards.values(): cards.append_array(suspended.deck + suspended.discard)
	for individual in party:
		var owned: Array = []
		var seen: Dictionary = {}
		for card in cards:
			if int(card.owner) == int(individual.uid) and not seen.has(card.instance_id):
				var instance: Dictionary = card.duplicate(true)
				instance.erase("target_slot")
				owned.append(instance)
				seen[card.instance_id] = true
		individual.cards = owned

