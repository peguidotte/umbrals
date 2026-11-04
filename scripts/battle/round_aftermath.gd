extends RefCounted
## Consume committed cards and summarize the resolved battle state.

static func discard_hand(hand: Array, discard_pile: Array, selected: Array[int], queued_swaps: Array, queued_items: Array) -> void:
	# Every card, selected or not, leaves the hand exactly once each round.
	for card in hand:
		card.erase("target_slot")
		discard_pile.append(card)
	hand.clear()
	selected.clear()
	queued_swaps.clear()
	queued_items.clear()

static func summarize(events: Array, enemies: Array, party: Array) -> Dictionary:
	var incoming_damage: int = 0
	for event in events:
		if event.target_side == "ally" and event.kind in ["attack", "burn"]: incoming_damage += int(event.amount)
	var foes_alive: bool = false
	for opponent in enemies:
		if int(opponent.hp) > 0: foes_alive = true
	var party_alive: bool = false
	for individual in party:
		if int(individual.hp) > 0: party_alive = true
	return {"incoming_damage": incoming_damage, "foes_alive": foes_alive, "party_alive": party_alive}

static func complete_score(score: Dictionary, phase: String, applied_damage: int, incoming_damage: int, events: Array, passing: bool, resolved_round: int, encounter: int) -> void:
	score.ok = true
	score.phase = phase
	score.applied_damage = applied_damage
	score.incoming = incoming_damage
	score.events = events
	score.passed = passing
	score.resolved_round = resolved_round
	score.encounter_index = encounter
