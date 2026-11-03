extends RefCounted
## Read-only projection of game content for the discovery codex.
const Content = preload("res://scripts/content.gd")
const PAGE_SIZE = 3
const CATEGORIES = {"umbrals":"Umbrals","powers":"Poderes","passives":"Passivas","items":"Itens"}

static func build() -> Dictionary:
	var catalog: Dictionary = {"umbrals": [], "powers": [], "passives": [], "items": []}
	for id in Content.species_ids():
		for form_id in Content.form_ids(id):
			var individual: Dictionary = {"species": id, "form_id": form_id}
			catalog.umbrals.append({"id": form_id, "name": Content.display_name(individual), "art": Content.art_binding(individual), "species": id, "form_id": form_id, "initial": form_id == Content.initial_form(id)})
	# Encounter Umbrals share the same category, never a separate bestiary.
	var seen: Array = []
	for encounter in Content.ENCOUNTERS:
		for enemy in encounter.enemies:
			var id: String = str(enemy.art).get_file()
			if id in seen: continue
			seen.append(id)
			catalog.umbrals.append({"id": id, "name": enemy.name, "art": enemy.art, "species": "", "initial": true})
	for id in Content.POWERS:
		catalog.powers.append({"id": id, "name": str(Content.POWERS[id].name).replace("\n", " "), "art": Content.POWERS[id].art})
	for id in Content.PASSIVES:
		catalog.passives.append({"id": id, "name": Content.PASSIVES[id].name, "art": "attacks/life-seed"})
	for id in Content.CONSUMABLES:
		catalog.items.append({"id": id, "name": Content.CONSUMABLES[id].name, "art": "ui/backpack"})
	return catalog

static func ordered(catalog: Dictionary, category: String, progress: RefCounted) -> Array:
	var result: Array = []
	for known in [true,false]:
		for entry in catalog[category]:
			# Evolutions live in the selected lineage's record, as in the approved design.
			if category == "umbrals" and not bool(entry.get("initial", true)): continue
			if progress.knows(category,entry.id) == known: result.append(entry)
	return result

static func find_entry(catalog: Dictionary, category: String, id: String) -> Dictionary:
	for entry in catalog.get(category,[]):
		if entry.id == id: return entry
	return {}
