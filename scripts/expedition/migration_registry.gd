extends RefCounted
## Ordered, audited source identities. Each edge must preserve existing behavior.
const Identity = preload("res://scripts/expedition/identity.gd")
const Baseline = preload("res://scripts/expedition/baseline_manifest.gd")
const Previous = preload("res://scripts/expedition/rules2_manifest.gd")
const Catalog1 = preload("res://scripts/expedition/catalog1_manifest.gd")
const CATALOG1_IDENTITY = {"ruleset": "expedition-rules-4", "content_sha256": "07942959b491e5c9466c7133b0a4b1809283f9aee7162d405af6ff31aa278442"}
const RULES3_IDENTITY = {"ruleset": "expedition-rules-3", "content_sha256": "7df20eb40243b3b48a76c0ddee5eaa46321984f49612f36a59684e75cb673e80"}
const PREVIOUS_IDENTITY = {"ruleset": "expedition-rules-2", "content_sha256": "7df20eb40243b3b48a76c0ddee5eaa46321984f49612f36a59684e75cb673e80"}
const BASE_IDENTITY = {"ruleset": "expedition-rules-2", "content_sha256": "022bb34bd69d87cace6a96eb130260f812133c318381a5bcd77fa0d981efca58"}
const GRASS_EXTENSIONS = [{"species": "moss", "form": "foslash", "edge": "verdalio_to_foslash", "from": "verdalio", "revision": 1}, {"species": "moss", "form": "folivel", "edge": "verdalio_to_folivel", "from": "verdalio", "revision": 2}]

static func additive(old: Dictionary, target: Dictionary) -> bool:
	if old.keys().size() != target.keys().size(): return false
	if old.get("manifest_version") != 2 or target.get("manifest_version") != 2: return false
	for domain in ["catalog", "species", "powers", "passives", "item_effects"]:
		if not old.get(domain) is Dictionary or not target.get(domain) is Dictionary: return false
		for id in old[domain]:
			if not target[domain].has(id) or target[domain][id] != old[domain][id]: return false
	if not old.get("encounters") is Array or not target.get("encounters") is Array: return false
	if not _prefix(old.encounters, target.encounters): return false
	if not old.get("extras") is Dictionary or not target.get("extras") is Dictionary: return false
	if old.extras.keys().size() != target.extras.keys().size(): return false
	for key in old.extras:
		if not target.extras.has(key): return false
		if key == "species_order":
			if not _prefix(old.extras[key], target.extras[key]): return false
		elif key in ["consumables", "passive_pools"]:
			if not old.extras[key] is Dictionary or not target.extras[key] is Dictionary: return false
			for id in old.extras[key]:
				if not target.extras[key].has(id) or target.extras[key][id] != old.extras[key][id]: return false
		elif old.extras[key] != target.extras[key]: return false
	return true

static func _prefix(old: Array, target: Array) -> bool:
	if old.size() > target.size(): return false
	for i in range(old.size()):
		if old[i] != target[i]: return false
	return true

static func supports(source: Variant) -> bool:
	if source == Identity.current(): return true
	# A registry entry is an audited source, never a user-supplied manifest.
	if Identity.RULESET != "expedition-rules-4": return false
	if source == CATALOG1_IDENTITY:
		return JSON.stringify(Catalog1.DATA).sha256_text() == CATALOG1_IDENTITY.content_sha256 and catalog_transition(Catalog1.DATA, Identity.manifest(), 1)
	if source in [PREVIOUS_IDENTITY, RULES3_IDENTITY]:
		return JSON.stringify(Previous.DATA).sha256_text() == source.content_sha256 and catalog_transition(Previous.DATA, Identity.manifest())
	if source != BASE_IDENTITY: return false
	if JSON.stringify(Baseline.DATA).sha256_text() != BASE_IDENTITY.content_sha256: return false
	var adapted: Dictionary = Baseline.DATA.duplicate(true)
	adapted["manifest_version"] = 2
	adapted["item_effects"] = {"potion": "heal", "revive": "revive"}
	return catalog_transition(adapted, Identity.manifest())

