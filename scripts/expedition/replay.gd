extends RefCounted
## Whitelisted development replay over the current expedition and battle APIs.
static func apply(run: RefCounted, command: Dictionary) -> bool:
	var kind: Variant = command.get("command")
	var game: RefCounted = run.battle
	match kind:
		"select": return integer(command.get("index")) and game.toggle(int(command.index))
		"target": return integer(command.get("index")) and integer(command.get("slot")) and game.set_target(int(command.index), int(command.slot))
		"cast":
			if not game.play().get("ok", false): return false
			run.settle_battle()
			return true
		"redraw":
			if not game.redraw(): return false
			run.settle_battle()
			return true
		"item": return command.get("item") is String and integer(command.get("uid")) and game.queue_item(command.item, int(command.uid))
		"reward": return integer(command.get("index")) and integer(command.get("replace_uid", -1)) and integer(command.get("slot", -2)) and run.choose_reward(int(command.index), int(command.get("replace_uid", -1)), int(command.get("slot", -2)))
		"node": return command.get("id") is String and run.choose_node(command.id)
	return false

static func execute(run: RefCounted, commands: Array) -> Dictionary:
	for index in range(commands.size()):
		if not commands[index] is Dictionary or not apply(run, commands[index]): return {"ok": false, "failed_index": index, "snapshot": run.snapshot()}
	return {"ok": true, "commands": commands.size(), "snapshot": run.snapshot()}

static func integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= -2 and value <= 2147483647
