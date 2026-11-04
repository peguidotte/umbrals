extends RefCounted
## Individual creation and encounter setup over the canonical roster and zones.
const Content = preload("res://scripts/content.gd")

static func make_umbral(species: String, passive: String, uid: int, form_id: String = "") -> Dictionary:
	var individual: Dictionary = {"uid": uid, "species": species, "passive": passive, "form_id": Content.initial_form(species) if form_id.is_empty() else form_id, "slot": -1, "block": 0, "statuses": {}, "status_sources": {}, "can_act_round": 1}
	var stats: Dictionary = Content.species_stats(individual)
	for key in ["max_hp", "attack", "defense", "speed"]:
		individual[key] = int(stats[key])
	individual.hp = individual.max_hp
	individual.known_powers = Content.SPECIES[species].powers.duplicate()
	individual.cards = []
	for power_id in individual.known_powers:
		for copy_number in range(Content.INITIAL_POWER_COPIES):
			individual.cards.append({"instance_id": "%d:%s:%d" % [uid, power_id, copy_number], "owner": uid, "power": power_id})
	return individual

static func shuffle(cards: Array, rng: RandomNumberGenerator) -> void:
	for i in range(cards.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: Variant = cards[i]
		cards[i] = cards[j]
		cards[j] = temp

static func normalize(individual: Dictionary) -> void:
	var defaults: Dictionary = make_umbral(str(individual.species), str(individual.get("passive", "fierce")), int(individual.uid), Content.form_id(individual))
	for key in defaults:
		if not individual.has(key): individual[key] = defaults[key]

static func setup(party: Array, deck: Array, suspended_cards: Dictionary, enemies: Array, encounter: int, rng: RandomNumberGenerator, max_active: int) -> void:
	for individual in party:
		normalize(individual)
		individual.block = 0
		individual.statuses = {}
		individual.status_sources = {}
		individual.can_act_round = 1
		if int(individual.slot) >= 0 or int(individual.hp) <= 0:
			deck.append_array(individual.cards.duplicate(true))
		else:
			suspended_cards[int(individual.uid)] = {"deck": individual.cards.duplicate(true), "discard": [], "entered": false}
	shuffle(deck, rng)
	enemies.clear()
	var definitions: Array = Content.ENCOUNTERS[encounter].get("enemies", [])
	for i in range(mini(max_active, definitions.size())):
		var definition: Dictionary = definitions[i]
		var opponent: Dictionary = make_umbral(str(definition.get("species", "moss")), str(definition.get("passive", "")), int(definition.get("uid", 100 + i)), Content.form_id(definition))
		for key in definition: opponent[key] = definition[key]
		opponent.slot = int(definition.get("slot", i))
		opponent.max_hp = int(definition.get("max_hp", definition.get("hp", opponent.max_hp)))
		opponent.hp = int(definition.get("hp", opponent.max_hp))
		opponent.block = 0
		opponent.statuses = {}
		opponent.status_sources = {}
		enemies.append(opponent)
