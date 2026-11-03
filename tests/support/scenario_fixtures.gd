extends RefCounted
const Expedition = preload("res://scripts/expedition/expedition.gd")
const Rules = preload("res://scripts/rules.gd")
const Replay = preload("res://scripts/expedition/replay.gd")
const NAMES = ["battle", "wounded", "enemy_shield", "rewards", "rewards_many", "replacement", "inventory_full"]

static func make(name: String) -> Dictionary:
	if name not in NAMES: return {}
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
