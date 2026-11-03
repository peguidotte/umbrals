extends RefCounted
## Presentation-only item choices assembled from catalog definitions and inventory.

static func choices(definitions: Dictionary, inventory: Dictionary) -> Array:
	var result: Array = []
	# Keep the original two controls visible when their stock is exhausted.
	for id in ["potion", "revive"]:
		if definitions.has(id): result.append(id)
	for id in definitions:
		if id not in result and int(inventory.get(id, 0)) > 0: result.append(id)
	return result

static func name_for(id: String, definitions: Dictionary) -> String:
	return str(definitions.get(id, {}).get("name", id.capitalize()))

static func count(inventory: Dictionary, definitions: Dictionary) -> int:
	var total: int = 0
	for id in choices(definitions, inventory): total += int(inventory.get(id, 0))
	return total

static func summary(inventory: Dictionary, definitions: Dictionary, short: bool = false) -> String:
	var parts: Array[String] = []
	for id in choices(definitions, inventory):
		var label: String = name_for(id, definitions).to_lower()
		if id == "potion": label = "poções" if short else "poção(ões)"
		elif id == "revive": label = "reanimação" if short else "reanimação(ões)"
		parts.append("%d %s" % [int(inventory.get(id, 0)), label])
	return " · ".join(parts)

static func effect_text(item: Dictionary, description: String) -> String:
	if item.has("heal"): return "Restaura %d HP." % int(item.heal)
	if item.has("revive_ratio"): return "Reanima com %d%% do HP máximo." % int(float(item.revive_ratio) * 100)
	return description
