class_name UmbralRules
extends RefCounted
## Pure deterministic combat. Preview never samples RNG or resolves enemy plans.
signal state_changed(kind: String)

const Content = preload("res://scripts/content.gd")
const Targeting = preload("res://scripts/battle/targeting.gd")
const Initiative = preload("res://scripts/battle/initiative.gd")
const Conditions = preload("res://scripts/battle/conditions.gd")
const Reactions = preload("res://scripts/battle/reactions.gd")
const EnemyPlanner = preload("res://scripts/battle/enemy_planner.gd")
const ENERGY = 3 # Compatibility name; the single execution resource is actions.
const HAND_SIZE = 6
const MAX_SELECTED = 64 # No per-owner or three-card cap; actions limit the cast.
const ROUND_BUDGET = 0 # Deprecated. Encounters have no arbitrary turn limit.
const MAX_TEAM = 6
const MAX_ACTIVE = 3

var rng = RandomNumberGenerator.new()
var seed_value: int = 0
var starter_species: String = "ember"
var encounter: int = 0
var round_number: int = 1
var encounter_rounds_resolved: int = 0
var phase: String = "battle"
var party: Array = []
var enemies: Array = []
var hand: Array = []
var deck: Array = []
var discard_pile: Array = []
var suspended_cards: Dictionary = {}
var selected: Array[int] = []
var queued_swaps: Array = []
var queued_items: Array = []
var declined_replacements: Dictionary = {}
var inventory: Dictionary = Content.STARTING_ITEMS.duplicate()
var relics: Array = []
var hand_size_modifier: int = 0
var action_modifier: int = 0
var enemy_plan: Array = []
var information_mode: String = "partial"
var pending_information_mode: String = "partial"
var reward_offers: Array = []
var next_uid: int = 2
var total_damage: int = 0
var actions: int = 0 # Total committed rounds, retained for run statistics.
var last_result: Dictionary = {}
var expedition_mode: bool = false
# Read-only compatibility aggregates for previous presentation/statistics callers.
var max_hp: int = 40
var player_hp: int = 40
var enemy_hp: int = 0
var enemy_burn: int = 0
var plays: int = 0
var discards: int = -1

static func make_umbral(species: String, passive: String, uid: int, stage: int = 1) -> Dictionary:
	var individual: Dictionary = {"uid": uid, "species": species, "passive": passive, "stage": stage, "slot": -1, "block": 0, "statuses": {}, "status_sources": {}, "can_act_round": 1}
	var stats: Dictionary = _species_stats(individual)
	for key in ["max_hp", "attack", "defense", "speed"]:
		individual[key] = int(stats[key])
	individual.hp = individual.max_hp
	individual.known_powers = Content.SPECIES[species].powers.duplicate()
	individual.cards = []
	for power_id in individual.known_powers:
		for copy_number in range(Content.INITIAL_POWER_COPIES):
			individual.cards.append({"instance_id": "%d:%s:%d" % [uid, power_id, copy_number], "owner": uid, "power": power_id})
	return individual

static func _species_stats(individual: Dictionary) -> Dictionary:
	return Content.species_stats(individual)

func new_run(run_seed: int, mode: String = "partial", starter: String = "ember") -> void:
	seed_value = run_seed
	rng.seed = run_seed
	encounter = 0
	next_uid = 2
	var species: String = starter if starter in Content.STARTERS else "ember"
	starter_species = species
	party = [make_umbral(species, _roll_passive(species), 1)]
	party[0].slot = 1
	total_damage = 0
	actions = 0
	last_result = {}
	inventory = Content.STARTING_ITEMS.duplicate()
	relics.clear()
	hand_size_modifier = 0
	action_modifier = 0
	reward_offers.clear()
	information_mode = mode if mode in ["hidden", "partial", "full"] else "partial"
	pending_information_mode = information_mode
	if expedition_mode:
		phase = "map"
	else:
		start_encounter()

func enable_expedition() -> void:
	expedition_mode = true

static func encounter_index(encounter_id: String) -> int:
	for index in range(Content.ENCOUNTERS.size()):
		if Content.ENCOUNTERS[index].get("id", "") == encounter_id: return index
	return -1

func start_route_encounter(encounter_id: String) -> bool:
	if not expedition_mode or phase != "map": return false
	var index: int = encounter_index(encounter_id)
	if index < 0: return false
	encounter = index
	start_encounter()
	return true

func _roll_passive(species: String) -> String:
	var pool: Array = Content.PASSIVE_POOLS[species]
	return str(pool[rng.randi_range(0, pool.size() - 1)])

