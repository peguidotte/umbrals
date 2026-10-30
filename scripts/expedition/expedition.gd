class_name Expedition
extends RefCounted

const Rules = preload("res://scripts/rules.gd")
const Content = preload("res://scripts/content.gd")
const Conditions = preload("res://scripts/battle/conditions.gd")
const IDS = ["clearing", "thicket", "spring", "boss"]
const TITLES = ["Clareira", "Mata fechada", "Nascente", "Guardião"]
const KINDS = ["battle", "battle", "rest", "boss"]
const DESCRIPTIONS = ["Um primeiro encontro no bosque.", "Enfrente outro encontro e escolha uma recompensa.", "Cure 25% do HP máximo dos aliados vivos.", "Enfrente o guardião do bosque."]
const NEXT = [["thicket", "spring"], ["boss"], ["boss"], []]
const BATTLE_FIELDS = ["seed_value", "starter_species", "encounter", "round_number", "encounter_rounds_resolved", "phase", "party", "enemies", "hand", "deck", "discard_pile", "suspended_cards", "declined_replacements", "inventory", "relics", "hand_size_modifier", "action_modifier", "enemy_plan", "information_mode", "pending_information_mode", "reward_offers", "next_uid", "total_damage", "actions", "last_result"]

var battle = Rules.new()
var phase: String = "map"
var current_node_id: String = ""
var completed: Array = []

func new_run(seed: int, mode: String = "partial", starter: String = "ember") -> void:
	battle = Rules.new()
	battle.enable_expedition()
	battle.new_run(seed, mode, starter)
	phase = "map"
	current_node_id = ""
	completed = []

func _available(id: String) -> bool:
	if phase != "map" or id in completed: return false
	if id == "clearing": return completed.is_empty()
	if id in ["thicket", "spring"]: return "clearing" in completed and not ("thicket" in completed or "spring" in completed)
	if id == "boss": return ("thicket" in completed or "spring" in completed) and not "boss" in completed
	return false

func public_state() -> Dictionary:
	var nodes: Array = []
	for i in range(IDS.size()):
		var available: bool = _available(IDS[i])
		nodes.append({"id": IDS[i], "title": TITLES[i], "kind": KINDS[i], "description": DESCRIPTIONS[i], "available": available, "completed": IDS[i] in completed, "locked": not available and not IDS[i] in completed, "encounter_id": IDS[i] if IDS[i] != "spring" else "", "next": NEXT[i].duplicate()})
	return {"phase": phase, "seed": str(battle.seed_value), "biome": "Bosque", "current_node_id": current_node_id, "nodes": nodes, "party": battle.party.duplicate(true), "inventory": battle.inventory.duplicate(true)}

func choose_node(id: String) -> bool:
	if not _available(id): return false
	if id == "spring":
		current_node_id = id
		for individual in battle.party:
			if int(individual.hp) > 0:
				individual.hp = mini(int(individual.max_hp), int(individual.hp) + ceili(float(individual.max_hp) * 0.25))
		battle._sync_compatibility()
		completed.append(id)
		return true
	if not battle.start_route_encounter(id): return false
	current_node_id = id
	phase = "combat"
	return true

func settle_battle() -> void:
	if phase != "combat": return
	if battle.phase == "reward": phase = "reward"
	elif battle.phase == "victory":
		phase = "victory"
		completed.append(current_node_id)
	elif battle.phase == "defeat": phase = "defeat"

func choose_reward(index: int, replace_uid: int = -1, capture_slot: int = -2) -> bool:
	if phase != "reward" or not battle.choose_reward(index, replace_uid, capture_slot): return false
	completed.append(current_node_id)
	phase = "map"
	return true

func snapshot() -> Dictionary:
	var state: Dictionary = {}
	for field in BATTLE_FIELDS:
		var value: Variant = battle.get(field)
		state[field] = value.duplicate(true) if value is Array or value is Dictionary else value
	state["seed_value"] = str(battle.seed_value)
	state["rng_seed"] = str(battle.rng.seed)
	state["rng_state"] = str(battle.rng.state)
	return {"schema": 1, "phase": phase, "current_node_id": current_node_id, "completed": completed.duplicate(), "battle": state}

