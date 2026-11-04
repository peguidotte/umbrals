extends RefCounted
## Formation and replacement operations over the canonical roster.
const Targeting = preload("res://scripts/battle/targeting.gd")

static func by_uid(party: Array, uid: int) -> Dictionary:
	for individual in party:
		if int(individual.uid) == uid: return individual
	return {}

static func set_formation(uids_by_slot: Array, phase: String, expedition_mode: bool, party: Array, max_active: int) -> bool:
	# A dealt hand cannot be fished by repeatedly changing the starting formation.
	if phase != "reward" and not (expedition_mode and phase == "map"): return false
	if uids_by_slot.size() != max_active: return false
	var seen: Dictionary = {}
	for uid in uids_by_slot:
		if int(uid) < 0: continue
		var individual: Dictionary = by_uid(party, int(uid))
		if individual.is_empty() or int(individual.hp) <= 0 or seen.has(int(uid)): return false
		seen[int(uid)] = true
	if seen.is_empty(): return false
	for individual in party: individual.slot = uids_by_slot.find(int(individual.uid))
	return true

static func replace_after_ko(slot: int, in_uid: int, phase: String, party: Array, round_number: int, max_active: int) -> bool:
	if phase != "replacement" or slot < 0 or slot >= max_active: return false
	var outgoing: Dictionary = Targeting.at_slot(party, slot)
	# Only a vacated KO body grants a free replacement, never an unused field slot.
	if outgoing.is_empty() or int(outgoing.hp) > 0: return false
	var incoming: Dictionary = by_uid(party, in_uid)
	if incoming.is_empty() or int(incoming.hp) <= 0 or int(incoming.slot) >= 0: return false
	if not outgoing.is_empty(): outgoing.slot = -1
	incoming.slot = slot
	incoming.can_act_round = round_number
	return true
