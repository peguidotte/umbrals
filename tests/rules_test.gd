extends SceneTree
const Cases = preload("res://tests/support/case_selection.gd")
const Planner = preload("res://scripts/domain/selection_planner.gd")

const Models = preload("res://scripts/domain/models.gd")
const Rules = preload("res://scripts/rules.gd")
const Content = preload("res://scripts/content.gd")
var checks: int = 0
var failures: Array[String] = []

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		printerr("FAIL: " + description)

func unit(species: String, passive: String = "vital", uid: int = 1, form_id: String = "") -> Models.Individual:
	return Rules.make_umbral(species, passive, uid, form_id)

func power(id: String, owner: int = 1, copy_number: int = 0) -> Models.CardInstance:
	return Models.CardInstance.new(id, owner, copy_number)

func _init() -> void:
	if not Cases.run({"traits": test_traits, "individual_passives": test_individual_passives, "energy_and_ownership": test_energy_and_ownership, "determinism_and_inputs": test_determinism_and_inputs, "round_resolution": test_round_resolution, "capture_and_evolution": test_capture_and_evolution, "simulations": test_simulations}):
		quit(2)
		return
	print(JSON.stringify({"case": Cases.active_case, "cases": Cases.executed, "suite": "umbral_rules", "checks": checks, "failed": failures.size(), "failures": failures}))
	quit(0 if failures.is_empty() else 1)

func test_traits() -> void:
	var ember: Array[Models.Individual] = [unit("ember")]
	var ball: Models.CastEvaluation = Rules.evaluate([power("fireball")], ember)
	expect(ball.valid and ball.direct_damage == 12 and ball.burn_added == 2 and ball.damage == 14, "Brasa fireball deals 12 direct plus 2 Combustão")
	expect(Rules.evaluate([power("cinder_claw")], ember).burn_added == 5, "Claw's burn and species trait stack")
	expect(Rules.evaluate([power("flame_guard")], ember).burn_added == 0, "Combustão requires an attack")
	expect(Rules.evaluate([power("fireball")], ember, 6).damage == 20, "Existing burn and newly applied burn tick together")
	var moss: Array[Models.Individual] = [unit("moss")]
	var roots: Models.CastEvaluation = Rules.evaluate([power("root_wall")], moss)
	expect(roots.block == 12 and roots.heal == 2, "Musgo's protection activates Raízes Vivas")
	var double_roots: Models.CastEvaluation = Rules.evaluate([power("root_wall"), power("root_wall", 1, 1)], moss)
	expect(double_roots.block == 24 and double_roots.heal == 2, "Raízes Vivas heals once per individual per round")
	expect(Rules.evaluate([power("life_seed")], moss).heal == 8, "A healing power does not activate the protection trait")
	var team: Array[Models.Individual] = [unit("ember", "vital", 1), unit("moss", "vital", 2), unit("volt", "vital", 3)]
	expect(Rules.evaluate([power("lightning", 3)], team).damage == 11, "Circuito Vivo needs another active Umbral")
	var pair: Models.CastEvaluation = Rules.evaluate([power("fireball"), power("lightning", 3)], team)
	expect(pair.damage == 29, "Two-Umbral casting activates Circuito Vivo")
	var trio: Models.CastEvaluation = Rules.evaluate([power("fireball"), power("root_wall", 2), power("lightning", 3)], team)
	expect(trio.damage == 39 and trio.block == 12 and trio.heal == 2, "Three-Umbral cast combines all traits and the +6 link bonus")
	var reverse_trio: Array[Models.CardInstance] = [power("lightning", 3), power("root_wall", 2), power("fireball")]
	var reverse: Models.CastEvaluation = Rules.evaluate(reverse_trio, team)
	expect(reverse.damage == trio.damage and reverse.energy == trio.energy, "Selection order does not change a simultaneous cast")
	var evolved: Array[Models.Individual] = [unit("ember", "vital", 1, "ignivar")]
	var evolved_ball: Models.CastEvaluation = Rules.evaluate([power("fireball")], evolved)
	expect(evolved_ball.direct_damage == 17 and evolved_ball.burn_added == 4, "Evolution improves existing powers and species trait")
	expect(Rules.evaluate([power("inferno")], evolved).damage == 42, "Evolved Brasa unlocks Sol devorador with 42 total damage")
	var sanctuary: Models.CastEvaluation = Rules.evaluate([power("sanctuary")], [unit("moss", "fierce", 1, "verdalio")])
	expect(sanctuary.valid and sanctuary.block == 22 and sanctuary.heal == 12, "Verdálio unlocks its upgraded sanctuary and stronger healing trait")
	var judgment: Models.CastEvaluation = Rules.evaluate([power("fireball"), power("judgment", 3)], [unit("ember"), unit("volt", "vital", 3, "tempestral")])
	expect(judgment.valid and judgment.damage == 56 and judgment.block == 9, "Tempestral unlocks judgment with the stronger shared-cast trait")
	var twin_moss: Models.CastEvaluation = Rules.evaluate([power("root_wall"), power("root_wall", 2)], [unit("moss"), unit("moss", "vital", 2)])
	expect(twin_moss.heal == 4, "Two individual Musgo can each trigger their own trait")

