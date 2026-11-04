class_name UmbralRules
extends RefCounted
## Pure deterministic combat. Preview never samples RNG or resolves enemy plans.
signal state_changed(kind: String)

const ItemEffects = preload("res://scripts/battle/item_effects/registry.gd")
const Conditions = preload("res://scripts/battle/conditions.gd")
const Formation = preload("res://scripts/battle/formation.gd")
const BattleView = preload("res://scripts/battle/battle_view.gd")
const RoundAftermath = preload("res://scripts/battle/round_aftermath.gd")
const EncounterSetup = preload("res://scripts/battle/encounter_setup.gd")
const Rewards = preload("res://scripts/battle/rewards.gd")
const Planning = preload("res://scripts/battle/planning.gd")
const CardCycle = preload("res://scripts/battle/card_cycle.gd")
const RoundResolution = preload("res://scripts/battle/round_resolution.gd")
const PowerEvaluation = preload("res://scripts/battle/power_evaluation.gd")
const Planner = preload("res://scripts/domain/selection_planner.gd")
const Content = preload("res://scripts/content.gd")
const Targeting = preload("res://scripts/battle/targeting.gd")
const Initiative = preload("res://scripts/battle/initiative.gd")
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
	return EncounterSetup.make_umbral(species, passive, uid, form_id)

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
	EncounterSetup.setup(party, deck, suspended_cards, enemies, encounter, rng, MAX_ACTIVE)
	if _needs_replacement():
		phase = "replacement"
	else:
		_begin_round()
	_sync_compatibility()
	state_changed.emit("encounter")

func active_party(only_able: bool = false) -> Array:
	return BattleView.active_party(party, only_able)

func reserves() -> Array:
	return BattleView.reserves(party)

func umbral_by_uid(uid: int) -> Dictionary:
	return _by_uid(party, uid)

func _by_uid(roster: Array, uid: int) -> Dictionary:
	return BattleView.by_uid(roster, uid)

func _at_slot(roster: Array, slot: int) -> Dictionary:
	return Targeting.at_slot(roster, slot)

func hand_capacity() -> int:
	return BattleView.hand_capacity(party, relics, hand_size_modifier, HAND_SIZE)

func action_budget() -> int:
	return BattleView.action_budget(relics, action_modifier, ENERGY)

func set_formation(uids_by_slot: Array) -> bool:
	if not Formation.set_formation(uids_by_slot, phase, expedition_mode, party, MAX_ACTIVE): return false
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
	return BattleView.first_living_slot(roster, MAX_ACTIVE)

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
	return BattleView.selected_cards(selected, hand)

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
	return Planning.swap_reason(slot, in_uid, phase, party, declined_replacements, queued_swaps, MAX_ACTIVE)

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
	return Planning.item_reason(item, uid, phase, party, inventory, queued_items)

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
	return BattleView.public_intents(enemy_plan, enemies, information_mode, mode)

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
	RoundAftermath.discard_hand(hand, discard_pile, selected, queued_swaps, queued_items)
	_sync_owner_zones()
	var aftermath: Dictionary = RoundAftermath.summarize(events, enemies, party)
	round_number += 1
	if not aftermath.party_alive:
		phase = "defeat"
	elif not aftermath.foes_alive:
		phase = "victory" if (Content.ENCOUNTERS[encounter].get("id", "") == "boss" if expedition_mode else Content.ENCOUNTERS[encounter].get("id", "") == Content.route_encounter_ids().back()) else "reward"
		if phase == "reward": _prepare_rewards()
	elif _needs_replacement():
		phase = "replacement"
	else:
		_begin_round()
	_sync_compatibility()
	RoundAftermath.complete_score(score, phase, applied_damage, int(aftermath.incoming_damage), events, passing, round_number - 1, encounter)
	last_result = score.duplicate(true)
	state_changed.emit("resolved")
	return score

func _needs_replacement() -> bool:
	return BattleView.needs_replacement(party, declined_replacements)

func replace_after_ko(slot: int, in_uid: int) -> bool:
	if not Formation.replace_after_ko(slot, in_uid, phase, party, round_number, MAX_ACTIVE): return false
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
	Rewards.prepare(reward_offers, party, starter_species, encounter, expedition_mode, next_uid, rng)

func capture_destinations(offer_index: int, replace_uid: int = -1) -> Array[int]:
	return Rewards.capture_destinations(offer_index, replace_uid, phase, reward_offers, party)

func choose_reward(offer_index: int, replace_uid: int = -1, capture_slot: int = -2) -> bool:
	if not Rewards.apply_offer(offer_index, replace_uid, capture_slot, phase, reward_offers, party, hand, deck, discard_pile, suspended_cards, MAX_TEAM): return false
	if reward_offers[offer_index].kind == "capture": next_uid += 1
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

func _sync_compatibility() -> void:
	var values: Dictionary = BattleView.compatibility(party, enemies)
	max_hp = values.max_hp
	player_hp = values.player_hp
	enemy_hp = values.enemy_hp
	enemy_burn = values.enemy_burn

func best_selection() -> Array[int]:
	return Planner.choose(hand, action_budget(), preview_selection)
