extends RefCounted
## Deterministic initial conditions, compiled only into the isolated fixture project.
const Content = preload("res://scripts/content.gd")
const Rules = preload("res://scripts/rules.gd")
const Planner = preload("res://scripts/domain/selection_planner.gd")
const Replay = preload("res://scripts/session/run_replay.gd")
const Evolution = preload("res://scripts/catalog/evolution_definition.gd")
const Inventory = preload("res://scripts/domain/inventory.gd")
const NAMES = ["battle", "wounded", "enemy_shield", "rewards", "branching_rewards", "replacement", "inventory_full"]

static func catalog_for(name: String) -> Content.Catalog:
	var catalog = Content.create_catalog()
	if name == "branching_rewards":
		var species = catalog.species.ember
		var branch = species.forms[1].duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
		branch.form_id = "fixture_branch"
		branch.display_name = "Outra evolução"
		branch.evolutions.clear()
		species.forms.append(branch)
		var edge = Evolution.new()
		edge.transition_id = "fixture_branch"
		edge.target_form_id = branch.form_id
		species.forms[0].evolutions.append(edge)
	return catalog

static func make(name: String) -> Dictionary:
	if name not in NAMES: return {}
	var game = Rules.new(catalog_for(name))
	game.new_run(42013)
	if name in ["wounded", "inventory_full"]: game.player_hp = 32
	if name == "enemy_shield":
		game.enemy_hp = 1
		game.enemy_block = 50
	if name == "inventory_full":
		for i in range(8):
			var item = Inventory.ItemInstance.new()
			item.instance_id = game.inventory.items.size() + 1
			item.definition = game.catalog.items[i % game.catalog.items.size()]
			item.quantity = 2
			game.inventory.items.append(item)
	var initial: Dictionary = game.export_state()
	var commands: Array = []
	if name in ["rewards", "branching_rewards", "replacement"]:
		if not _until_reward(game, commands): return {}
		if name == "replacement":
			var reward: Dictionary = {"command": "reward", "index": 0}
			if not Replay.apply(game, reward): return {}
			commands.append(reward)
			var equip: Dictionary = {"command": "equip", "id": 2, "uid": 2}
			if not Replay.apply(game, equip): return {}
			commands.append(equip)
			if not _until_reward(game, commands): return {}
	return {"schema_version": 1, "name": name, "initial_state": initial, "commands": commands, "snapshot": game.export_state()}

static func _until_reward(game: Rules, commands: Array) -> bool:
	var steps: int = 0
	while game.phase == "battle" and steps < 7:
		for index in Planner.choose(game.hand, game.project, game.intent_damage()):
			var command: Dictionary = {"command": "select", "index": index}
			if not Replay.apply(game, command): return false
			commands.append(command)
		var cast: Dictionary = {"command": "cast"}
		if not Replay.apply(game, cast): return false
		commands.append(cast)
		steps += 1
	return game.phase == "reward"
