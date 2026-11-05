extends RefCounted
const Rules = preload("res://scripts/rules.gd")
const Resolution = preload("res://scripts/battle/round_resolution.gd")
const Initiative = preload("res://scripts/battle/initiative.gd")
const Expedition = preload("res://scripts/expedition/expedition.gd")
const Identity = preload("res://scripts/expedition/identity.gd")
const Replay = preload("res://scripts/expedition/replay.gd")
const Store = preload("res://scripts/session/run_save.gd")
const Events = preload("res://scripts/ui/attack_events.gd")
const Readout = preload("res://scripts/ui/battle_readout.gd")

static func example(form: String = "lonelo", power: String = "tidal_splash", revision: int = 6, hp: int = 100, block: int = 0, status: Dictionary = {}) -> Dictionary:
	var owner: Dictionary = Rules.make_umbral("dew", "", 1, form)
	owner.slot = 1
	owner.statuses = status.duplicate(true)
	var target: Dictionary = Rules.make_umbral("moss", "", 9001, "moss")
	target.slot = 1
	target.max_hp = 100
	target.hp = hp
	target.defense = 2
	target.block = block
	var card: Dictionary = {"owner": 1, "power": power, "instance_id": "1:test", "target_slot": 1}
	var party: Array = [owner]
	var enemies: Array = [target]
	var queue: Array = Initiative.player_entries([card], party, [], [])
	var result: Dictionary = Resolution.new(party, enemies, {}, {}, 1, revision).resolve(queue)
	return {"result": result, "owner": owner, "target": target, "queue": queue, "party": party, "enemies": enemies}

static func attacks(result: Dictionary) -> Array:
	return result.events.filter(func(event: Dictionary) -> bool: return event.kind == "attack")

static func run(expect: Callable) -> void:
	var normal: Dictionary = example()
	var hits: Array = attacks(normal.result)
	expect.call(hits.size() == 2 and hits[0].amount == 21 and hits[1].amount == 4 and normal.target.hp == 75, "Lonelo's water technique resolves 21 + 4 after defense on each hit")
	expect.call(hits[1].get("companion") == true and hits[1].actor_uid == 1 and hits[1].target_uid == 9001, "Companion strike retains actual owner and target identity")
	expect.call(normal.result.applied_damage == 25 and hits[0].target_state.hp == 79 and hits[1].target_state.hp == 75, "Damage total and sequential public snapshots include both strikes")
	var first: Dictionary = Events.collect(normal.result.events, 0)
	var second: Dictionary = Events.collect(normal.result.events, int(first.next))
	expect.call(attacks(first).size() == 1 and attacks(second).size() == 1, "Presentation separates the two strikes into separate gestures")
	expect.call(Readout.event_line(hits[1]).contains("Companheira de Lonelo"), "Resolved second strike is explicitly attributed to the companion")
	var blocked: Dictionary = example("lonelo", "tidal_splash", 6, 100, 24)
	var blocked_hits: Array = attacks(blocked.result)
	expect.call(blocked_hits[0].blocked == 21 and blocked_hits[1].blocked == 3 and blocked.target.hp == 99, "Both strikes spend the same finite shield in order")
	var weak: Array = attacks(example("lonelo", "tidal_splash", 6, 100, 0, {"electrified": 2}).result)
	expect.call(weak[0].amount == 15 and weak[1].amount == 2, "Electrified weakens the full two-hit technique without being consumed twice")
	var charged: Array = attacks(example("lonelo", "tidal_splash", 6, 100, 0, {"charge": 8}).result)
	expect.call(charged[0].amount == 29 and charged[1].amount == 4, "Stored charge augments the original hit only, not the bounded companion strike")
	var lethal: Dictionary = example("lonelo", "tidal_splash", 6, 20)
	expect.call(attacks(lethal.result).size() == 1 and lethal.target.hp == 0, "A target killed by Lonelo receives no extra strike or retarget")
	var final_hit: Dictionary = example("lonelo", "tidal_splash", 6, 23)
	expect.call(attacks(final_hit.result)[1].amount == 2 and final_hit.result.events.back().kind == "ko", "Companion damage is capped by remaining HP and emits KO")
	for form: String in ["dew", "mareveu", "londraval"]:
		expect.call(attacks(example(form).result).size() == 1, "Other aquatic forms retain a single strike: " + form)
	expect.call(attacks(example("lonelo", "rain_sweep").result).size() == 1, "Area water is not doubled")
	expect.call(attacks(example("lonelo", "dew_mend").result).is_empty(), "Support does not trigger the companion")
	expect.call(attacks(example("lonelo", "tidal_splash", 5).result).size() == 1, "Historical graph 5 retains one strike")
	for disabled: String in ["hp", "slot", "can_act_round"]:
		var fixture: Dictionary = example()
		fixture.owner[disabled] = {"hp": 0, "slot": -1, "can_act_round": 2}[disabled]
		var stopped: Dictionary = Resolution.new(fixture.party, fixture.enemies, {}, {}, 1, 6).resolve(fixture.queue)
		expect.call(attacks(stopped).is_empty() and stopped.events[0].kind == "canceled", "Companion cannot act when owner is unavailable: " + disabled)
	var defended: Dictionary = example()
	defended.target.hp = 100
	defended.target.resistances = {"water": 50}
	var resisted: Array = attacks(Resolution.new(defended.party, defended.enemies, {}, {}, 1, 6).resolve(defended.queue))
	expect.call(resisted[0].amount == 9 and resisted[1].amount == 1, "Water resistance halves each strike before separate defense")
	var double: Dictionary = example()
	double.target.hp = 100
	var copy: Dictionary = double.queue[0].duplicate(true)
	copy.card.instance_id = "1:second-copy"
	var repeated: Dictionary = Resolution.new(double.party, double.enemies, {}, {}, 1, 6).resolve([double.queue[0], copy])
	expect.call(attacks(repeated).size() == 4 and double.target.hp == 50, "Two owned copies produce two bounded pairs, not recursive followups")
	var seeded: Dictionary = example()
	seeded.target.hp = 100
	seeded.target.statuses = {"seed": 2}
	seeded.target.status_sources = {"seed": {"uid": 1, "side": "ally"}}
	seeded.owner.hp = 30
	var blossom: Dictionary = Resolution.new(seeded.party, seeded.enemies, {}, {}, 1, 6).resolve(seeded.queue)
	expect.call(seeded.owner.hp == 38 and blossom.events.filter(func(e: Dictionary) -> bool: return e.kind == "reaction").size() == 1, "Companion does not duplicate the original seed reaction")
	history_and_save(expect)

