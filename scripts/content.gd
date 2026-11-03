class_name UmbralContent
extends RefCounted
## Species, powers and individual passives, without runtime state.

const VERSION = "0.3.0"
const INITIAL_POWER_COPIES = 2
const STARTING_ITEMS = {"potion": 2, "revive": 1}
# Codex prose is presentation content; it grants no abilities or progression.
const NATURES = {
	"fire": {"name": "Fogo", "color": "ef987b"},
	"water": {"name": "Água", "color": "80d7e5"},
	"lightning": {"name": "Raio", "color": "e8cf81"},
	"forest": {"name": "Bosque", "color": "91c8a1"},
}
const STARTERS = ["ember", "moss", "volt", "dew"]
# Short prototype routes make each starter's reactions reachable without a debug team.
const CAPTURE_ROUTES = {
	"ember": ["moss", "dew"], "moss": ["dew", "ember"],
	"volt": ["dew", "moss"], "dew": ["volt", "moss"],
}
const PASSIVES = {
	"fierce": {"name": "Feroz", "description": "Ataques ganham +3 dano."},
	"resilient": {"name": "Resiliente", "description": "Proteções ganham +3 escudo."},
	"vital": {"name": "Vital", "description": "Poderes de cura ganham +2 cura."},
	"ardent": {"name": "Ardente", "description": "Ataques aplicam +2 queimadura."},
	"swift": {"name": "Ágil", "description": "+3 Velocidade para este Umbral.", "speed_bonus": 3},
}
const PASSIVE_IDS = ["fierce", "resilient", "vital", "ardent", "swift"]
# Target describes the side; scope describes semantic slots, never front/back ranks.
# Larger priority resolves first. Order is only a stable per-power tiebreaker;
# water does not receive an implicit phase ahead of faster lightning owners.
# Legacy summary fields remain available to screens and migrated records. The
# playable battle uses individual enemies, not the legacy aggregate hp/intents.

const GameplayCatalog = preload("res://scripts/catalog/gameplay_catalog.gd")
static var DEFAULT_CATALOG = GameplayCatalog.new()
static var POWERS: Dictionary = DEFAULT_CATALOG.powers()
static var CONSUMABLES: Dictionary = DEFAULT_CATALOG.items()
static var ENCOUNTERS: Array = DEFAULT_CATALOG.encounters()
static var POWER_DESCRIPTIONS: Dictionary = DEFAULT_CATALOG.descriptions("power")
static var ITEM_DESCRIPTIONS: Dictionary = DEFAULT_CATALOG.descriptions("item")
static var ENCOUNTER_LORE: Dictionary = DEFAULT_CATALOG.descriptions("encounter")

static func item_effect(item_id: String) -> String:
	return DEFAULT_CATALOG.item_effect(item_id)

static func route_encounter_ids() -> Array:
	return ["clearing", "thicket", "boss"]

# Ordered manifest: explicit preload order is independent of filesystem enumeration.
const CatalogLookup = preload("res://scripts/catalog/lookup.gd")
const MANIFEST = preload("res://content/species/catalog.tres")
static var CATALOG: Dictionary = _catalog_from_manifest()
static var SPECIES: Dictionary = _species_projection()
static var PASSIVE_POOLS: Dictionary = _passive_pools()
static var UMBRAL_LORE: Dictionary = _umbral_lore()

static func _catalog_from_manifest() -> Dictionary:
	var result: Dictionary = {}
	for package in MANIFEST.species: result[str(package.id)] = package
	return result

# Transitional projection for existing screens. Author only the resources.
static func _species_projection() -> Dictionary:
	var result: Dictionary = {}
	for species_id in CATALOG:
		var package: Resource = CATALOG[species_id]
		var first: Dictionary = CatalogLookup.form(package, str(package.initial_form))
		var data: Dictionary = {"nature": first.nature, "secondary_natures": [], "resistances": first.resistances.duplicate(true), "names": [], "element": package.element, "color": package.color, "art": [], "trait": first.trait, "trait_description": first.trait_description, "trait_values": [], "powers": package.powers.duplicate(), "signature": package.signature, "stats": first.stats.duplicate(true)}
		for form in package.forms:
			data.secondary_natures.append(form.secondary_nature)
			data.names.append(form.name)
			data.art.append(form.art)
			data.trait_values.append(form.trait_value)
		result[species_id] = data
	return result

static func _umbral_lore() -> Dictionary:
	var result: Dictionary = ENCOUNTER_LORE.duplicate(true)
	for species_id in CATALOG:
		for form in CATALOG[species_id].forms:
			result[str(form.id)] = form.lore.duplicate(true)
	return result

static func _passive_pools() -> Dictionary:
	var result: Dictionary = {}
	for species_id in CATALOG: result[species_id] = CATALOG[species_id].passive_pool.duplicate()
	return result

