extends RefCounted
## Validated JSON boundary. No scene, I/O, RNG consumption or mutation of a live run.
const Models = preload("res://scripts/domain/models.gd")
const Combat = preload("res://scripts/domain/combat_records.gd")
const Inventory = preload("res://scripts/domain/inventory.gd")
const Catalog = preload("res://scripts/catalog/game_catalog.gd")
var errors: Array[String] = []

func integer(value: Variant, low: int = 0, high: int = 2147483647) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= low and value <= high

func string(value: Variant, maximum: int = 300) -> bool:
	return value is String and value.length() <= maximum

func individual(data: Variant, catalog: Catalog) -> Models.Individual:
	if not data is Dictionary or not integer(data.get("uid"), 1) or not string(data.get("species_id")) or not catalog.species.has(data.species_id) or not string(data.get("form_id")) or not string(data.get("passive")): return null
	var definition = catalog.species[data.species_id]
	if definition.form(data.form_id) == null or data.passive not in definition.passive_pool: return null
	return Models.Individual.new(data.species_id, data.passive, int(data.uid), data.form_id)

func cards(data: Variant, owners: Dictionary, catalog: Catalog, seen: Dictionary) -> Array[Models.CardInstance]:
	var result: Array[Models.CardInstance] = []
	if not data is Array:
		errors.append("Invalid cards")
		return result
	for entry in data:
		if not entry is Dictionary or not integer(entry.get("owner"), 1) or not owners.has(int(entry.owner)) or not string(entry.get("power")) or not string(entry.get("instance_id")):
			errors.append("Invalid card record")
			continue
		var shape = catalog.form(owners[int(entry.owner)])
		var parts: PackedStringArray = entry.instance_id.split(":")
		if shape.power(entry.power) == null or parts.size() != 3 or not parts[2].is_valid_int():
			errors.append("Unknown card power/copy")
			continue
		var copy: int = int(parts[2])
		var card = Models.CardInstance.new(entry.power, int(entry.owner), copy)
		if copy < 0 or copy >= shape.copies_per_power or card.instance_id != entry.instance_id or seen.has(card.instance_id): errors.append("Invalid/duplicate card identity")
		else:
			seen[card.instance_id] = true
			result.append(card)
	return result

func statuses(data: Variant, definitions: Dictionary) -> Array[Combat.StatusInstance]:
	var result: Array[Combat.StatusInstance] = []
	var seen: Dictionary = {}
	if not data is Array:
		errors.append("Invalid statuses")
		return result
	for entry in data:
		if not entry is Dictionary or not string(entry.get("status_id")) or not definitions.has(entry.status_id) or entry.get("target") not in ["player", "enemy"]:
			errors.append("Unknown status")
			continue
		var definition = definitions[entry.status_id]
		if not integer(entry.get("stacks"), 1, definition.max_stacks) or not integer(entry.get("remaining"), -1, 100000) or not integer(entry.get("source_uid"), -1) or not string(entry.get("source_id")) or not string(entry.get("source_instance_id")):
			errors.append("Invalid status record")
			continue
		var key: String = entry.target + ":" + entry.status_id
		if seen.has(key) or (definition.duration == -1 and entry.remaining != -1) or (definition.duration > 0 and (entry.remaining <= 0 or entry.remaining > definition.duration)):
			errors.append("Invalid status lifetime/identity")
			continue
		seen[key] = true
		var status = Combat.StatusInstance.new()
		status.definition = definition
		status.target = entry.target
		status.stacks = int(entry.stacks)
		status.remaining = int(entry.remaining)
		status.source_id = entry.source_id
		status.source_uid = int(entry.source_uid)
		status.source_instance_id = entry.source_instance_id
		result.append(status)
	return result

func inventory(data: Variant, catalog: Catalog, owners: Dictionary) -> Inventory:
	var result = Inventory.new()
	var definitions: Dictionary = {}
	for item in catalog.items: definitions[item.item_id] = item
	var seen: Dictionary = {}
	var equipped: Dictionary = {}
	if not data is Array:
		errors.append("Invalid inventory")
		return result
	for entry in data:
		if not entry is Dictionary or not integer(entry.get("instance_id"), 1) or not integer(entry.get("quantity"), 0, 100000) or not integer(entry.get("equipped_uid"), -1) or not string(entry.get("item_id")) or not definitions.has(entry.item_id):
			errors.append("Invalid item record")
			continue
		var definition = definitions[entry.item_id]
		var uid: int = int(entry.equipped_uid)
		if seen.has(entry.instance_id) or (uid != -1 and (not owners.has(uid) or equipped.has(uid) or definition.kind != "relic" or entry.quantity <= 0)):
			errors.append("Invalid equipment/instance")
			continue
		seen[entry.instance_id] = true
		if uid != -1: equipped[uid] = true
		var item = Inventory.ItemInstance.new()
		item.instance_id = int(entry.instance_id)
		item.definition = definition
		item.quantity = int(entry.quantity)
		item.equipped_uid = uid
		result.items.append(item)
	return result

func events(data: Variant, definitions: Dictionary) -> Array[Combat.Event]:
	var result: Array[Combat.Event] = []
	if not data is Array:
		errors.append("Invalid history")
		return result
	for entry in data:
		if not entry is Dictionary or entry.get("kind") not in ["action", "damage", "block", "heal", "status", "draw"] or entry.get("target") not in ["player", "enemy"] or entry.get("phase") not in ["cast", "after_traits", "link", "enemy_action", "after_cast", "after_retaliation"]:
			errors.append("Invalid event kind/phase")
			continue
		var valid: bool = entry.get("changed") is bool
		for field in ["source_id", "source_instance_id", "status_id", "action_id", "sound_id"]: valid = valid and string(entry.get(field))
		for field in ["requested", "blocked"]: valid = valid and integer(entry.get(field))
		valid = valid and integer(entry.get("source_uid"), -1) and integer(entry.get("applied"), -100000)
		if not valid or (not entry.status_id.is_empty() and not definitions.has(entry.status_id)):
			errors.append("Invalid event record")
			continue
		var request = Combat.Request.new(entry.kind, int(entry.requested), entry.target, entry.source_id, int(entry.source_uid), definitions.get(entry.status_id))
		request.source_instance_id = entry.source_instance_id
		request.action_id = entry.action_id
		request.sound_id = entry.sound_id
		var event = Combat.Event.new(request, int(entry.applied))
		event.phase = entry.phase
		event.blocked = int(entry.blocked)
		event.changed = entry.changed
		result.append(event)
	return result

func combat_state(data: Variant, definitions: Dictionary) -> Combat.State:
	if not data is Dictionary:
		errors.append("Invalid projected state")
		return null
	var state = Combat.State.new()
	for field in ["player_hp", "player_max", "enemy_hp", "enemy_max", "player_block", "enemy_block", "draw", "draw_capacity"]:
		if not integer(data.get(field)): errors.append("Invalid projected state amount")
		else: state.set(field, int(data[field]))
	if state.player_max <= 0 or state.enemy_max <= 0 or state.player_hp > state.player_max or state.enemy_hp > state.enemy_max: errors.append("Invalid projected state bounds")
	state.statuses = statuses(data.get("statuses"), definitions)
	return state
