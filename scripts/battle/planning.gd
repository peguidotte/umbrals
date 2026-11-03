extends RefCounted
## Pure plan validation over public battle data; no RNG or mutation of state.
const Content = preload("res://scripts/content.gd")
const Targeting = preload("res://scripts/battle/targeting.gd")
const PowerEvaluation = preload("res://scripts/battle/power_evaluation.gd")

static func by_uid(roster: Array, uid: int) -> Dictionary:
	for individual in roster:
		if int(individual.uid) == uid: return individual
	return {}

static func card_reason(index: int, phase: String, hand: Array, party: Array, round_number: int) -> String:
	if phase != "battle" or index < 0 or index >= hand.size(): return "Poder indisponível"
	var individual: Dictionary = by_uid(party, int(hand[index].owner))
	if individual.is_empty(): return "Dono ausente"
	if int(individual.hp) <= 0: return "Umbral incapacitado"
	if int(individual.slot) < 0: return "Umbral na reserva"
	if int(individual.get("can_act_round", 1)) > round_number: return "Age na próxima rodada"
	return ""

static func target_options(index: int, hand: Array, party: Array, enemies: Array) -> Array[int]:
	if index < 0 or index >= hand.size(): return []
	var card: Dictionary = hand[index]
	var owner: Dictionary = by_uid(party, int(card.owner))
	if owner.is_empty() or not Content.POWERS.has(card.power): return []
	return Targeting.options(Content.power_stats(str(card.power), owner), owner, party, enemies)

static func preview_selection(indices: Array[int], hand: Array, party: Array, enemies: Array, phase: String, round_number: int, queued_swaps: Array, queued_items: Array, budget: int) -> Dictionary:
	var cards: Array = []
	for index in indices:
		if index >= 0 and index < hand.size(): cards.append(hand[index])
	var result: Dictionary = PowerEvaluation.evaluate(cards, party)
	if not cards.is_empty() and not result.valid and result.reason != "Ações insuficientes": return result
	if cards.size() != indices.size():
		result.valid = false
		result.reason = "Seleção inválida"
		return result
	for index in indices:
		if not card_reason(index, phase, hand, party, round_number).is_empty():
			result.valid = false
			result.reason = card_reason(index, phase, hand, party, round_number)
			return result
		var card: Dictionary = hand[index]
		var owner: Dictionary = by_uid(party, int(card.owner))
		for swap in queued_swaps:
			if int(swap.out_uid) == int(owner.uid):
				result.valid = false
				result.reason = "Quem sai não pode conjurar nesta rodada"
				return result
		if not int(card.get("target_slot", -1)) in target_options(index, hand, party, enemies):
			result.valid = false
			result.reason = "Escolha uma vaga com alvo apto no alcance do poder"
			return result
	result.actions += queued_swaps.size()
	for item in queued_items: result.actions += int(Content.CONSUMABLES[item.item].cost)
	result.energy = result.actions
	result.valid = (not cards.is_empty() or not queued_swaps.is_empty() or not queued_items.is_empty()) and int(result.actions) <= budget
	result.reason = "" if result.valid else "Ações insuficientes" if int(result.actions) > budget else "Selecione poderes, uma troca ou um item"
	if cards.is_empty() and result.valid: result.name = "Manobra do time"
	return result

