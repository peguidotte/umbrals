extends RefCounted
## Bump RULESET whenever deterministic mechanics change. JSON.stringify sorts keys.
const Content = preload("res://scripts/content.gd")
const RULESET = "expedition-rules-4"
const DISPLAY_FIELDS = ["name", "names", "art", "color", "element", "title", "text", "lore", "description", "trait", "trait_description"]

static func gameplay_projection(value: Variant) -> Variant:
	if value is Array:
		var result: Array = []
		for item in value: result.append(gameplay_projection(item))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value:
			if not key in DISPLAY_FIELDS: result[key] = gameplay_projection(value[key])
		return result
	return value

static func content_digest(catalog: Dictionary, species: Dictionary, powers: Dictionary, passives: Dictionary, encounters: Array, extras: Dictionary) -> String:
	return JSON.stringify(gameplay_projection({"catalog": catalog, "species": species, "powers": powers, "passives": passives, "encounters": encounters, "extras": extras})).sha256_text()

static func manifest() -> Dictionary:
	var catalog: Dictionary = {}
	for id in Content.species_ids():
		var entry = Content.CATALOG[id]
		catalog[id] = {"initial_form": entry.initial_form, "forms": entry.forms, "evolutions": entry.evolutions}
	var extras: Dictionary = {"species_order": Content.species_ids(), "starters": Content.STARTERS, "passive_pools": Content.PASSIVE_POOLS, "capture_routes": Content.CAPTURE_ROUTES, "consumables": Content.CONSUMABLES, "starting_items": Content.STARTING_ITEMS, "initial_power_copies": Content.INITIAL_POWER_COPIES}
	var effects: Dictionary = {}
	for id in Content.CONSUMABLES: effects[id] = Content.item_effect(id)
	return gameplay_projection({"manifest_version": 2, "item_effects": effects, "catalog": catalog, "species": Content.SPECIES, "powers": Content.POWERS, "passives": Content.PASSIVES, "encounters": Content.ENCOUNTERS, "extras": extras})

static func current() -> Dictionary:
	return {"ruleset": RULESET, "content_sha256": JSON.stringify(manifest()).sha256_text()}

static func matches(value: Variant) -> bool:
	return value is Dictionary and value == current()
