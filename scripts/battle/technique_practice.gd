extends RefCounted
## Experimental between-encounter practice. Pure queries; one physical copy changes.
const Content = preload("res://scripts/content.gd")
const MIN_COPIES = 1
const MAX_COPIES = 3

static func counts(individual: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for power in individual.known_powers: result[power] = 0
	for card in individual.cards:
		if result.has(card.power): result[card.power] += 1
	return result

static func options(party: Array) -> Array:
	var result: Array = []
	for individual in party:
		if int(individual.hp) <= 0: continue
		var copies: Dictionary = counts(individual)
		var donors: Array = copies.keys().filter(func(power): return copies[power] > MIN_COPIES)
		var receivers: Array = copies.keys().filter(func(power): return copies[power] < MAX_COPIES)
		if donors.any(func(power): return receivers.any(func(other): return power != other)):
			result.append({"uid": individual.uid, "counts": copies, "donors": donors, "receivers": receivers})
	return result

static func valid(party: Array, choice: Dictionary) -> bool:
	if choice.size() != 3 or not choice.get("uid") is int or not choice.get("from_power") is String or not choice.get("to_power") is String: return false
	if choice.from_power == choice.to_power: return false
	if not Content.POWERS.has(choice.from_power) or not Content.POWERS.has(choice.to_power): return false
	for option in options(party):
		if option.uid == choice.uid: return choice.from_power in option.donors and choice.to_power in option.receivers
	return false

static func apply(party: Array, choice: Dictionary) -> bool:
	if not valid(party, choice): return false
	for individual in party:
		if individual.uid != choice.uid: continue
		var donors: Array = individual.cards.filter(func(card): return card.power == choice.from_power)
		donors.sort_custom(func(a, b): return str(a.instance_id) < str(b.instance_id))
		# Identity is opaque, never reconstructed from the new power or a copy index.
		donors[0].power = choice.to_power
		return true
	return false
