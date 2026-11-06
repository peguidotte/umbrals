extends RefCounted
## Ordered, audited source identities. Each edge must preserve existing behavior.
const Identity = preload("res://scripts/expedition/identity.gd")
const Baseline = preload("res://scripts/expedition/baseline_manifest.gd")
const Previous = preload("res://scripts/expedition/rules2_manifest.gd")
const CatalogRevision = preload("res://scripts/battle/catalog_revision.gd")
const Electric3 = preload("res://scripts/expedition/electric3_manifest.gd")
const Aquatic5 = preload("res://scripts/expedition/aquatic5_manifest.gd")
const AQUATIC5_IDENTITY = {"ruleset": "expedition-rules-4", "content_sha256": "cdefbb7c0dfe65b32aecb1ba32f08a60c941a6287638959381b8e5ae8c516d50"}
const Combined4 = preload("res://scripts/expedition/combined4_manifest.gd")
const COMBINED4_IDENTITY = {"ruleset": "expedition-rules-4", "content_sha256": "28b326e20a544fd37abc3958a6efabdf5714cfca1b59d8cfe6b1898e71b09221"}
const AQUATIC_EXTENSIONS = [{"species": "dew", "form": "londraval", "edge": "mareveu_to_londraval", "from": "mareveu", "revision": 5}, {"species": "dew", "form": "lonelo", "edge": "mareveu_to_lonelo", "from": "mareveu", "revision": 5}]
const Grass2 = preload("res://scripts/expedition/grass2_manifest.gd")
const ELECTRIC3_IDENTITY = {"ruleset": "expedition-rules-3", "content_sha256": "90f86d297508c87095608b229e3aa2201bcffca022a8813bc9ddbd7e0657b1e4"}
const GRASS2_IDENTITY = {"ruleset": "expedition-rules-4", "content_sha256": "adb2e79ba0b52d2b9fe9e2fa9299f2c3e425017199f6f8086263cef2bb02d418"}
const Catalog1 = preload("res://scripts/expedition/catalog1_manifest.gd")
const CATALOG1_IDENTITY = {"ruleset": "expedition-rules-4", "content_sha256": "07942959b491e5c9466c7133b0a4b1809283f9aee7162d405af6ff31aa278442"}
const RULES3_IDENTITY = {"ruleset": "expedition-rules-3", "content_sha256": "7df20eb40243b3b48a76c0ddee5eaa46321984f49612f36a59684e75cb673e80"}
const ELECTRIC_SOURCE_IDENTITY = RULES3_IDENTITY
const PREVIOUS_IDENTITY = {"ruleset": "expedition-rules-2", "content_sha256": "7df20eb40243b3b48a76c0ddee5eaa46321984f49612f36a59684e75cb673e80"}
const BASE_IDENTITY = {"ruleset": "expedition-rules-2", "content_sha256": "022bb34bd69d87cace6a96eb130260f812133c318381a5bcd77fa0d981efca58"}
const GRASS_EXTENSIONS = [{"species": "moss", "form": "foslash", "edge": "verdalio_to_foslash", "from": "verdalio", "revision": 1}, {"species": "moss", "form": "folivel", "edge": "verdalio_to_folivel", "from": "verdalio", "revision": 2}]

const ELECTRIC_EXTENSIONS = [{"species": "volt", "form": "auravel", "edge": "tempestral_to_auravel", "from": "tempestral", "revision": 3, "deferred": true}, {"species": "volt", "form": "zuldar", "edge": "tempestral_to_zuldar", "from": "tempestral", "revision": 3, "deferred": true}]

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

