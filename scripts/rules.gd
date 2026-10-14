class_name UmbralRules
extends RefCounted
## Deterministic combat. Never accesses nodes, files, or the network.
signal state_changed(kind: String)

const Content = preload("res://scripts/content.gd")
const ENERGY = 3
const HAND_SIZE = 6
const MAX_SELECTED = 3
const ROUND_BUDGET = 7
const MAX_TEAM = 3

var rng = RandomNumberGenerator.new()
var seed_value: int = 0
var encounter: int = 0
var max_hp: int = 40
var player_hp: int = 40
var enemy_hp: int = 0
var enemy_burn: int = 0
var plays: int = ROUND_BUDGET
var discards: int = 2
var phase: String = "battle"
var party: Array = []
var hand: Array = []
var deck: Array = []
var discard_pile: Array = []
var selected: Array[int] = []
var reward_offers: Array = []
var next_uid: int = 3
var total_damage: int = 0
var actions: int = 0
var last_result: Dictionary = {}

static func make_umbral(species: String, passive: String, uid: int, stage: int = 1) -> Dictionary:
	return {"uid": uid, "species": species, "passive": passive, "stage": stage}

func new_run(run_seed: int) -> void:
	seed_value = run_seed
	rng.seed = run_seed
	encounter = 0
	player_hp = max_hp
	next_uid = 3
	party = [make_umbral("ember", _roll_passive("ember"), 1), make_umbral("moss", _roll_passive("moss"), 2)]
	total_damage = 0
	actions = 0
	last_result = {}
	reward_offers.clear()
	start_encounter()

func _roll_passive(species: String) -> String:
	var pool: Array = Content.PASSIVE_POOLS[species]
	return pool[rng.randi_range(0, pool.size() - 1)]