## Remove only these audited appended forms for runs retaining the old graph.
## The original conservative comparator still checks every existing definition.
static func catalog_transition(old: Dictionary, target: Dictionary, source_revision: int = 0) -> bool:
	if source_revision < 0 or source_revision > 1: return false
	var historical: Dictionary = target.duplicate(true)
	for index in range(GRASS_EXTENSIONS.size() - 1, -1, -1):
		var extension: Dictionary = GRASS_EXTENSIONS[index]
		if extension.revision <= source_revision: continue
		if not historical.get("catalog") is Dictionary or not historical.catalog.has(extension.species) or not historical.get("species") is Dictionary or not historical.species.has(extension.species): return false
		var entry: Dictionary = historical.catalog[extension.species]
		var projection: Dictionary = historical.species[extension.species]
		if not entry.get("forms") is Array or not entry.get("evolutions") is Array or entry.forms.is_empty() or entry.evolutions.is_empty(): return false
		var form: Dictionary = entry.forms.back()
		var expected_edge: Dictionary = {"id": extension.edge, "from": extension.from, "to": extension.form, "catalog_revision": extension.revision}
		if form.get("id") != extension.form or form.get("catalog_revision") != extension.revision or entry.evolutions.back() != expected_edge: return false
		for field in ["secondary_natures", "trait_values"]:
			if not projection.get(field) is Array or projection[field].size() != entry.forms.size(): return false
		if projection.secondary_natures.back() != form.get("secondary_nature") or projection.trait_values.back() != form.get("trait_value"): return false
		entry.forms.pop_back()
		entry.evolutions.pop_back()
		projection.secondary_natures.pop_back()
		projection.trait_values.pop_back()
	return additive(old, historical)

# A historical identity cannot legitimately contain definitions introduced later.
static func source_state_valid(snapshot: Dictionary) -> bool:
	if snapshot.get("identity") == Identity.current(): return true
	if not snapshot.get("identity") in [BASE_IDENTITY, PREVIOUS_IDENTITY, RULES3_IDENTITY, CATALOG1_IDENTITY] or not snapshot.get("battle") is Dictionary: return false
	var catalog1: bool = snapshot.identity == CATALOG1_IDENTITY
	var source: Dictionary = Catalog1.DATA if catalog1 else (Previous.DATA if snapshot.identity in [PREVIOUS_IDENTITY, RULES3_IDENTITY] else Baseline.DATA)
	var catalog_revision: Variant = snapshot.get("catalog_revision") if catalog1 else snapshot.get("catalog_revision", 0)
	if not (catalog_revision is int or catalog_revision is float): return false
	if catalog_revision != 0 and (not catalog1 or catalog_revision != 1): return false
	# Rules 2 cannot contain the new room or opt into its choices via migration.
	if snapshot.identity in [RULES3_IDENTITY, CATALOG1_IDENTITY]:
		var revision: Variant = snapshot.get("event_revision")
		if not (revision is int or revision is float) or (revision != 0 and revision != 1): return false
	elif snapshot.get("phase") == "event" or snapshot.get("event_revision", 0) != 0: return false
	var battle: Dictionary = snapshot.battle
	if not battle.get("starter_species") in source.extras.starters: return false
	if not battle.get("inventory") is Dictionary: return false
	for id in battle.inventory:
		if not source.extras.consumables.has(id): return false
	for group in ["party", "enemies"]:
		if not battle.get(group) is Array: return false
		for unit in battle[group]:
			if not _source_unit(unit, source, int(catalog_revision)): return false
	for offer in battle.get("reward_offers", []):
		if not offer is Dictionary: return false
		if offer.get("kind") == "capture" and not _source_unit(offer.get("umbral"), source, int(catalog_revision)): return false
		if offer.get("kind") == "evolve" and not _source_evolution(offer, battle.party, source, int(catalog_revision)): return false
	for zone in ["hand", "deck", "discard_pile"]:
		if not battle.get(zone) is Array: return false
		for card in battle[zone]:
			if not _source_card(card, source): return false
	if not battle.get("suspended_cards") is Dictionary: return false
	for zone in battle.suspended_cards.values():
		if not zone is Dictionary or not zone.get("deck") is Array or not zone.get("discard") is Array: return false
		for card in zone.deck + zone.discard:
			if not _source_card(card, source): return false
	return true

static func _source_unit(unit: Variant, source: Dictionary, catalog_revision: int) -> bool:
	if not unit is Dictionary or not source.species.has(unit.get("species")): return false
	var form_found: bool = false
	for form in source.catalog[unit.species].forms:
		if form.id == unit.get("form_id") and int(form.get("catalog_revision", 0)) <= catalog_revision: form_found = true
	if not form_found: return false
	if not unit.get("passive") is String or (not unit.passive.is_empty() and not source.passives.has(unit.passive)): return false
	if not unit.get("known_powers") is Array or not unit.get("cards") is Array: return false
	for power in unit.known_powers:
		if not source.powers.has(power): return false
	for card in unit.cards:
		if not _source_card(card, source): return false
	return true

static func _source_card(card: Variant, source: Dictionary) -> bool:
	return card is Dictionary and source.powers.has(card.get("power"))

static func _source_evolution(offer: Dictionary, party: Array, source: Dictionary, catalog_revision: int) -> bool:
	for unit in party:
		if unit.get("uid") != offer.get("uid"): continue
		for edge in source.catalog[unit.species].evolutions:
			if int(edge.get("catalog_revision", 0)) <= catalog_revision and edge.get("from") == unit.get("form_id") and edge.get("id") == offer.get("transition_id") and edge.get("from") == offer.get("source_form_id") and edge.get("to") == offer.get("target_form_id"): return true
	return false
