extends SceneTree
const Cases = preload("res://tests/support/case_selection.gd")
const Rules = preload("res://scripts/rules.gd")
const Models = preload("res://scripts/domain/models.gd")
const Content = preload("res://scripts/content.gd")
const Combat = preload("res://scripts/domain/combat_records.gd")
const Resolver = preload("res://scripts/domain/effect_resolver.gd")
const Effect = preload("res://scripts/catalog/effect_definition.gd")
const Status = preload("res://scripts/catalog/status_definition.gd")
const Action = preload("res://scripts/catalog/enemy_action.gd")
const Contracts = preload("res://scripts/domain/content_contracts.gd")
const Summary = preload("res://scripts/ui/combat_event_summary.gd")
var definitions: Content.Catalog = Content.create_catalog()
var checks: int = 0
var failed: int = 0

func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + description)

func request(op: String, amount: int, target: String, status: Resource = null) -> Combat.Request:
	return Combat.Request.new(op, amount, target, "fixture", 12, status)

func state() -> Combat.State:
	var initial = Combat.State.new()
	initial.player_hp = 30
	initial.player_max = 40
	initial.enemy_hp = 100
	initial.enemy_max = 105
	return initial

func game() -> Rules:
	var rules = Rules.new(definitions)
	rules.new_run(42013)
	rules.party.assign([Rules.make_umbral("ember", "fierce", 1), Rules.make_umbral("moss", "vital", 2)])
	rules.start_encounter()
	return rules

func test_statuses() -> void:
	var poison = Status.new()
	poison.status_id = "poison"
	poison.display_name = "Veneno"
	poison.duration = 2
	var initial: Combat.State = state()
	var cast: Array[Combat.Request] = [request("status", 3, "enemy", poison)]
	var outcome = Resolver.resolve(initial, cast)
	expect(initial.statuses.is_empty() and initial.enemy_hp == 100, "Resolver never aliases input status state")
	expect(outcome.state.enemy_hp == 97 and outcome.state.statuses[0].remaining == 1, "Poison ticks immediately with explicit two-cast duration")
	expect(outcome.events[1].source_uid == 12 and outcome.events[1].status_id == "poison" and outcome.events[1].phase == "after_cast", "Status tick keeps source and phase")
	outcome = Resolver.resolve(outcome.state, [])
	expect(outcome.state.enemy_hp == 94 and outcome.state.statuses.is_empty(), "Finite status expires after second tick")
	poison.stacking = "max"
	outcome = Resolver.resolve(initial, [request("status", 5, "enemy", poison), request("status", 2, "enemy", poison)], [], false)
	expect(outcome.state.stacks("poison") == 5, "Maximum stacking keeps stronger application")
	poison.stacking = "replace"
	outcome = Resolver.resolve(initial, [request("status", 5, "enemy", poison), request("status", 2, "enemy", poison)], [], false)
	expect(outcome.state.stacks("poison") == 2, "Replacement stacking explicitly replaces")
	poison.stacking = "add"
	poison.max_stacks = 6
	outcome = Resolver.resolve(initial, [request("status", 5, "enemy", poison), request("status", 2, "enemy", poison)], [], false)
	expect(outcome.state.stacks("poison") == 6 and outcome.events[1].applied == 1, "Additive stacks respect cap and report actual addition")
	var regeneration = Status.new()
	regeneration.status_id = "regeneration"
	regeneration.display_name = "Regeneração"
	regeneration.tick_operation = "heal"
	regeneration.duration = 1
	regeneration.timing = "after_retaliation"
	outcome = Resolver.resolve(initial, [request("status", 4, "player", regeneration)], [request("damage", 7, "player")])
	expect(outcome.state.player_hp == 27 and outcome.events[-1].phase == "after_retaliation", "Regeneration runs in its declared phase after damage")
	outcome = Resolver.resolve(initial, [request("damage", 900, "enemy")], [request("damage", 7, "player")])
	expect(outcome.state.player_hp == 30 and outcome.events.size() == 1, "Enemy death skips its entire action")
	expect(outcome.events[0].requested == 900 and outcome.events[0].applied == 100, "Overkill retains requested and applied damage separately")
	outcome = Resolver.resolve(initial, [request("heal", 50, "player")], [], false)
	expect(outcome.events[0].requested == 50 and outcome.events[0].applied == 10, "Healing event records capped amount")
	initial.draw_capacity = 1
	var limited = Resolver.resolve(initial, [request("draw", 3, "player"), request("draw", 2, "player")], [], false)
	expect(limited.state.draw == 1 and limited.events[0].applied == 1 and limited.events[1].applied == 0, "Draw events report available cards rather than requested excess")
	var summary = Summary.new(outcome.events)
	expect(summary.healing == 10 and summary.damage == 0, "Presentation reads applied events rather than power definitions")