static func lineage_extension(old: Dictionary, target: Dictionary) -> bool:
	if not old.get("catalog") is Dictionary or not target.get("catalog") is Dictionary: return false
	var collapsed: Dictionary = target.duplicate(true)
	for id in old.catalog:
		if not target.catalog.has(id): return false
		var before: Dictionary = old.catalog[id]
		var after: Dictionary = target.catalog[id]
		if not before.get("forms") is Array or not after.get("forms") is Array: return false
		if not before.get("evolutions") is Array or not after.get("evolutions") is Array: return false
		if not _prefix(before.forms, after.forms) or not _prefix(before.evolutions, after.evolutions): return false
		var new_forms: Array = after.forms.slice(before.forms.size()).map(func(form: Dictionary) -> String: return str(form.id))
		for edge in after.evolutions.slice(before.evolutions.size()):
			if edge.get("deferred") != true or not edge.get("to") in new_forms: return false
		collapsed.catalog[id].forms = before.forms.duplicate(true)
		collapsed.catalog[id].evolutions = before.evolutions.duplicate(true)
		# The compatibility species projection also stores these per-form arrays.
		if not old.species.has(id) or not target.species.has(id): return false
		for key in ["secondary_natures", "trait_values"]:
			if not old.species[id].get(key) is Array or not target.species[id].get(key) is Array: return false
			if target.species[id][key].size() != after.forms.size() or not _prefix(old.species[id][key], target.species[id][key]): return false
			collapsed.species[id][key] = old.species[id][key].duplicate(true)
	return additive(old, collapsed)

static func supports(source: Variant) -> bool:
	if source == Identity.current(): return true
	if Identity.RULESET != "expedition-rules-5": return false
	if source == AQUATIC5_IDENTITY:
		return JSON.stringify(Aquatic5.DATA).sha256_text() == source.content_sha256 and additive(Aquatic5.DATA, Identity.manifest())
	if source == COMBINED4_IDENTITY:
		return JSON.stringify(Combined4.DATA).sha256_text() == source.content_sha256 and catalog_transition(Combined4.DATA, Identity.manifest(), 4)
	if source == ELECTRIC3_IDENTITY:
		return JSON.stringify(Electric3.DATA).sha256_text() == source.content_sha256 and lineage_extension(Previous.DATA, Electric3.DATA) and catalog_transition(Electric3.DATA, Identity.manifest(), 3)
	if source == GRASS2_IDENTITY:
		return JSON.stringify(Grass2.DATA).sha256_text() == source.content_sha256 and catalog_transition(Grass2.DATA, Identity.manifest(), 2)
	if source == CATALOG1_IDENTITY:
		return JSON.stringify(Catalog1.DATA).sha256_text() == source.content_sha256 and catalog_transition(Catalog1.DATA, Identity.manifest(), 1)
	if source in [PREVIOUS_IDENTITY, RULES3_IDENTITY]:
		return JSON.stringify(Previous.DATA).sha256_text() == source.content_sha256 and catalog_transition(Previous.DATA, Identity.manifest())
	if source != BASE_IDENTITY: return false
	if JSON.stringify(Baseline.DATA).sha256_text() != BASE_IDENTITY.content_sha256: return false
	var adapted: Dictionary = Baseline.DATA.duplicate(true)
	adapted["manifest_version"] = 2
	adapted["item_effects"] = {"potion": "heal", "revive": "revive"}
	return catalog_transition(adapted, Identity.manifest())

static func revision_for(snapshot: Dictionary) -> int:
	if snapshot.identity == ELECTRIC3_IDENTITY: return 3
	return int(snapshot.get("catalog_revision", 0))

