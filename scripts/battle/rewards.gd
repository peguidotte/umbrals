extends RefCounted
## Reward destination and card collection operations over explicit roster data.
const EncounterSetup = preload("res://scripts/battle/encounter_setup.gd")
const Content = preload("res://scripts/content.gd")
const Evolution = preload("res://scripts/battle/evolution.gd")
const CatalogRevision = preload("res://scripts/battle/catalog_revision.gd")
const Targeting = preload("res://scripts/battle/targeting.gd")

static func by_uid(roster: Array, uid: int) -> Dictionary:
	for individual in roster:
		if int(individual.uid) == uid: return individual
	return {}

static func active_party(party: Array) -> Array:
	var active: Array = []
	for individual in party:
		if int(individual.get("slot", -1)) >= 0: active.append(individual)
	active.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.slot) < int(b.slot))
	return active

static func capture_destinations(offer_index: int, replace_uid: int, phase: String, reward_offers: Array, party: Array) -> Array[int]:
	var result: Array[int] = []
	if phase != "reward" or offer_index < 0 or offer_index >= reward_offers.size() or reward_offers[offer_index].kind != "capture": return result
	if party.size() < 6 and replace_uid != -1: return result
	if party.size() >= 6 and by_uid(party, replace_uid).is_empty(): return result
	# Never leave a new encounter with no field body that can act or be replaced.
	for individual in active_party(party):
		if int(individual.uid) != replace_uid:
			result.append(-1)
			break
	for slot in range(3):
		var occupant: Dictionary = Targeting.at_slot(party, slot)
		if occupant.is_empty() or int(occupant.uid) == replace_uid: result.append(slot)
	return result

static func persist_card_collection(party: Array, hand: Array, deck: Array, discard_pile: Array, suspended_cards: Dictionary) -> void:
	# Zones, rather than species defaults, own the current edited deck. Learning,
	# thinning and evolving preserve precisely these physical card instances.
	var cards: Array = hand + deck + discard_pile
	for suspended in suspended_cards.values(): cards.append_array(suspended.deck + suspended.discard)
	for individual in party:
		var owned: Array = []
		var seen: Dictionary = {}
		for card in cards:
			if int(card.owner) == int(individual.uid) and not seen.has(card.instance_id):
				var instance: Dictionary = card.duplicate(true)
				instance.erase("target_slot")
				owned.append(instance)
				seen[card.instance_id] = true
		individual.cards = owned


static func apply_offer(offer_index: int, replace_uid: int, capture_slot: int, phase: String, reward_offers: Array, party: Array, hand: Array, deck: Array, discard_pile: Array, suspended_cards: Dictionary, max_team: int, catalog_revision: int) -> bool:
	if not CatalogRevision.supported(catalog_revision): return false
	if phase != "reward" or offer_index < 0 or offer_index >= reward_offers.size(): return false
	var offer: Dictionary = reward_offers[offer_index]
	if offer.kind == "capture" and not CatalogRevision.form_available(str(offer.umbral.species), str(offer.umbral.form_id), catalog_revision): return false
	if replace_uid != -1 and (offer.kind != "capture" or party.size() < max_team): return false
	if offer.kind == "capture" and party.size() >= max_team and by_uid(party, replace_uid).is_empty(): return false
	var destination: int = -1
	if offer.kind == "capture":
		destination = capture_slot
		if destination == -2:
			destination = int(by_uid(party, replace_uid).slot) if party.size() >= max_team else -1
		if not destination in capture_destinations(offer_index, replace_uid, phase, reward_offers, party): return false
	elif capture_slot != -2: return false
	if offer.kind != "capture":
		var candidate: Dictionary = by_uid(party, int(offer.uid))
		if candidate.is_empty() or not Evolution.valid(candidate, offer, CatalogRevision.edges(candidate, catalog_revision)): return false
	persist_card_collection(party, hand, deck, discard_pile, suspended_cards)
	if offer.kind == "capture":
		if party.size() >= max_team:
			var old: Dictionary = by_uid(party, replace_uid)
			if old.is_empty(): return false
			var index: int = party.find(old)
			var captured: Dictionary = offer.umbral.duplicate(true)
			captured.slot = destination
			party[index] = captured
		else:
			var captured: Dictionary = offer.umbral.duplicate(true)
			captured.slot = destination
			party.append(captured)
	else:
		var individual: Dictionary = by_uid(party, int(offer.uid))
		if individual.is_empty() or not Evolution.valid(individual, offer, CatalogRevision.edges(individual, catalog_revision)): return false
		var evolved: Dictionary = individual.duplicate(true)
		evolved.form_id = str(offer.target_form_id)
		Evolution.apply(individual, evolved.form_id, Content.species_stats(evolved))
		# Existing instances and learned power IDs survive. No automatic signature cards.
	return true

static func prepare(reward_offers: Array, party: Array, starter_species: String, encounter: int, expedition_mode: bool, next_uid: int, rng: RandomNumberGenerator, catalog_revision: int) -> void:
	reward_offers.clear()
	if not CatalogRevision.supported(catalog_revision): return
	var route: Array = Content.CAPTURE_ROUTES[starter_species]
	var reward_index: int = (0 if Content.ENCOUNTERS[encounter].get("id", "") == "clearing" else 1) if expedition_mode else encounter
	var species: String = str(route[clampi(reward_index, 0, route.size() - 1)])
	var pool: Array = Content.PASSIVE_POOLS[species]
	var passive: String = str(pool[rng.randi_range(0, pool.size() - 1)])
	reward_offers.append({"kind": "capture", "umbral": EncounterSetup.make_umbral(species, passive, next_uid)})
	var deferred: Array = []
	for individual in party:
		for edge in CatalogRevision.edges(individual, catalog_revision):
			var offers: Array = Evolution.offers(individual, [edge])
			if edge.get("deferred", false): deferred.append_array(offers)
			else: reward_offers.append_array(offers)
	reward_offers.append_array(deferred)