static func history_and_save(expect: Callable) -> void:
	var history: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/aquatic5_lonelo_8d1a3ae.json"))
	var game = Expedition.new()
	expect.call(game.restore(history.initial_state) and Replay.execute(game, history.commands).ok, "Actual old-main Lonelo checkpoint/replay migrates")
	var expected: Dictionary = history.after.duplicate(true)
	expected.identity = Identity.current()
	expect.call(JSON.parse_string(JSON.stringify(game.snapshot())) == expected and JSON.parse_string(JSON.stringify(game.battle.last_result.events)) == history.events, "Old Lonelo replay retains complete snapshots and exact original single-strike events")
	var forged: Dictionary = history.initial_state.duplicate(true)
	forged.catalog_revision = 6
	expect.call(not game.restore(forged), "Old rules4 identity cannot forge new companion mechanics")
	var current: Dictionary = history.initial_state.duplicate(true)
	current.identity = Identity.current()
	current.catalog_revision = 6
	expect.call(game.restore(current), "New mechanics fixture validates through public restore")
	var before: Dictionary = game.snapshot()
	var store = Store.new("user://lonelo_companion_test.json", "lonelo.companion.test")
	expect.call(store.save(before), "New Lonelo run writes through real two-slot storage")
	var resumed = Expedition.new()
	expect.call(resumed.restore(store.load_snapshot()), "New Lonelo resumes through validated real storage")
	var selection: Dictionary = history.commands[0]
	expect.call(Replay.apply(game, selection), "Owned water copy can be selected normally")
	var rng: int = game.battle.rng.state
	var preview: Dictionary = game.battle.preview()
	expect.call(preview.valid and preview.actions == 1 and preview.bonuses.size() == 1 and game.battle.rng.state == rng, "Pure preview explains companion without spending an extra action or RNG")
	expect.call(Replay.apply(game, history.commands[1]) and Replay.execute(resumed, history.commands).ok, "Both live and resumed runs commit the same real card")
	expect.call(game.snapshot() == resumed.snapshot() and game.battle.last_result.events == resumed.battle.last_result.events, "New double-strike replay is exactly deterministic across save/load")
	var followups: Array = game.battle.last_result.events.filter(func(event: Dictionary) -> bool: return event.get("companion", false))
	expect.call(followups.size() == 1 and game.battle.party.size() == 1, "One owned single-target card produces one companion strike without another unit")
	store.clear()
