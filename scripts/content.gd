class_name UmbralContent
extends RefCounted
## Pure typed catalog facade. Authored resources are loaded explicitly, never directory-scanned.
const Catalog = preload("res://scripts/catalog/game_catalog.gd")
const Models = preload("res://scripts/domain/models.gd")
const Species = preload("res://scripts/catalog/species_definition.gd")
const Form = preload("res://scripts/catalog/form_definition.gd")
const Power = preload("res://scripts/catalog/power_definition.gd")
static var DATABASE: Resource = load("res://content/catalog.tres")
const VERSION = "0.3.0"
static var SPECIES: Dictionary[String, Species] = _species_index()
const PASSIVES = {
    "fierce": {
        "name": "Feroz",
        "description": "Ataques ganham +3 dano."
    },
    "resilient": {
        "name": "Resiliente",
        "description": "Proteções ganham +3 escudo."
    },
    "vital": {
        "name": "Vital",
        "description": "Poderes de cura ganham +2 cura."
    },
    "ardent": {
        "name": "Ardente",
        "description": "Ataques aplicam +2 queimadura."
    },
    "swift": {
        "name": "Ágil",
        "description": "−1 energia por rodada para este Umbral."
    }
}
const PASSIVE_IDS = ["fierce", "resilient", "vital", "ardent", "swift"]
static var ITEMS: Resource = load("res://content/items/catalog.tres")
static var EXPEDITION: Resource = load("res://content/expedition.tres")
static var ENCOUNTERS: Array = EXPEDITION.encounters
static var DEFAULT: Catalog = Catalog.new(DATABASE, EXPEDITION, ITEMS, PASSIVES)

static func create_catalog() -> Catalog:
	return DEFAULT.fork()

static func _species_index() -> Dictionary[String, Species]:
	var result: Dictionary[String, Species] = {}
	for entry in DATABASE.species: result[entry.species_id] = entry
	return result

static func form(umbral: Models.Individual) -> Form:
	if umbral == null or not SPECIES.has(umbral.species_id): return null
	return SPECIES[umbral.species_id].form(umbral.form_id)

static func display_name(umbral: Models.Individual) -> String:
	return form(umbral).display_name

static func trait_text(umbral: Models.Individual) -> String:
	return SPECIES[umbral.species_id].trait_description % form(umbral).trait_strength

static func power_stats(power_id: String, umbral: Models.Individual) -> Power:
	return form(umbral).power(power_id)

static func portrait_path(umbral: Models.Individual, facing: String = "right") -> String:
	return form(umbral).presentation.direction(facing).portrait_path

static func evolution_names(species: Species) -> String:
	var edges: Array[String] = []
	for shape in species.forms:
		for transition in shape.evolutions:
			edges.append(shape.display_name + " → " + species.form(transition.target_form_id).display_name)
	return " · ".join(edges) if not edges.is_empty() else species.form(species.initial_form_id).display_name
