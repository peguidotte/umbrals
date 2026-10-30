extends SceneTree
## Independent numerical examples plus state-machine invariants for the 3-slot battle.
const Rules = preload("res://scripts/rules.gd")
const Content = preload("res://scripts/content.gd")
var checks: int = 0
var failures: Array[String] = []

func expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		printerr("FAIL: " + description)

func unit(species: String, passive: String = "vital", uid: int = 1, stage: int = 1, slot: int = 1) -> Dictionary:
	var result: Dictionary = Rules.make_umbral(species, passive, uid, stage)
	result.slot = slot
	return result

func power(id: String, owner: int = 1, copy_number: int = 0, slot: int = 1) -> Dictionary:
	return {"instance_id": "%d:%s:%d" % [owner, id, copy_number], "owner": owner, "power": id, "target_slot": slot}

func active_cards(g: RefCounted) -> Array:
	return g.hand + g.deck + g.discard_pile

func all_cards(g: RefCounted) -> Array:
	var result: Array = active_cards(g)
	for zone in g.suspended_cards.values():
		result += zone.deck + zone.discard
	return result

func state_snapshot(g: RefCounted) -> String:
	return JSON.stringify({"party": g.party, "enemies": g.enemies, "hand": g.hand, "deck": g.deck, "discard": g.discard_pile, "suspended": g.suspended_cards, "plan": g.enemy_plan, "round": g.round_number, "actions": g.actions, "phase": g.phase, "declined_ko": g.declined_replacements, "rng": g.rng.state})

func fixture(companions: Array) -> RefCounted:
	var game = Rules.new()
	game.new_run(42013)
	game.party = companions
	game.start_encounter()
	# Durable, harmless opponents isolate the player's effects and card cycle.
	for enemy in game.enemies:
		enemy.hp = 500
		enemy.max_hp = 500
		enemy.attack = 10
		enemy.defense = 0
		enemy.speed = 0
	game.enemy_plan.clear()
	return game

func _init() -> void:
	test_traits_and_passives()
	test_budget_and_ownership()
	test_seed_preview_and_inputs()
	test_roster_and_card_cycle()
	test_formation_boundaries()
	test_swaps_and_ko()
	test_ko_transition_flow()
	test_delayed_ko_entry()
	test_reserve_reinsertion()
	test_speed_and_scopes()
	test_visibility()
	test_multiple_items()
	test_enemy_attributes()
	test_tactical_planning()
	test_enemy_preparation()
	test_capture_and_evolution()
	test_natures_and_reactions()
	test_initial_passive_usefulness()
	test_elemental_starters()
	test_battle_lifecycle()
	test_simulations()
	print(JSON.stringify({"suite": "umbral_rules", "checks": checks, "failed": failures.size(), "failures": failures}))
	quit(0 if failures.is_empty() else 1)

func test_traits_and_passives() -> void:
	var ember: Array = [unit("ember")]
	var ball: Dictionary = Rules.evaluate([power("fireball")], ember)
	expect(ball.valid and ball.direct_damage == 12 and ball.burn_added == 2, "Brasa's fireball has 12 base damage and applies 2 Combustão")
	expect(Rules.evaluate([power("cinder_claw")], ember).burn_added == 5, "Claw and Combustão stack to five burn")
	expect(Rules.evaluate([power("flame_guard")], ember).burn_added == 0, "Protection does not apply Combustão")
	expect(Rules.evaluate([power("fireball")], [unit("ember", "fierce")]).direct_damage == 15, "Feroz adds exactly three attack damage")
	expect(Rules.evaluate([power("fireball")], [unit("ember", "ardent")]).burn_added == 4, "Ardente adds two burn to Combustão")
	var roots: Dictionary = Rules.evaluate([power("root_wall")], [unit("moss")])
	expect(roots.block == 12 and roots.heal == 2, "Musgo protection grants twelve block and two Raízes Vivas healing")
	var twin_roots: Dictionary = Rules.evaluate([power("root_wall"), power("root_wall", 1, 1)], [unit("moss")])
	expect(twin_roots.block == 24 and twin_roots.heal == 2, "Raízes Vivas applies once per owner per round")
	expect(Rules.evaluate([power("root_wall")], [unit("moss", "resilient")]).block == 15, "Resiliente adds three protection")
	expect(Rules.power_effect(power("life_seed"), unit("moss", "vital"), 1).heal == 8, "Vital adds two to an explicit healing power")
	var evolved: Dictionary = Rules.evaluate([power("fireball")], [unit("ember", "vital", 1, 2)])
	expect(evolved.direct_damage == 20 and evolved.burn_added == 4, "Evolution improves existing fireball and its species trait")
	var solo: Dictionary = Rules.evaluate([power("lightning")], [unit("volt")])
	var pair: Dictionary = Rules.evaluate([power("fireball"), power("lightning", 2)], [unit("ember"), unit("volt", "vital", 2)])
	expect(solo.direct_damage == 12 and pair.direct_damage == 28, "Circuito Vivo adds four when another ally participates")
	var trio: Dictionary = Rules.evaluate([power("fireball"), power("root_wall", 2), power("lightning", 3)], [unit("ember"), unit("moss", "vital", 2), unit("volt", "vital", 3)])
	expect(trio.direct_damage == 32, "Three owners gain only their explicit traits, no automatic triple-cast bonus")
	var swift: Dictionary = Rules.evaluate([power("storm_dive"), power("lightning")], [unit("volt", "swift")])
	expect(swift.actions == 3, "Ágil affects speed rather than discounting the shared action budget")
	var passive_types: Dictionary = {}
	for seed_number in range(50):
		var game = Rules.new()
		game.new_run(seed_number)
		for companion in game.party:
			passive_types[companion.passive] = true
			expect(companion.passive in Content.PASSIVE_POOLS[companion.species], "Seeded individuals receive a species-compatible passive")
	expect(passive_types.size() >= 3, "Seeded starters vary individual passives")

func test_tactical_planning() -> void:
	var game = fixture([unit("ember", "vital", 1, 1, 1), unit("moss", "vital", 2, 1, 0), unit("dew", "vital", 3, 1, -1)])
	game.hand = [power("flame_guard"), power("fireball"), power("cinder_claw")]
	expect(game.target_options(0) == [1], "Self defense targets only its owner, never a different ally")
	expect(not game.set_target(0, 0) and game.hand[0].target_slot == 1, "An invalid self-target is rejected without editing the card")
	game.hand[0].target_slot = 0
	game.selected.assign([0])
	var before: String = state_snapshot(game)
	expect(not game.play().ok and state_snapshot(game) == before, "Forged self-targets fail atomically at commit as well as through the selector")
	game.hand[0].target_slot = 1
	game.selected.clear()
	game.enemies[0].slot = 2
	expect(game.target_options(1) == [2] and game.target_options(2).is_empty(), "Selectors distinguish individual targets from a fixed mask with no occupied targets")
	expect(not game.set_target(2, 2), "Upper-pair scope cannot be redirected to a lower-only enemy")
	game.enemies[0].slot = 1
	game.selected.assign([1, 0])
	before = state_snapshot(game)
	var entries: Array = game.planned_actions()
	expect(entries[0].card.power == "flame_guard" and entries[1].card.power == "fireball", "The public player plan uses the same priority vocabulary as resolution")
	for mode in ["hidden", "partial", "full"]:
		game.information_mode = mode
		expect(game.planned_actions() == entries, "Player plan rows do not depend on enemy visibility: " + mode)
	expect(state_snapshot(game) == before, "Reading the player plan consumes no RNG and changes no gameplay state")
	entries[0].card.target_slot = 2
	expect(game.hand[0].target_slot == 1, "Editing a projected command cannot mutate its physical hand card")
	game.party[0].hp = 20
	expect(game.queue_item("potion", 1) and not game.item_reason("potion", 1).is_empty(), "Queued consumables expose the same duplicate-target reason used by validation")
	expect(game.queue_deploy(2, 3) and not game.swap_reason(2, 3).is_empty(), "Entry selectors explain reserved slots and already-queued entrants")
	before = state_snapshot(game)
	var stock: Dictionary = game.inventory.duplicate()
	expect(game.clear_plan() and game.selected.is_empty() and game.queued_items.is_empty() and game.queued_swaps.is_empty(), "Clearing the full plan removes powers, items and swaps together")
	expect(state_snapshot(game) == before and game.inventory == stock, "Clearing a plan never spends a round, card, item, HP or RNG")
	game.inventory.unknown = 9
	expect(not game.queue_item("unknown", 1), "Inventory data cannot turn an unknown item into a potion")
	game.phase = "reward"
	expect(not game.clear_plan(), "Plan editing is closed outside the battle phase")