func _shuffle(cards: Array) -> void:
	for i in range(cards.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: Variant = cards[i]
		cards[i] = cards[j]
		cards[j] = temp

func _normalize(individual: Dictionary) -> void:
	var defaults: Dictionary = make_umbral(str(individual.species), str(individual.get("passive", "fierce")), int(individual.uid), int(individual.get("stage", 1)))
	for key in defaults:
		if not individual.has(key): individual[key] = defaults[key]

func start_encounter() -> void:
	phase = "battle"
	round_number = 1
	encounter_rounds_resolved = 0
	selected.clear()
	queued_swaps.clear()
	queued_items.clear()
	declined_replacements.clear()
	hand.clear()
	deck.clear()
	discard_pile.clear()
	suspended_cards.clear()
	enemy_plan.clear()
	reward_offers.clear()
	for individual in party:
		_normalize(individual)
		individual.block = 0
		individual.statuses = {}
		individual.status_sources = {}
		individual.can_act_round = 1
		if int(individual.slot) >= 0 or int(individual.hp) <= 0:
			deck.append_array(individual.cards.duplicate(true))
		else:
			suspended_cards[int(individual.uid)] = {"deck": individual.cards.duplicate(true), "discard": [], "entered": false}
	_shuffle(deck)
	enemies.clear()
	var definitions: Array = Content.ENCOUNTERS[encounter].get("enemies", [])
	for i in range(mini(MAX_ACTIVE, definitions.size())):
		var definition: Dictionary = definitions[i]
		var opponent: Dictionary = make_umbral(str(definition.get("species", "moss")), str(definition.get("passive", "")), int(definition.get("uid", 100 + i)), int(definition.get("stage", 1)))
		for key in definition: opponent[key] = definition[key]
		opponent.slot = int(definition.get("slot", i))
		opponent.max_hp = int(definition.get("max_hp", definition.get("hp", opponent.max_hp)))
		opponent.hp = int(definition.get("hp", opponent.max_hp))
		opponent.block = 0
		opponent.statuses = {}
		opponent.status_sources = {}
		enemies.append(opponent)
	if _needs_replacement():
		phase = "replacement"
	else:
		_begin_round()
	_sync_compatibility()
	state_changed.emit("encounter")

func active_party(only_able: bool = false) -> Array:
	var result: Array = []
	for individual in party:
		if int(individual.get("slot", -1)) >= 0 and (not only_able or int(individual.get("hp", 0)) > 0): result.append(individual)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.slot) < int(b.slot))
	return result

func reserves() -> Array:
	var result: Array = []
	for individual in party:
		if int(individual.get("slot", -1)) < 0 and int(individual.get("hp", 0)) > 0: result.append(individual)
	return result

func umbral_by_uid(uid: int) -> Dictionary:
	return _by_uid(party, uid)

func _by_uid(roster: Array, uid: int) -> Dictionary:
	for individual in roster:
		if int(individual.uid) == uid: return individual
	return {}

func _at_slot(roster: Array, slot: int) -> Dictionary:
	return Targeting.at_slot(roster, slot)

func hand_capacity() -> int:
	var capacity: int = HAND_SIZE + hand_size_modifier
	for relic in relics:
		if relic is Dictionary: capacity += int(relic.get("hand_modifier", 0))
	for individual in active_party(true): capacity += int(individual.get("hand_modifier", 0))
	return clampi(capacity, 1, 24)

func action_budget() -> int:
	var budget: int = ENERGY + action_modifier
	for relic in relics:
		if relic is Dictionary: budget += int(relic.get("action_modifier", 0))
	return maxi(1, budget)

func set_formation(uids_by_slot: Array) -> bool:
	# A dealt hand cannot be fished by repeatedly changing the starting formation.
	if phase != "reward" and not (expedition_mode and phase == "map"): return false
	if uids_by_slot.size() != MAX_ACTIVE: return false
	var seen: Dictionary = {}
	for uid in uids_by_slot:
		if int(uid) < 0: continue
		var individual: Dictionary = umbral_by_uid(int(uid))
		if individual.is_empty() or int(individual.hp) <= 0 or seen.has(int(uid)): return false
		seen[int(uid)] = true
	if seen.is_empty(): return false
	for individual in party: individual.slot = uids_by_slot.find(int(individual.uid))
	_sync_compatibility()
	state_changed.emit("formation")
	return true

func _draw_hand() -> void:
	while hand.size() < hand_capacity():
		if deck.is_empty():
			if discard_pile.is_empty(): break
			deck = discard_pile.duplicate(true)
			discard_pile.clear()
			_shuffle(deck)
		hand.append(deck.pop_back())
	_assign_default_targets()

func _assign_default_targets() -> void:
	for index in range(hand.size()):
		var options: Array[int] = target_options(index)
		if not options.is_empty() and not int(hand[index].get("target_slot", -1)) in options:
			hand[index].target_slot = options[0]

func _first_living_slot(roster: Array) -> int:
	for slot in range(MAX_ACTIVE):
		var individual: Dictionary = _at_slot(roster, slot)
		if not individual.is_empty() and int(individual.get("hp", 0)) > 0: return slot
	return 1

func _sync_owner_zones() -> void:
	var returning: Array = []
	for individual in party:
		var uid: int = int(individual.uid)
		var eligible: bool = int(individual.slot) >= 0 or int(individual.hp) <= 0
		if not eligible:
			if not suspended_cards.has(uid): suspended_cards[uid] = {"deck": [], "discard": [], "entered": true}
			var suspended: Dictionary = suspended_cards[uid]
			_move_owner_cards(deck, suspended.deck, uid)
			_move_owner_cards(discard_pile, suspended.discard, uid)
			_move_owner_cards(hand, suspended.discard, uid)
		elif suspended_cards.has(uid):
			var suspended: Dictionary = suspended_cards[uid]
			var incoming: Array = suspended.deck
			if not bool(suspended.get("entered", true)): _shuffle(incoming)
			returning.append(incoming)
			discard_pile.append_array(suspended.discard)
			suspended_cards.erase(uid)
	if returning.is_empty(): return
	# Recycle only at exhaustion. Otherwise a solo owner's discarded hand
	# would wait behind six new cards and guarantee a reserve-only next hand.
	if deck.is_empty() and not discard_pile.is_empty():
		deck = discard_pile.duplicate(true)
		discard_pile.clear()
		_shuffle(deck)
	for incoming in returning: _interleave_draw(incoming)

func _interleave_draw(incoming: Array) -> void:
	# Uniformly merge the incoming sequence with the current draw sequence.
	# Existing cards retain their relative order; no global redraw or fishing.
	var merged: Array = []
	var old_index: int = 0
	var new_index: int = 0
	while old_index < deck.size() and new_index < incoming.size():
		var old_left: int = deck.size() - old_index
		var new_left: int = incoming.size() - new_index
		if rng.randi_range(1, old_left + new_left) <= old_left:
			merged.append(deck[old_index])
			old_index += 1
		else:
			merged.append(incoming[new_index])
			new_index += 1
	merged.append_array(deck.slice(old_index))
	merged.append_array(incoming.slice(new_index))
	deck = merged

