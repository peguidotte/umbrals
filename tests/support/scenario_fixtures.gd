extends RefCounted
const Expedition = preload("res://scripts/expedition/expedition.gd")
const Rules = preload("res://scripts/rules.gd")
const Replay = preload("res://scripts/expedition/replay.gd")
const NAMES = ["spring_room", "battle", "wounded", "enemy_shield", "rewards", "rewards_many", "replacement", "inventory_full", "motion_ember", "motion_ignivar", "motion_moss", "motion_verdalio", "motion_dew", "motion_mareveu", "motion_volt", "motion_tempestral"]

static func make(name: String) -> Dictionary:
	if name not in NAMES: return {}
	if name == "spring_room": return _spring()
	if name.begins_with("motion_"): return _motion(name)
	var run = Expedition.new()
	run.new_run(42013, "full", "ember")
	var game: RefCounted = run.battle
	var count: int = 6 if name in ["replacement", "inventory_full"] else 3 if name == "rewards_many" else 1
	for uid in range(2, count + 1):
		var species: String = ["ember", "moss", "volt", "dew"][(uid - 1) % 4]
		var unit: Dictionary = Rules.make_umbral(species, "vital", uid)
		unit.slot = uid - 2 if uid <= 3 else -1
		game.party.append(unit)
	game.next_uid = count + 1
	if count > 1: game.party[0].slot = 2
	if not run.choose_node("clearing"): return {}
	if name in ["wounded", "inventory_full"]:
		for unit in game.party: unit.hp = int(unit.max_hp) - 12
		game.inventory.potion = 20
	if name == "enemy_shield": game.enemies[0].block = 50
	if name in ["rewards", "rewards_many", "replacement"]: game.enemies[0].hp = 1
	game._sync_compatibility()
	var initial: Dictionary = run.snapshot()
	var commands: Array = []
	if name in ["rewards", "rewards_many", "replacement"]:
		for index in game.best_selection(): commands.append({"command": "select", "index": index})
		commands.append({"command": "cast"})
		if not Replay.execute(run, commands).ok or run.phase != "reward": return {}
	var result: Dictionary = Replay.envelope(initial, commands)
	result.merge({"name": name, "snapshot": run.snapshot()})
	return result

static func _motion(name: String) -> Dictionary:
	# Test-only, validated checkpoints. Receivers have endurance so all three
	# presentations can be observed through real owned cards and normal commits.
	var cases: Dictionary = {"ember": ["ember", "ember", 1], "ignivar": ["ember", "ignivar", 1], "moss": ["moss", "moss", 2], "verdalio": ["moss", "verdalio", 0], "dew": ["dew", "dew", 1], "mareveu": ["dew", "mareveu", 2], "volt": ["volt", "volt", 0], "tempestral": ["volt", "tempestral", 1]}
	var definition: Array = cases[name.trim_prefix("motion_")]
	var run = Expedition.new()
	run.new_run(42013, "full", str(definition[0]))
	var game: RefCounted = run.battle
	game.party[0] = Rules.make_umbral(str(definition[0]), "vital", 1, str(definition[1]))
	game.party[0].slot = int(definition[2])
	if not run.choose_node("clearing"): return {}
	game.enemies.clear()
	var receivers: Array = [["moss", "verdalio"], ["dew", "mareveu"], ["volt", "tempestral"]]
	for slot in range(3):
		var body: Dictionary = Rules.make_umbral(str(receivers[slot][0]), "", 9000 + slot, str(receivers[slot][1]))
		body.slot = slot
		body.max_hp = 250
		body.hp = 250
		body.pattern = [{"category": "defend", "damage": 0, "block": 1, "heal": 0, "scope": "single", "priority": 1, "nature": "forest", "conditions": {}}]
		game.enemies.append(body)
	game._commit_enemy_plan()
	game._sync_compatibility()
	var snapshot: Dictionary = run.snapshot()
	var result: Dictionary = Replay.envelope(snapshot, [])
	result.merge({"name": name, "snapshot": snapshot})
	return result

static func _spring() -> Dictionary:
	var base: Dictionary = make("rewards_many")
	var initial: Dictionary = base.initial_state.duplicate(true)
	for unit in initial.battle.party: unit.hp = int(unit.max_hp) - 12
	var run = Expedition.new()
	if not run.restore(initial): return {}
	var commands: Array = base.commands.duplicate(true)
	commands.append({"command": "reward", "index": 1})
	commands.append({"command": "node", "id": "spring"})
	if not Replay.execute(run, commands).ok or run.phase != "event": return {}
	var result: Dictionary = Replay.envelope(initial, commands)
	result.merge({"name": "spring_room", "snapshot": run.snapshot()})
	return result