func test_individual_passives() -> void:
	expect(Rules.evaluate([power("fireball")], [unit("ember", "fierce")]).damage == 17, "Feroz increases direct attack damage")
	expect(Rules.evaluate([power("root_wall")], [unit("moss", "resilient")]).block == 15, "Resiliente increases shield")
	expect(Rules.evaluate([power("life_seed")], [unit("moss", "vital")]).heal == 8, "Vital increases healing powers")
	expect(Rules.evaluate([power("fireball")], [unit("ember", "ardent")]).burn_added == 4, "Ardente and Combustão stack")
	var swift: Array[Models.Individual] = [unit("volt", "swift")]
	var double_dive: Array[Models.CardInstance] = [power("storm_dive"), power("storm_dive", 1, 1)]
	expect(Rules.evaluate(double_dive, swift).energy == 3, "Ágil discounts exactly one energy per individual per round")
	expect(Rules.evaluate([power("lightning"), power("lightning", 1, 1)], swift).energy == 1, "Ágil does not discount every card")
	var team: Array[Models.Individual] = [unit("ember", "swift", 1), unit("moss", "swift", 2)]
	expect(Rules.evaluate([power("fireball"), power("root_wall", 2)], team).energy == 0, "Different individuals can each use their discount")
	var passive_types: Dictionary = {}
	for seed_number in range(50):
		var g = Rules.new()
		g.new_run(seed_number)
		for u in g.party:
			passive_types[u.passive] = true
			expect(u.passive in Content.SPECIES[u.species_id].passive_pool, "Random individuals only roll passives useful to their species")
	expect(passive_types.size() == 5, "Seeded population includes all five individual passives")

func test_energy_and_ownership() -> void:
	var volt: Array[Models.Individual] = [unit("volt")]
	var over: Models.CastEvaluation = Rules.evaluate([power("storm_dive"), power("storm_dive", 1, 1)], volt)
	expect(not over.valid and over.energy == 4, "Four-energy cast is rejected")
	expect(Rules.evaluate([power("storm_dive"), power("lightning")], volt).valid, "Exactly three energy is allowed")
	expect(not Rules.evaluate([], volt).valid, "Empty cast is not an action")
	expect(not Rules.evaluate([power("lightning", 99)], volt).valid, "Powers require a present owner")
	expect(not Rules.evaluate([power("fireball")], volt).valid, "A species cannot use another species' power")
	expect(not Rules.evaluate([power("judgment")], volt).valid, "Signature is locked before evolution")
	expect(not Rules.evaluate([power("missing")], volt).valid, "Unknown powers are rejected")
	expect(not Rules.evaluate([power("lightning"), power("lightning")], volt).valid, "The same card instance cannot be used twice")
	expect(not Rules.evaluate([power("lightning", 1, 0), power("lightning", 1, 1), power("static_veil"), power("storm_dive")], volt).valid, "Four powers exceed the selection cap")

func test_determinism_and_inputs() -> void:
	var a = Rules.new()
	var b = Rules.new()
	a.new_run(42013)
	b.new_run(42013)
	expect(Models.records(a.party) == Models.records(b.party) and Models.records(a.hand) == Models.records(b.hand) and Models.records(a.deck) == Models.records(b.deck), "Same seed reproduces individuals, passives, and shuffle")
	expect(a.party.size() == 2 and a.hand.size() == 6 and a.deck.size() == 6, "Starter pair contributes twelve powers and deals six")
	for c in a.hand + a.deck:
		expect(a.umbral_by_uid(c.owner) != null, "Every dealt power belongs to the current team")
	var before_rng: int = a.rng.state
	var before_hand: Array = Models.records(a.hand)
	a.toggle(0)
	a.preview()
	a.preview()
	expect(a.rng.state == before_rng and Models.records(a.hand) == before_hand, "Repeated previews neither reroll nor mutate the hand")
	expect(not a.toggle(-1) and not a.toggle(6), "Out-of-range power selection is rejected")
	a.toggle(1)
	a.toggle(2)
	expect(not a.toggle(3) and a.selected.size() == 3, "Only three powers can be selected")
	a.toggle(0)
	expect(a.selected.size() == 2, "Selecting again deselects")
	var turn_before: int = a.plays
	var intent_before: int = a.intent_damage()
	expect(a.redraw(), "Selected powers can be exchanged")
	expect(a.selected.is_empty() and a.hand.size() == 6 and a.discards == 1, "Exchange spends one charge and refills the hand")
	expect(a.plays == turn_before and a.intent_damage() == intent_before, "Exchange does not advance the enemy's intention")
	expect(not a.redraw(), "Empty exchange does not consume a charge")
	a.toggle(0)
	a.redraw()
	a.toggle(0)
	expect(not a.redraw(), "Exhausted exchanges cannot be reused")
	expect(a.hand.size() + a.deck.size() + a.discard_pile.size() == 12, "Exchanges conserve the deck")

