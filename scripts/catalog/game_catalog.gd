extends RefCounted
## Explicit content dependency. A fork owns its Resource graph; fixtures never edit globals.
const Models = preload("res://scripts/domain/models.gd")
const Species = preload("res://scripts/catalog/species_definition.gd")
const Form = preload("res://scripts/catalog/form_definition.gd")
const Item = preload("res://scripts/catalog/item_definition.gd")
const Power = preload("res://scripts/catalog/power_definition.gd")
var species: Dictionary[String, Species] = {}
var encounters: Array = []
var items: Array[Item] = []
var passives: Dictionary = {}

func _init(database: Resource = null, expedition: Resource = null, equipment: Resource = null, common: Dictionary = {}) -> void:
	if database != null:
		for entry in database.species: species[entry.species_id] = entry
	if expedition != null: encounters = expedition.encounters
	if equipment != null: items = equipment.items
	passives = common.duplicate(true)

func fork() -> RefCounted:
	var copy = get_script().new()
	# Duplicate a single graph to retain shared power identity across forms.
	for id in species: copy.species[id] = species[id].duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	for encounter in encounters: copy.encounters.append(encounter.duplicate_deep(Resource.DEEP_DUPLICATE_ALL))
	for item in items: copy.items.append(item.duplicate_deep(Resource.DEEP_DUPLICATE_ALL))
	copy.passives = passives.duplicate(true)
	return copy

func form(individual: Models.Individual) -> Form:
	if individual == null or not species.has(individual.species_id): return null
	return species[individual.species_id].form(individual.form_id)

func display_name(individual: Models.Individual) -> String:
	return form(individual).display_name

func trait_text(individual: Models.Individual) -> String:
	return species[individual.species_id].trait_description % form(individual).trait_strength

func power_stats(id: String, individual: Models.Individual) -> Power:
	return form(individual).power(id)

func portrait_path(individual: Models.Individual, facing: String = "right") -> String:
	return form(individual).presentation.direction(facing).portrait_path

func make_individual(id: String, passive: String, uid: int, form_id: String = "") -> Models.Individual:
	return Models.Individual.new(id, passive, uid, form_id if not form_id.is_empty() else species[id].initial_form_id if species.has(id) else "")

func fingerprint() -> String:
	return JSON.stringify({"species": encode(species), "encounters": encode(encounters), "items": encode(items), "passives": passives}).sha256_text()

static func encode(value: Variant) -> Variant:
	if value is Script: return value.resource_path
	if value is Resource:
		var data: Dictionary = {}
		for property in value.get_property_list():
			if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE: data[property.name] = encode(value.get(property.name))
		return data
	if value is Array or value is PackedStringArray:
		var result: Array = []
		for item in value: result.append(encode(item))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value: result[key] = encode(value[key])
		return result
	if value is Color: return [value.r, value.g, value.b, value.a]
	if value is Vector2: return [value.x, value.y]
	return value
