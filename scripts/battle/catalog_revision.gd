extends RefCounted
## A run retains its authored evolution graph across catalog additions.
const Content = preload("res://scripts/content.gd")
const CURRENT: int = 5
# Revisions 1/2 are grass histories; 3 is independent electric history.
const GRAPHS: Dictionary = {0: [0], 1: [0, 1], 2: [0, 1, 2], 3: [0, 3], 4: [0, 1, 2, 3], 5: [0, 1, 2, 3, 5]}

static func supported(revision: int) -> bool:
	return GRAPHS.has(revision)

static func includes(revision: int, introduced: int) -> bool:
	return supported(revision) and introduced in GRAPHS[revision]

static func form_available(species_id: String, form_id: String, revision: int) -> bool:
	if not supported(revision): return false
	var form: Dictionary = Content.form_definition(species_id, form_id)
	var introduced: Variant = form.get("catalog_revision", 0)
	return not form.is_empty() and introduced is int and includes(revision, introduced)

static func edges(individual: Dictionary, revision: int) -> Array:
	var result: Array = []
	var species_id: String = str(individual.get("species", ""))
	if not form_available(species_id, Content.form_id(individual), revision): return result
	for edge in Content.evolution_edges(individual):
		var introduced: Variant = edge.get("catalog_revision", 0)
		if introduced is int and includes(revision, introduced) and form_available(species_id, str(edge.to), revision): result.append(edge)
	return result