func test_powers_and_enemies() -> void:
	var base = definitions.species.ember.form("ember").power("fireball")
	var evolved = definitions.species.ember.form("ignivar").power("fireball")
	expect(base.identity == evolved.identity and base.damage == 12 and evolved.damage == 17, "Forms share power identity while stats remain explicit")
	var g: Rules = game()
	var cards: Array[Models.CardInstance] = [Models.CardInstance.new("fireball", 1), Models.CardInstance.new("root_wall", 2)]
	var before: Dictionary = g.snapshot()
	var random_state: int = g.rng.state
	var a = g.project(cards)
	cards.reverse()
	var b = g.project(cards)
	expect(a.to_dict() == b.to_dict(), "Canonical cast order preserves effects and event attribution")
	expect(g.snapshot() == before and g.rng.state == random_state, "Full event projection is pure")
	expect(a.combat_events.any(func(event): return event.source_uid == 1 and event.source_id == "fireball"), "Power events identify source individual and definition")
	expect(a.combat_events.any(func(event): return event.source_instance_id == "1:fireball:0"), "Events distinguish copies of the same owned power")
	var conditional = Effect.new()
	conditional.operation = "damage"
	conditional.amount = 5
	conditional.condition = "target_burning"
	base.effects.append(conditional)
	var cold = g.project([Models.CardInstance.new("fireball", 1)])
	expect(cold.evaluation.damage == 17, "New burn from same cast does not activate a start-state condition")
	g.enemy_burn = 1
	var hot = g.project([Models.CardInstance.new("fireball", 1)])
	expect(hot.evaluation.damage == 23, "Existing burn activates authored conditional damage")
	base.effects.erase(conditional)
	var draw = Effect.new()
	draw.operation = "draw"
	draw.target = "player"
	draw.amount = 2
	base.effects.append(draw)
	g.deck.append_array(g.hand)
	g.hand.clear()
	for index in range(g.deck.size()):
		if g.deck[index].power == "fireball":
			g.hand.append(g.deck[index])
			g.deck.remove_at(index)
			break
	g.selected.assign([0])
	var projection = g.preview_round()
	expect(projection.extra_draw == 2 and g.hand.size() == 1, "Draw preview reports cards without consuming RNG")
	g.play()
	expect(g.hand.size() == 8 and g.last_result.extra_draw == 2, "Committed draw effect refills then draws two additional powers")
	base.effects.erase(draw)
	var enemy = definitions.encounters[0].enemy
	var previous: Array = enemy.actions.duplicate()
	var defense = Action.new()
	defense.action_id = "guard"
	defense.display_name = "Proteção"
	var guard = Effect.new()
	guard.operation = "block"
	guard.target = "enemy"
	guard.amount = 50
	defense.effects.append(guard)
	enemy.actions.assign([defense])
	g = game()
	g.hand.assign([Models.CardInstance.new("fireball", 1)])
	g.selected.assign([0])
	projection = g.preview_round()
	expect(projection.incoming == 0 and projection.state_after.enemy_block == 50, "Enemy defense is authored as an action")
	g.play()
	projection = g.project([Models.CardInstance.new("fireball", 1)])
	expect(projection.applied_damage == 0, "Enemy shield absorbs next cast including its burn tick")
	expect(projection.combat_events.any(func(event): return event.kind == "damage" and event.blocked > 0), "Events distinguish shield absorption from overkill")
	var heal = Effect.new()
	heal.operation = "heal"
	heal.target = "enemy"
	heal.amount = 9
	defense.effects.assign([heal])
	g.enemy_block = 0
	projection = g.project([Models.CardInstance.new("fireball", 1)])
	expect(projection.combat_events.any(func(event): return event.kind == "heal" and event.target == "enemy" and event.applied == 9), "Enemy healing uses same executor and structured events")
	enemy.actions.assign(previous)

