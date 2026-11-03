extends RefCounted
## Command log interpreter; no I/O and no browser mutation API.
const Rules = preload("res://scripts/rules.gd")

static func apply(game: Rules, command: Dictionary) -> bool:
	var kind: Variant = command.get("command")
	match kind:
		"new_run":
			if not command.get("seed") is String or not command.seed.is_valid_int(): return false
			game.new_run(int(command.seed))
			return true
		"select": return _integer(command.get("index")) and game.toggle(int(command.index))
		"cast": return game.play().ok
		"redraw": return game.redraw()
		"reward": return _integer(command.get("index")) and _integer(command.get("replace_uid", -1)) and game.choose_reward(int(command.index), int(command.get("replace_uid", -1)))
		"equip": return _integer(command.get("id")) and _integer(command.get("uid")) and game.equip_item(int(command.id), int(command.uid))
		"use_item": return _integer(command.get("id")) and game.use_item(int(command.id)) != null
	return false

static func run(game: Rules, commands: Array) -> Dictionary:
	for index in range(commands.size()):
		if not commands[index] is Dictionary or not apply(game, commands[index]): return {"ok": false, "failed_index": index, "state": game.export_state()}
	return {"ok": true, "commands": commands.size(), "state": game.export_state()}

static func _integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= -1 and value <= 2147483647