func _move_owner_cards(source: Array, destination: Array, uid: int) -> void:
	for i in range(source.size() - 1, -1, -1):
		if int(source[i].owner) == uid:
			destination.push_front(source[i])
			source.remove_at(i)

func card_reason(index: int) -> String:
	if phase != "battle" or index < 0 or index >= hand.size(): return "Poder indisponível"
	var individual: Dictionary = umbral_by_uid(int(hand[index].owner))
	if individual.is_empty(): return "Dono ausente"
	if int(individual.hp) <= 0: return "Umbral incapacitado"
	if int(individual.slot) < 0: return "Umbral na reserva"
	if int(individual.get("can_act_round", 1)) > round_number: return "Age na próxima rodada"
	return ""

func card_usable(index: int) -> bool:
	return card_reason(index).is_empty()

func toggle(index: int) -> bool:
	if phase != "battle" or index < 0 or index >= hand.size(): return false
	if index in selected:
		selected.erase(index)
		state_changed.emit("selection")
		return true
	if not card_usable(index): return false
	selected.append(index)
	state_changed.emit("selection")
	return true

func target_options(index: int) -> Array[int]:
	if index < 0 or index >= hand.size(): return []
	var card: Dictionary = hand[index]
	var owner: Dictionary = umbral_by_uid(int(card.owner))
	if owner.is_empty() or not Content.POWERS.has(card.power): return []
	return Targeting.options(Content.power_stats(str(card.power), int(owner.stage)), owner, party, enemies)

func set_target(index: int, slot: int) -> bool:
	if phase != "battle" or not card_usable(index) or not slot in target_options(index): return false
	hand[index].target_slot = slot
	state_changed.emit("target")
	return true

func clear_plan() -> bool:
	if phase != "battle": return false
	selected.clear()
	queued_swaps.clear()
	queued_items.clear()
	state_changed.emit("selection")
	return true

func planned_actions() -> Array:
	# Only the player's commands. Never projects enemy initiative, targets or HP.
	var entries: Array = Initiative.player_entries(selected_cards(), party, queued_swaps, queued_items)
	entries.sort_custom(Initiative.precedes)
	return entries

func selected_cards() -> Array:
	var cards: Array = []
	for index in selected:
		if index >= 0 and index < hand.size(): cards.append(hand[index])
	return cards

static func power_effect(card: Dictionary, individual: Dictionary, companion_count: int, trait_available: bool = true) -> Dictionary:
	var stats: Dictionary = Content.power_stats(str(card.power), int(individual.get("stage", 1)))
	var damage: int = int(stats.get("damage", 0))
	var block: int = int(stats.get("block", 0))
	var heal: int = int(stats.get("heal", 0))
	var burn: int = int(stats.get("burn", 0))
	if damage > 0:
		damage = maxi(0, damage + int(individual.get("attack", 10)) - 10)
		if individual.get("passive", "") == "fierce": damage += 3
		if individual.get("passive", "") == "ardent": burn += 2
	if individual.get("passive", "") == "resilient" and block > 0: block += 3
	if individual.get("passive", "") == "vital" and heal > 0: heal += 2
	var species: String = str(individual.species)
	var trait_values: Array = Content.SPECIES[species].get("trait_values", [0, 0])
	var strength: int = int(trait_values[clampi(int(individual.get("stage", 1)) - 1, 0, trait_values.size() - 1)])
	if species == "ember" and damage > 0: burn += strength
	if species == "moss" and block > 0 and trait_available: heal += strength
	if species == "volt" and damage > 0: damage += strength * maxi(0, companion_count - 1)
	stats.damage = damage + (int(individual.get("statuses", {}).get("charge", 0)) if damage > 0 else 0)
	stats.attack_multiplier = Conditions.attack_multiplier(individual)
	if burn > 0: stats.conditions.burn = burn
	stats.block = block
	stats.heal = heal
	stats.burn = burn
	return stats

static func evaluate(cards: Array, companions: Array, existing_burn: int = 0) -> Dictionary:
	var result: Dictionary = {"valid": false, "reason": "Selecione poderes, uma troca ou um item", "name": "Prepare sua conjuração", "actions": 0, "energy": 0, "damage": 0, "direct_damage": 0, "burn_added": 0, "burn_tick": existing_burn, "block": 0, "heal": 0, "bonuses": []}
	if cards.is_empty(): return result
	var owners: Dictionary = {}
	for individual in companions: owners[int(individual.uid)] = individual
	var seen: Dictionary = {}
	var participating: Dictionary = {}
	var moss_used: Dictionary = {}
	for card in cards:
		if not card.has("instance_id") or seen.has(card.instance_id) or not owners.has(int(card.get("owner", -1))) or not Content.POWERS.has(card.get("power", "")):
			result.reason = "Poder inválido"
			return result
		var individual: Dictionary = owners[int(card.owner)]
		if int(individual.get("hp", 1)) <= 0 or int(individual.get("slot", 0)) < 0:
			result.reason = "Umbral incapacitado ou na reserva"
			return result
		var known: Array = individual.get("known_powers", Content.SPECIES[individual.species].powers)
		if not card.power in known:
			result.reason = "Este Umbral não conhece esse poder"
			return result
		seen[card.instance_id] = true
		participating[int(card.owner)] = true
	var able_count: int = 0
	for individual in companions:
		if int(individual.get("slot", 0)) >= 0 and int(individual.get("hp", 1)) > 0: able_count += 1
	for card in cards:
		var individual: Dictionary = owners[int(card.owner)]
		var stats: Dictionary = power_effect(card, individual, able_count, not moss_used.has(int(individual.uid)))
		if individual.species == "moss" and int(stats.block) > 0: moss_used[int(individual.uid)] = true
		result.actions += int(stats.cost)
		result.direct_damage += floori(float(stats.damage) * float(stats.attack_multiplier))
		result.block += int(stats.block)
		result.heal += int(stats.heal)
		result.burn_added += int(stats.burn)
	result.energy = result.actions
	result.damage = result.direct_damage
	result.name = "Conjuração conjunta" if participating.size() > 1 else "Poder de " + Content.display_name(owners[participating.keys()[0]])
	result.valid = int(result.actions) <= ENERGY
	result.reason = "" if result.valid else "Ações insuficientes"
	return result