func test_enemy_preparation() -> void:
	var game = fixture([unit("ember")])
	var prepare: Dictionary = hostile(game.enemies[0], 0)
	prepare.category = "prepare"
	prepare.charge = 6
	game.enemy_plan = [prepare]
	var hp: int = int(game.party[0].hp)
	game.redraw()
	expect(game.party[0].hp == hp and game.enemies[0].statuses.get("charge", 0) == 6, "Preparation stores six visible charge without dealing phantom damage")
	expect(game.last_result.events.any(func(event: Dictionary) -> bool: return event.kind == "prepare" and event.amount == 6), "Preparation emits a presentation event with an actual status snapshot")
	game.enemy_plan = [hostile(game.enemies[0], 10)]
	expect(game.public_intents("full")[0].damage == 16, "Full information includes the charge in the committed attack's power")
	expect(not game.public_intents("partial")[0].has("damage") and not game.public_intents("hidden")[0].has("target_slot"), "Charge does not reveal secret attack values or targets in restricted modes")
	game.redraw()
	expect(game.party[0].hp == hp - 14 and not game.enemies[0].statuses.has("charge"), "The next attack spends charge once and applies defense normally")
	game.enemy_plan = [hostile(game.enemies[0], 10)]
	game.redraw()
	expect(game.party[0].hp == hp - 22, "A subsequent unprepared attack does not keep the spent bonus")
	var area = fixture([unit("ember", "vital", 1, 1, 0), unit("moss", "vital", 2, 1, 1), unit("volt", "vital", 3, 1, 2)])
	for companion in area.party: companion.defense = 0
	area.enemies[0].statuses.charge = 6
	area.enemy_plan = [hostile(area.enemies[0], 5, "all")]
	area.redraw()
	for companion in area.party: expect(companion.hp == companion.max_hp - 11, "Prepared area attack applies the same stored bonus to each occupied slot")
	var planner = preload("res://scripts/battle/enemy_planner.gd")
	area.enemies[0].pattern = [{"category": "attack", "damage": 5, "target_policy": "weakest"}]
	area.party[2].hp = 1
	var plan: Array = planner.build(area.enemies, area.party, 1, area.rng)
	expect(plan[0].target_slot == 2, "Weak-target patterns choose a currently vulnerable active body")
	area.party[2].slot = -1
	plan = planner.build(area.enemies, area.party, 1, area.rng)
	expect(plan[0].target_slot != 2, "Enemy targeting excludes healthy reserves even when they are weaker")

func test_budget_and_ownership() -> void:
	var volt: Array = [unit("volt")]
	var over: Dictionary = Rules.evaluate([power("storm_dive"), power("storm_dive", 1, 1)], volt)
	expect(not over.valid and over.actions == 4, "Four actions are rejected")
	expect(Rules.evaluate([power("storm_dive"), power("lightning")], volt).valid, "Exactly three shared actions are legal")
	expect(Rules.evaluate([power("lightning"), power("lightning", 1, 1), power("interference")], volt).valid, "One Umbral may use all three shared actions")
	expect(not Rules.evaluate([], volt).valid, "An empty conjuration is invalid")
	expect(not Rules.evaluate([power("lightning", 99)], volt).valid, "Every power requires its current owner")
	expect(not Rules.evaluate([power("fireball")], volt).valid, "A species cannot use an unlearned incompatible power")
	expect(not Rules.evaluate([power("judgment")], volt).valid, "An unevolved owner cannot use a signature it does not know")
	expect(not Rules.evaluate([power("missing")], volt).valid, "Unknown powers are rejected")
	expect(not Rules.evaluate([power("lightning"), power("lightning")], volt).valid, "A physical instance cannot be spent twice")
	var bench: Dictionary = unit("volt", "vital", 1, 1, -1)
	expect(not Rules.evaluate([power("lightning")], [bench]).valid, "A healthy reserve cannot conjure")
	var fallen: Dictionary = unit("volt")
	fallen.hp = 0
	expect(not Rules.evaluate([power("lightning")], [fallen]).valid, "An incapacitated owner cannot conjure")

func test_seed_preview_and_inputs() -> void:
	var first = Rules.new()
	var second = Rules.new()
	first.new_run(42013)
	second.new_run(42013)
	expect(state_snapshot(first) == state_snapshot(second), "Equal seeds reproduce individuals, card cycle and committed intentions")
	expect(first.party.size() == 1 and first.active_party().size() == 1 and first.hand.size() == 6, "An expedition starts with exactly one Umbral and a six-card hand")
	expect(first.hand_capacity() == 6 and first.action_budget() == 3, "Base options and shared action budget are independent")
	first.toggle(0)
	var before: String = state_snapshot(first)
	for repetition in range(8): first.preview()
	expect(state_snapshot(first) == before, "Repeated previews preserve the card cycle, actors, plan and RNG")
	expect(not first.toggle(-1) and not first.toggle(first.hand.size()), "Out-of-bounds selection is rejected")
	first.selected.clear()
	first.hand = [power("storm_dive"), power("storm_dive", 1, 1)]
	first.party = [unit("volt")]
	first.selected.assign([0, 1])
	before = state_snapshot(first)
	expect(not first.play().ok and state_snapshot(first) == before, "Over-budget commitment changes no HP, cards, plan, round or RNG")
	var game = fixture([unit("ember")])
	var round_before: int = game.round_number
	var old_ids: Array = []
	for card in game.hand: old_ids.append(card.instance_id)
	expect(game.redraw(), "Full-hand reroll is legal without selecting particular cards")
	expect(game.round_number == round_before + 1 and game.actions == 1, "Reroll spends an entire round")
	expect(game.selected.is_empty() and game.hand.size() == 6, "Reroll refreshes the hand and clears planned powers")
	expect(game.enemies[0].hp == 500, "Reroll performs no attack on an enemy")
	expect(all_cards(game).size() == 6, "Reroll conserves six distinct physical instances")

func test_roster_and_card_cycle() -> void:
	var companions: Array = [unit("ember")]
	for uid in range(2, 7): companions.append(unit("moss", "vital", uid, 1, -1))
	var game = fixture(companions)
	expect(game.party.size() == 6 and game.active_party().size() == 1 and game.reserves().size() == 5, "One active and five reserves is a valid full roster")
	expect(game.hand_capacity() == 6 and active_cards(game).size() == 6, "Healthy reserve powers never enter active hand, draw or discard")
	for card in active_cards(game): expect(card.owner == 1, "Solo active deck belongs exclusively to the field owner")
	expect(all_cards(game).size() == 36, "All roster-owned physical instances survive in active or suspended zones")
	var triple = fixture([unit("ember", "vital", 1, 1, 0), unit("moss", "vital", 2, 1, 1), unit("volt", "vital", 3, 1, 2)])
	expect(active_cards(triple).size() == 18 and triple.hand.size() == 6, "Three active owners contribute eighteen cards but still draw six")
	for iteration in range(7):
		triple.enemy_plan.clear()
		triple.redraw()
		var ids: Dictionary = {}
		for card in all_cards(triple): ids[card.instance_id] = true
		expect(ids.size() == 18 and all_cards(triple).size() == 18, "Round-end discard/recycle conserves eighteen unique instances")

