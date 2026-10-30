extends SceneTree
const Expedition = preload("res://scripts/expedition/expedition.gd")
const Rules = preload("res://scripts/rules.gd")
const Content = preload("res://scripts/content.gd")
var checks: int = 0
var failures: Array[String] = []
func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("FAIL: " + message)
func reject_unchanged(run, data: Dictionary, baseline: Dictionary, description: String) -> void:
	expect(not run.restore(data) and run.snapshot() == baseline, description)
func win_fight(run) -> void:
	# A controlled terminal fixture exercises the real resolution and reward path.
	for foe in run.battle.enemies: foe.hp = 1
	for unused in range(30):
		if run.battle.phase != "battle": break
		var picks: Array = run.battle.best_selection()
		for index in picks: run.battle.toggle(index)
		if picks.is_empty(): run.battle.redraw()
		else: run.battle.play()
	run.settle_battle()
func _initialize() -> void:
	for id in ["clearing", "thicket", "boss"]:
		var index: int = Rules.encounter_index(id)
		expect(index >= 0 and Content.ENCOUNTERS[index].id == id, "encounter ID resolves catalog record: " + id)
	expect(Rules.encounter_index("missing") == -1, "unknown encounter ID rejected")
	var run = Expedition.new()
	run.new_run(123, "partial", "ember")
	var original: Dictionary = run.snapshot()
	expect(not run.choose_node("boss") and not run.choose_node("spring"), "locked nodes rejected")
	var pub: Dictionary = run.public_state()
	pub.party[0].hp = 0
	pub.nodes[0].next.clear()
	expect(run.snapshot() == original, "public state is a pure copy and consumes no RNG")
	expect(run.choose_node("clearing") and not run.choose_node("clearing"), "enter clearing only once")
	var committed: Dictionary = run.snapshot()
	var resumed = Expedition.new()
	expect(resumed.restore(committed), "restore committed battle")
	expect(resumed.snapshot() == committed, "restored battle keeps RNG, hand and committed intent")
	var json_save: Dictionary = JSON.parse_string(JSON.stringify(committed))
	expect(resumed.restore(json_save) and resumed.snapshot() == committed, "JSON checkpoint preserves integer fields and RNG")
	var chosen: Array = run.battle.best_selection()
	for index in chosen:
		run.battle.toggle(index)
		resumed.battle.toggle(index)
	if not chosen.is_empty():
		run.battle.play()
		resumed.battle.play()
		expect(run.snapshot() == resumed.snapshot(), "restored combat resolves identically")
	committed = resumed.snapshot()
	var broken: Dictionary = committed.duplicate(true)
	broken.battle.party[0].species = "unknown"
	reject_unchanged(resumed, broken, committed, "invalid species is atomic")
	broken = committed.duplicate(true)
	broken.battle.party[0].cards.append(broken.battle.party[0].cards[0].duplicate(true))
	reject_unchanged(resumed, broken, committed, "duplicate canonical instance rejected")
	broken = committed.duplicate(true)
	broken.battle.party[0].cards[0].power = "missing"
	reject_unchanged(resumed, broken, committed, "unknown canonical power rejected")
	broken = committed.duplicate(true)
	broken.battle.hand.pop_back()
	reject_unchanged(resumed, broken, committed, "missing zone instance rejected")
	broken = committed.duplicate(true)
	broken.battle.hand.append(broken.battle.hand[0].duplicate(true))
	reject_unchanged(resumed, broken, committed, "duplicate zone instance rejected")
	broken = committed.duplicate(true)
	broken.battle.hand[0].instance_id = "unknown-instance"
	reject_unchanged(resumed, broken, committed, "unknown zone instance rejected")
	broken = committed.duplicate(true)
	broken.battle.next_uid = broken.battle.party[0].uid
	reject_unchanged(resumed, broken, committed, "next uid must exceed party uids")
	broken = committed.duplicate(true)
	broken.battle.party[0].statuses = {"burn": "wrong"}
	reject_unchanged(resumed, broken, committed, "malformed status rejected")
	broken = committed.duplicate(true)
	broken.battle.party[0].status_sources = {"burn": {"uid": [], "side": "ally"}}
	reject_unchanged(resumed, broken, committed, "malformed status source rejected")
	broken = committed.duplicate(true)
	broken.battle.party[0].resistances = {"fire": 101}
	reject_unchanged(resumed, broken, committed, "out of range resistance rejected")
	broken = committed.duplicate(true)
	broken.battle.party[0].cards = [42]
	reject_unchanged(resumed, broken, committed, "non-dictionary card rejected")
	broken = committed.duplicate(true)
	broken.battle.party[0] = []
	reject_unchanged(resumed, broken, committed, "non-dictionary party member rejected")
	broken = committed.duplicate(true)
	broken.checkpoint_id = 42
	reject_unchanged(resumed, broken, committed, "checkpoint id must be text")
	broken.checkpoint_id = "result-token"
	expect(resumed.restore(broken), "optional checkpoint id accepted")
	win_fight(run)
	expect(run.phase == "reward", "clearing yields reward")
	var reward_save: Dictionary = run.snapshot()
	expect(resumed.restore(reward_save), "pending capture reward restores")
	var bad_reward: Dictionary = reward_save.duplicate(true)
	bad_reward.battle.reward_offers[0].umbral.uid += 1
	reject_unchanged(resumed, bad_reward, reward_save, "pending capture uid must match next uid")
	expect(run.choose_reward(0, -1, -1), "capture into reserve")
	expect(run.battle.party.size() == 2 and run.battle.party[1].slot == -1, "reserve persists")
	var before_formation: Dictionary = run.snapshot()
	expect(not run.battle.set_formation([-1, -1, -1]), "map formation requires a living active")
	expect(run.battle.set_formation([2, 1, -1]), "map formation deploys captured reserve")
	expect(run.battle.party[0].slot == 1 and run.battle.party[1].slot == 0, "map formation assigns explicit slots")
	var after_formation: Dictionary = run.snapshot()
	expect(after_formation.battle.rng_state == before_formation.battle.rng_state and after_formation.battle.hand.is_empty() and after_formation.battle.deck.is_empty() and after_formation.battle.discard_pile.is_empty(), "map formation does not draw or consume RNG")
	expect(after_formation.battle.party[0].cards == before_formation.battle.party[0].cards and after_formation.battle.party[1].cards == before_formation.battle.party[1].cards, "map formation preserves owned cards")
	var formation_save: Dictionary = JSON.parse_string(JSON.stringify(after_formation))
	expect(resumed.restore(formation_save) and resumed.battle.party == run.battle.party, "map formation checkpoint restores")
	expect(run.battle.set_formation([-1, 1, -1]), "map formation can return member to reserve")
	var map_save: Dictionary = JSON.parse_string(JSON.stringify(run.snapshot()))
	expect(resumed.restore(map_save) and resumed.battle.party == run.battle.party, "map checkpoint preserves captured collection")
	expect(not run.choose_reward(0) and not run.choose_node("clearing"), "no repeated reward or node")
	var maximum: int = run.battle.party[0].max_hp
	run.battle.party[0].hp = 1
	run.battle.party[1].hp = 0
	var before_rng: int = run.battle.rng.state
	expect(run.choose_node("spring"), "spring available")
	expect(run.battle.party[0].hp == 1 + ceili(maximum * 0.25) and run.battle.party[1].hp == 0, "spring heals living only")
	expect(run.battle.rng.state == before_rng and not run.choose_node("spring") and not run.choose_node("thicket"), "rest once, no roll, closes fork")
	expect(run.choose_node("boss"), "boss follows rest")
	var at_boss: Dictionary = run.snapshot()
	expect(resumed.restore(at_boss), "restore boss with reserve and KO")
	expect(resumed.battle.party == run.battle.party, "party survives restoration")
	var bad_boss: Dictionary = at_boss.duplicate(true)
	bad_boss.battle.enemies[1].uid = bad_boss.battle.enemies[0].uid
	reject_unchanged(resumed, bad_boss, at_boss, "duplicate enemy uid rejected")
	bad_boss = at_boss.duplicate(true)
	bad_boss.battle.enemies[1].slot = bad_boss.battle.enemies[0].slot
	reject_unchanged(resumed, bad_boss, at_boss, "duplicate enemy slot rejected")
	var target_save: Dictionary = at_boss.duplicate(true)
	target_save.battle.hand[0].target_slot = 2
	expect(resumed.restore(target_save) and resumed.battle.hand[0].target_slot == 2 and resumed.battle.enemy_plan == target_save.battle.enemy_plan, "restore preserves hand targets and committed enemy plan")
	resumed.battle.selected.append(0)
	resumed.battle.queued_items.append({"item": "potion", "uid": 1})
	expect(resumed.restore(target_save) and resumed.battle.selected.is_empty() and resumed.battle.queued_items.is_empty(), "uncommitted commands clear")
	var alt = Expedition.new()
	alt.new_run(222)
	expect(alt.choose_node("clearing"), "alternate clearing")
	win_fight(alt)
	expect(alt.choose_reward(1), "evolve reward")
	expect(alt.choose_node("thicket") and not alt.choose_node("spring"), "combat fork")
	win_fight(alt)
	expect(alt.phase == "reward" and alt.choose_reward(0, -1, -1), "second reward")
	expect(alt.choose_node("boss"), "boss follows thicket")
	win_fight(alt)
	expect(alt.phase == "victory", "boss concludes expedition")
	print("Expedition checks: %d; failures: %d" % [checks, failures.size()])
	quit(1 if failures.size() else 0)
