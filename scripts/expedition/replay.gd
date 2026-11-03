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

const Identity = preload("res://scripts/expedition/identity.gd")
const Registry = preload("res://scripts/expedition/migration_registry.gd")
const Migration = preload("res://scripts/expedition/migration.gd")
const SCHEMA = "umbral.expedition.replay"
const VERSION = 2

static func envelope(initial_state: Dictionary, commands: Array) -> Dictionary:
	return {"schema": SCHEMA, "version": VERSION, "identity": Identity.current(), "initial_state": initial_state.duplicate(true), "commands": commands.duplicate(true)}

## Unversioned recordings are schema 1 and may only carry schema 1 checkpoints.
static func decode(data: Variant) -> Dictionary:
	if not data is Dictionary or not data.get("initial_state") is Dictionary or not data.get("commands") is Array: return {}
	if data.has("schema") or data.has("version") or data.has("identity"):
		if data.get("schema") != SCHEMA or data.get("version") != VERSION or not Registry.supports(data.get("identity")): return {}
		if data.initial_state.get("schema") != 2 or data.initial_state.get("identity") != data.get("identity"): return {}
	else:
		if data.initial_state.get("schema") != 1: return {}
	var checkpoint: Dictionary = Migration.checkpoint(data.initial_state)
	if checkpoint.is_empty(): return {}
	var expedition_script = load("res://scripts/expedition/expedition.gd")
	var candidate = expedition_script.new()
	if not candidate.restore(checkpoint): return {}
	return envelope(checkpoint, data.commands)
