extends RefCounted
## Schema 1 is the only supported legacy checkpoint. Never mutates its input.
const Content = preload("res://scripts/content.gd")
const Identity = preload("res://scripts/expedition/identity.gd")
# This adapter was validated against this precise ruleset and gameplay catalog.
# A changed target needs an explicit migration and review before changing this pin.
const LEGACY_TARGET = {"ruleset": "expedition-rules-2", "content_sha256": "022bb34bd69d87cace6a96eb130260f812133c318381a5bcd77fa0d981efca58"}

static func supported_legacy_target(identity: Dictionary) -> bool:
	return identity == LEGACY_TARGET

static func checkpoint(input: Dictionary) -> Dictionary:
	var result: Dictionary = input.duplicate(true)
	if result.get("schema") == 2:
		return result if Identity.matches(result.get("identity")) else {}
	if result.get("schema") != 1 or not result.get("battle") is Dictionary or not supported_legacy_target(Identity.current()): return {}
	var battle: Dictionary = result.battle
	for group in ["party", "enemies"]:
		if not battle.get(group) is Array: return {}
		for unit in battle[group]:
			if not _unit(unit): return {}
	if not battle.get("reward_offers") is Array: return {}
	for offer in battle.reward_offers:
		if not offer is Dictionary: return {}
		if offer.get("kind") == "capture":
			if not _unit(offer.get("umbral")): return {}
		elif offer.get("kind") == "evolve":
			var owner: Dictionary = {}
			for unit in battle.party:
				if unit.get("uid") == offer.get("uid"): owner = unit
			if owner.is_empty(): return {}
			var edges: Array = Content.evolution_edges(owner)
			if edges.size() != 1: return {}
			offer["source_form_id"] = edges[0].from
			offer["target_form_id"] = edges[0].to
			offer["transition_id"] = edges[0].id
	result.schema = 2
	result["identity"] = Identity.current()
	return result

static func _unit(unit: Variant) -> bool:
	if not unit is Dictionary or not unit.get("species") is String: return false
	var stage: Variant = unit.get("stage")
	if not (stage is int or stage is float) or stage != floor(stage): return false
	var id: String = Content.legacy_form(unit.species, int(stage))
	if id.is_empty(): return false
	unit["form_id"] = id
	unit.erase("stage")
	return true