func test_formation_boundaries() -> void:
	var game = fixture([unit("ember"), unit("moss", "vital", 2, 1, -1), unit("volt", "vital", 3, 1, -1), unit("dew", "vital", 4, 1, -1)])
	var before: String = state_snapshot(game)
	expect(not game.set_formation([1, 2, 3]), "Free formation editing cannot move bodies after an enemy plan has committed")
	game.phase = "reward"
	before = state_snapshot(game)
	expect(not game.set_formation([1, 2, 3, 4]), "A fourth field position is rejected even when the roster has room")
	expect(not game.set_formation([1, 1, -1]) and not game.set_formation([-1, -1, -1]), "Formation rejects duplicated individuals and an empty battlefield")
	expect(state_snapshot(game) == before, "Rejected formations do not consume cards, HP, plans or RNG")
	expect(game.set_formation([1, 2, 3]), "Between encounters the formation can explicitly choose three members")
	expect(game.active_party().size() == 3 and game.reserves().size() == 1, "Formation keeps the fourth individual in reserve")
	expect(not game.queue_deploy(3, 4), "Deployment cannot create a fourth active slot")
	expect(game.set_formation([-1, 1, -1]) and game.active_party().size() == 1, "The player may choose a single central active without auto-filling")
	game.start_encounter()
	expect(not game.set_formation([1, 2, 3]), "Free formation editing stays closed during battle")

func test_swaps_and_ko() -> void:
	var game = fixture([unit("ember"), unit("moss", "vital", 2, 1, -1)])
	var before: String = state_snapshot(game)
	expect(game.queue_swap(1, 2), "A healthy reserve can be queued into an occupied slot")
	expect(state_snapshot(game) == before, "Planning a swap changes no body, cards, initiative plan or RNG")
	expect(game.preview().valid and game.preview().actions == 1, "A voluntary swap consumes one shared action")
	expect(game.cancel_swap(1) and state_snapshot(game) == before, "Canceling a queued swap is free and deterministic")
	game.queue_swap(1, 2)
	expect(game.play().ok, "A swap-only conjuration can be committed")
	expect(game.umbral_by_uid(1).slot == -1 and game.umbral_by_uid(2).slot == 1, "Commit changes occupants without changing the semantic target slot")
	for card in active_cards(game): expect(card.owner == 2, "Only the incoming healthy owner participates in the next normal draw")
	expect(all_cards(game).size() == 12, "Voluntary swap conserves outgoing and incoming physical cards")
	game.enemy_plan.clear()
	game.queue_swap(2, 1)
	game.play()
	expect(all_cards(game).size() == 12, "Returning from reserve restores the same instances instead of duplicating a repertoire")
	var fallen: Dictionary = unit("ember")
	fallen.hp = 0
	var ko_game = fixture([fallen, unit("moss", "vital", 2, 1, -1)])
	# The encounter preserves incapacitation; replacement must keep the old penalty.
	ko_game.umbral_by_uid(1).hp = 0
	ko_game.phase = "replacement"
	expect(ko_game.replace_after_ko(1, 2), "Apt reserve can freely replace a knocked-out occupant between rounds")
	var actions_before: int = ko_game.actions
	expect(ko_game.finish_replacements(), "Replacement phase continues with a surviving active")
	expect(ko_game.actions == actions_before and ko_game.umbral_by_uid(2).slot == 1, "Forced replacement adds no action or automatic extra active")
	var blocked: int = 0
	for card in active_cards(ko_game):
		if int(card.owner) == 1: blocked += 1
	expect(blocked == 6, "Replacing an incapacitated body retains all six blocked owner cards in the cycle")
	var boundary = fixture([unit("ember"), unit("moss", "vital", 2, 1, 0), unit("volt", "vital", 3, 1, -1)])
	boundary.party[0].hp = 5
	boundary.party[0].defense = 0
	var untouched_hp: int = boundary.party[2].hp
	boundary.enemy_plan = [hostile(boundary.enemies[0], 10), hostile(boundary.enemies[0], 10)]
	boundary.redraw()
	expect(boundary.phase == "replacement" and boundary.party[2].slot == -1 and boundary.party[2].hp == untouched_hp, "KO replacement waits until the entire shared queue ends; reserve cannot absorb a remaining hit for free")
	var boundary_round: int = boundary.round_number
	expect(boundary.replace_after_ko(1, 3) and boundary.finish_replacements(), "Replacement resumes the next planning round with the chosen reserve")
	expect(boundary.round_number == boundary_round, "Finishing free replacement does not spend another round")

func test_ko_transition_flow() -> void:
	var game = fixture([unit("ember"), unit("moss", "resilient", 2, 1, 0), unit("dew", "vital", 3, 1, -1)])
	game.party[0].hp = 1
	game.party[0].statuses = {"burn": 1}
	force_reward(game, false)
	expect(game.phase == "reward" and int(game.party[0].hp) == 0, "An ally can be incapacitated by burn on the same round that wins an encounter")
	expect(game.choose_reward(1) and game.phase == "replacement" and game.hand.is_empty(), "The next encounter offers free partial-KO replacement before drawing or committing enemy intentions")
	var actions_before: int = game.actions
	expect(game.finish_replacements() and game.phase == "battle", "A surviving active may explicitly decline a free replacement")
	game.enemy_plan.clear()
	game.redraw()
	expect(game.phase == "battle" and game.actions == actions_before + 1, "Declining a KO does not reopen its replacement prompt every round")
	expect(game.queue_item("revive", 1), "A declined incapacitated body remains available for ordinary revival")
	game.enemy_plan = [hostile(game.enemies[0], 100, "single", 1)]
	game.play()
	expect(game.phase == "replacement" and int(game.party[0].hp) == 0, "A new KO after revival offers replacement again for the same individual")
	game.finish_replacements()
	game.enemy_plan = [hostile(game.enemies[0], 100, "single", 0)]
	game.redraw()
	expect(game.phase == "replacement" and game.active_party(true).is_empty(), "Declining an earlier KO never suppresses recovery when the final active falls")

func test_delayed_ko_entry() -> void:
	var fallen: Dictionary = unit("ember")
	fallen.hp = 0
	var game = fixture([fallen, unit("moss", "resilient", 2, 1, 0), unit("dew", "vital", 3, 1, -1)])
	expect(game.phase == "replacement" and game.finish_replacements(), "A partial-KO lineup can decline the initial free offer")
	var before: String = state_snapshot(game)
	expect(game.queue_swap(1, 3) and state_snapshot(game) == before, "A declined KO slot accepts a later voluntary replacement without moving bodies or drawing during planning")
	expect(game.preview().valid and game.preview().actions == 1, "Delayed replacement uses the ordinary one-action budget")
	expect(game.cancel_swap(1) and state_snapshot(game) == before, "Canceling delayed replacement preserves every physical card and RNG")
	game.queue_swap(1, 3)
	game.enemy_plan = [hostile(game.enemies[0], 10, "all")]
	var actions_before: int = game.actions
	expect(game.play().ok and game.actions == actions_before + 1, "Delayed replacement executes only with the committed round")
	expect(int(game.umbral_by_uid(1).hp) == 0 and int(game.umbral_by_uid(1).slot) == -1 and int(game.umbral_by_uid(3).slot) == 1, "The new body takes the KO slot without reviving or deleting its former owner")
	expect(int(game.umbral_by_uid(3).hp) == int(game.umbral_by_uid(3).max_hp) - 8, "The incoming replacement receives the committed area strike in its slot")
	var blocked: int = 0
	var incoming: int = 0
	for card in active_cards(game):
		if int(card.owner) == 1: blocked += 1
		if int(card.owner) == 3: incoming += 1
	expect(blocked == 6 and incoming == 6 and all_cards(game).size() == 18 and game.hand.size() == 6, "Delayed replacement keeps KO penalties and incoming copies through one normal draw")

