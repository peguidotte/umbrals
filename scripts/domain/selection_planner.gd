extends RefCounted
## Cost-bounded automation. Enumerates the current action budget, not a three-card rule.
const Content = preload("res://scripts/content.gd")

static func candidates(costs: Array[int], budget: int) -> Array:
	var result: Array = []
	_extend(costs, budget, 0, [], result)
	# Preserve the former ascending-mask tie order without integer masks or a 12-card cap.
	result.sort_custom(func(a: Array, b: Array) -> bool:
		var i: int = a.size() - 1
		var j: int = b.size() - 1
		while i >= 0 and j >= 0:
			if a[i] != b[j]: return a[i] < b[j]
			i -= 1
			j -= 1
		return a.size() < b.size())
	return result

static func _extend(costs: Array[int], remaining: int, start: int, selected: Array, result: Array) -> void:
	for index in range(start, costs.size()):
		if costs[index] < 0 or costs[index] > remaining: continue
		var next: Array = selected + [index]
		result.append(next)
		_extend(costs, remaining - costs[index], index + 1, next, result)

static func choose(hand: Array, budget: int, preview: Callable) -> Array[int]:
	var costs: Array[int] = []
	for card in hand: costs.append(int(Content.POWERS[card.power].cost))
	var best: Array[int] = []
	var best_value: float = -INF
	for candidate in candidates(costs, budget):
		var indices: Array[int] = []
		indices.assign(candidate)
		var score: Dictionary = preview.call(indices)
		if not score.valid: continue
		var value: float = float(score.direct_damage) + float(score.block) * 0.45 + float(score.heal) * 0.35 + float(score.burn_added) * 1.2
		for index in indices:
			if int(Content.POWERS[hand[index].power].conditions.get("wet", 0)) > 0: value += 2.0
		if value > best_value:
			best_value = value
			best = indices
	return best
