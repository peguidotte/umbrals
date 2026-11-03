class_name UmbralRules
extends RefCounted
## Deterministic combat. Never accesses nodes, files, or the network.
signal state_changed(kind: String)

const Models = preload("res://scripts/domain/models.gd")
const Ids = preload("res://scripts/domain/ids.gd")
const Snapshot = preload("res://scripts/domain/run_snapshot.gd")
const Inventory = preload("res://scripts/domain/inventory.gd")
const Cast = preload("res://scripts/domain/cast_evaluator.gd")
const Combat = preload("res://scripts/domain/combat_records.gd")
const Resolver = preload("res://scripts/domain/effect_resolver.gd")
const Content = preload("res://scripts/content.gd")
const ENERGY = 3
const HAND_SIZE = 6
const MAX_SELECTED = 3
const ROUND_BUDGET = 7
const MAX_TEAM = 3

var catalog: Content.Catalog

func _init(definitions: Content.Catalog = null) -> void:
	catalog = definitions if definitions != null else Content.create_catalog()

var inventory: Inventory = Inventory.new()
var history: Array[Combat.Event] = []
var rng = RandomNumberGenerator.new()
var seed_value: int = 0
var encounter: int = 0
var max_hp: int = 40
var player_hp: int = 40
var enemy_hp: int = 0
var statuses: Array[Combat.StatusInstance] = []
var enemy_block: int = 0
var player_block: int = 0
var enemy_burn: int:
	get: return combat_state().stacks("burn")
	set(value):
		for status in statuses.duplicate():
			if status.target == "enemy" and status.definition.status_id == "burn": statuses.erase(status)
		if value > 0:
			var state = Combat.State.new()
			state.statuses = statuses
			Resolver.add_status(state, Combat.Request.new("status", value, "enemy", "burn", -1, Content.Power.BURN))
var plays: int = ROUND_BUDGET
var discards: int = 2
var phase: String = Ids.BATTLE
var party: Array[Models.Individual] = []
var hand: Array[Models.CardInstance] = []
var deck: Array[Models.CardInstance] = []
var discard_pile: Array[Models.CardInstance] = []
var selected: Array[int] = []
var reward_offers: Array[Models.RewardOffer] = []
var next_uid: int = 3
var total_damage: int = 0
var actions: int = 0
var last_result: Models.ResolutionResult

static func make_umbral(species: String, passive: String, uid: int, form_id: String = "", definitions: Content.Catalog = null) -> Models.Individual:
	return (definitions if definitions != null else Content.DEFAULT).make_individual(species, passive, uid, form_id)

func new_run(run_seed: int) -> void:
	inventory.reset(catalog.items)
	history.clear()
	seed_value = run_seed
	rng.seed = run_seed
	encounter = 0
	player_hp = max_hp
	next_uid = 3
	party = [catalog.make_individual("ember", _roll_passive("ember"), 1), catalog.make_individual("moss", _roll_passive("moss"), 2)]
	total_damage = 0
	actions = 0
	last_result = null
	reward_offers.clear()
	start_encounter()

func _roll_passive(species: String) -> String:
	var pool: PackedStringArray = catalog.species[species].passive_pool
	return pool[rng.randi_range(0, pool.size() - 1)]

