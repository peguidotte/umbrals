extends RefCounted
## Test/automation planner. Enumerates only legal-sized subsets; never drives game state.
const Models = preload("res://scripts/domain/models.gd")

static func combinations(size: int, limit: int = 3) -> Array[Array]:
	var result: Array[Array] = []
	for i in range(size):
		result.append([i])
		if limit < 2: continue
		for j in range(i + 1, size):
			result.append([i, j])
			if limit < 3: continue
			for k in range(j + 1, size): result.append([i, j, k])
	result.sort_custom(_original_order)
	return result

static func _original_order(a: Array, b: Array) -> bool:
	# Preserve old ascending-mask tie breaks, without a machine-word hand-size limit.
	for offset in range(1, 4):
		var left: int = a[-offset] if a.size() >= offset else -1
		var right: int = b[-offset] if b.size() >= offset else -1
		if left != right: return left < right
	return false

static func choose(hand: Array[Models.CardInstance], project: Callable, intention: int) -> Array[int]:
	var best: Array[int] = []
	var best_value: float = -INF
	for indices in combinations(hand.size()):
		var cards: Array[Models.CardInstance] = []
		for index in indices: cards.append(hand[index])
		var projection: Models.ResolutionResult = project.call(cards)
		var score: Models.CastEvaluation = projection.evaluation
		if not projection.ok: continue
		var healing: int = projection.effective_heal
		var after_hp: int = projection.player_hp_after
		var value: float = projection.applied_damage + mini(intention, score.block) * 1.25 + healing * 1.4
		if projection.enemy_hp_after == 0: value = 10000 + healing - score.energy
		elif after_hp <= 0: value -= 20000
		elif after_hp < 12: value -= (12 - after_hp) * 4
		if value > best_value:
			best_value = value
			best.assign(indices)
	return best
