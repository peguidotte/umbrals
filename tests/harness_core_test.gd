extends SceneTree
const Cases = preload("res://tests/support/case_selection.gd")
const Rules = preload("res://scripts/rules.gd")
const Content = preload("res://scripts/content.gd")
const Models = preload("res://scripts/domain/models.gd")
const Planner = preload("res://scripts/domain/selection_planner.gd")
const Replay = preload("res://scripts/session/run_replay.gd")
var checks: int = 0
var failed: int = 0

func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + description)

func fresh() -> Rules:
	var game = Rules.new()
	game.new_run(42013)
	return game

func selection(game: Rules) -> Array[int]:
	return Planner.choose(game.hand, game.project, game.intent_damage())

func test_catalog_isolation() -> void:
	var a: Rules = fresh()
	var b: Rules = fresh()
	expect(a.catalog != b.catalog and a.catalog.species.ember != b.catalog.species.ember, "Runs own independent definition graphs")
	a.catalog.species.ember.form("ember").power("fireball").damage = 90
	expect(b.catalog.species.ember.form("ember").power("fireball").damage == 12 and Content.SPECIES.ember.form("ember").power("fireball").damage == 12, "Fixture cannot mutate another run or authored source")
	expect(a.catalog.species.ember.form("ember").power("fireball").identity == a.catalog.species.ember.form("ignivar").power("fireball").identity, "Fork retains shared identity inside its own species")
	a.catalog.species.erase("volt")
	expect(b.catalog.species.has("volt") and Content.SPECIES.has("volt"), "Catalog membership is per run")
	expect(b.catalog.fingerprint() == Content.DEFAULT.fingerprint(), "Fork fingerprint is semantically stable")

func test_planner() -> void:
	expect(Planner.combinations(12).size() == 298, "Twelve-card hand examines 298 subsets rather than 4095 masks")
	expect(Planner.combinations(24).size() == 2324, "Twenty-four-card hand grows cubically rather than exponentially")
	var masks: Array[int] = []
	for indices in Planner.combinations(6):
		var mask: int = 0
		for index in indices: mask |= 1 << index
		masks.append(mask)
	var sorted: Array[int] = masks.duplicate()
	sorted.sort()
	expect(masks == sorted, "Planner preserves ascending-mask tie order")
	var game: Rules = fresh()
	var before: Dictionary = game.export_state()
	var chosen: Array[int] = selection(game)
	expect(not chosen.is_empty() and game.export_state() == before, "Planner does not mutate run, history, selection or RNG")
	var best: Array[int] = []
	var best_value: float = -INF
	for mask in range(1, 1 << game.hand.size()):
		var indices: Array[int] = []
		var cards: Array[Models.CardInstance] = []
		for i in range(game.hand.size()):
			if mask & (1 << i): indices.append(i); cards.append(game.hand[i])
		if cards.size() > 3: continue
		var projection = game.project(cards)
		if not projection.ok: continue
		var value: float = projection.applied_damage + mini(game.intent_damage(), projection.evaluation.block) * 1.25 + projection.effective_heal * 1.4
		if value > best_value: best_value = value; best = indices
	expect(chosen == best, "Independent old enumeration chooses the same opening action")

func test_snapshot() -> void:
	var game: Rules = fresh()
	game.selected = selection(game)
	game.play()
	game.equip_item(2, 1)
	game.use_item(1)
	game.toggle(0)
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(game.export_state()))
	var restored: Rules = fresh()
	expect(restored.restore_state(snapshot), "JSON checkpoint restores complete live state")
	expect(restored.export_state() == game.export_state(), "Health, piles, equipment, statuses, history and last result survive roundtrip")
	expect(restored.last_result.state_after.to_dict() == game.last_result.state_after.to_dict() and restored.last_result.state_after.player_hp != restored.player_hp, "Last projection remains distinct from later tonic healing")
	expect(restored.rng.state == game.rng.state and restored.seed_value == game.seed_value, "RNG uses exact decimal strings without JSON precision loss")
	game.selected = selection(game)
	restored.selected = selection(restored)
	expect(game.play().to_dict() == restored.play().to_dict(), "Next committed resolution agrees after restore")
	expect(game.export_state() == restored.export_state(), "Draw/recycle RNG and all state remain identical")
	var original: Dictionary = restored.export_state()
	for change in ["schema", "rng", "owner", "duplicate", "selection", "quantity", "equipment", "catalog", "missing"]:
		var bad: Dictionary = original.duplicate(true)
		match change:
			"schema": bad.schema_version = 999
			"rng": bad.rng_state = "not-an-integer"
			"owner": bad.hand[0].owner = 999
			"duplicate": bad.deck.append(bad.hand[0].duplicate())
			"selection": bad.selected = [999]
			"quantity": bad.inventory[0].quantity = -1
			"equipment": bad.inventory[1].equipped_uid = 999
			"catalog": bad.catalog_id = "foreign"
			"missing": bad.erase("history")
		expect(not restored.restore_state(bad) and restored.export_state() == original, "Invalid snapshot is atomic: " + change)
	var detached: Dictionary = restored.export_state()
	detached.party[0].passive = "missing"
	expect(restored.party[0].passive != "missing", "Checkpoint dictionaries do not alias live records")

func test_reward_checkpoint() -> void:
	var game: Rules = fresh()
	while game.phase == "battle":
		game.selected = selection(game)
		if not game.play().ok: break
	expect(game.phase == "reward", "Real rules reach checkpoint before reward choice")
	var restored: Rules = fresh()
	expect(restored.restore_state(JSON.parse_string(JSON.stringify(game.export_state()))), "Offered identities and evolution edges restore without reroll")
	var previous_result: Dictionary = game.export_state().last_result
	expect(game.choose_reward(0) and restored.choose_reward(0) and game.export_state() == restored.export_state(), "Reward selection and next encounter shuffle replay exactly")
	expect(game.export_state().last_result == previous_result, "Starting an encounter cannot mutate the committed result status list")

func test_replay() -> void:
	var game: Rules = fresh()
	var log: Array = [{"command": "new_run", "seed": "42013"}]
	for index in selection(game): log.append({"command": "select", "index": index})
	log.append({"command": "cast"})
	log.append({"command": "equip", "id": 2, "uid": 1})
	log.append({"command": "use_item", "id": 1})
	var other: Rules = fresh()
	var first: Dictionary = Replay.run(game, log)
	var second: Dictionary = Replay.run(other, JSON.parse_string(JSON.stringify(log)))
	expect(first.ok and second.ok and game.export_state() == other.export_state(), "Serializable commands replay through production rule methods")
	var before: Dictionary = game.export_state()
	expect(not Replay.apply(game, {"command": "set_hp", "value": 999}) and game.export_state() == before, "Replay exposes no arbitrary setters")
	expect(not Replay.run(game, [{"command": "select", "index": 999}]).ok and game.export_state() == before, "Rejected replay command preserves state and reports failure")

func _init() -> void:
	if not Cases.run({"catalog_isolation": test_catalog_isolation, "planner": test_planner, "snapshot": test_snapshot, "reward_checkpoint": test_reward_checkpoint, "replay": test_replay}):
		quit(2)
		return
	print(JSON.stringify({"case": Cases.active_case, "cases": Cases.executed, "suite": "harness_core", "checks": checks, "failed": failed}))
	quit(0 if failed == 0 else 1)
