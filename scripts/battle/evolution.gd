extends RefCounted
## Evolution changes a form, never individual identity or physical card ownership.
static func offers(individual: Dictionary, edges: Array) -> Array:
	var result: Array = []
	for edge in edges:
		if str(edge.from) == str(individual.form_id):
			result.append({"kind": "evolve", "uid": individual.uid, "source_form_id": str(edge.from), "target_form_id": str(edge.to), "transition_id": str(edge.id)})
	return result

static func valid(individual: Dictionary, offer: Dictionary, edges: Array) -> bool:
	return offers(individual, edges).any(func(candidate: Dictionary) -> bool: return candidate == offer)

static func apply(individual: Dictionary, target_form_id: String, stats: Dictionary) -> void:
	var ratio: float = float(individual.hp) / maxi(1, int(individual.max_hp))
	individual.form_id = target_form_id
	for key in ["max_hp", "attack", "defense", "speed"]: individual[key] = int(stats[key])
	individual.hp = ceili(float(individual.max_hp) * ratio) if ratio > 0.0 else 0