func _shuffle(cards: Array) -> void:
	for i in range(cards.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: Dictionary = cards[i]
		cards[i] = cards[j]
		cards[j] = temp

func start_encounter() -> void:
	phase = "battle"
	enemy_hp = Content.ENCOUNTERS[encounter].hp
	enemy_burn = 0
	plays = ROUND_BUDGET
	discards = 2
	selected.clear()
	hand.clear()
	deck.clear()
	discard_pile.clear()
	reward_offers.clear()
	for umbral in party:
		var power_ids: Array = Content.SPECIES[umbral.species].powers.duplicate()
		if int(umbral.stage) == 2:
			power_ids.append(Content.SPECIES[umbral.species].signature)
		for power_id in power_ids:
			for copy_number in range(2):
				deck.append({"instance_id": "%d:%s:%d" % [umbral.uid, power_id, copy_number], "owner": umbral.uid, "power": power_id})
	_shuffle(deck)
	_draw_hand()
	state_changed.emit("encounter")

func _draw_hand() -> void:
	while hand.size() < HAND_SIZE:
		if deck.is_empty():
			if discard_pile.is_empty(): break
			deck = discard_pile.duplicate(true)
			discard_pile.clear()
			_shuffle(deck)
		hand.append(deck.pop_back())

func umbral_by_uid(uid: int) -> Dictionary:
	for umbral in party:
		if int(umbral.uid) == uid: return umbral
	return {}

func intent_damage() -> int:
	var pattern: Array = Content.ENCOUNTERS[encounter].intents
	return pattern[(ROUND_BUDGET - plays) % pattern.size()]

func toggle(index: int) -> bool:
	if phase != "battle" or index < 0 or index >= hand.size(): return false
	if index in selected:
		selected.erase(index)
		state_changed.emit("selection")
		return true
	if selected.size() >= MAX_SELECTED: return false
	selected.append(index)
	state_changed.emit("selection")
	return true

func selected_cards() -> Array:
	var cards: Array = []
	for index in selected: cards.append(hand[index])
	return cards

static func evaluate(cards: Array, companions: Array, existing_burn: int = 0) -> Dictionary:
	var result: Dictionary = {"valid": false, "reason": "Selecione seus poderes", "name": "Prepare sua conjuração", "energy": 0, "damage": 0, "direct_damage": 0, "burn_added": 0, "burn_tick": 0, "block": 0, "heal": 0, "bonuses": []}
	if cards.is_empty() or cards.size() > MAX_SELECTED: return result
	var owners: Dictionary = {}
	for umbral in companions: owners[int(umbral.uid)] = umbral
	var active: Dictionary = {}
	var unique_cards: Dictionary = {}
	for card in cards:
		if not card.has("instance_id") or unique_cards.has(card.instance_id) or not owners.has(int(card.get("owner", -1))) or not Content.POWERS.has(card.get("power", "")):
			result.reason = "Poder inválido"
			return result
		var owner: Dictionary = owners[int(card.owner)]
		var allowed: Array = Content.SPECIES[owner.species].powers.duplicate()
		if int(owner.stage) == 2: allowed.append(Content.SPECIES[owner.species].signature)
		if not card.power in allowed:
			result.reason = "Este Umbral ainda não conhece esse poder"
			return result
		unique_cards[card.instance_id] = true
		active[int(card.owner)] = true
	var protected_moss: Dictionary = {}
	var discounted: Dictionary = {}
	for card in cards:
		var umbral: Dictionary = owners[int(card.owner)]
		var stats: Dictionary = Content.power_stats(card.power, int(umbral.stage))
		var damage: int = int(stats.damage)
		var block: int = int(stats.block)
		var heal: int = int(stats.heal)
		var burn: int = int(stats.burn)
		result.energy += int(stats.cost)
		if umbral.passive == "fierce" and damage > 0: damage += 3
		if umbral.passive == "resilient" and block > 0: block += 3
		if umbral.passive == "vital" and heal > 0: heal += 2
		if umbral.passive == "ardent" and damage > 0: burn += 2
		if umbral.passive == "swift" and not discounted.has(int(umbral.uid)):
			result.energy -= 1
			discounted[int(umbral.uid)] = true
			result.bonuses.append("%s: Ágil −1 energia" % Content.display_name(umbral))
		var trait_value: int = Content.SPECIES[umbral.species].trait_values[int(umbral.stage) - 1]
		if umbral.species == "ember" and damage > 0:
			burn += trait_value
			result.bonuses.append("Combustão +%d queimadura" % trait_value)
		if umbral.species == "moss" and block > 0 and not protected_moss.has(int(umbral.uid)):
			heal += trait_value
			protected_moss[int(umbral.uid)] = true
			result.bonuses.append("Raízes Vivas +%d cura" % trait_value)
		if umbral.species == "volt" and damage > 0 and active.size() > 1:
			var extra: int = trait_value * (active.size() - 1)
			damage += extra
			result.bonuses.append("Circuito Vivo +%d dano" % extra)
		result.direct_damage += damage
		result.block += block
		result.heal += heal
		result.burn_added += burn
	if active.size() == 3:
		result.direct_damage += 6
		result.bonuses.append("Vínculo triplo +6 dano")
	result.burn_tick = existing_burn + int(result.burn_added)
	result.damage = int(result.direct_damage) + int(result.burn_tick)
	result.name = "Vínculo triplo" if active.size() == 3 else "Conjuração conjunta" if active.size() == 2 else "Poder de " + Content.display_name(owners[active.keys()[0]])
	result.valid = int(result.energy) <= ENERGY
	result.reason = "" if result.valid else "Energia insuficiente"
	return result

func preview() -> Dictionary:
	return evaluate(selected_cards(), party, enemy_burn)

func play() -> Dictionary:
	if phase != "battle" or plays <= 0: return {"ok": false, "reason": "invalid_phase"}
	var score: Dictionary = preview()
	if not score.valid: return {"ok": false, "reason": score.reason}
	var incoming: int = intent_damage()
	var applied_damage: int = mini(enemy_hp, int(score.damage))
	enemy_hp = maxi(0, enemy_hp - int(score.damage))
	enemy_burn = maxi(0, enemy_burn + int(score.burn_added) - 1)
	player_hp = mini(max_hp, player_hp + int(score.heal))
	total_damage += applied_damage
	plays -= 1
	actions += 1
	_remove_selected()
	if enemy_hp == 0:
		phase = "victory" if encounter == Content.ENCOUNTERS.size() - 1 else "reward"
		if phase == "reward": _prepare_rewards()
		score["incoming"] = 0
	else:
		score["incoming"] = maxi(0, incoming - int(score.block))
		player_hp = maxi(0, player_hp - int(score.incoming))
		if player_hp == 0 or plays == 0: phase = "defeat"
	_draw_hand()
	score["ok"] = true
	score["phase"] = phase
	score["applied_damage"] = applied_damage
	last_result = score.duplicate(true)
	state_changed.emit("resolved")
	return score

func redraw() -> bool:
	if phase != "battle" or selected.is_empty() or discards <= 0: return false
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
	var has_volt: bool = false
	for umbral in party:
		if umbral.species == "volt": has_volt = true
	var species: String = "volt" if not has_volt else ["ember", "moss", "volt"][rng.randi_range(0, 2)]
	reward_offers.append({"kind": "capture", "umbral": make_umbral(species, _roll_passive(species), next_uid)})
	for umbral in party:
		if int(umbral.stage) < 2:
			reward_offers.append({"kind": "evolve", "uid": umbral.uid})

func choose_reward(offer_index: int, replace_uid: int = -1) -> bool:
	if phase != "reward" or offer_index < 0 or offer_index >= reward_offers.size(): return false
	var offer: Dictionary = reward_offers[offer_index]
	if offer.kind == "capture":
		if party.size() >= MAX_TEAM:
			var replace_index: int = -1
			for i in range(party.size()):
				if int(party[i].uid) == replace_uid: replace_index = i
			if replace_index == -1: return false
			party[replace_index] = offer.umbral.duplicate(true)
		else:
			party.append(offer.umbral.duplicate(true))
		next_uid += 1
	else:
		var umbral: Dictionary = umbral_by_uid(int(offer.uid))
		if umbral.is_empty() or int(umbral.stage) >= 2: return false
		umbral.stage = 2
	player_hp = mini(max_hp, player_hp + 8)
	encounter += 1
	start_encounter()
	return true

func best_selection() -> Array[int]:
	# A bounded heuristic player for integration tests and balance exploration.
	var best: Array[int] = []
	var best_value: float = -INF
	for mask in range(1, 1 << hand.size()):
		var indices: Array[int] = []
		var cards: Array = []
		for i in range(hand.size()):
			if mask & (1 << i):
				indices.append(i)
				cards.append(hand[i])
		if cards.size() > MAX_SELECTED: continue
		var score: Dictionary = evaluate(cards, party, enemy_burn)
		if not score.valid: continue
		var incoming: int = maxi(0, intent_damage() - int(score.block))
		var healing: int = mini(max_hp - player_hp, int(score.heal))
		var after_hp: int = player_hp + healing - incoming
		var value: float = mini(enemy_hp, int(score.damage)) + mini(intent_damage(), int(score.block)) * 1.25 + healing * 1.4
		if int(score.damage) >= enemy_hp:
			value = 10000 + healing - int(score.energy)
		elif after_hp <= 0:
			value -= 20000
		elif after_hp < 12:
			value -= (12 - after_hp) * 4
		if value > best_value:
			best_value = value
			best = indices
	return best
