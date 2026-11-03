extends RefCounted
## Takes detached snapshots so callers cannot mutate either authored assets or one another.

const SPECIES_MANIFEST = preload("res://content/species/catalog.tres")
const Lookup = preload("res://scripts/catalog/lookup.gd")
const POWER_MANIFEST = preload("res://content/powers/catalog.tres")
const ITEM_MANIFEST = preload("res://content/items/catalog.tres")
const ENCOUNTER_MANIFEST = preload("res://content/encounters/catalog.tres")
var _species: Dictionary = {}
var _powers: Dictionary = {}
var _items: Dictionary = {}
var _encounters: Array = []
var _effects: Dictionary = {}
var _descriptions: Dictionary = {"power": {}, "item": {}, "encounter": {}}

func _init(power_manifest: Resource = POWER_MANIFEST, item_manifest: Resource = ITEM_MANIFEST, encounter_manifest: Resource = ENCOUNTER_MANIFEST, species_manifest: Resource = SPECIES_MANIFEST) -> void:
	for resource in species_manifest.species:
		_species[resource.id] = resource.duplicate(true)
	for resource in power_manifest.entries:
		var definition: Dictionary = {}
		for key in ["nature", "learning", "conditions", "name", "cost", "damage", "block", "heal", "art", "target", "scope", "priority", "order"]:
			definition[key] = resource.get(key)
		_powers[resource.id] = definition.duplicate(true)
		_descriptions.power[resource.id] = resource.description
	for resource in item_manifest.entries:
		var definition: Dictionary = {"name": resource.name, "cost": resource.cost}
		definition.merge(resource.effect_parameters.duplicate(true))
		_items[resource.id] = definition
		_effects[resource.id] = resource.effect_id
		_descriptions.item[resource.id] = resource.description
	for resource in encounter_manifest.entries:
		var definition: Dictionary = {}
		for key in ["id", "name", "subtitle", "hp", "intents", "art", "enemies"]:
			definition[key] = resource.get(key)
		_encounters.append(definition.duplicate(true))
		_descriptions.encounter[str(resource.art).get_file()] = resource.lore.duplicate(true)

func powers() -> Dictionary:
	return _powers.duplicate(true)

func items() -> Dictionary:
	return _items.duplicate(true)

func encounters() -> Array:
	return _encounters.duplicate(true)

func descriptions(kind: String) -> Dictionary:
	return _descriptions.get(kind, {}).duplicate(true)

func item_effect(id: String) -> String:
	return str(_effects.get(id, ""))

func species_ids() -> Array:
	return _species.keys()

func form(species_id: String, form_id: String) -> Dictionary:
	if not _species.has(species_id): return {}
	return Lookup.form(_species[species_id], form_id)

func evolution_edges(species_id: String, form_id: String) -> Array:
	if not _species.has(species_id): return []
	return Lookup.edges(_species[species_id], form_id)