func test_round_resolution() -> void:
	var g = Rules.new()
	g.new_run(1)
	g.party.assign([unit("ember")])
	g.start_encounter()
	expect(not g.play().ok and g.plays == 7, "Empty play leaves round budget untouched")
	g.hand.assign([power("fireball")])
	g.selected.assign([0])
	var result: Models.ResolutionResult = g.play()
	expect(result.ok and g.enemy_hp == 91 and g.enemy_burn == 1, "Fireball resolves direct damage, burn tick and burn decay")
	expect(g.player_hp == 33, "Unprotected survivor counterattacks for its announced seven damage")
	g.hand.assign([power("flame_guard")])
	g.selected.assign([0])
	result = g.play()
	expect(result.evaluation.damage == 1 and result.incoming == 1 and g.enemy_burn == 0, "Persistent burn ticks with protection and then expires")
	g.new_run(1)
	g.party.assign([unit("moss")])
	g.start_encounter()
	g.player_hp = 20
	g.hand.assign([power("root_wall")])
	g.selected.assign([0])
	result = g.play()
	expect(g.player_hp == 22 and result.incoming == 0, "Shield prevents the counterattack while the trait heals")
	g.hand.assign([power("life_seed")])
	g.selected.assign([0])
	g.player_hp = 39
	result = g.play()
	expect(g.player_hp == 31, "Healing is capped before the announced nine damage counterattack")
	g.new_run(1)
	g.enemy_hp = 4
	g.enemy_burn = 4
	g.hand.assign([power("root_wall", 2)])
	g.selected.assign([0])
	var hp: int = g.player_hp
	result = g.play()
	expect(g.phase == "reward" and g.enemy_hp == 0 and result.incoming == 0, "Burn can kill before the counterattack")
	expect(g.player_hp == hp and g.total_damage == 4, "Kills avoid retaliation and damage statistics exclude overkill")
	expect(not g.toggle(0) and not g.play().ok and not g.redraw(), "Combat inputs are blocked during rewards")
	g.new_run(1)
	g.party.assign([unit("volt")])
	g.start_encounter()
	g.hand.assign([power("storm_dive"), power("storm_dive", 1, 1)])
	g.selected.assign([0, 1])
	var before: String = JSON.stringify({"hand": Models.records(g.hand), "hp": g.player_hp, "enemy": g.enemy_hp, "plays": g.plays, "rng": g.rng.state})
	expect(not g.play().ok, "Over-budget action cannot be executed")
	expect(before == JSON.stringify({"hand": Models.records(g.hand), "hp": g.player_hp, "enemy": g.enemy_hp, "plays": g.plays, "rng": g.rng.state}), "Rejected action has no side effects")
	g.new_run(1)
	g.player_hp = 1
	g.hand.assign([power("fireball", 1)])
	g.selected.assign([0])
	g.play()
	expect(g.phase == "defeat" and g.player_hp == 0, "An unblocked hit can end the expedition")
	g.new_run(1)
	g.plays = 1
	g.hand.assign([power("life_seed", 2)])
	g.selected.assign([0])
	g.play()
	expect(g.phase == "defeat" and g.plays == 0, "A living enemy at the round limit ends the fight")

func force_reward(g: Rules) -> void:
	g.enemy_hp = 1
	g.hand.assign([power("fireball", int(g.party[0].uid))])
	g.selected.assign([0])
	g.play()

