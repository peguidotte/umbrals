class_name UmbralRules
extends RefCounted
## Pure deterministic combat. Preview never samples RNG or resolves enemy plans.
signal state_changed(kind: String)

const ItemEffects = preload("res://scripts/battle/item_effects/registry.gd")
const Rewards = preload("res://scripts/battle/rewards.gd")
const Planning = preload("res://scripts/battle/planning.gd")
const CardCycle = preload("res://scripts/battle/card_cycle.gd")
const RoundResolution = preload("res://scripts/battle/round_resolution.gd")
const PowerEvaluation = preload("res://scripts/battle/power_evaluation.gd")
const Evolution = preload("res://scripts/battle/evolution.gd")
const Traits = preload("res://scripts/battle/traits.gd")
const Planner = preload("res://scripts/domain/selection_planner.gd")
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

static func make_umbral(species: String, passive: String, uid: int, form_id: String = "") -> Dictionary:
	var individual: Dictionary = {"uid": uid, "species": species, "passive": passive, "form_id": Content.initial_form(species) if form_id.is_empty() else form_id, "slot": -1, "block": 0, "statuses": {}, "status_sources": {}, "can_act_round": 1}
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
	var defaults: Dictionary = make_umbral(str(individual.species), str(individual.get("passive", "fierce")), int(individual.uid), Content.form_id(individual))
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
		var opponent: Dictionary = make_umbral(str(definition.get("species", "moss")), str(definition.get("passive", "")), int(definition.get("uid", 100 + i)), Content.form_id(definition))
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
	var cycle = CardCycle.new(party, hand, deck, discard_pile, suspended_cards, rng)
	cycle.draw(hand_capacity())
	deck = cycle.deck
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
	var cycle = CardCycle.new(party, hand, deck, discard_pile, suspended_cards, rng)
	cycle._sync_owner_zones()
	deck = cycle.deck

func card_reason(index: int) -> String:
	return Planning.card_reason(index, phase, hand, party, round_number)

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
	return Planning.target_options(index, hand, party, enemies)

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
	return PowerEvaluation.power_effect(card, individual, companion_count, trait_available)

static func evaluate(cards: Array, companions: Array, existing_burn: int = 0) -> Dictionary:
	return PowerEvaluation.evaluate(cards, companions, existing_burn)

func preview() -> Dictionary:
	return preview_selection(selected)

func preview_selection(indices: Array[int]) -> Dictionary:
	return Planning.preview_selection(indices, hand, party, enemies, phase, round_number, queued_swaps, queued_items, action_budget())

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
	var reason: String = ItemEffects.reason(Content.item_effect(item), target)
	if not reason.is_empty(): return reason
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
	var resolver = RoundResolution.new(party, enemies, inventory, declined_replacements, round_number)
	var resolution: Dictionary = resolver.resolve(queue)
	var events: Array = resolution.events
	var applied_damage: int = int(resolution.applied_damage)
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
		phase = "victory" if (Content.ENCOUNTERS[encounter].get("id", "") == "boss" if expedition_mode else Content.ENCOUNTERS[encounter].get("id", "") == Content.route_encounter_ids().back()) else "reward"
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
		reward_offers.append_array(Evolution.offers(individual, Content.evolution_edges(individual)))

func _valid_evolution(individual: Dictionary, offer: Dictionary) -> bool:
	return Evolution.valid(individual, offer, Content.evolution_edges(individual))

func capture_destinations(offer_index: int, replace_uid: int = -1) -> Array[int]:
	return Rewards.capture_destinations(offer_index, replace_uid, phase, reward_offers, party)

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
		if candidate.is_empty() or not _valid_evolution(candidate, offer): return false
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
		if individual.is_empty() or not _valid_evolution(individual, offer): return false
		var evolved: Dictionary = individual.duplicate(true)
		evolved.form_id = str(offer.target_form_id)
		Evolution.apply(individual, evolved.form_id, _species_stats(evolved))
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
		var route: Array = Content.route_encounter_ids()
		var route_index: int = route.find(Content.ENCOUNTERS[encounter].get("id", ""))
		encounter = encounter_index(str(route[route_index + 1]))
		start_encounter()
	return true

func _persist_card_collection() -> void:
	Rewards.persist_card_collection(party, hand, deck, discard_pile, suspended_cards)

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
	return Planner.choose(hand, action_budget(), preview_selection)