func preview() -> Dictionary:
	var cards: Array = selected_cards()
	var result: Dictionary = evaluate(cards, party)
	if not cards.is_empty() and not result.valid and result.reason != "Ações insuficientes": return result
	if cards.size() != selected.size():
		result.valid = false
		result.reason = "Seleção inválida"
		return result
	for index in selected:
		if not card_usable(index):
			result.valid = false
			result.reason = card_reason(index)
			return result
		var card: Dictionary = hand[index]
		var owner: Dictionary = umbral_by_uid(int(card.owner))
		for swap in queued_swaps:
			if int(swap.out_uid) == int(owner.uid):
				result.valid = false
				result.reason = "Quem sai não pode conjurar nesta rodada"
				return result
		if not int(card.get("target_slot", -1)) in target_options(index):
			result.valid = false
			result.reason = "Escolha uma vaga com alvo apto no alcance do poder"
			return result
	result.actions += queued_swaps.size()
	for item in queued_items: result.actions += int(Content.CONSUMABLES[item.item].cost)
	result.energy = result.actions
	result.valid = (not cards.is_empty() or not queued_swaps.is_empty() or not queued_items.is_empty()) and int(result.actions) <= action_budget()
	result.reason = "" if result.valid else "Ações insuficientes" if int(result.actions) > action_budget() else "Selecione poderes, uma troca ou um item"
	if cards.is_empty() and result.valid: result.name = "Manobra do time"
	return result

func queue_swap(out_uid: int, in_uid: int) -> bool:
	var outgoing: Dictionary = umbral_by_uid(out_uid)
	if outgoing.is_empty() or int(outgoing.get("slot", -1)) < 0: return false
	return _queue_entry(int(outgoing.slot), out_uid, in_uid)

func queue_deploy(slot: int, in_uid: int) -> bool:
	if not _at_slot(party, slot).is_empty(): return false
	return _queue_entry(slot, -1, in_uid)

func deploy_reserve(slot: int, in_uid: int) -> bool:
	return queue_deploy(slot, in_uid)

func _queue_entry(slot: int, out_uid: int, in_uid: int) -> bool:
	if not swap_reason(slot, in_uid).is_empty(): return false
	queued_swaps.append({"slot": slot, "out_uid": out_uid, "in_uid": in_uid})
	state_changed.emit("selection")
	return true

func swap_reason(slot: int, in_uid: int) -> String:
	if phase != "battle" or slot < 0 or slot >= MAX_ACTIVE: return "Troca indisponível"
	var incoming: Dictionary = umbral_by_uid(in_uid)
	if incoming.is_empty() or int(incoming.get("slot", -1)) >= 0 or int(incoming.hp) <= 0: return "Escolha uma reserva apta"
	var outgoing: Dictionary = _at_slot(party, slot)
	if not outgoing.is_empty() and int(outgoing.hp) <= 0 and not declined_replacements.has(int(outgoing.uid)): return "Reposição de nocaute acontece entre rodadas"
	for swap in queued_swaps:
		if int(swap.slot) == slot: return "Essa vaga já tem uma troca planejada"
		if int(swap.in_uid) == in_uid: return "Essa reserva já tem entrada planejada"
	return ""

func cancel_swap(slot: int) -> bool:
	if phase != "battle": return false
	for i in range(queued_swaps.size()):
		if int(queued_swaps[i].slot) == slot:
			queued_swaps.remove_at(i)
			state_changed.emit("selection")
			return true
	return false

func queue_item(item: String, uid: int) -> bool:
	if not item_reason(item, uid).is_empty(): return false
	queued_items.append({"item": item, "uid": uid})
	state_changed.emit("selection")
	return true

func item_reason(item: String, uid: int) -> String:
	if phase != "battle" or not Content.CONSUMABLES.has(item): return "Item indisponível"
	var target: Dictionary = umbral_by_uid(uid)
	if target.is_empty(): return "Alvo ausente"
	var definition: Dictionary = Content.CONSUMABLES[item]
	if definition.has("heal") and (int(target.hp) <= 0 or int(target.hp) >= int(target.max_hp)): return "Requer um Umbral ferido e apto"
	if definition.has("revive_ratio") and int(target.hp) > 0: return "Requer um Umbral incapacitado"
	var reserved: int = 0
	for order in queued_items:
		if order.item == item: reserved += 1
		if int(order.uid) == uid and order.item == item: return "Já planejado para esse Umbral"
	if reserved >= int(inventory.get(item, 0)): return "Sem unidades livres; confira o plano"
	return ""

func cancel_item(index: int) -> bool:
	if phase != "battle" or index < 0 or index >= queued_items.size(): return false
	queued_items.remove_at(index)
	state_changed.emit("selection")
	return true

func set_information_mode(mode: String) -> bool:
	if mode not in ["hidden", "partial", "full"]: return false
	pending_information_mode = mode
	state_changed.emit("information")
	return true