func hostile(actor: Dictionary, damage: int = 10, scope: String = "single", slot: int = 1) -> Dictionary:
	return {"actor_uid": actor.uid, "actor_slot": actor.slot, "category": "attack", "power": "enemy_attack", "damage": damage, "block": 0, "heal": 0, "wet": 0, "scope": scope, "target_slot": slot, "priority": 0}

func test_reserve_reinsertion() -> void:
	# With an exhausted solo pile, entry must mix both owners at the normal
	# recycle boundary, rather than guaranteeing the new owner's six-card hand.
	var mixed: int = 0
	var total_incoming: int = 0
	for seed_number in range(128):
		var game = Rules.new()
		game.new_run(seed_number)
		game.party.append(unit("moss", "resilient", 2, 1, -1))
		game.start_encounter()
		game.enemies[0].hp = 500
		game.enemies[0].max_hp = 500
		game.enemy_plan.clear()
		var hand_before: Array = game.hand.duplicate(true)
		var rng_before: int = game.rng.state
		expect(game.queue_deploy(0, 2) and game.hand == hand_before and game.rng.state == rng_before, "Planning entry never draws, mixes or consumes RNG")
		game.play()
		var incoming: int = 0
		var ids: Dictionary = {}
		for card in game.hand:
			if int(card.owner) == 2: incoming += 1
		for card in all_cards(game): ids[card.instance_id] = true
		expect(game.hand.size() == 6 and ids.size() == 12 and all_cards(game).size() == 12, "Entry keeps one normal six-card draw and twelve unique instances")
		if incoming > 0 and incoming < 6: mixed += 1
		total_incoming += incoming
	expect(mixed > 110 and total_incoming > 300 and total_incoming < 470, "Across 128 seeds entry mixes the two owners without guaranteed reserve-only hands or starvation")
	# A nonempty draw pile keeps the relative order of all prior cards. The
	# discard remains unavailable until the draw really runs out.
	var game = fixture([unit("ember"), unit("moss", "resilient", 2, 1, 0), unit("dew", "vital", 3, 1, -1)])
	var previous_draw: Array = game.deck.duplicate(true)
	var existing_hand: Array = game.hand.duplicate(true)
	game.discard_pile.append(game.hand.pop_back())
	var previous_discard: Array = game.discard_pile.duplicate(true)
	game.party[2].slot = 2
	game._sync_owner_zones()
	var surviving_order: Array = []
	for card in game.deck:
		if int(card.owner) != 3: surviving_order.append(card)
	expect(surviving_order == previous_draw and game.discard_pile == previous_discard, "Incoming cards interleave without reordering old draw cards or recycling a nonexhausted pile")
	expect(game.hand == existing_hand.slice(0, existing_hand.size() - 1), "Synchronizing eligible owners never grants an immediate hand")
	var before: String = state_snapshot(game)
	game._sync_owner_zones()
	expect(state_snapshot(game) == before, "Repeated zone synchronization neither duplicates nor reshuffles incoming copies")

func test_speed_and_scopes() -> void:
	var game = fixture([unit("ember", "vital", 1, 1, 0), unit("moss", "vital", 2, 1, 1), unit("volt", "vital", 3, 1, 2)])
	game.hand = [power("fireball", 1), power("root_wall", 2), power("lightning", 3)]
	game.selected.assign([0, 1, 2])
	var first: Dictionary = game.preview()
	game.selected.assign([2, 1, 0])
	expect(game.preview() == first, "Reversing clicks preserves the same planned conjuration")
	var other = fixture([unit("ember", "vital", 1, 1, 0), unit("moss", "vital", 2, 1, 1), unit("volt", "vital", 3, 1, 2)])
	other.hand = game.hand.duplicate(true)
	other.selected.assign([0, 1, 2])
	game.play()
	other.play()
	expect(state_snapshot(game) == state_snapshot(other), "Reversed selections resolve identically including seeded queue ties")
	var slow = fixture([unit("ember")])
	slow.party[0].hp = 5
	slow.party[0].defense = 0
	slow.party[0].speed = 5
	slow.enemies[0].speed = 30
	slow.enemy_plan = [hostile(slow.enemies[0], 5)]
	slow.hand = [power("fireball")]
	slow.selected.assign([0])
	slow.play()
	expect(slow.party[0].hp == 0 and slow.enemies[0].hp == 500, "A faster lethal enemy cancels the knocked-out owner's queued power")
	var fast = fixture([unit("ember")])
	fast.enemies[0].hp = 1
	fast.enemy_plan = [hostile(fast.enemies[0], 100)]
	fast.hand = [power("fireball")]
	fast.selected.assign([0])
	var original_hp: int = fast.party[0].hp
	fast.play()
	expect(fast.enemies[0].hp == 0 and fast.party[0].hp == original_hp, "A faster lethal ally cancels the defeated enemy's queued attack")
	var damages: Array = []
	for water_first in [true, false]:
		var combo = fixture([unit("dew", "vital", 1, 1, 0), unit("volt", "vital", 2, 1, 1)])
		combo.party[0].attack = 10
		combo.party[1].attack = 10
		combo.party[0].speed = 30 if water_first else 5
		combo.party[1].speed = 10
		combo.hand = [power("lightning", 2), power("tidal_splash", 1)]
		combo.selected.assign([0, 1])
		combo.play()
		damages.append(500 - int(combo.enemies[0].hp))
	expect(damages == [38, 23], "Water before lightning deals 38; faster lightning deals 23 without a not-yet-applied Wet bonus")
	var area = fixture([unit("ember")])
	var template: Dictionary = area.enemies[0].duplicate(true)
	area.enemies.clear()
	for slot in range(3):
		var enemy: Dictionary = template.duplicate(true)
		enemy.uid = 1001 + slot
		enemy.slot = slot
		area.enemies.append(enemy)
	area.hand = [power("cinder_claw")]
	area.selected.assign([0])
	area.play()
	expect(area.enemies[0].hp == 487 and area.enemies[1].hp == 487 and area.enemies[2].hp == 500, "Upper-pair claw damages and burns only upper and central slots")
	var splash = fixture([unit("ember", "vital", 1, 1, 0), unit("moss", "vital", 2, 1, 1), unit("volt", "vital", 3, 1, 2)])
	for companion in splash.party:
		companion.hp = 30
		companion.defense = 0
	splash.enemy_plan = [hostile(splash.enemies[0], 10, "all")]
	splash.redraw()
	expect(splash.party[0].hp == 20 and splash.party[1].hp == 20 and splash.party[2].hp == 20, "All-slot enemy attack damages each living occupied position individually")
	var vacant = fixture([unit("ember", "vital", 1, 1, 2)])
	vacant.party[0].defense = 0
	vacant.enemy_plan = [hostile(vacant.enemies[0], 10, "upper_pair")]
	var hp_before: int = vacant.party[0].hp
	vacant.redraw()
	expect(vacant.party[0].hp == hp_before, "Vacant upper/central slots do not redirect area attacks to a lower solo member")
	var swap = fixture([unit("ember"), unit("moss", "vital", 2, 1, -1)])
	swap.party[0].defense = 0
	swap.party[1].defense = 0
	swap.enemy_plan = [hostile(swap.enemies[0], 10)]
	var outgoing_hp: int = swap.party[0].hp
	var incoming_hp: int = swap.party[1].hp
	swap.queue_swap(1, 2)
	swap.play()
	expect(swap.party[0].hp == outgoing_hp and swap.party[1].hp == incoming_hp - 10, "Substitute receives the precomputed attack aimed at the outgoing slot")
	var revive = fixture([unit("ember"), unit("moss", "vital", 2, 1, 0)])
	revive.party[0].hp = 0
	revive.hand = [power("fireball"), power("root_wall", 2, 0, 0)]
	revive.selected.assign([1])
	expect(revive.queue_item("revive", 1), "Revive can be planned for an incapacitated teammate")
	expect(not revive.toggle(0), "A planned revive does not let its owner select a power in the same conjuration")
	revive.play()
	expect(revive.party[0].hp > 0, "Revive restores individual HP during resolution")
	revive.enemy_plan.clear()
	revive.hand = [power("fireball")]
	revive.selected.assign([0])
	expect(revive.preview().valid, "The reanimated active owner can use powers in the following round")
	var modifier = fixture([unit("ember", "vital", 1, 1, 0), unit("moss", "vital", 2, 1, 1)])
	modifier.hand_size_modifier = 1
	expect(modifier.hand_capacity() == 7 and modifier.hand.size() == 6, "Hand modifier changes capacity without drawing cards immediately")
	modifier.redraw()
	expect(modifier.hand.size() == 7, "Expanded capacity is applied at the next normal draw")
	modifier.hand_size_modifier = -1
	modifier.enemy_plan.clear()
	modifier.redraw()
	expect(modifier.hand.size() == 5, "A negative modifier reduces the next hand to five")
	modifier.hand_size_modifier = 0
	modifier.party[0].hand_modifier = 1
	modifier.party[1].hand_modifier = -1
	expect(modifier.hand_capacity() == 6, "Explicit living-active Umbral hand modifiers stack additively")
	modifier.party[1].slot = -1
	expect(modifier.hand_capacity() == 7, "A healthy reserve does not provide a field-only hand modifier")
	modifier.relics = [{"hand_modifier": 2, "action_modifier": 1}]
	expect(modifier.hand_capacity() == 9 and modifier.action_budget() == 4 and modifier.active_party().size() == 1, "Explicit relic modifiers alter hand/actions without expanding the battlefield")
	var solo = fixture([unit("ember")])
	solo.hand_size_modifier = 5
	solo.redraw()
	expect(solo.hand_capacity() == 11 and solo.hand.size() == 6 and all_cards(solo).size() == 6, "An expanded hand never fabricates duplicate cards to fill unused capacity")

