extends RefCounted
const Rules = preload("res://scripts/rules.gd")
const Planning = preload("res://scripts/battle/planning.gd")
const Initiative = preload("res://scripts/battle/initiative.gd")
const Resolution = preload("res://scripts/battle/round_resolution.gd")

static func run(expect: Callable) -> void:
	for revision: int in [5, 6]:
		check_revision(revision, expect)

static func check_revision(revision: int, expect: Callable) -> void:
	var history: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/lonelo_preview_graph5_8d1a3ae.json"))
	var case_index: int = 0
	for example: Dictionary in [{"status": {}, "potential": [46, 58], "applied": [46, 58]}, {"status": {"charge": 8}, "potential": [62, 66], "applied": [54, 66]}, {"status": {"electrified": 2}, "potential": [34, 50], "applied": [40, 50]}, {"status": {"charge": 8, "electrified": 2}, "potential": [46, 56], "applied": [46, 56]}]:
		var owner: Dictionary = Rules.make_umbral("dew", "", 1, "lonelo")
		owner.slot = 1
		owner.statuses = example.status.duplicate(true)
		var target: Dictionary = Rules.make_umbral("moss", "", 9001)
		target.slot = 1
		target.hp = 1000
		target.max_hp = 1000
		target.defense = 0
		target.resistances = {"water": 0}
		var cards: Array = owner.cards.filter(func(card: Dictionary) -> bool: return card.power == "tidal_splash").duplicate(true)
		for card: Dictionary in cards: card.target_slot = 1
		var before: Array = [owner.duplicate(true), target.duplicate(true), cards.duplicate(true)]
		var potential: int = example.potential[revision - 5]
		var score: Dictionary = Planning.preview_selection([0, 1], cards, [owner], [target], "battle", 1, [], [], 3, revision)
		var reversed: Dictionary = Planning.preview_selection([1, 0], cards, [owner], [target], "battle", 1, [], [], 3, revision)
		expect.call(score.valid and score.actions == 2 and score.direct_damage == potential and score.damage == potential and score.bonuses.size() == (2 if revision == 6 else 0), "Two Lonelo copies show graph-specific potential of one-time modifiers: " + str(example.status))
		expect.call(score == reversed and before == [owner, target, cards], "Click order and repeated previews never change public state")
		if revision == 5: expect.call(JSON.parse_string(JSON.stringify(score)) == history.cases[case_index].preview, "Graph 5 preserves every historical score field from actual main")
		var queue: Array = Initiative.player_entries(cards, [owner], [], [])
		queue.sort_custom(Initiative.precedes)
		var result: Dictionary = Resolution.new([owner], [target], {}, {}, 1, revision).resolve(queue)
		expect.call(result.applied_damage == example.applied[revision - 5], "Unopposed resolution confirms each graph's unchanged applied mechanics")
		case_index += 1