func public_intents(mode: String = "") -> Array:
	var visibility: String = information_mode if mode.is_empty() else mode
	var result: Array = []
	for entry in enemy_plan:
		var projection: Dictionary = {"slot": int(entry.actor_slot), "category": "unknown" if visibility == "hidden" else str(entry.category)}
		if visibility == "full":
			for key in ["power", "scope", "target_slot", "damage", "block", "heal", "wet", "priority", "charge", "nature", "conditions"]:
				var value: Variant = entry.get(key, 0)
				projection[key] = value.duplicate(true) if value is Dictionary or value is Array else value
			var opponent: Dictionary = _by_uid(enemies, int(entry.actor_uid))
			if int(entry.get("damage", 0)) > 0: projection.damage = floori(float(maxi(0, int(entry.damage) + int(opponent.get("attack", 10)) - 10) + int(opponent.statuses.get("charge", 0))) * Conditions.attack_multiplier(opponent))
		result.append(projection)
	return result

func _commit_enemy_plan() -> void:
	enemy_plan = EnemyPlanner.build(enemies, party, round_number, rng)

func intent_damage() -> int:
	# Legacy display helper: intentionally hides exact damage except in full mode.
	if information_mode != "full": return -1
	var damage: int = 0
	for entry in enemy_plan: damage += int(entry.get("damage", 0))
	return damage

func _begin_round() -> void:
	phase = "battle"
	information_mode = pending_information_mode
	for individual in party + enemies: individual.block = 0
	_sync_owner_zones()
	_draw_hand()
	_commit_enemy_plan()
	_sync_compatibility()

func play() -> Dictionary:
	if phase != "battle": return {"ok": false, "reason": "invalid_phase"}
	var score: Dictionary = preview()
	if not score.valid: return {"ok": false, "reason": score.reason}
	return _resolve_round(score, false)

func redraw() -> bool:
	if phase != "battle": return false
	var score: Dictionary = evaluate([], party)
	score.valid = true
	score.reason = ""
	score.name = "Resortear · passa o turno"
	_resolve_round(score, true)
	return true

func _resolve_round(score: Dictionary, passing: bool) -> Dictionary:
	var player_entries: Array = [] if passing else Initiative.player_entries(selected_cards(), party, queued_swaps, queued_items)
	var queue: Array = Initiative.commit(player_entries, enemy_plan, enemies, rng)
	var events: Array = []
	var moss_used: Dictionary = {}
	var applied_damage: int = 0
	for entry in queue:
		if entry.kind == "swap":
			_resolve_swap(entry, events)
		elif entry.kind == "item":
			_resolve_item(entry, events)
		else:
			var roster: Array = party if entry.side == "ally" else enemies
			var owner: Dictionary = _by_uid(roster, int(entry.actor_uid))
			if owner.is_empty() or int(owner.hp) <= 0 or int(owner.slot) < 0 or int(owner.get("can_act_round", 1)) > round_number:
				events.append(_event("canceled", entry, owner, "ally" if entry.side == "enemy" else "enemy", {}, "", 0))
				events.back().reason = "dono ausente" if owner.is_empty() else "incapacitado" if int(owner.hp) <= 0 else "na reserva" if int(owner.slot) < 0 else "age na próxima rodada"
				continue
			applied_damage += _resolve_power(entry, owner, events, moss_used)
	_tick_statuses(events)
	for event in events:
		if event.kind == "burn" and event.target_side == "enemy": applied_damage += int(event.amount)
	total_damage += applied_damage
	actions += 1
	encounter_rounds_resolved += 1
	# Every card, selected or not, leaves the hand exactly once each round.
	for card in hand:
		card.erase("target_slot")
		discard_pile.append(card)
	hand.clear()
	selected.clear()
	queued_swaps.clear()
	queued_items.clear()
	_sync_owner_zones()
	var incoming_damage: int = 0
	for event in events:
		if event.target_side == "ally" and event.kind in ["attack", "burn"]: incoming_damage += int(event.amount)
	round_number += 1
	var foes_alive: bool = false
	for opponent in enemies:
		if int(opponent.hp) > 0: foes_alive = true
	var party_alive: bool = false
	for individual in party:
		if int(individual.hp) > 0: party_alive = true
	if not party_alive:
		phase = "defeat"
	elif not foes_alive:
		phase = "victory" if (Content.ENCOUNTERS[encounter].get("id", "") == "boss" if expedition_mode else encounter == Content.ENCOUNTERS.size() - 1) else "reward"
		if phase == "reward": _prepare_rewards()
	elif _needs_replacement():
		phase = "replacement"
	else:
		_begin_round()
	_sync_compatibility()
	score.ok = true
	score.phase = phase
	score.applied_damage = applied_damage
	score.incoming = incoming_damage
	score.events = events
	score.passed = passing
	score.resolved_round = round_number - 1
	score.encounter_index = encounter
	last_result = score.duplicate(true)
	state_changed.emit("resolved")
	return score

func _event(kind: String, entry: Dictionary, owner: Dictionary, target_side: String, target: Dictionary, power: String, amount: int) -> Dictionary:
	var snapshot: Dictionary = {}
	for key in ["uid", "species", "name", "art", "stage", "passive", "hp", "max_hp", "attack", "defense", "speed", "block", "statuses", "status_sources", "resistances", "slot", "can_act_round"]:
		if target.has(key): snapshot[key] = target[key].duplicate(true) if target[key] is Dictionary else target[key]
	var event: Dictionary = {"kind": kind, "actor_uid": int(owner.get("uid", entry.get("actor_uid", -1))), "actor_side": str(entry.get("side", "ally")), "actor_slot": int(owner.get("slot", entry.get("actor_slot", -1))), "target_uid": int(target.get("uid", -1)), "target_side": target_side, "target_slot": int(target.get("slot", -1)), "power": power, "amount": amount, "target_state": snapshot}
	event.actor_name = str(owner.name) if owner.has("name") else Content.display_name(owner) if owner.has("species") else "Umbral"
	event.target_name = str(target.name) if target.has("name") else Content.display_name(target) if target.has("species") else "Umbral"
	return event