func test_enemy_attributes() -> void:
	var game = fixture([unit("ember")])
	game.enemies[0].attack = 15
	game.enemy_plan = [hostile(game.enemies[0], 7)]
	game.hand = [power("fireball")]
	game.selected.assign([0])
	expect(game.public_intents("full")[0].damage == 12, "Full intent shows enemy attack-adjusted power before target defenses")
	var before: int = game.party[0].hp
	var result: Dictionary = game.play()
	expect(result.incoming == 10 and game.party[0].hp == before - 10, "Enemy Attack affects its strike; individual Defense reduces twelve power to ten HP")

func test_multiple_items() -> void:
	var game = fixture([unit("ember"), unit("moss", "vital", 2, 1, 0), unit("volt", "vital", 3, 1, 2)])
	game.party[0].hp = 10
	game.party[1].hp = 10
	game.party[2].hp = 0
	expect(game.queue_item("potion", 1) and game.queue_item("potion", 2) and game.queue_item("revive", 3), "Multiple legal item targets share a single conjuration")
	expect(game.preview().valid and game.preview().actions == 3, "Three queued consumables use exactly three shared actions")
	var result: Dictionary = game.play()
	expect(result.ok and game.party[0].hp == 28 and game.party[1].hp == 28 and game.party[2].hp == 13, "Two potions and a revive resolve without invalid priority comparisons")
	expect(game.inventory.potion == 0 and game.inventory.revive == 0, "Each executed consumable is spent exactly once")

func test_visibility() -> void:
	var game = Rules.new()
	game.new_run(42013)
	var plan: Array = game.enemy_plan.duplicate(true)
	var seed_state: int = game.rng.state
	var hidden: Array = game.public_intents("hidden")
	var partial: Array = game.public_intents("partial")
	var full: Array = game.public_intents("full")
	expect(hidden.size() == game.enemies.size() and partial.size() == full.size(), "Every information mode represents the same opposing actors")
	for intention in hidden:
		expect(not intention.has("damage") and not intention.has("target_slot") and str(intention.get("category", "unknown")) == "unknown", "Hidden intention exports no actionable category, damage or target")
	for intention in partial:
		expect(intention.has("category") and not intention.has("damage") and not intention.has("target_slot"), "Partial intention exposes a reliable category without exact damage or target")
	expect(game.enemy_plan == plan and game.rng.state == seed_state, "Projecting information modes never replans or consumes RNG")
	expect(game.set_information_mode("hidden") and game.information_mode == "partial", "An information setting does not change the already committed round")
	var a = Rules.new()
	var b = Rules.new()
	a.new_run(42013)
	b.new_run(42013)
	# Keep a following planning round available; winning immediately has no next plan.
	for candidate in [a, b]:
		candidate.enemies[0].hp = 500
		candidate.enemies[0].max_hp = 500
	a.set_information_mode("hidden")
	b.set_information_mode("full")
	a.selected = a.best_selection()
	b.selected = b.best_selection()
	expect(a.preview() == b.preview(), "Mode configuration cannot change the player's preview")
	a.play()
	b.play()
	expect(state_snapshot(a) == state_snapshot(b), "Hidden and full modes resolve the same precomputed actions, outcomes and RNG")
	expect(a.information_mode == "hidden" and b.information_mode == "full", "Requested information modes take effect at the following normal round")
	game.toggle(0)
	var preview: Dictionary = game.preview()
	expect(not preview.has("future_hp") and not preview.has("enemy_actions") and not preview.has("incoming"), "Preview cannot reveal hidden enemy resolution or exact future HP")

func force_reward(game: RefCounted, restore_owner: bool = true) -> void:
	for enemy in game.enemies:
		enemy.hp = 0
	game.enemies[0].hp = 1
	game.enemies[0].slot = 1
	game.enemy_plan.clear()
	var owner: Dictionary = game.party[0]
	owner.slot = 1
	if restore_owner: owner.hp = owner.max_hp
	var available: Array = active_cards(game)
	var chosen: Dictionary = {}
	var rest: Array = []
	for card in available:
		if chosen.is_empty() and card.power == "fireball" and int(card.owner) == int(owner.uid):
			chosen = card
		else:
			rest.append(card)
	chosen.target_slot = 1
	game.hand = [chosen]
	game.deck = rest
	game.discard_pile.clear()
	game.selected.assign([0])
	game.play()

