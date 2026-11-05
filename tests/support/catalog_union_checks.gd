extends RefCounted
const Identity = preload("res://scripts/expedition/identity.gd")
const Registry = preload("res://scripts/expedition/migration_registry.gd")
const Revision = preload("res://scripts/battle/catalog_revision.gd")
const Expedition = preload("res://scripts/expedition/expedition.gd")
const Rewards = preload("res://scripts/battle/rewards.gd")
const Evolution = preload("res://scripts/battle/evolution.gd")
const Content = preload("res://scripts/content.gd")
const Replay = preload("res://scripts/expedition/replay.gd")

static func run(expect: Callable) -> void:
	var history: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/electric_catalog3_4df4809.json"))
	expect.call(history.identity == Registry.ELECTRIC3_IDENTITY and JSON.stringify(Registry.Electric3.DATA).sha256_text() == history.identity.content_sha256, "Electric candidate has its exact frozen pre-merge gameplay manifest")
	expect.call(Registry.supports(history.identity) and Registry.supports(Registry.GRASS2_IDENTITY), "Both independently reviewed source catalogs migrate through audited adapters")
	expect.call(Registry.catalog_transition(Registry.Electric3.DATA, Identity.manifest(), 3) and Registry.catalog_transition(Registry.Grass2.DATA, Identity.manifest(), 2), "Combined catalog projects exactly to either independent source")
	for identity: Dictionary in [Registry.BASE_IDENTITY, Registry.RULES3_IDENTITY, Registry.CATALOG1_IDENTITY, Registry.GRASS2_IDENTITY, Registry.ELECTRIC3_IDENTITY]:
		for attempt: int in range(4):
			expect.call(Registry.supports(identity), "Repeated compatibility checks remain deterministic without mutating extension order: " + str(attempt))
	var game = Expedition.new()
	for source: Dictionary in [history.initial_state, history.reward, history.adults.auravel, history.adults.zuldar]:
		var before: Dictionary = source.duplicate(true)
		expect.call(game.restore(source) and source == before and game.battle.catalog_revision == 3, "Existing electric save restores without mutating its source or opening grass finals")
		var expected: Dictionary = source.duplicate(true)
		expected.identity = Identity.current()
		expected.catalog_revision = 3
		expect.call(JSON.parse_string(JSON.stringify(game.snapshot())) == JSON.parse_string(JSON.stringify(expected)), "Electric reward/adult snapshot preserves exact RNG, cards, plans, HP, UID and passive")
		expect.call(not Revision.form_available("moss", "foslash", game.battle.catalog_revision) and not Revision.form_available("moss", "folivel", game.battle.catalog_revision), "The independent electric history never gains a different evolution graph")
	expect.call(game.restore(history.initial_state) and Replay.execute(game, history.commands).ok, "Actual pre-merge electrical commands still execute")
	var expected_reward: Dictionary = history.reward.duplicate(true)
	expected_reward.identity = Identity.current()
	expected_reward.catalog_revision = 3
	expect.call(JSON.parse_string(JSON.stringify(game.snapshot())) == JSON.parse_string(JSON.stringify(expected_reward)), "Historical mixed-party reward order and RNG remain exact")
	for adult: String in ["auravel", "zuldar"]:
		expect.call(Revision.form_available("volt", adult, 3) and Revision.form_available("volt", adult, Revision.CURRENT), "Electric-only and combined graphs retain each electrical adult")
		expect.call(not Revision.form_available("volt", adult, 2), "Historical grass catalog cannot forge an electric adult")
	for final: String in ["foslash", "folivel"]:
		expect.call(Revision.form_available("moss", final, 2) and Revision.form_available("moss", final, Revision.CURRENT), "Grass-only and combined graphs retain each grass final")
	var forged: Dictionary = history.adults.auravel.duplicate(true)
	forged.catalog_revision = Revision.CURRENT
	expect.call(not game.restore(forged), "Historical electric identity cannot forge a combined-catalog marker")
	mixed_rewards(history, expect)


static func card_set(party: Array) -> Dictionary:
	var result: Dictionary = {}
	for unit: Dictionary in party:
		for card: Dictionary in unit.cards: result[card.instance_id] = card.duplicate(true)
	return result

static func mixed_rewards(history: Dictionary, expect: Callable) -> void:
	var expected: Dictionary = {2: ["ignivar", "foslash", "folivel"], 3: ["ignivar", "auravel", "zuldar"], 4: ["ignivar", "foslash", "folivel", "auravel", "zuldar"]}
	for graph: int in [2, 3, 4]:
		# Author a detached current fixture; historical source fixtures remain untouched.
		var fixture: Dictionary = history.reward.duplicate(true)
		fixture.identity = Identity.current()
		fixture.catalog_revision = graph
		var owner: Dictionary = fixture.battle.party[2]
		var evolved: Dictionary = owner.duplicate(true)
		evolved.form_id = "verdalio"
		Evolution.apply(owner, "verdalio", Content.species_stats(evolved))
		var rng = RandomNumberGenerator.new()
		rng.seed = int(fixture.battle.rng_seed)
		rng.state = int(fixture.battle.rng_state)
		var offers: Array = []
		Rewards.prepare(offers, fixture.battle.party, str(fixture.battle.starter_species), int(fixture.battle.encounter), true, int(fixture.battle.next_uid), rng, graph)
		fixture.battle.reward_offers = offers
		fixture.battle.rng_state = str(rng.state)
		var game = Expedition.new()
		expect.call(game.restore(fixture), "Private current mixed-lineage reward fixture validates: " + str(graph))
		expect.call(game.battle.reward_offers.slice(1).map(func(offer: Dictionary) -> String: return str(offer.target_form_id)) == expected[graph], "Mixed-party grass rewards precede deferred electrical rewards: " + str(graph))
		var reward: Dictionary = game.snapshot()
		for index: int in range(1, game.battle.reward_offers.size()):
			expect.call(game.restore(reward), "Each mixed-party evolution starts from the same validated reward")
			var cards: Dictionary = card_set(game.battle.party)
			var selected: Dictionary = game.battle.reward_offers[index].duplicate(true)
			expect.call(game.choose_reward(index), "Each permitted mixed-party final is reachable through the expedition API")
			var chosen: Array = game.battle.party.filter(func(unit: Dictionary) -> bool: return unit.uid == selected.uid)
			expect.call(chosen.size() == 1 and chosen[0].form_id == selected.target_form_id and card_set(game.battle.party) == cards, "Mixed evolution preserves owner UID and every party member's physical cards")
			var resumed = Expedition.new()
			expect.call(resumed.restore(game.snapshot()) and resumed.snapshot() == game.snapshot(), "Each mixed-party branch resumes its exact graph and state")