func _resolve_swap(entry: Dictionary, events: Array) -> void:
	var swap: Dictionary = entry.swap
	var incoming: Dictionary = umbral_by_uid(int(swap.in_uid))
	var outgoing: Dictionary = umbral_by_uid(int(swap.out_uid))
	if incoming.is_empty() or int(incoming.hp) <= 0 or int(incoming.slot) >= 0: return
	if not outgoing.is_empty():
		if int(outgoing.slot) != int(swap.slot): return
		if int(outgoing.hp) <= 0 and not declined_replacements.has(int(outgoing.uid)): return
		outgoing.slot = -1
	incoming.slot = int(swap.slot)
	incoming.can_act_round = round_number + 1
	var event: Dictionary = _event("swap", entry, incoming, "ally", incoming, "", 0)
	event.out_uid = int(swap.out_uid)
	events.append(event)

func _resolve_item(entry: Dictionary, events: Array) -> void:
	var order: Dictionary = entry.order
	var target: Dictionary = umbral_by_uid(int(order.uid))
	if target.is_empty() or int(inventory.get(order.item, 0)) <= 0: return
	var definition: Dictionary = Content.CONSUMABLES[order.item]
	if definition.has("revive_ratio"):
		if int(target.hp) > 0: return
		target.hp = maxi(1, ceili(float(target.max_hp) * float(definition.revive_ratio)))
		declined_replacements.erase(int(target.uid))
		target.can_act_round = round_number + 1
		target.statuses = {}
		target.status_sources = {}
		events.append(_event("revive", entry, {}, "ally", target, "revive", int(target.hp)))
	else:
		if int(target.hp) <= 0: return
		var healing: int = mini(int(definition.get("heal", 0)), int(target.max_hp) - int(target.hp))
		target.hp += healing
		events.append(_event("heal", entry, {}, "ally", target, "potion", healing))
	inventory[order.item] = int(inventory[order.item]) - 1

func _scope_slots(scope: String, target_slot: int) -> Array:
	return Targeting.slots(scope, target_slot)

func _resolve_power(entry: Dictionary, owner: Dictionary, events: Array, moss_used: Dictionary) -> int:
	var stats: Dictionary
	var power: String
	if entry.kind == "enemy":
		stats = entry.intent.duplicate(true)
		if int(stats.get("damage", 0)) > 0:
			stats.damage = maxi(0, int(stats.damage) + int(owner.get("attack", 10)) - 10) + int(owner.statuses.get("charge", 0))
		stats.attack_multiplier = Conditions.attack_multiplier(owner)
		power = str(stats.power)
		stats.target = "self" if str(stats.category) in ["defend", "prepare"] else "enemy"
		if str(stats.category) == "prepare":
			Conditions.apply(owner, "charge", int(stats.get("charge", 0)), {"uid": int(owner.uid), "side": entry.side})
			events.append(_event("prepare", entry, owner, str(entry.side), owner, power, int(stats.get("charge", 0))))
		# Old custom enemy patterns remain readable; authored techniques use conditions.
		if not stats.has("conditions"): stats.conditions = {}
		for id in ["burn", "wet"]:
			if int(stats.get(id, 0)) > 0: stats.conditions[id] = int(stats[id])
	else:
		power = str(entry.card.power)
		stats = power_effect(entry.card, owner, active_party(true).size(), not moss_used.has(int(owner.uid)))
		stats.target_slot = int(entry.card.get("target_slot", owner.slot))
		if owner.species == "moss" and int(stats.block) > 0: moss_used[int(owner.uid)] = true
	var offensive: bool = int(stats.get("damage", 0)) > 0
	if offensive:
		# Spend once per technique, before iterating area targets. Support keeps both.
		for id in ["charge", "electrified"]:
			if int(owner.statuses.get(id, 0)) > 0:
				Conditions.consume(owner, id)
				var spent: Dictionary = _event("condition_spent", entry, owner, str(entry.side), owner, power, 0)
				spent.condition = id
				events.append(spent)
	var hostile: bool = str(stats.get("target", "enemy")) == "enemy"
	var target_side: String = ("enemy" if entry.side == "ally" else "ally") if hostile else str(entry.side)
	var targets: Array = enemies if target_side == "enemy" else party
	var target_slot: int = int(stats.get("target_slot", owner.slot))
	if str(stats.get("target", "enemy")) == "self": target_slot = int(owner.slot)
	var scope: String = str(stats.get("scope", "single"))
	if hostile and scope == "single":
		for individual in targets:
			if int(individual.get("slot", -1)) >= 0 and int(individual.hp) > 0 and int(individual.statuses.get("taunt", 0)) > 0:
				target_slot = int(individual.slot)
				break
	var applied_damage: int = 0
	for slot in _scope_slots(scope, target_slot):
		var target: Dictionary = _at_slot(targets, int(slot))
		if target.is_empty() or int(target.hp) <= 0: continue
		var reaction: Dictionary = Reactions.choose(stats, target)
		var seed_before: bool = int(target.statuses.get("seed", 0)) > 0
		var beneficiary: Dictionary = target.get("status_sources", {}).get("seed", {}).duplicate(true)
		if not reaction.is_empty() and bool(reaction.consume): Conditions.consume(target, str(reaction.condition))
		if offensive:
			var raw: float = float(stats.damage) * float(stats.get("attack_multiplier", 1.0)) * float(reaction.get("multiplier", 1.0))
			var resistance: int = clampi(int(Content.resistances(target).get(str(stats.get("nature", "")), 0)), 0, 100)
			raw *= 1.0 - float(resistance) / 100.0
			var damage: int = maxi(0, floori(raw) - int(target.defense))
			var absorbed: int = mini(int(target.block), damage)
			target.block -= absorbed
			damage = mini(int(target.hp), damage - absorbed)
			target.hp -= damage
			var hit: Dictionary = _event("attack", entry, owner, target_side, target, power, damage)
			hit.blocked = absorbed
			hit.amplified = reaction.get("id", "") == "conduction"
			hit.nature = str(stats.get("nature", ""))
			hit.resistance = resistance
			hit.weakened = float(stats.get("attack_multiplier", 1.0)) < 1.0
			events.append(hit)
			if target_side == "enemy": applied_damage += damage
		if not reaction.is_empty(): _apply_reaction(reaction, beneficiary, entry, owner, target_side, target, power, events, moss_used)
		if int(target.hp) <= 0:
			events.append(_event("ko", entry, owner, target_side, target, power, 0))
			continue
		for id in stats.get("conditions", {}):
			# A preexisting seed is used or refreshed, never replanted by this same hit.
			if id in ["taunt", "charge"] or (id == "seed" and seed_before): continue
			Conditions.apply(target, id, int(stats.conditions[id]), {"uid": int(owner.uid), "side": entry.side})
			var applied: Dictionary = _event("wet" if id == "wet" else "condition", entry, owner, target_side, target, power, int(stats.conditions[id]))
			applied.condition = id
			events.append(applied)
		if not hostile: _apply_support(stats, entry, owner, target_side, target, power, events)
	if hostile and (int(stats.get("block", 0)) > 0 or int(stats.get("heal", 0)) > 0 or int(stats.get("taunt", 0)) > 0):
		_apply_support(stats, entry, owner, str(entry.side), owner, power, events)
	return applied_damage