func test_capture_and_evolution() -> void:
	var field = Rules.new()
	field.new_run(42013)
	force_reward(field)
	expect(field.capture_destinations(0) == [-1, 0, 2], "Capture offers the reserve and only genuinely vacant lateral slots")
	for invalid in [[-1, 1], [-1, 3], [-1, -3], [1, 1]]:
		# Independent states keep an intentionally broken validator from advancing
		# the next case and turning a behavioral mutation failure into a crash.
		var rejected = Rules.new()
		rejected.new_run(42013)
		force_reward(rejected)
		var before_reject: String = state_snapshot(rejected)
		expect(not rejected.choose_reward(0, int(invalid[0]), int(invalid[1])) and state_snapshot(rejected) == before_reject, "Occupied, out-of-range or forged release destinations preserve the reward and RNG")
	var captured_uid: int = field.reward_offers[0].umbral.uid
	expect(field.choose_reward(0, -1, 0) and field.umbral_by_uid(captured_uid).slot == 0, "Explicit field capture deploys into the selected free slot before the new encounter")
	expect(field.actions == 1 and field.round_number == 1 and field.active_party().size() == 2 and active_cards(field).size() == 12, "Between-encounter field capture adds no combat action and builds the combined initial deck")
	# Both copies of every power survive, and the third unused slot stays empty.
	expect(field._at_slot(field.party, 2).is_empty() and all_cards(field).size() == 12, "Field capture never autofills remaining vacancies or duplicates cards")
	var game = Rules.new()
	game.new_run(42013)
	force_reward(game)
	expect(game.phase == "reward" and game.reward_offers.size() >= 2, "First clear offers a captured individual and evolution")
	var offers: Array = game.reward_offers.duplicate(true)
	var rolled_state: int = game.rng.state
	expect(not game.choose_reward(-1) and not game.choose_reward(99), "Invalid reward indices are rejected")
	expect(game.reward_offers == offers and game.rng.state == rolled_state, "Rejected rewards preserve the rolled passive and RNG")
	var incoming: Dictionary = offers[0].umbral.duplicate(true)
	expect(game.choose_reward(0), "Capture accepts the already rolled individual")
	expect(game.party.size() == 2 and game.party[1].uid == incoming.uid and game.party[1].passive == incoming.passive, "Capture preserves UID and passive")
	expect(game.active_party().size() == 1 and game.party[1].slot == -1, "Capture adds a reserve without auto-filling the field")
	for card in active_cards(game): expect(card.owner != incoming.uid, "A captured reserve does not pollute the active cycle")
	force_reward(game)
	var uid: int = game.party[0].uid
	var passive: String = game.party[0].passive
	var count_before: int = 12 # Two owners keep their six learned instances after evolution.
	expect(game.choose_reward(1), "An existing individual can evolve instead of capturing")
	expect(game.party[0].uid == uid and game.party[0].passive == passive and game.party[0].stage == 2, "Evolution preserves UID and individual passive")
	expect(all_cards(game).size() == count_before, "Evolution upgrades learned copies without automatically inflating the deck")
	# A full roster fixture exercises release explicitly; a three-encounter run cannot naturally capture six.
	var full = Rules.new()
	full.new_run(42013)
	for index in range(2, 7): full.party.append(unit("moss", "vital", index, 1, -1))
	full.next_uid = 7
	full.start_encounter()
	force_reward(full)
	var party_before: Array = full.party.duplicate(true)
	expect(not full.choose_reward(0) and full.party == party_before, "Seventh capture requires an explicit release choice")
	var old_uid: int = full.party[1].uid
	var new_uid: int = full.reward_offers[0].umbral.uid
	expect(full.choose_reward(0, old_uid), "Full roster capture explicitly replaces the selected individual")
	expect(full.party.size() == 6 and full.umbral_by_uid(old_uid).is_empty() and not full.umbral_by_uid(new_uid).is_empty(), "Replacement preserves six members and the incoming identity")
	for card in all_cards(full): expect(card.owner != old_uid, "Released owner leaves no card in active or suspended zones")
	var last_active = Rules.new()
	last_active.new_run(42013)
	for index in range(2, 7): last_active.party.append(unit("moss", "resilient", index, 1, -1))
	last_active.next_uid = 7
	last_active.start_encounter()
	force_reward(last_active)
	var before_release: String = state_snapshot(last_active)
	expect(not last_active.choose_reward(0, 1, -1) and state_snapshot(last_active) == before_release, "Releasing the last field body cannot strand a capture in reserve without a replacement slot")
	expect(last_active.choose_reward(0, 1) and last_active.active_party(true).size() == 1, "Replacing the last active preserves its slot by default and keeps the new encounter playable")

func test_battle_lifecycle() -> void:
	var items_used: int = 0
	var entries_used: int = 0
	var field_captures: int = 0
	var transitions: int = 0
	for starter in Content.STARTERS:
		for seed_number in range(12):
			var game = Rules.new()
			game.new_run(seed_number + 42000, ["hidden", "partial", "full"][seed_number % 3], starter)
			game.hand_size_modifier = seed_number % 5 - 2
			game.action_modifier = seed_number % 3 - 1
			game.start_encounter()
			var policy = RandomNumberGenerator.new()
			policy.seed = seed_number + 90000
			for step in range(100):
				if game.phase in ["victory", "defeat"]: break
				if game.phase == "reward":
					var reward: int = policy.randi_range(0, game.reward_offers.size() - 1)
					var destination: int = -2
					if game.reward_offers[reward].kind == "capture":
						var options: Array[int] = game.capture_destinations(reward)
						destination = options[policy.randi_range(0, options.size() - 1)]
						if destination >= 0: field_captures += 1
					expect(game.choose_reward(reward, -1, destination), "Lifecycle policy accepts a legal capture destination or evolution")
				elif game.phase == "replacement":
					for occupant in game.active_party():
						if int(occupant.hp) <= 0 and not game.reserves().is_empty():
							expect(game.replace_after_ko(int(occupant.slot), int(game.reserves()[0].uid)), "Lifecycle policy can replace an actual KO")
					expect(game.finish_replacements(), "Lifecycle replacement always returns to planning with a living active")
				else:
					if not game.reserves().is_empty() and policy.randf() < 0.25:
						var incoming: int = int(game.reserves()[0].uid)
						var slot: int = policy.randi_range(0, Rules.MAX_ACTIVE - 1)
						if game.swap_reason(slot, incoming).is_empty():
							var occupant: Dictionary = game._at_slot(game.party, slot)
							var accepted: bool = game.queue_deploy(slot, incoming) if occupant.is_empty() else game.queue_swap(int(occupant.uid), incoming)
							if accepted: entries_used += 1
					for individual in game.party:
						var item: String = "revive" if int(individual.hp) <= 0 else "potion"
						if policy.randf() < 0.35 and game.item_reason(item, int(individual.uid)).is_empty():
							if game.queue_item(item, int(individual.uid)): break
					for index in range(game.hand.size()):
						if not game.card_usable(index) or policy.randf() > 0.65: continue
						game.toggle(index)
						if not game.preview().valid: game.toggle(index)
					if game.preview().valid and policy.randf() > 0.15:
						game.play()
					else: game.redraw()
					for event in game.last_result.events:
						if event.kind == "revive" or (event.kind == "heal" and event.power == "potion"): items_used += 1
				transitions += 1
				var ids: Dictionary = {}
				var slots: Dictionary = {}
				var valid: bool = true
				for individual in game.party:
					valid = valid and int(individual.hp) >= 0 and int(individual.hp) <= int(individual.max_hp)
					if int(individual.slot) >= 0:
						valid = valid and int(individual.slot) < 3 and not slots.has(int(individual.slot))
						slots[int(individual.slot)] = true
				for card in all_cards(game):
					valid = valid and not ids.has(card.instance_id) and not game.umbral_by_uid(int(card.owner)).is_empty()
					ids[card.instance_id] = true
				for card in active_cards(game):
					var owner: Dictionary = game.umbral_by_uid(int(card.owner))
					valid = valid and (int(owner.slot) >= 0 or int(owner.hp) <= 0)
				valid = valid and slots.size() <= 3 and ids.size() == game.party.size() * 6 and all_cards(game).size() == ids.size()
				expect(valid, "Lifecycle preserves HP, slots, reserve exclusions and every physical card: %s seed %d step %d" % [starter, seed_number, step])
				if not valid: break
	expect(items_used > 0 and entries_used > 0 and field_captures > 0, "Lifecycle exploration actually uses consumables, entries and field captures")
	print(JSON.stringify({"simulation": "battle_lifecycle", "cases": 48, "transitions": transitions, "consumable_effects": items_used, "entries": entries_used, "field_captures": field_captures, "limits": "Bounded random legal commands; not human balance or an assertion that every policy wins"}))