func test_capture_and_evolution() -> void:
	var g = Rules.new()
	g.new_run(42013)
	force_reward(g)
	expect(g.reward_offers.size() == 3 and g.reward_offers[0].umbral.species_id == "volt", "First clear offers a new species plus two evolutions")
	var offers: Array = Models.records(g.reward_offers)
	var rolled_state: int = g.rng.state
	expect(not g.choose_reward(-1) and not g.choose_reward(99), "Unknown reward choices are rejected")
	expect(Models.records(g.reward_offers) == offers and g.rng.state == rolled_state, "Inspecting/rejecting rewards never rerolls the individual")
	var candidate: Models.Individual = g.reward_offers[0].umbral.clone()
	g.player_hp = 33
	expect(g.choose_reward(0), "Capture accepts the individual on the offer")
	expect(g.party.size() == 3 and g.party[2].to_dict() == candidate.to_dict() and g.player_hp == 40, "Capture preserves its rolled passive and caps reward healing")
	expect(g.encounter == 1 and g.plays == 7 and g.discards == 2, "Reward advances the fight and refreshes action budgets")
	var lightning_count: int = 0
	for c in g.hand + g.deck:
		if c.power == "lightning" and c.owner == candidate.uid: lightning_count += 1
	expect(lightning_count == 2, "Captured Umbral's actual powers enter the new deck")
	expect(not g.choose_reward(0), "Reward cannot be claimed twice")
	force_reward(g)
	var passive: String = g.party[0].passive
	expect(g.choose_reward(1), "Existing Brasa can evolve instead of capturing")
	expect(g.party[0].form_id == "ignivar" and g.party[0].passive == passive and Content.display_name(g.party[0]) == "Ignivar", "Evolution changes form while preserving identity and passive")
	var signatures: int = 0
	for c in g.hand + g.deck:
		if c.power == "inferno": signatures += 1
	expect(signatures == 2 and g.hand.size() + g.deck.size() == 20, "Evolution unlocks two signature cards alongside upgraded powers")
	force_reward(g)
	expect(g.phase == "victory", "Final clear completes the run")

	var replacement = Rules.new()
	replacement.new_run(42013)
	force_reward(replacement)
	replacement.choose_reward(0)
	force_reward(replacement)
	var team_before: Array = Models.records(replacement.party)
	expect(not replacement.choose_reward(0), "Full team requires an explicit replacement choice")
	expect(Models.records(replacement.party) == team_before and replacement.phase == "reward", "A missing replacement never loses a current ally")
	var old_uid: int = replacement.party[1].uid
	var incoming: Models.Individual = replacement.reward_offers[0].umbral.clone()
	expect(replacement.choose_reward(0, old_uid), "Capture can explicitly replace one ally")
	expect(replacement.party.size() == 3 and replacement.umbral_by_uid(old_uid) == null and replacement.party[1].to_dict() == incoming.to_dict(), "Replacement preserves incoming individual and team size")
	for c in replacement.hand + replacement.deck:
		expect(c.owner != old_uid, "Rebuilt deck removes powers from the released Umbral")

func test_simulations() -> void:
	var wins: int = 0
	var reasons: Dictionary = {"health": 0, "round_limit": 0}
	for seed_number in range(100):
		var g = Rules.new()
		g.new_run(seed_number)
		var steps: int = 0
		while g.phase not in ["victory", "defeat"] and steps < 30:
			if g.phase == "reward":
				g.choose_reward(0 if g.encounter == 0 else 1)
			else:
				g.selected = Planner.choose(g.hand, g.project, g.intent_damage())
				expect(not g.selected.is_empty() and g.preview().valid, "Seed %d has a legal action" % seed_number)
				g.play()
			steps += 1
			expect(g.player_hp >= 0 and g.player_hp <= g.max_hp and g.enemy_hp >= 0 and g.enemy_burn >= 0, "Seed %d maintains bounded combat state" % seed_number)
			var seen: Dictionary = {}
			for c in g.hand + g.deck + g.discard_pile: seen[c.instance_id] = true
			var expected_cards: int = 0
			for u in g.party: expected_cards += Content.form(u).powers.size() * Content.form(u).copies_per_power
			expect(seen.size() == expected_cards and seen.size() == g.hand.size() + g.deck.size() + g.discard_pile.size(), "Seed %d conserves unique power instances through recycling" % seed_number)
			expect(g.hand.size() == 6 and g.selected.is_empty(), "Seed %d refills and clears selection" % seed_number)
		expect(g.phase in ["victory", "defeat"], "Seed %d reaches a terminal outcome" % seed_number)
		if g.phase == "victory": wins += 1
		else: reasons["health" if g.player_hp == 0 else "round_limit"] += 1
	print(JSON.stringify({"simulation": "shield_aware_player", "seeds": 100, "wins": wins, "losses": 100 - wins, "defeats": reasons}))
