class_name UmbralContent
extends RefCounted
## Species, powers and individual passives, without runtime state.

const VERSION = "0.3.0"
const INITIAL_POWER_COPIES = 2
const STARTING_ITEMS = {"potion": 2, "revive": 1}
const CONSUMABLES = {
	"potion": {"name": "Poção", "cost": 1, "heal": 18},
	"revive": {"name": "Reanimar", "cost": 1, "revive_ratio": 0.35},
}
# Codex prose is presentation content; it grants no abilities or progression.
const ENCOUNTER_LORE = {
	"spore": {"title": "Um viajante das raízes", "text": "Esporo errante atravessa a clareira seguindo a umidade do chão. Seus passos espalham pequenos brilhos sob o chapéu, marcando trilhas que desaparecem quando o bosque seca.\n\nÉ fácil confundir sua imobilidade com distração. Ele está escutando o que se move debaixo das folhas."},
	"owl": {"title": "A vigília entre os espinhos", "text": "A Coruja dos espinhos repousa onde os galhos se cruzam. Imóvel, acompanha as passagens da floresta e só revela sua presença quando decide mudar de poleiro.\n\nAs penas lembram folhas secas; os olhos, porém, não deixam que nada se perca na escuridão."},
	"stag": {"title": "O Rei sem Aurora", "text": "O brilho de seus galhos surge entre as árvores antes que se ouçam seus passos. Os Umbrals da clareira se aquietam quando ele passa.\n\nNinguém sabe por quanto tempo ele vigia o bosque. À luz da lua, parece escutar uma manhã que ainda não chegou."},
}
const ITEM_DESCRIPTIONS = {
	"potion": "Uma pequena reserva de cuidado para as travessias do bosque. A poção recupera o fôlego de um Umbral ferido e segue na mochila até que o Guia escolha quem precisa dela.",
	"revive": "Quando um Umbral já não consegue continuar, este preparo ajuda a reacender seu vínculo. Reanima um companheiro incapacitado e devolve parte de seu HP.",
}
const POWER_DESCRIPTIONS = {
	"sowing": "Espalha uma semente sobre o alvo. Fogo, água e bosque podem dar destinos diferentes ao que foi plantado.",
	"interference": "Uma descarga desordena o ritmo do alvo. Além do impacto, a Interferência enfraquece seu próximo ataque.",
	"fireball": "Uma chama concentrada é lançada contra um alvo. Um golpe direto para abrir caminho entre as sombras do bosque.",
	"cinder_claw": "Brasas acompanham um golpe de garras. O calor permanece nos alvos atingidos mesmo depois do impacto.",
	"flame_guard": "Uma camada de cinzas protege quem conjura. O escudo ajuda a absorver os golpes da rodada.",
	"thorn_lash": "Um chicote de espinhos alcança os alvos enquanto o bosque prepara uma pequena proteção para quem o conduz.",
	"root_wall": "Raízes se erguem para proteger quem conjura. A barreira também provoca os oponentes.",
	"life_seed": "A energia de uma semente é dedicada à recuperação de um aliado ferido.",
	"lightning": "Um arco de eletricidade alcança um alvo. Água sobre o oponente pode abrir caminho para uma reação de Condução.",
	"static_veil": "Eletricidade envolve quem conjura, combinando proteção com uma descarga contra o alvo.",
	"storm_dive": "Um mergulho concentra a força da tempestade em um único alvo. Exige mais ações do que os golpes básicos.",
	"tidal_splash": "Um jato de água atinge e deixa o alvo Encharcado, preparando o terreno para outras técnicas.",
	"rain_sweep": "Uma cortina de chuva alcança posições vizinhas e deixa os oponentes atingidos Encharcados.",
	"dew_mend": "Uma gota preservada é compartilhada com um aliado para recuperar parte de seu HP.",
	"inferno": "A chama de Ignivar se expande sobre os oponentes. O impacto deixa queimaduras nos alvos atingidos.",
	"sanctuary": "Verdálio abre um abrigo para os aliados, unindo escudo e recuperação.",
	"judgment": "Tempestral espalha uma descarga pela formação adversária e prepara proteção para si.",
	"moon_tide": "A água de Marevéu atravessa a formação oponente, deixando os alvos atingidos Encharcados.",
}
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
const POWERS = {
	"sowing": {"nature": "forest", "learning": "nature", "conditions": {"seed": 3}, "name": "Semeadura", "cost": 1, "damage": 6, "block": 0, "heal": 0, "art": "attacks/life-seed", "target": "enemy", "scope": "single", "priority": 0, "order": 60},
	"interference": {"nature": "lightning", "learning": "nature", "conditions": {"electrified": 2}, "name": "Interferência", "cost": 1, "damage": 4, "block": 0, "heal": 0, "art": "attacks/lightning", "target": "enemy", "scope": "single", "priority": 0, "order": 80},
	"fireball": {"nature": "fire", "learning": "nature", "conditions": {}, "name": "Bola de\nfogo", "cost": 1, "damage": 12, "block": 0, "heal": 0, "art": "attacks/fireball", "target": "enemy", "scope": "single", "priority": 0, "order": 10},
	"cinder_claw": {"nature": "fire", "learning": "nature", "conditions": {"burn": 3}, "name": "Garra de\nbrasas", "cost": 1, "damage": 8, "block": 0, "heal": 0, "art": "attacks/cinder-claw", "target": "enemy", "scope": "upper_pair", "priority": 0, "order": 20},
	"flame_guard": {"nature": "fire", "learning": "nature", "conditions": {}, "name": "Manto de\ncinzas", "cost": 1, "damage": 0, "block": 8, "heal": 0, "art": "attacks/flame-guard", "target": "self", "scope": "single", "priority": 1, "order": 30},
	"thorn_lash": {"nature": "forest", "learning": "nature", "conditions": {}, "name": "Chicote de\nespinhos", "cost": 1, "damage": 8, "block": 4, "heal": 0, "art": "attacks/thorn-lash", "target": "enemy", "scope": "lower_pair", "priority": 0, "order": 40},
	"root_wall": {"nature": "forest", "learning": "nature", "conditions": {"taunt": 1}, "name": "Muralha de\nraízes", "cost": 1, "damage": 0, "block": 12, "heal": 0, "art": "attacks/root-wall", "target": "self", "scope": "single", "priority": 1, "order": 50},
	"life_seed": {"nature": "forest", "learning": "nature", "conditions": {}, "name": "Semente\nvital", "cost": 1, "damage": 0, "block": 0, "heal": 6, "art": "attacks/life-seed", "target": "ally", "scope": "single", "priority": 0, "order": 60},
	"lightning": {"nature": "lightning", "learning": "nature", "conditions": {}, "name": "Arco\nelétrico", "cost": 1, "damage": 11, "block": 0, "heal": 0, "art": "attacks/lightning", "target": "enemy", "scope": "single", "priority": 0, "order": 70},
	"static_veil": {"nature": "lightning", "learning": "nature", "conditions": {}, "name": "Véu\nestático", "cost": 1, "damage": 4, "block": 8, "heal": 0, "art": "attacks/static-veil", "target": "enemy", "scope": "single", "priority": 1, "order": 80},
	"storm_dive": {"nature": "lightning", "learning": "nature", "conditions": {}, "name": "Mergulho\ntrovão", "cost": 2, "damage": 25, "block": 0, "heal": 0, "art": "attacks/storm-dive", "target": "enemy", "scope": "single", "priority": 0, "order": 90},
	"tidal_splash": {"nature": "water", "learning": "nature", "conditions": {"wet": 2}, "name": "Jato de\norvalho", "cost": 1, "damage": 8, "block": 0, "heal": 0, "art": "attacks/splash", "target": "enemy", "scope": "single", "priority": 0, "order": 100},
	"rain_sweep": {"nature": "water", "learning": "nature", "conditions": {"wet": 2}, "name": "Chuva\nlateral", "cost": 1, "damage": 4, "block": 0, "heal": 0, "art": "attacks/rain", "target": "enemy", "scope": "upper_pair", "priority": 0, "order": 110},
	"dew_mend": {"nature": "water", "learning": "nature", "conditions": {}, "name": "Gota\nserena", "cost": 1, "damage": 0, "block": 0, "heal": 6, "art": "attacks/dew-mend", "target": "ally", "scope": "single", "priority": 0, "order": 120},
	"inferno": {"nature": "fire", "learning": "lineage", "conditions": {"burn": 5}, "name": "Sol\ndevorador", "cost": 2, "damage": 27, "block": 0, "heal": 0, "art": "attacks/inferno", "target": "enemy", "scope": "all", "priority": 0, "order": 130},
	"sanctuary": {"nature": "forest", "learning": "lineage", "conditions": {}, "name": "Santuário\nancestral", "cost": 2, "damage": 0, "block": 18, "heal": 6, "art": "attacks/sanctuary", "target": "ally", "scope": "all", "priority": 1, "order": 140},
	"judgment": {"nature": "lightning", "learning": "lineage", "conditions": {}, "name": "Juízo da\ntempestade", "cost": 2, "damage": 30, "block": 5, "heal": 0, "art": "attacks/judgment", "target": "enemy", "scope": "all", "priority": 0, "order": 150},
	"moon_tide": {"nature": "water", "learning": "lineage", "conditions": {"wet": 2}, "name": "Maré\nlunar", "cost": 2, "damage": 12, "block": 0, "heal": 0, "art": "attacks/rain", "target": "enemy", "scope": "all", "priority": 0, "order": 160},
}
# Legacy summary fields remain available to screens and migrated records. The
# playable battle uses individual enemies, not the legacy aggregate hp/intents.
const ENCOUNTERS = [
	{
		"id": "clearing", "name": "Esporo errante", "subtitle": "A FLORESTA EXPERIMENTA SEUS VÍNCULOS", "hp": 105, "intents": [7, 9, 6], "art": "characters/spore",
		"enemies": [
			{"uid": 1001, "species": "moss", "name": "Esporo errante", "art": "characters/spore", "form_id": "moss", "max_hp": 58, "hp": 58, "attack": 10, "defense": 0, "speed": 8, "slot": 1, "pattern": [
				{"nature": "forest", "conditions": {}, "category": "attack", "damage": 8, "block": 0, "wet": 0, "scope": "single"},
				{"nature": "forest", "conditions": {}, "category": "defend", "damage": 0, "block": 7, "wet": 0, "scope": "single", "priority": 1},
				{"nature": "forest", "conditions": {}, "category": "attack", "damage": 11, "block": 0, "wet": 0, "scope": "single", "target_policy": "weakest"},
			]},
		],
	},
	{
		"id": "thicket", "name": "Coruja dos espinhos", "subtitle": "UMBRALS NÃO LUTAM SOZINHOS", "hp": 170, "intents": [9, 12, 8], "art": "characters/owl",
		"enemies": [
			{"uid": 2001, "species": "volt", "name": "Coruja dos espinhos", "art": "characters/owl", "form_id": "volt", "max_hp": 46, "hp": 46, "attack": 10, "defense": 1, "speed": 14, "slot": 0, "pattern": [
				{"nature": "lightning", "conditions": {}, "category": "prepare", "charge": 6, "damage": 0, "block": 0, "wet": 0, "scope": "single"},
				{"nature": "lightning", "conditions": {}, "category": "attack", "damage": 7, "block": 0, "wet": 0, "scope": "upper_pair"},
				{"nature": "lightning", "conditions": {"electrified": 2}, "category": "attack", "damage": 6, "block": 0, "wet": 0, "scope": "single", "target_policy": "weakest"},
			]},
			{"uid": 2002, "species": "moss", "name": "Esporo vigia", "art": "characters/spore", "form_id": "moss", "max_hp": 40, "hp": 40, "attack": 10, "defense": 1, "speed": 8, "slot": 2, "pattern": [
				{"nature": "forest", "conditions": {"seed": 3}, "category": "attack", "damage": 4, "block": 0, "wet": 0, "scope": "single"},
				{"nature": "forest", "conditions": {}, "category": "defend", "damage": 0, "block": 8, "wet": 0, "scope": "single", "priority": 1},
				{"nature": "forest", "conditions": {}, "category": "attack", "damage": 6, "block": 0, "wet": 0, "scope": "lower_pair"},
			]},
		],
	},
	{
		"id": "boss", "name": "O Rei sem Aurora", "subtitle": "O ÚLTIMO ECO DO BOSQUE", "hp": 255, "intents": [11, 15, 9], "art": "characters/stag",
		"enemies": [
			{"uid": 3001, "species": "ember", "name": "O Rei sem Aurora", "art": "characters/stag", "form_id": "ignivar", "max_hp": 76, "hp": 76, "attack": 12, "defense": 2, "speed": 11, "slot": 1, "pattern": [
				{"nature": "fire", "conditions": {}, "category": "prepare", "charge": 6, "damage": 0, "block": 0, "wet": 0, "scope": "all"},
				{"nature": "fire", "conditions": {}, "category": "attack", "damage": 10, "block": 0, "wet": 0, "scope": "all"},
				{"nature": "fire", "conditions": {}, "category": "defend", "damage": 0, "block": 12, "wet": 0, "scope": "single", "priority": 1},
			]},
			{"uid": 3002, "species": "moss", "name": "Raiz do crepúsculo", "art": "characters/spore", "form_id": "moss", "max_hp": 40, "hp": 40, "attack": 10, "defense": 2, "speed": 6, "slot": 2, "pattern": [
				{"nature": "forest", "conditions": {}, "category": "defend", "damage": 0, "block": 8, "wet": 0, "scope": "single", "priority": 1},
				{"nature": "forest", "conditions": {"seed": 3}, "category": "attack", "damage": 4, "block": 0, "wet": 0, "scope": "lower_pair"},
				{"nature": "forest", "conditions": {}, "category": "attack", "damage": 6, "block": 0, "wet": 0, "scope": "single", "target_policy": "weakest"},
			]},
			{"uid": 3003, "species": "volt", "name": "Coruja da fenda", "art": "characters/owl", "form_id": "volt", "max_hp": 36, "hp": 36, "attack": 10, "defense": 0, "speed": 15, "slot": 0, "pattern": [
				{"nature": "lightning", "conditions": {}, "category": "attack", "damage": 5, "block": 0, "wet": 0, "scope": "single"},
				{"nature": "lightning", "conditions": {}, "category": "prepare", "charge": 6, "damage": 0, "block": 0, "wet": 0, "scope": "single"},
				{"nature": "lightning", "conditions": {}, "category": "attack", "damage": 7, "block": 0, "wet": 0, "scope": "upper_pair"},
			]},
		],
	},
]

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