# Validation is performed on a detached candidate before touching the live run.
func restore(data: Dictionary) -> bool:
	var normalized: Dictionary = _normalize_json(data)
	if not _valid_snapshot(normalized): return false
	data = normalized
	var s: Dictionary = data.battle
	var candidate = Rules.new()
	candidate.enable_expedition()
	candidate.seed_value = int(s.seed_value)
	candidate.starter_species = s.starter_species
	candidate.encounter = int(s.encounter)
	candidate.round_number = int(s.round_number)
	candidate.encounter_rounds_resolved = int(s.encounter_rounds_resolved)
	candidate.phase = s.phase
	candidate.party = s.party.duplicate(true)
	candidate.enemies = s.enemies.duplicate(true)
	candidate.hand = s.hand.duplicate(true)
	candidate.deck = s.deck.duplicate(true)
	candidate.discard_pile = s.discard_pile.duplicate(true)
	candidate.suspended_cards = _int_keys(s.suspended_cards)
	candidate.declined_replacements = _int_keys(s.declined_replacements)
	candidate.inventory = s.inventory.duplicate(true)
	candidate.relics = s.relics.duplicate(true)
	candidate.hand_size_modifier = int(s.hand_size_modifier)
	candidate.action_modifier = int(s.action_modifier)
	candidate.enemy_plan = s.enemy_plan.duplicate(true)
	candidate.information_mode = s.information_mode
	candidate.pending_information_mode = s.pending_information_mode
	candidate.reward_offers = s.reward_offers.duplicate(true)
	candidate.next_uid = int(s.next_uid)
	candidate.total_damage = int(s.total_damage)
	candidate.actions = int(s.actions)
	candidate.last_result = s.last_result.duplicate(true)
	candidate.rng.seed = int(s.rng_seed)
	candidate.rng.state = int(s.rng_state)
	candidate._sync_compatibility()
	battle = candidate
	phase = data.phase
	current_node_id = data.current_node_id
	completed = data.completed.duplicate()
	return true

func _normalize_json(value: Variant) -> Variant:
	if value is float and is_finite(value) and value == floor(value) and abs(value) < 9007199254740992.0: return int(value)
	if value is Array:
		var array: Array = []
		for item in value: array.append(_normalize_json(item))
		return array
	if value is Dictionary:
		var dict: Dictionary = {}
		for key in value: dict[key] = _normalize_json(value[key])
		return dict
	return value