func _shuffle(cards: Array[Models.CardInstance]) -> void:
	for i in range(cards.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: Models.CardInstance = cards[i]
		cards[i] = cards[j]
		cards[j] = temp

func start_encounter() -> void:
	phase = Ids.BATTLE
	enemy_hp = catalog.encounters[encounter].hp
	statuses.clear()
	enemy_block = 0
	player_block = 0
	plays = ROUND_BUDGET
	discards = 2
	selected.clear()
	hand.clear()
	deck.clear()
	discard_pile.clear()
	reward_offers.clear()
	for umbral in party:
		var shape: Content.Form = catalog.form(umbral)
		for power in shape.powers:
			for copy_number in range(shape.copies_per_power):
				deck.append(Models.CardInstance.new(power.power_id, umbral.uid, copy_number))
	_shuffle(deck)
	_draw_hand()
	state_changed.emit("encounter")

func _draw_hand(target_size: int = HAND_SIZE) -> void:
	while hand.size() < target_size:
		if deck.is_empty():
			if discard_pile.is_empty(): break
			deck = discard_pile.duplicate(true)
			discard_pile.clear()
			_shuffle(deck)
		hand.append(deck.pop_back())

func umbral_by_uid(uid: int) -> Models.Individual:
	for umbral in party:
		if int(umbral.uid) == uid: return umbral
	return null

func enemy_action() -> Resource:
	var pattern: Array = catalog.encounters[encounter].enemy.actions
	return pattern[(ROUND_BUDGET - plays) % pattern.size()]

func intent_damage() -> int:
	var damage: int = 0
	for effect in enemy_action().effects:
		if effect.operation == "damage" and effect.target == "player": damage += effect.amount
	return damage

func combat_state() -> Combat.State:
	var state = Combat.State.new()
	state.player_hp = player_hp
	state.player_max = max_hp
	state.enemy_hp = enemy_hp
	state.enemy_max = catalog.encounters[encounter].hp
	state.enemy_block = enemy_block
	state.player_block = player_block
	state.statuses = statuses
	state.draw_capacity = maxi(0, deck.size() + discard_pile.size() + hand.size() - maxi(HAND_SIZE, hand.size()))
	return state

func toggle(index: int) -> bool:
	if phase != Ids.BATTLE or index < 0 or index >= hand.size(): return false
	if index in selected:
		selected.erase(index)
		state_changed.emit("selection")
		return true
	if selected.size() >= MAX_SELECTED: return false
	selected.append(index)
	state_changed.emit("selection")
	return true

func selected_cards() -> Array[Models.CardInstance]:
	var cards: Array[Models.CardInstance] = []
	for index in selected: cards.append(hand[index])
	return cards

static func evaluate(cards: Array[Models.CardInstance], companions: Array[Models.Individual], existing_burn: int = 0, definitions: Content.Catalog = null) -> Models.CastEvaluation:
	return Cast.evaluate(cards, companions, existing_burn, false, null, definitions)

func preview() -> Models.CastEvaluation:
	return preview_round().evaluation

func project(cards: Array[Models.CardInstance]) -> Models.ResolutionResult:
	# Pure: all round consequences are computed before any state/RNG changes.
	var result = Models.ResolutionResult.new()
	result.evaluation = Cast.evaluate(cards, party, enemy_burn, enemy_hp < catalog.encounters[encounter].hp, combat_state(), catalog)
	if phase != Ids.BATTLE or plays <= 0: return result
	if not result.evaluation.valid:
		result.reason = result.evaluation.reason
		return result
	var score: Models.CastEvaluation = result.evaluation
	result.ok = true
	result.reason = ""
	var retaliation: Array[Combat.Request] = []
	for effect in enemy_action().effects:
		var burning: bool = combat_state().stacks("burn", effect.target) > 0
		var wounded: bool = player_hp < max_hp if effect.target == "player" else enemy_hp < catalog.encounters[encounter].hp
		if effect.enabled(burning, wounded): retaliation.append(Combat.Request.new(effect.operation, effect.amount, effect.target, enemy_action().action_id, -1, effect.status))
	inventory.modify(score.requests)
	var initial: Combat.State = combat_state()
	initial.draw_capacity = maxi(0, deck.size() + discard_pile.size() + hand.size() - maxi(HAND_SIZE, hand.size() - cards.size()))
	var outcome: Combat.Outcome = Resolver.resolve(initial, score.requests, retaliation)
	score.block = 0
	score.heal = 0
	score.direct_damage = 0
	for request in score.requests:
		if request.operation == "block" and request.target == "player": score.block += request.amount
		if request.operation == "heal" and request.target == "player": score.heal += request.amount
		if request.operation == "damage" and request.target == "enemy": score.direct_damage += request.amount
	score.damage = 0
	for event in outcome.events:
		if event.kind == "damage" and event.target == "enemy" and event.phase != "enemy_action": score.damage += event.requested
	result.state_after = outcome.state
	result.combat_events = outcome.events
	result.applied_damage = outcome.total("damage", "enemy")
	result.enemy_hp_after = outcome.state.enemy_hp
	result.burn_after = outcome.state.stacks("burn")
	result.effective_heal = outcome.total("heal", "player")
	result.plays_after = plays - 1
	result.incoming = outcome.total("damage", "player")
	result.player_hp_after = outcome.state.player_hp
	result.extra_draw = outcome.state.draw
	result.phase = Ids.BATTLE
	if result.enemy_hp_after == 0:
		result.phase = Ids.VICTORY if encounter == catalog.encounters.size() - 1 else Ids.REWARD
	elif result.player_hp_after == 0 or result.plays_after == 0:
		result.phase = Ids.DEFEAT
	return result

func preview_round() -> Models.ResolutionResult:
	return project(selected_cards())

func play() -> Models.ResolutionResult:
	var result: Models.ResolutionResult = preview_round()
	if not result.ok: return result
	enemy_hp = result.enemy_hp_after
	statuses = result.state_after.clone().statuses
	enemy_block = result.state_after.enemy_block
	player_block = 0
	player_hp = result.player_hp_after
	total_damage += result.applied_damage
	plays = result.plays_after
	actions += 1
	_remove_selected()
	phase = result.phase
	if phase == Ids.REWARD: _prepare_rewards()
	_draw_hand(maxi(HAND_SIZE, hand.size()) + result.extra_draw)
	history.append_array(result.combat_events)
	last_result = result
	state_changed.emit("resolved")
	return result

func redraw() -> bool:
	if phase != Ids.BATTLE or selected.is_empty() or discards <= 0: return false
	discards -= 1
	actions += 1
	_remove_selected()
	_draw_hand()
	state_changed.emit("redraw")
	return true

func _remove_selected() -> void:
	selected.sort()
	selected.reverse()
	for index in selected:
		discard_pile.append(hand[index])
		hand.remove_at(index)
	selected.clear()

func _prepare_rewards() -> void:
	reward_offers.clear()
	var table = catalog.encounters[encounter].rewards
	var guaranteed: String = table.guaranteed_missing_species
	for umbral in party:
		if umbral.species_id == guaranteed: guaranteed = ""
	var pool: Array = catalog.species.keys() if table.capture_pool.is_empty() else Array(table.capture_pool)
	var species: String = guaranteed if not guaranteed.is_empty() else pool[rng.randi_range(0, pool.size() - 1)]
	reward_offers.append(Models.RewardOffer.new(Ids.CAPTURE, catalog.make_individual(species, _roll_passive(species), next_uid)))
	for umbral in party:
		for transition in catalog.form(umbral).evolutions:
			if transition.eligible(encounter, player_hp, umbral.passive):
				reward_offers.append(Models.RewardOffer.new(Ids.EVOLVE, null, umbral.uid, transition.target_form_id, umbral.form_id, transition.transition_id))

func choose_reward(offer_index: int, replace_uid: int = -1) -> bool:
	if phase != Ids.REWARD or offer_index < 0 or offer_index >= reward_offers.size(): return false
	var offer: Models.RewardOffer = reward_offers[offer_index]
	if offer.kind == Ids.CAPTURE:
		if party.size() >= MAX_TEAM:
			var replace_index: int = -1
			for i in range(party.size()):
				if int(party[i].uid) == replace_uid: replace_index = i
			if replace_index == -1: return false
			party[replace_index] = offer.umbral.clone()
		else:
			party.append(offer.umbral.clone())
		next_uid += 1
	elif offer.kind == Ids.EVOLVE:
		var umbral: Models.Individual = umbral_by_uid(int(offer.uid))
		if umbral == null or umbral.form_id != offer.source_form_id: return false
		var transition = catalog.form(umbral).transition(offer.transition_id)
		if transition == null or transition.target_form_id != offer.target_form_id or not transition.eligible(encounter, player_hp, umbral.passive): return false
		if catalog.species[umbral.species_id].form(offer.target_form_id) == null: return false
		player_hp -= transition.health_cost
		umbral.form_id = offer.target_form_id
	else:
		return false
	inventory.detach_missing(party_uids())
	player_hp = mini(max_hp, player_hp + catalog.encounters[encounter].rewards.heal)
	encounter += 1
	start_encounter()
	return true

func party_uids() -> Array[int]:
	var uids: Array[int] = []
	for individual in party: uids.append(individual.uid)
	return uids

func equip_item(id: int, uid: int) -> bool:
	if phase != Ids.BATTLE or not inventory.equip(id, uid, party_uids()): return false
	state_changed.emit("inventory")
	return true

func use_item(id: int) -> Combat.Outcome:
	if phase != Ids.BATTLE: return null
	var outcome: Combat.Outcome = inventory.consume(id, combat_state())
	if outcome == null: return null
	player_hp = outcome.state.player_hp
	total_damage += outcome.total("damage", "enemy")
	enemy_hp = outcome.state.enemy_hp
	statuses = outcome.state.statuses
	enemy_block = outcome.state.enemy_block
	player_block = outcome.state.player_block
	_draw_hand(maxi(HAND_SIZE, hand.size()) + outcome.state.draw)
	history.append_array(outcome.events)
	actions += 1
	if enemy_hp == 0:
		phase = Ids.VICTORY if encounter == catalog.encounters.size() - 1 else Ids.REWARD
		if phase == Ids.REWARD: _prepare_rewards()
	elif player_hp == 0: phase = Ids.DEFEAT
	state_changed.emit("item")
	return outcome

func snapshot() -> Dictionary:
	# JSON boundary shared by diagnostics and replay assertions; never exposes mutable records.
	return {"phase": phase, "party": Models.records(party), "hand": Models.records(hand), "deck": Models.records(deck), "discard": Models.records(discard_pile), "selected": selected.duplicate(), "hp": player_hp, "enemy_hp": enemy_hp, "burn": enemy_burn, "intent": intent_damage(), "plays": plays, "actions": actions, "discards": discards, "encounter": encounter, "offers": Models.records(reward_offers), "inventory": Models.records(inventory.items), "history": Models.records(history), "statuses": Models.records(statuses), "player_block": player_block, "enemy_block": enemy_block, "preview": preview().to_dict()}

func export_state() -> Dictionary:
	return Snapshot.capture(self)

func restore_state(data: Variant) -> bool:
	var decoded: Dictionary = Snapshot.decode(data, catalog)
	if not decoded.ok: return false
	for field in decoded.state: set(field, decoded.state[field])
	seed_value = decoded.seed_value
	rng.seed = decoded.rng_seed
	rng.state = decoded.rng_state
	state_changed.emit("restored")
	return true
