extends SceneTree
const Expedition = preload("res://scripts/expedition/expedition.gd")
const Replay = preload("res://scripts/expedition/replay.gd")
const Fixtures = preload("res://tests/support/scenario_fixtures.gd")
const Planner = preload("res://scripts/domain/selection_planner.gd")
const Cases = preload("res://tests/support/case_selection.gd")
var checks: int = 0
var failed: int = 0
func expect(ok: bool, description: String) -> void:
	checks += 1
	if not ok: failed += 1; printerr("FAIL: " + description)

func test_checkpoint() -> void:
	var fixture: Dictionary = Fixtures.make("rewards_many")
	var run = Expedition.new()
	expect(run.restore(JSON.parse_string(JSON.stringify(fixture.snapshot))), "Current collective checkpoint restores")
	expect(run.snapshot() == fixture.snapshot, "RNG, intents, owned copies and offered identities roundtrip")
	var previous: Dictionary = run.snapshot()
	var bad: Dictionary = previous.duplicate(true)
	bad.battle.party[0].hp = -1
	expect(not run.restore(bad) and run.snapshot() == previous, "Invalid checkpoint leaves the current expedition unchanged")
	var restored = Expedition.new()
	expect(restored.restore(previous), "A second independent run restores")
	expect(run.choose_reward(0, -1, -1) and restored.choose_reward(0, -1, -1), "Real reward API accepts the same offered capture")
	expect(run.snapshot() == restored.snapshot(), "Map progression and capture match after restore")

func test_replay() -> void:
	var fixture: Dictionary = Fixtures.make("rewards")
	var run = Expedition.new()
	expect(run.restore(fixture.initial_state) and Replay.execute(run, fixture.commands).ok, "Whitelisted commands reproduce a real battle")
	expect(run.snapshot() == fixture.snapshot, "Replay agrees with validated reward fixture")
	var previous: Dictionary = run.snapshot()
	expect(not Replay.apply(run, {"command": "set_hp", "value": 99}) and run.snapshot() == previous, "Replay has no arbitrary setter")

func test_planner() -> void:
	var costs: Array[int] = []
	costs.resize(24); costs.fill(1)
	expect(Planner.candidates(costs, 3).size() == 2324, "Twenty-four cards enumerate 2324 legal-budget candidates")
	costs.resize(4); costs.fill(0)
	expect(Planner.candidates(costs, 0).size() == 15, "Zero-cost powers do not acquire an artificial three-card limit")
	var run = Expedition.new()
	run.new_run(42013); run.choose_node("clearing")
	var before: Dictionary = run.snapshot()
	var selection: Array[int] = run.battle.selected.duplicate()
	var best: Array[int] = run.battle.best_selection()
	expect(not best.is_empty() and run.snapshot() == before and run.battle.selected == selection, "Planning does not mutate selection, RNG or committed state")
	var expected: Array[int] = []
	var best_value: float = -INF
	for mask in range(1, 1 << run.battle.hand.size()):
		var indices: Array[int] = []
		for i in range(run.battle.hand.size()):
			if mask & (1 << i): indices.append(i)
		var score: Dictionary = run.battle.preview_selection(indices)
		if not score.valid: continue
		var value: float = float(score.direct_damage) + float(score.block) * 0.45 + float(score.heal) * 0.35 + float(score.burn_added) * 1.2
		if value > best_value: best_value = value; expected = indices
	expect(best == expected, "Current opening preserves the old exhaustive-search tie order")

func _init() -> void:
	if not Cases.run({"checkpoint": test_checkpoint, "replay": test_replay, "planner": test_planner}): quit(2); return
	print(JSON.stringify({"suite": "harness_core", "case": Cases.active_case, "cases": Cases.executed, "checks": checks, "failed": failed}))
	quit(0 if failed == 0 else 1)