func test_simulations() -> void:
	var wins: int = 0
	for seed_number in range(100):
		var game = Rules.new()
		game.new_run(seed_number)
		var steps: int = 0
		while game.phase not in ["victory", "defeat"] and steps < 100:
			if game.phase == "reward":
				game.choose_reward(0 if game.encounter == 0 else 1)
			elif game.phase == "replacement":
				var reserves: Array = game.reserves()
				if not reserves.is_empty():
					for companion in game.party:
						if int(companion.slot) >= 0 and int(companion.hp) == 0:
							game.replace_after_ko(int(companion.slot), int(reserves[0].uid))
							break
				game.finish_replacements()
			else:
				game.selected = game.best_selection()
				if game.selected.is_empty(): game.redraw()
				else: game.play()
			steps += 1
			for actor in game.party + game.enemies:
				expect(actor.hp >= 0 and actor.hp <= actor.max_hp, "Seed %d keeps individual HP bounded" % seed_number)
			var ids: Dictionary = {}
			for card in all_cards(game): ids[card.instance_id] = true
			expect(ids.size() == game.party.size() * 6 and all_cards(game).size() == ids.size(), "Seed %d conserves six unique instances per owner" % seed_number)
			for card in active_cards(game):
				var owner: Dictionary = game.umbral_by_uid(int(card.owner))
				expect(not owner.is_empty() and (int(owner.slot) >= 0 or int(owner.hp) == 0), "Seed %d excludes only healthy reserves, retaining KO penalties" % seed_number)
		expect(game.phase in ["victory", "defeat"], "Seed %d reaches a terminal outcome without deadlock" % seed_number)
		if game.phase == "victory": wins += 1
	print(JSON.stringify({"simulation": "bounded_heuristic_player", "seeds": 100, "wins": wins, "losses": 100 - wins, "limits": "A deterministic heuristic is not a fun or balance assessment."}))

