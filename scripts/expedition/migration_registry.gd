extends RefCounted
## Ordered, audited source identities. Each edge must preserve existing behavior.
const Identity = preload("res://scripts/expedition/identity.gd")
const Baseline = preload("res://scripts/expedition/baseline_manifest.gd")
const BASE_IDENTITY = {"ruleset": "expedition-rules-2", "content_sha256": "022bb34bd69d87cace6a96eb130260f812133c318381a5bcd77fa0d981efca58"}

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
	if source != BASE_IDENTITY or Identity.RULESET != BASE_IDENTITY.ruleset: return false
	if JSON.stringify(Baseline.DATA).sha256_text() != BASE_IDENTITY.content_sha256: return false
	var adapted: Dictionary = Baseline.DATA.duplicate(true)
	adapted["manifest_version"] = 2
	adapted["item_effects"] = {"potion": "heal", "revive": "revive"}
	return additive(adapted, Identity.manifest())

# A historical identity cannot legitimately contain definitions introduced later.
static func source_state_valid(snapshot: Dictionary) -> bool:
	if snapshot.get("identity") == Identity.current(): return true
	if snapshot.get("identity") != BASE_IDENTITY or not snapshot.get("battle") is Dictionary: return false
	var battle: Dictionary = snapshot.battle
	if not battle.get("starter_species") in Baseline.DATA.extras.starters: return false
	if not battle.get("inventory") is Dictionary: return false
	for id in battle.inventory:
		if not Baseline.DATA.extras.consumables.has(id): return false
	for group in ["party", "enemies"]:
		if not battle.get(group) is Array: return false
		for unit in battle[group]:
			if not _source_unit(unit): return false
	for offer in battle.get("reward_offers", []):
		if not offer is Dictionary: return false
		if offer.get("kind") == "capture" and not _source_unit(offer.get("umbral")): return false
		if offer.get("kind") == "evolve" and not _source_evolution(offer, battle.party): return false
	for zone in ["hand", "deck", "discard_pile"]:
		if not battle.get(zone) is Array: return false
		for card in battle[zone]:
			if not _source_card(card): return false
	if not battle.get("suspended_cards") is Dictionary: return false
	for zone in battle.suspended_cards.values():
		if not zone is Dictionary or not zone.get("deck") is Array or not zone.get("discard") is Array: return false
		for card in zone.deck + zone.discard:
			if not _source_card(card): return false
	return true

static func _source_unit(unit: Variant) -> bool:
	if not unit is Dictionary or not Baseline.DATA.species.has(unit.get("species")): return false
	var form_found: bool = false
	for form in Baseline.DATA.catalog[unit.species].forms:
		if form.id == unit.get("form_id"): form_found = true
	if not form_found: return false
	if not unit.get("passive") is String or (not unit.passive.is_empty() and not Baseline.DATA.passives.has(unit.passive)): return false
	if not unit.get("known_powers") is Array or not unit.get("cards") is Array: return false
	for power in unit.known_powers:
		if not Baseline.DATA.powers.has(power): return false
	for card in unit.cards:
		if not _source_card(card): return false
	return true

static func _source_card(card: Variant) -> bool:
	return card is Dictionary and Baseline.DATA.powers.has(card.get("power"))

static func _source_evolution(offer: Dictionary, party: Array) -> bool:
	for unit in party:
		if unit.get("uid") != offer.get("uid"): continue
		for edge in Baseline.DATA.catalog[unit.species].evolutions:
			if edge.get("id") == offer.get("transition_id") and edge.get("from") == offer.get("source_form_id") and edge.get("to") == offer.get("target_form_id"): return true
	return false
