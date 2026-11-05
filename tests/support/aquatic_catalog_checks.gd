extends RefCounted
const Identity = preload("res://scripts/expedition/identity.gd")
const Registry = preload("res://scripts/expedition/migration_registry.gd")
const Revision = preload("res://scripts/battle/catalog_revision.gd")
const Expedition = preload("res://scripts/expedition/expedition.gd")
const Replay = preload("res://scripts/expedition/replay.gd")
const Rules = preload("res://scripts/rules.gd")
const Cards = preload("res://tests/support/catalog_union_checks.gd")

static func run(expect: Callable) -> void:
	preload("res://tests/support/aquatic_history_checks.gd").run(expect)
	var history: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/combined_catalog4_60b4e30.json"))
	expect.call(history.identity == Registry.COMBINED4_IDENTITY and Registry.supports(history.identity), "Frozen actual main catalog migrates through exact aquatic projection")
	var old = Expedition.new()
	var source: Dictionary = history.initial_state.duplicate(true)
	expect.call(old.restore(source) and source == history.initial_state, "Aquatic migration leaves source checkpoint untouched")
	expect.call(Replay.execute(old, history.commands).ok, "Actual pre-aquatic replay still executes")
	var expected: Dictionary = history.after.duplicate(true)
	expected.identity = Identity.current()
	expect.call(JSON.parse_string(JSON.stringify(old.snapshot())) == expected, "Historical aquatic replay preserves every state field, RNG, cards and plans")
	for id: String in ["londraval", "lonelo"]:
		for revision: int in [0, 1, 2, 3, 4]:
			expect.call(not Revision.form_available("dew", id, revision), "Older graphs cannot acquire an aquatic final: " + str(revision))
		expect.call(Revision.form_available("dew", id, Revision.CURRENT), "New graph includes explicit aquatic branch: " + id)
	var forged: Dictionary = source.duplicate(true)
	forged.catalog_revision = Revision.CURRENT
	expect.call(not old.restore(forged), "Historical combined identity cannot forge aquatic graph")
	var game = Expedition.new()
	game.new_run(42013, "full", "dew")
	game.battle.party[0] = Rules.make_umbral("dew", "vital", 1, "mareveu")
	game.battle.party[0].slot = 1
	expect.call(game.choose_node("clearing"), "Lonaro starts a private real battle checkpoint")
	game.battle.enemies[0].hp = 1
	game.battle._sync_compatibility()
	var initial: Dictionary = game.snapshot()
	expect.call(game.restore(initial), "Pre-evolution fixture passes public snapshot validation")
	var commands: Array = []
	for index: int in game.battle.best_selection(): commands.append({"command": "select", "index": index})
	commands.append({"command": "cast"})
	expect.call(Replay.execute(game, commands).ok and game.phase == "reward", "A real owned water cast reaches evolution rewards")
	var reward: Dictionary = game.snapshot()
	var finals: Array = []
	for index: int in range(game.battle.reward_offers.size()):
		var offer: Dictionary = reward.battle.reward_offers[index]
		if offer.get("kind") != "evolve": continue
		finals.append(offer.target_form_id)
		expect.call(game.restore(reward), "Each branch begins at same validated reward")
		var cards: Dictionary = Cards.card_set(game.battle.party)
		var passive: String = game.battle.party[0].passive
		expect.call(game.choose_reward(index), "Final evolves through player reward API: " + str(offer.target_form_id))
		expect.call(game.battle.party[0].form_id == offer.target_form_id and game.battle.party[0].uid == 1 and game.battle.party[0].passive == passive and Cards.card_set(game.battle.party) == cards, "Aquatic evolution preserves physical cards, passive and individual ownership")
		var resumed = Expedition.new()
		expect.call(resumed.restore(game.snapshot()) and resumed.snapshot() == game.snapshot(), "Both final branches resume exact state")
	expect.call(finals == ["londraval", "lonelo"], "Lonaro offers both explicit final branches in authored order")
	# The same battle on graph 4 must retain its old no-final reward behavior.
	initial.catalog_revision = 4
	expect.call(game.restore(initial) and Replay.execute(game, commands).ok, "Historical graph executes the identical battle commands")
	expect.call(game.battle.reward_offers.filter(func(offer: Dictionary) -> bool: return offer.get("kind") == "evolve").is_empty(), "Continued old runs never gain aquatic evolution offers")