# Schema 1 compatibility only. New individuals persist form_id, never an ordinal.
const LEGACY_FORMS = {
	"ember": {1: "ember", 2: "ignivar"}, "moss": {1: "moss", 2: "verdalio"},
	"volt": {1: "volt", 2: "tempestral"}, "dew": {1: "dew", 2: "mareveu"},
}

static func species_ids() -> Array:
	return CATALOG.keys()

static func form_ids(species_id: String) -> Array:
	var ids: Array = []
	if CATALOG.has(species_id):
		for form in CATALOG[species_id].forms: ids.append(str(form.id))
	return ids

static func initial_form(species_id: String) -> String:
	return str(CATALOG[species_id].initial_form) if CATALOG.has(species_id) else ""

static func legacy_form(species_id: String, stage: int) -> String:
	return str(LEGACY_FORMS.get(species_id, {}).get(stage, ""))

static func form_id(individual: Dictionary) -> String:
	var species_id: String = str(individual.get("species", "ember"))
	if individual.has("form_id"): return str(individual.form_id)
	return initial_form(species_id)

static func form_definition(species_id: String, id: String) -> Dictionary:
	if not CATALOG.has(species_id): return {}
	return CatalogLookup.form(CATALOG[species_id], id)

static func evolution_edges(individual: Dictionary) -> Array:
	var species_id: String = str(individual.get("species", ""))
	var result: Array = []
	if not CATALOG.has(species_id): return result
	return CatalogLookup.edges(CATALOG[species_id], form_id(individual))

static func art_binding(individual: Dictionary) -> String:
	return str(form_definition(str(individual.get("species", "")), form_id(individual)).get("art", ""))

static func species_stats(individual: Dictionary) -> Dictionary:
	var form: Dictionary = form_definition(str(individual.get("species", "ember")), form_id(individual))
	var stats: Dictionary = form.get("stats", {}).duplicate(true)
	var passive: Dictionary = PASSIVES.get(str(individual.get("passive", "")), {})
	stats.speed = int(stats.speed) + int(passive.get("speed_bonus", 0))
	return stats

## Evolution upgrades these same instances. Signatures are learning options,
## never automatic extra cards. The rules own UIDs, ownership and card zones.
static func initial_power_ids(species_id: String) -> Array:
	var result: Array = []
	for power_id in SPECIES[species_id].powers:
		for _copy_number in range(INITIAL_POWER_COPIES):
			result.append(str(power_id))
	return result

static func display_name(umbral: Dictionary) -> String:
	return str(form_definition(str(umbral.species), form_id(umbral)).get("name", ""))

static func trait_text(umbral: Dictionary) -> String:
	var form: Dictionary = form_definition(str(umbral.species), form_id(umbral))
	return str(form.trait_description) % int(form.trait_value)

static func natures(individual: Dictionary) -> Array[String]:
	var form: Dictionary = form_definition(str(individual.species), form_id(individual))
	var result: Array[String] = [str(form.nature)]
	var secondary: String = str(form.secondary_nature)
	if not secondary.is_empty(): result.append(secondary)
	return result

static func nature_text(individual: Dictionary) -> String:
	var names: Array[String] = []
	for nature in natures(individual): names.append(str(NATURES[nature].name))
	return " / ".join(names)

static func resistances(individual: Dictionary) -> Dictionary:
	return individual.get("resistances", form_definition(str(individual.species), form_id(individual)).get("resistances", {})).duplicate(true)

static func resistance_text(individual: Dictionary) -> String:
	var labels: Array[String] = []
	var values: Dictionary = resistances(individual)
	for nature in NATURES:
		if int(values.get(nature, 0)) > 0: labels.append("%s −%d%%" % [NATURES[nature].name, int(values[nature])])
	return " · ".join(labels) if not labels.is_empty() else "Nenhuma"

static func can_learn(individual: Dictionary, power_id: String) -> bool:
	if not POWERS.has(power_id): return false
	var power: Dictionary = POWERS[power_id]
	if power.learning == "universal": return true
	if power.learning == "lineage": return SPECIES[individual.species].signature == power_id
	return str(power.nature) in natures(individual)

static func power_stats(power_id: String, individual: Dictionary) -> Dictionary:
	var stats: Dictionary = POWERS[power_id].duplicate(true)
	var form: Dictionary = form_definition(str(individual.get("species", "ember")), form_id(individual))
	var profile: Dictionary = form.get("power_profile", {})
	for id in ["damage", "block", "heal"]:
		if int(stats[id]) > 0: stats[id] = int(stats[id]) + int(profile.get(id, 0))
	for id in ["burn", "wet"]:
		if int(stats.conditions.get(id, 0)) > 0: stats.conditions[id] = int(stats.conditions[id]) + int(profile.get(id, 0))
	for id in ["burn", "wet", "taunt"]: stats[id] = int(stats.conditions.get(id, 0))
	stats.lightning = stats.nature == "lightning"
	return stats