func test_natures_and_reactions() -> void:
	var conditions = preload("res://scripts/battle/conditions.gd")
	var reactions = preload("res://scripts/battle/reactions.gd")
	for id in Content.POWERS:
		var technique: Dictionary = Content.POWERS[id]
		expect(Content.NATURES.has(technique.nature), "Every move explicitly declares its own nature: " + id)
		for status in technique.conditions: expect(conditions.DEFINITIONS.has(status), "Move conditions reference the catalog: " + id)
	var evolved: Dictionary = unit("volt", "vital", 1, 2)
	expect(Content.natures(unit("volt")) == ["lightning"] and Content.natures(evolved) == ["lightning", "water"], "Only Tempestral gains its explicitly authored secondary Water nature")
	expect(Content.can_learn(evolved, "tidal_splash") and not Content.can_learn(unit("volt"), "tidal_splash"), "Secondary nature expands learning compatibility without changing the move")
	expect(evolved.cards.size() == 6 and not "tidal_splash" in evolved.known_powers and Content.resistances(evolved) == {"lightning": 25}, "A secondary nature grants no automatic cards or Water resistance")
	var unchanged: Dictionary = Content.POWERS.sowing.duplicate(true)
	Content.power_stats("sowing", 2).conditions.seed = 99
	expect(Content.POWERS.sowing == unchanged, "Nested condition definitions remain immutable when evolved power data changes")
	var projection = fixture([unit("ember")])
	var announced: Dictionary = hostile(projection.enemies[0], 4)
	announced.nature = "lightning"
	announced.conditions = {"electrified": 2}
	projection.enemy_plan = [announced]
	var public_view: Array = projection.public_intents("full")
	public_view[0].conditions.electrified = 99
	expect(projection.enemy_plan[0].conditions.electrified == 2, "Nested public intention metadata cannot mutate the committed enemy plan")
	var refresh: Dictionary = unit("moss")
	conditions.apply(refresh, "seed", 3, {"uid": 2, "side": "enemy"})
	conditions.tick(refresh)
	conditions.apply(refresh, "seed", 3, {"uid": 3, "side": "ally"})
	expect(refresh.statuses.seed == 3 and refresh.status_sources.seed.uid == 2, "Refreshing a seed renews duration without stacking or stealing the original source")
	conditions.tick(refresh)
	conditions.tick(refresh)
	conditions.tick(refresh)
	expect(not refresh.statuses.has("seed") and not refresh.status_sources.has("seed"), "Expiring a condition removes its counter and source together")
	var solo = fixture([unit("moss")])
	solo.party[0].hp = 30
	solo.hand = [power("sowing"), power("sowing", 1, 1)]
	solo.selected.assign([0])
	var before: String = state_snapshot(solo)
	for repetition in range(4): solo.preview()
	expect(state_snapshot(solo) == before, "Elemental previews do not consume seeds, source data, HP or RNG")
	solo.play()
	expect(solo.enemies[0].statuses.seed == 2 and solo.last_result.events.filter(func(event: Dictionary) -> bool: return event.kind == "reaction").is_empty(), "First Semeadura plants for three rounds including this one, without reacting to itself")
	solo.enemy_plan.clear()
	solo.hand = [power("sowing"), power("sowing", 1, 1)]
	solo.selected.assign([0, 1])
	solo.play()
	var sprouts: Array = solo.last_result.events.filter(func(event: Dictionary) -> bool: return event.get("reaction", "") == "sprouting")
	expect(sprouts.size() == 1 and solo.enemies[0].statuses.seed == 2, "A preexisting seed is consumed once; a subsequent separate move can plant again")
	expect(solo.last_result.events.any(func(event: Dictionary) -> bool: return event.kind == "block" and event.amount == 6), "Solo Brotação grants exactly six shield to the original planter")
	expect(solo.party[0].hp == 32, "Brotação triggers Raízes Vivas once, without passive or recursive healing bonuses")
	for alive in [true, false]:
		var bloom = fixture([unit("dew", "vital", 1), unit("moss", "vital", 2, 1, -1)])
		bloom.party[1].hp = 10 if alive else 0
		conditions.apply(bloom.enemies[0], "seed", 3, {"uid": 2, "side": "ally"})
		bloom.hand = [power("tidal_splash")]
		bloom.selected.assign([0])
		bloom.play()
		expect(bloom.party[1].hp == (18 if alive else 0), "Floração follows its original source into reserve, and never revives a KO source")
		expect(not bloom.enemies[0].statuses.has("seed") and bloom.enemies[0].statuses.wet == 1, "Floração consumes only Semeado while the water move still applies Encharcado")
	var moved = fixture([unit("moss"), unit("moss", "vital", 2, 1, -1)])
	moved.party[0].hp = 20
	conditions.apply(moved.enemies[0], "seed", 3, {"uid": 1, "side": "ally"})
	moved.queue_swap(1, 2)
	moved.play()
	moved.enemy_plan.clear()
	moved.hand = [power("sowing", 2)]
	moved.selected.assign([0])
	moved.play()
	expect(moved.party[0].hp == 22 and moved.party[1].hp == moved.party[1].max_hp, "Swapping slots does not transfer a seed benefit or trait healing to the incoming body")
	var fire = fixture([unit("ember")])
	conditions.apply(fire.enemies[0], "seed", 3, {"uid": 1, "side": "ally"})
	fire.enemies[0].statuses.wet = 2
	fire.hand = [power("fireball")]
	fire.selected.assign([0])
	fire.play()
	expect(fire.enemies[0].hp == 482 and fire.enemies[0].statuses.burn == 5, "Incêndio adds four Queima to Combustão's two: twelve direct plus six ticking damage")
	expect(fire.enemies[0].statuses.wet == 1 and not fire.enemies[0].statuses.has("seed"), "Fogo consumes Semeado without inventing evaporation or extinguishing Encharcado")
	var multi: Dictionary = unit("moss")
	multi.statuses = {"seed": 3, "wet": 2}
	expect(reactions.choose({"damage": 1, "nature": "lightning"}, multi).id == "conduction", "Explicit reaction precedence picks a single reaction and leaves unmatched setups")
	var resistant = fixture([unit("ember")])
	resistant.party[0].statuses.wet = 2
	resistant.party[0].resistances = {"lightning": 25}
	resistant.party[0].block = 5
	resistant.party[0].hp = 40
	var strike: Dictionary = hostile(resistant.enemies[0], 20)
	strike.nature = "lightning"
	resistant.enemy_plan = [strike]
	resistant.redraw()
	expect(resistant.party[0].hp == 17, "Twenty power × Condução × 75% resistance − two Defense − five shield deals exactly 23 HP")
	expect(resistant.party[0].statuses.wet == 1, "Resistance does not resist conditions, and Condução preserves Wet")
	var attacker = fixture([unit("volt", "vital", 1, 2)])
	attacker.party[0].known_powers.append("judgment")
	attacker.party[0].statuses.electrified = 2
	attacker.enemies[0].resistances = {}
	var template: Dictionary = attacker.enemies[0].duplicate(true)
	for slot in [0, 2]:
		var foe: Dictionary = template.duplicate(true)
		foe.uid += slot + 10
		foe.slot = slot
		attacker.enemies.append(foe)
	attacker.hand = [power("judgment")]
	attacker.selected.assign([0])
	attacker.play()
	for foe in attacker.enemies: expect(foe.hp == 471, "Eletrificado weakens every target of one area technique (39 × 75%, rounded down once)")
	expect(not attacker.party[0].statuses.has("electrified"), "An area technique consumes Interferência once, rather than once per target")
	var support = fixture([unit("moss")])
	support.party[0].statuses.electrified = 2
	support.party[0].hp = 20
	support.hand = [power("root_wall")]
	support.selected.assign([0])
	support.play()
	expect(support.party[0].hp == 22 and support.party[0].statuses.electrified == 1, "Healing and defense are unaffected and do not consume Eletrificado")
	var inactive = fixture([unit("ember"), unit("moss", "vital", 2, 1, -1)])
	conditions.apply(inactive.party[1], "seed", 3, {"uid": 1001, "side": "enemy"})
	inactive.redraw()
	expect(inactive.party[1].statuses.seed == 3, "Condition duration pauses on reserves")
	var interference = fixture([unit("volt")])
	interference.party[0].defense = 0
	interference.enemies[0].resistances = {}
	interference.enemy_plan = [hostile(interference.enemies[0], 20)]
	interference.hand = [power("interference")]
	interference.selected.assign([0])
	interference.play()
	expect(interference.party[0].hp == 21 and not interference.enemies[0].statuses.has("electrified"), "Fast Interferência weakens the enemy's already committed attack to fifteen without skipping it")
	var enemy_bloom = fixture([unit("dew")])
	enemy_bloom.enemies[0].hp = 450
	conditions.apply(enemy_bloom.party[0], "seed", 3, {"uid": int(enemy_bloom.enemies[0].uid), "side": "enemy"})
	var aquatic: Dictionary = hostile(enemy_bloom.enemies[0], 4)
	aquatic.nature = "water"
	enemy_bloom.enemy_plan = [aquatic]
	enemy_bloom.redraw()
	expect(enemy_bloom.enemies[0].hp == 458 and not enemy_bloom.party[0].statuses.has("seed"), "Enemy techniques share the same Floração and source-ownership rules")

	var slow_control = fixture([unit("volt")])
	slow_control.party[0].speed = 1
	slow_control.party[0].defense = 0
	slow_control.enemies[0].speed = 30
	slow_control.enemy_plan = [hostile(slow_control.enemies[0], 8)]
	slow_control.hand = [power("interference")]
	slow_control.selected.assign([0])
	slow_control.play()
	expect(slow_control.party[0].hp == 28 and slow_control.enemies[0].statuses.electrified == 1, "Slower Interferência cannot weaken the attack that already executed")
	slow_control.enemy_plan = [hostile(slow_control.enemies[0], 8)]
	slow_control.redraw()
	expect(slow_control.party[0].hp == 22 and not slow_control.enemies[0].statuses.has("electrified"), "The next round's attack consumes the remaining one-round Interferência and still executes")
	var learner: Dictionary = unit("ember")
	learner.known_powers.append("tidal_splash")
	var borrowed: Dictionary = Rules.power_effect(power("tidal_splash"), learner, 1)
	expect(borrowed.nature == "water" and borrowed.burn == 2 and borrowed.conditions.wet == 2, "A learned water move keeps Water and Wet while Brasa's explicit attack trait still applies")
	var symmetry = fixture([unit("ember", "vital", 1, 1, 0), unit("moss", "vital", 2, 1, 1), unit("volt", "vital", 3, 1, 2)])
	for actor in symmetry.party:
		actor.defense = 0
		actor.resistances = {}
		actor.statuses.wet = 2
	symmetry.enemies[0].statuses.electrified = 2
	var electric_area: Dictionary = hostile(symmetry.enemies[0], 10, "all")
	electric_area.nature = "lightning"
	symmetry.enemy_plan = [electric_area]
	symmetry.redraw()
	for actor in symmetry.party: expect(actor.hp == actor.max_hp - 15, "Enemy area applies weakening before Condução with only one final rounding")
	expect(symmetry.last_result.events.filter(func(event: Dictionary) -> bool: return event.get("reaction", "") == "conduction").size() == 3, "An area can react once with each of its three occupied targets")
	var guarded = fixture([unit("ember")])
	guarded.enemies[0].resistances = {"fire": 25}
	guarded.hand = [power("fireball")]
	guarded.selected.assign([0])
	guarded.play()
	expect(guarded.enemies[0].hp == 489 and guarded.enemies[0].statuses.burn == 1, "A fire resistance reduces only direct damage: nine direct plus two unresisted Queima")
	for mode in ["hidden", "partial"]:
		var view: Array = guarded.public_intents(mode)
		expect(view.all(func(intent: Dictionary) -> bool: return not intent.has("nature") and not intent.has("conditions")), "A public body resistance never leaks the nature or condition of a secret technique: " + mode)

func test_elemental_starters() -> void:
	for species in Content.STARTERS:
		var clears: int = 0
		for run_seed in range(12):
			var game = Rules.new()
			game.new_run(run_seed, "partial", species)
			expect(game.party.size() == 1 and game.party[0].species == species and game.hand.size() == 6, "Each chosen starter begins alone with precisely six owned cards: " + species)
			var steps: int = 0
			while game.phase == "battle" and steps < 60:
				game.selected = game.best_selection()
				if game.preview().valid: game.play()
				else: game.redraw()
				steps += 1
			expect(game.phase in ["reward", "defeat"], "Every starter exits the first encounter without deadlock: " + species)
			if game.phase == "reward": clears += 1
		expect(clears > 0, "Each starter has a measured solo route through the first encounter: " + species)
		print(JSON.stringify({"starter": species, "seeds": 12, "first_encounter_clears": clears, "policy": "bounded heuristic, no items", "limits": "Not a human playtest or balance verdict"}))

func test_initial_passive_usefulness() -> void:
	for species in Content.STARTERS:
		for passive in Content.PASSIVE_POOLS[species]:
			var owner: Dictionary = unit(species, passive)
			var neutral: Dictionary = unit(species, "")
			var useful: bool = int(owner.speed) != int(neutral.speed)
			for id in owner.known_powers:
				var enhanced: Dictionary = Rules.power_effect(power(id), owner, 1)
				var normal: Dictionary = Rules.power_effect(power(id), neutral, 1)
				for effect in ["damage", "block", "heal", "burn"]:
					if int(enhanced[effect]) != int(normal[effect]): useful = true
			expect(useful, "Every initial passive changes a usable starting power or initiative: %s/%s" % [species, passive])