func _int_keys(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in source: result[int(key)] = source[key].duplicate(true) if source[key] is Dictionary or source[key] is Array else source[key]
	return result

func _valid_snapshot(data: Dictionary) -> bool:
	if data.get("schema") != 1 or not data.get("battle") is Dictionary or not data.get("completed") is Array: return false
	if data.has("checkpoint_id") and not data.checkpoint_id is String: return false
	if not data.get("phase") in ["map", "combat", "reward", "victory", "defeat"] or not data.get("current_node_id") is String: return false
	var current: String = data.current_node_id
	if current != "" and not current in IDS: return false
	var done: Array = data.completed
	if done.size() != done.duplicate().reduce(func(acc, x): return acc if x in acc else acc + [x], []).size(): return false
	for id in done:
		if not id is String or not id in IDS: return false
	if ("thicket" in done and "spring" in done) or (done.size() > 0 and done[0] != "clearing"): return false
	if "boss" in done and not ("thicket" in done or "spring" in done): return false
	if done.size() > 1 and not done[1] in ["thicket", "spring"]: return false
	if done.size() > 2 and (done.size() != 3 or done[2] != "boss"): return false
	if data.phase == "map" and ((done.is_empty() and current != "") or (not done.is_empty() and current != done.back())): return false
	if data.phase != "map" and (current == "" or current in done):
		if not (data.phase == "victory" and current == "boss" and current in done): return false
	if current in ["thicket", "spring"] and not "clearing" in done: return false
	if current == "boss" and not ("thicket" in done or "spring" in done): return false
	var s: Dictionary = data.battle
	for field in BATTLE_FIELDS:
		if not s.has(field): return false
	for field in ["seed_value", "rng_seed", "rng_state"]:
		if not s.get(field) is String or not s[field].is_valid_int(): return false
	for field in ["encounter", "round_number", "encounter_rounds_resolved", "hand_size_modifier", "action_modifier", "next_uid", "total_damage", "actions"]:
		if not s[field] is int: return false
	for field in ["party", "enemies", "hand", "deck", "discard_pile", "relics", "enemy_plan", "reward_offers"]:
		if not s[field] is Array: return false
	for field in ["suspended_cards", "declined_replacements", "inventory", "last_result"]:
		if not s[field] is Dictionary: return false
	if not s.starter_species is String or not s.information_mode is String or not s.pending_information_mode is String or not s.phase is String: return false
	if not s.starter_species in Content.STARTERS or not s.information_mode in ["hidden", "partial", "full"] or not s.pending_information_mode in ["hidden", "partial", "full"]: return false
	if int(s.seed_value) != int(s.rng_seed): return false
	if data.phase != "map" and s.encounter != Rules.encounter_index(current): return false
	if s.encounter < 0 or s.encounter > 2 or s.round_number < 1 or s.next_uid < 2 or s.party.is_empty() or s.party.size() > 6 or s.enemies.size() > 3: return false
	if data.phase == "map" and s.phase != "map": return false
	if data.phase == "combat" and (not s.phase in ["battle", "replacement", "reward", "victory", "defeat"] or not current in ["clearing", "thicket", "boss"]): return false
	if data.phase in ["reward", "victory", "defeat"] and s.phase != data.phase: return false
	var uids: Array = []
	var slots: Array = []
	for unit in s.party:
		if not _valid_unit(unit) or unit.uid in uids or (unit.slot >= 0 and unit.slot in slots): return false
		uids.append(unit.uid)
		if unit.uid >= s.next_uid: return false
		if unit.slot >= 0: slots.append(unit.slot)
	var enemy_uids: Array = []
	var enemy_slots: Array = []
	for unit in s.enemies:
		if not _valid_unit(unit): return false
		if unit.uid in enemy_uids or unit.slot < 0 or unit.slot in enemy_slots: return false
		enemy_uids.append(unit.uid)
		enemy_slots.append(unit.slot)
	for key in s.inventory:
		if not key in Content.STARTING_ITEMS or not s.inventory[key] is int or s.inventory[key] < 0: return false
	var suspended_uids: Array = []
	for key in s.suspended_cards:
		if not str(key).is_valid_int() or not int(key) in uids or not s.suspended_cards[key] is Dictionary: return false
		if int(key) in suspended_uids: return false
		suspended_uids.append(int(key))
		var zone: Dictionary = s.suspended_cards[key]
		if not zone.get("deck") is Array or not zone.get("discard") is Array or not zone.get("entered") is bool: return false
		for card in zone.deck + zone.discard:
			if not card is Dictionary or not card.get("owner") is int or card.owner != int(key): return false
	for key in s.declined_replacements:
		if not str(key).is_valid_int() or not int(key) in uids or not s.declined_replacements[key] is bool: return false
	var canonical: Dictionary = {}
	for unit in s.party:
		for card in unit.cards:
			if not _valid_card(card, uids) or card.owner != unit.uid or canonical.has(card.instance_id): return false
			canonical[card.instance_id] = {"owner": card.owner, "power": card.power}
	var cards: Array = s.hand + s.deck + s.discard_pile
	for zone in s.suspended_cards.values(): cards += zone.deck + zone.discard
	var card_ids: Dictionary = {}
	for card in cards:
		if not _valid_card(card, uids) or card_ids.has(card.instance_id) or not canonical.has(card.instance_id): return false
		if canonical[card.instance_id] != {"owner": card.owner, "power": card.power}: return false
		card_ids[card.instance_id] = true
	if data.phase == "map":
		if not cards.is_empty(): return false
	elif card_ids.size() != canonical.size(): return false
	for entry in s.enemy_plan:
		if not entry is Dictionary or not entry.get("actor_uid") is int or not entry.actor_uid in enemy_uids: return false
		if not entry.get("category") in ["attack", "defend", "support", "prepare"] or not entry.get("target_slot") is int or entry.target_slot < 0 or entry.target_slot > 2: return false
		for key in ["damage", "block", "heal", "wet", "priority", "actor_slot"]:
			if not entry.get(key) is int: return false
	for offer in s.reward_offers:
		if not offer is Dictionary or not offer.get("kind") in ["capture", "evolve"]: return false
		if offer.kind == "capture":
			if not _valid_unit(offer.get("umbral")): return false
			if offer.umbral.uid != s.next_uid or offer.umbral.uid in uids: return false
			var offer_ids: Array = []
			for card in offer.umbral.cards:
				if not _valid_card(card, [offer.umbral.uid]) or card.instance_id in offer_ids: return false
				offer_ids.append(card.instance_id)
		if offer.kind == "evolve" and (not offer.get("uid") is int or not offer.uid in uids): return false
	return true

func _valid_unit(unit: Variant) -> bool:
	if not unit is Dictionary: return false
	for key in ["uid", "stage", "slot", "hp", "max_hp", "attack", "defense", "speed", "block", "can_act_round"]:
		if not unit.get(key) is int: return false
	if not unit.get("species") is String or not unit.species in Content.SPECIES or not unit.get("passive") is String: return false
	if unit.uid < 1 or unit.stage < 1 or unit.stage > 2 or unit.slot < -1 or unit.slot > 2 or unit.max_hp < 1 or unit.hp < 0 or unit.hp > unit.max_hp: return false
	if not unit.get("statuses") is Dictionary or not unit.get("status_sources") is Dictionary or not unit.get("known_powers") is Array or not unit.get("cards") is Array: return false
	for power in unit.known_powers:
		if not power is String or not power in Content.POWERS: return false
	for status in unit.statuses:
		if not status is String or not status in Conditions.DEFINITIONS or not unit.statuses[status] is int or unit.statuses[status] < 0: return false
	for status in unit.status_sources:
		if not status is String or not status in Conditions.DEFINITIONS or not unit.status_sources[status] is Dictionary: return false
		var source: Dictionary = unit.status_sources[status]
		if not source.is_empty() and (not source.get("uid") is int or not source.get("side") is String or not source.side in ["ally", "enemy"]): return false
	if unit.has("resistances"):
		if not unit.resistances is Dictionary: return false
		for nature in unit.resistances:
			if not nature is String or not nature in ["fire", "water", "forest", "lightning"]: return false
			if not unit.resistances[nature] is int or unit.resistances[nature] < 0 or unit.resistances[nature] > 100: return false
	return true

func _valid_card(card: Variant, uids: Array) -> bool:
	if not card is Dictionary or not card.get("instance_id") is String or card.instance_id.is_empty(): return false
	if not card.get("owner") is int or not card.owner in uids or not card.get("power") is String or not card.power in Content.POWERS: return false
	if card.has("target_slot") and (not card.target_slot is int or card.target_slot < 0 or card.target_slot > 2): return false
	return true