func _apply_reaction(reaction: Dictionary, source: Dictionary, entry: Dictionary, owner: Dictionary, side: String, target: Dictionary, power: String, events: Array, moss_used: Dictionary) -> void:
	if int(target.hp) > 0 and int(reaction.get("burn", 0)) > 0:
		Conditions.apply(target, "burn", int(reaction.burn), {"uid": int(owner.uid), "side": entry.side})
	var event: Dictionary = _event("reaction", entry, owner, side, target, power, 0)
	event.reaction = str(reaction.id)
	event.label = str(reaction.name)
	event.condition = str(reaction.condition)
	events.append(event)
	if source.is_empty() or (int(reaction.get("block", 0)) <= 0 and int(reaction.get("heal", 0)) <= 0): return
	var beneficiary_side: String = str(source.get("side", "ally"))
	var beneficiary: Dictionary = _by_uid(party if beneficiary_side == "ally" else enemies, int(source.get("uid", -1)))
	if beneficiary.is_empty() or int(beneficiary.hp) <= 0: return
	var support: Dictionary = {"block": int(reaction.get("block", 0)), "heal": int(reaction.get("heal", 0))}
	if support.block > 0 and beneficiary.species == "moss" and not moss_used.has(int(beneficiary.uid)):
		support.heal += int(Content.SPECIES.moss.trait_values[clampi(int(beneficiary.stage) - 1, 0, 1)])
		moss_used[int(beneficiary.uid)] = true
	_apply_support(support, entry, owner, beneficiary_side, beneficiary, power, events)

func _apply_support(stats: Dictionary, entry: Dictionary, owner: Dictionary, side: String, target: Dictionary, power: String, events: Array) -> void:
	if int(stats.get("block", 0)) > 0:
		target.block += int(stats.block)
		events.append(_event("block", entry, owner, side, target, power, int(stats.block)))
	if int(stats.get("heal", 0)) > 0:
		var healing: int = mini(int(stats.heal), int(target.max_hp) - int(target.hp))
		target.hp += healing
		events.append(_event("heal", entry, owner, side, target, power, healing))
	if int(stats.get("taunt", 0)) > 0:
		Conditions.apply(target, "taunt", int(stats.taunt), {"uid": int(owner.uid), "side": entry.side})
		events.append(_event("condition", entry, owner, side, target, power, int(stats.taunt)))
		events.back().condition = "taunt"

func _tick_statuses(events: Array) -> void:
	for side in ["ally", "enemy"]:
		var roster: Array = party if side == "ally" else enemies
		for target in roster:
			if int(target.get("slot", -1)) < 0 or int(target.hp) <= 0: continue
			var burn: int = int(target.statuses.get("burn", 0))
			if burn > 0:
				var damage: int = mini(int(target.hp), burn)
				target.hp -= damage
				var entry: Dictionary = {"side": side, "actor_uid": int(target.uid), "actor_slot": int(target.slot)}
				events.append(_event("burn", entry, target, side, target, "burn", damage))
				if int(target.hp) <= 0: events.append(_event("ko", entry, target, side, target, "burn", 0))
			Conditions.tick(target)

func _needs_replacement() -> bool:
	if reserves().is_empty(): return false
	if active_party(true).is_empty(): return true
	for individual in active_party():
		if int(individual.hp) <= 0 and not declined_replacements.has(int(individual.uid)): return true
	return false

func replace_after_ko(slot: int, in_uid: int) -> bool:
	if phase != "replacement" or slot < 0 or slot >= MAX_ACTIVE: return false
	var outgoing: Dictionary = _at_slot(party, slot)
	# Only a vacated KO body grants a free replacement, never an unused field slot.
	if outgoing.is_empty() or int(outgoing.hp) > 0: return false
	var incoming: Dictionary = umbral_by_uid(in_uid)
	if incoming.is_empty() or int(incoming.hp) <= 0 or int(incoming.slot) >= 0: return false
	if not outgoing.is_empty(): outgoing.slot = -1
	incoming.slot = slot
	incoming.can_act_round = round_number
	_sync_owner_zones()
	_sync_compatibility()
	state_changed.emit("replacement")
	return true