# Exact per-source projections; existing comparator still audits every field.
static func catalog_transition(old: Dictionary, target: Dictionary, source_revision: int = 0) -> bool:
	if source_revision not in [0, 1, 2, 3, 4]: return false
	var historical: Dictionary = target.duplicate(true)
	var extensions: Array = GRASS_EXTENSIONS + ELECTRIC_EXTENSIONS + AQUATIC_EXTENSIONS
	for extension_index: int in range(extensions.size() - 1, -1, -1):
		var extension: Dictionary = extensions[extension_index]
		if not historical.get("catalog") is Dictionary or not historical.get("species") is Dictionary or not historical.catalog.has(extension.species) or not historical.species.has(extension.species): return false
		if CatalogRevision.includes(source_revision, int(extension.revision)):
			# The reviewed rules3 electric release predates only this gate metadata.
			if extension.revision == 3 and source_revision == 3:
				var found_form: bool = false
				var found_edge: bool = false
				for form: Dictionary in historical.catalog[extension.species].forms:
					if form.id == extension.form and form.get("catalog_revision") == 3:
						form.erase("catalog_revision")
						found_form = true
				for edge: Dictionary in historical.catalog[extension.species].evolutions:
					if edge.id == extension.edge and edge.get("catalog_revision") == 3:
						edge.erase("catalog_revision")
						found_edge = true
				if not found_form or not found_edge: return false
			continue
		if not historical.get("catalog") is Dictionary or not historical.catalog.has(extension.species) or not historical.get("species") is Dictionary or not historical.species.has(extension.species): return false
		var entry: Dictionary = historical.catalog[extension.species]
		var projection: Dictionary = historical.species[extension.species]
		if not entry.get("forms") is Array or not entry.get("evolutions") is Array or entry.forms.is_empty() or entry.evolutions.is_empty(): return false
		var form: Dictionary = entry.forms.back()
		var expected_edge: Dictionary = {"id": extension.edge, "from": extension.from, "to": extension.form, "catalog_revision": extension.revision}
		if extension.get("deferred", false): expected_edge.deferred = true
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
	if snapshot.get("identity") == Identity.current():
		var current_revision: Variant = snapshot.get("catalog_revision")
		return (current_revision is int or current_revision is float) and is_finite(float(current_revision)) and current_revision == floor(float(current_revision)) and CatalogRevision.supported(int(current_revision))
	if not snapshot.get("identity") in [BASE_IDENTITY, PREVIOUS_IDENTITY, RULES3_IDENTITY, CATALOG1_IDENTITY, GRASS2_IDENTITY, ELECTRIC3_IDENTITY, COMBINED4_IDENTITY, AQUATIC5_IDENTITY] or not snapshot.get("battle") is Dictionary: return false
	var source: Dictionary = Baseline.DATA
	var allowed: Array = [0]
	if snapshot.identity == AQUATIC5_IDENTITY:
		source = Aquatic5.DATA
		allowed = [0, 1, 2, 3, 4, 5]
	elif snapshot.identity == COMBINED4_IDENTITY:
		source = Combined4.DATA
		allowed = [0, 1, 2, 3, 4]
	elif snapshot.identity == ELECTRIC3_IDENTITY:
		source = Electric3.DATA
		allowed = [3]
	elif snapshot.identity == GRASS2_IDENTITY:
		source = Grass2.DATA
		allowed = [0, 1, 2]
	elif snapshot.identity == CATALOG1_IDENTITY:
		source = Catalog1.DATA
		allowed = [0, 1]
	elif snapshot.identity in [RULES3_IDENTITY, PREVIOUS_IDENTITY]: source = Previous.DATA
	if snapshot.identity in [CATALOG1_IDENTITY, GRASS2_IDENTITY, COMBINED4_IDENTITY, AQUATIC5_IDENTITY] and not snapshot.has("catalog_revision"): return false
	var catalog_revision: Variant = snapshot.get("catalog_revision", 3 if snapshot.identity == ELECTRIC3_IDENTITY else 0)
	if not (catalog_revision is int or catalog_revision is float) or not is_finite(float(catalog_revision)) or catalog_revision != floor(float(catalog_revision)) or not int(catalog_revision) in allowed: return false
	if snapshot.identity.ruleset in ["expedition-rules-3", "expedition-rules-4"]:
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
		if form.id == unit.get("form_id") and CatalogRevision.includes(catalog_revision, int(form.get("catalog_revision", 0))): form_found = true
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
			if CatalogRevision.includes(catalog_revision, int(edge.get("catalog_revision", 0))) and edge.get("from") == unit.get("form_id") and edge.get("id") == offer.get("transition_id") and edge.get("from") == offer.get("source_form_id") and edge.get("to") == offer.get("target_form_id"): return true
	return false