func test_inventory() -> void:
	var g: Rules = game()
	var before = g.snapshot()
	var random_state: int = g.rng.state
	expect(g.use_item(1) == null and g.inventory.items[0].quantity == 1, "Full-health tonic is not wasted")
	expect(g.use_item(999) == null and g.snapshot() == before, "Unknown item is rejected without mutation")
	g.player_hp = 37
	g.enemy_burn = 4
	var old_plays: int = g.plays
	var outcome = g.inventory.preview_use(1, g.combat_state())
	expect(outcome.total("heal", "player") == 3 and g.player_hp == 37, "Consumable preview shares heal cap and stays pure")
	outcome = g.use_item(1)
	expect(outcome != null and g.player_hp == 40 and g.inventory.items[0].quantity == 0, "One tonic consumes one dose only after effective healing")
	expect(g.plays == old_plays and g.enemy_burn == 4 and g.rng.state == random_state, "Item does not advance round, statuses, intention or RNG")
	expect(g.use_item(1) == null, "Empty consumable cannot be used again")
	expect(not g.equip_item(2, 999) and g.inventory.items[1].equipped_uid == -1, "Equipment requires a current individual UID")
	g.enemy_burn = 0
	var cards: Array[Models.CardInstance] = [Models.CardInstance.new("fireball", 1), Models.CardInstance.new("cinder_claw", 1)]
	var damage: int = g.project(cards).evaluation.damage
	expect(g.equip_item(2, 1), "Concrete relic can be equipped")
	var boosted = g.project(cards)
	expect(boosted.evaluation.damage == damage + 2, "Relic adds damage once per owner/cast, not once per card")
	expect(boosted.combat_events.filter(func(event): return event.source_id == "ember_charm").size() == 1, "Relic contribution has separate attributable event")
	var unboosted = g.project([Models.CardInstance.new("root_wall", 2)])
	expect(not unboosted.combat_events.any(func(event): return event.source_id == "ember_charm"), "Inactive equipped individual does not trigger relic")
	g.phase = "reward"
	g.reward_offers.assign([Models.RewardOffer.new("evolve", null, 1, "ignivar", "ember", "to_ignivar")])
	expect(g.choose_reward(0) and g.party[0].form_id == "ignivar" and g.inventory.items[1].equipped_uid == 1, "Equipment survives declared evolution by UID")
	g.phase = "reward"
	g.party.append(Rules.make_umbral("volt", "swift", 3))
	g.reward_offers.assign([Models.RewardOffer.new("capture", Rules.make_umbral("volt", "swift", 4))])
	expect(g.choose_reward(0, 1) and g.inventory.items[1].equipped_uid == -1, "Replacing equipped individual returns relic to bag")
	g.phase = "defeat"
	before = g.snapshot()
	expect(not g.equip_item(2, 2) and g.use_item(1) == null and g.snapshot() == before, "Inventory commands reject ended expedition")
	var detached = g.snapshot()
	if not detached.history.is_empty(): detached.history[0].applied = 999
	expect(g.history.is_empty() or g.history[0].applied != 999, "History snapshot does not expose live events")

func test_validation() -> void:
	expect(Contracts.expedition(Content.ENCOUNTERS, Content.SPECIES.keys()).is_empty(), "Authored encounters satisfy typed contracts")
	expect(Contracts.items(Content.ITEMS.items).is_empty(), "Concrete consumable and relic satisfy contracts")
	var effect = Effect.new()
	effect.operation = "unknown"
	expect(not Contracts.effects([effect]).is_empty(), "Unknown effect is rejected")
	effect.operation = "status"
	expect(not Contracts.effects([effect]).is_empty(), "Status requires explicit definition")
	effect.status = Status.new()
	effect.status.duration = 0
	expect(not Contracts.effects([effect]).is_empty(), "Invalid status duration is rejected")
	effect.operation = "draw"
	effect.target = "enemy"
	expect(not Contracts.effects([effect]).is_empty(), "Unsupported draw target is rejected")
	var encounters: Array = []
	for encounter in Content.ENCOUNTERS: encounters.append(encounter.duplicate_deep(Resource.DEEP_DUPLICATE_ALL))
	encounters[0].rewards.guaranteed_missing_species = "missing"
	expect(not Contracts.expedition(encounters, Content.SPECIES.keys()).is_empty(), "Unknown reward species is rejected before RNG use")

func _init() -> void:
	if not Cases.run({"enemy_shield": test_enemy_shield, "statuses": test_statuses, "powers_and_enemies": test_powers_and_enemies, "inventory": test_inventory, "validation": test_validation}):
		quit(2)
		return
	print(JSON.stringify({"case": Cases.active_case, "cases": Cases.executed, "suite": "growth_contracts", "checks": checks, "failed": failed}))
	quit(0 if failed == 0 else 1)

func test_enemy_shield() -> void:
	var g: Rules = game()
	g.enemy_hp = 1
	g.enemy_block = 50
	var result = g.project([Models.CardInstance.new("fireball", 1)])
	expect(result.enemy_hp_after == 1 and result.phase == "battle", "Shield prevents a lethal raw attack")
	expect(result.applied_damage == 0 and result.combat_events.any(func(event): return event.blocked > 0), "Shield reports actual absorption")