func finish_replacements() -> bool:
	if phase != "replacement" or active_party(true).is_empty(): return false
	for individual in active_party():
		if int(individual.hp) <= 0: declined_replacements[int(individual.uid)] = true
	_begin_round()
	state_changed.emit("replacement_done")
	return true

func _prepare_rewards() -> void:
	reward_offers.clear()
	var route: Array = Content.CAPTURE_ROUTES[starter_species]
	var reward_index: int = (0 if Content.ENCOUNTERS[encounter].get("id", "") == "clearing" else 1) if expedition_mode else encounter
	var species: String = str(route[clampi(reward_index, 0, route.size() - 1)])
	reward_offers.append({"kind": "capture", "umbral": make_umbral(species, _roll_passive(species), next_uid)})
	for individual in party:
		if int(individual.stage) < 2: reward_offers.append({"kind": "evolve", "uid": individual.uid})

func capture_destinations(offer_index: int, replace_uid: int = -1) -> Array[int]:
	var result: Array[int] = []
	if phase != "reward" or offer_index < 0 or offer_index >= reward_offers.size() or reward_offers[offer_index].kind != "capture": return result
	if party.size() < MAX_TEAM and replace_uid != -1: return result
	if party.size() >= MAX_TEAM and umbral_by_uid(replace_uid).is_empty(): return result
	# Never leave a new encounter with no field body that can act or be replaced.
	for individual in active_party():
		if int(individual.uid) != replace_uid:
			result.append(-1)
			break
	for slot in range(MAX_ACTIVE):
		var occupant: Dictionary = _at_slot(party, slot)
		if occupant.is_empty() or int(occupant.uid) == replace_uid: result.append(slot)
	return result

func choose_reward(offer_index: int, replace_uid: int = -1, capture_slot: int = -2) -> bool:
	if phase != "reward" or offer_index < 0 or offer_index >= reward_offers.size(): return false
	var offer: Dictionary = reward_offers[offer_index]
	if replace_uid != -1 and (offer.kind != "capture" or party.size() < MAX_TEAM): return false
	if offer.kind == "capture" and party.size() >= MAX_TEAM and umbral_by_uid(replace_uid).is_empty(): return false
	var destination: int = -1
	if offer.kind == "capture":
		destination = capture_slot
		if destination == -2:
			destination = int(umbral_by_uid(replace_uid).slot) if party.size() >= MAX_TEAM else -1
		if not destination in capture_destinations(offer_index, replace_uid): return false
	elif capture_slot != -2: return false
	if offer.kind != "capture":
		var candidate: Dictionary = umbral_by_uid(int(offer.uid))
		if candidate.is_empty() or int(candidate.stage) >= 2: return false
	_persist_card_collection()
	if offer.kind == "capture":
		if party.size() >= MAX_TEAM:
			var old: Dictionary = umbral_by_uid(replace_uid)
			if old.is_empty(): return false
			var index: int = party.find(old)
			var captured: Dictionary = offer.umbral.duplicate(true)
			captured.slot = destination
			party[index] = captured
		else:
			var captured: Dictionary = offer.umbral.duplicate(true)
			captured.slot = destination
			party.append(captured)
		next_uid += 1
	else:
		var individual: Dictionary = umbral_by_uid(int(offer.uid))
		if individual.is_empty() or int(individual.stage) >= 2: return false
		var ratio: float = float(individual.hp) / maxi(1, int(individual.max_hp))
		individual.stage = 2
		var stats: Dictionary = _species_stats(individual)
		for key in ["max_hp", "attack", "defense", "speed"]: individual[key] = int(stats[key])
		individual.hp = ceili(float(individual.max_hp) * ratio) if ratio > 0.0 else 0
		# Existing instances and learned power IDs survive. No automatic signature cards.
	if expedition_mode:
		reward_offers.clear()
		# The persisted individual collections own cards between encounters. The
		# old combat zones can still contain a released capture replacement.
		hand.clear()
		deck.clear()
		discard_pile.clear()
		suspended_cards.clear()
		enemy_plan.clear()
		phase = "map"
		_sync_compatibility()
		state_changed.emit("reward")
	else:
		encounter += 1
		start_encounter()
	return true

func _persist_card_collection() -> void:
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

func _sync_compatibility() -> void:
	max_hp = 0
	player_hp = 0
	for individual in active_party():
		max_hp += int(individual.max_hp)
		player_hp += int(individual.hp)
	enemy_hp = 0
	enemy_burn = 0
	for opponent in enemies:
		enemy_hp += int(opponent.hp)
		enemy_burn += int(opponent.statuses.get("burn", 0))

func best_selection() -> Array[int]:
	# Bounded heuristic for smoke simulations. Does not inspect hidden enemy plans.
	var best: Array[int] = []
	var best_value: float = -INF
	var original: Array[int] = selected.duplicate()
	var count: int = mini(hand.size(), 12)
	for mask in range(1, 1 << count):
		var indices: Array[int] = []
		var cards: Array = []
		for i in range(count):
			if mask & (1 << i):
				indices.append(i)
				cards.append(hand[i])
		selected = indices
		var score: Dictionary = preview()
		if not score.valid: continue
		var value: float = float(score.direct_damage) + float(score.block) * 0.45 + float(score.heal) * 0.35 + float(score.burn_added) * 1.2
		for card in cards:
			if int(Content.POWERS[card.power].conditions.get("wet", 0)) > 0: value += 2.0
		if value > best_value:
			best_value = value
			best = indices
	selected = original
	return best
