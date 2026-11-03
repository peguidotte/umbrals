extends RefCounted
const Item = preload("res://scripts/catalog/item_definition.gd")
const Combat = preload("res://scripts/domain/combat_records.gd")
const Resolver = preload("res://scripts/domain/effect_resolver.gd")

class ItemInstance extends RefCounted:
	var instance_id: int
	var definition: Resource
	var quantity: int
	var equipped_uid: int = -1
	func to_dict() -> Dictionary:
		return {"instance_id": instance_id, "item_id": definition.item_id, "quantity": quantity, "equipped_uid": equipped_uid}

var items: Array[ItemInstance] = []

func reset(definitions: Array[Item]) -> void:
	items.clear()
	for definition in definitions:
		var item = ItemInstance.new()
		item.instance_id = items.size() + 1
		item.definition = definition
		item.quantity = definition.starting_quantity
		items.append(item)

func find(id: int) -> ItemInstance:
	for item in items:
		if item.instance_id == id: return item
	return null

func preview_use(id: int, state: Combat.State) -> Combat.Outcome:
	var item: ItemInstance = find(id)
	if item == null or item.definition.kind != "consumable" or item.quantity <= 0: return null
	var requests: Array[Combat.Request] = []
	for effect in item.definition.effects:
		var wounded: bool = state.player_hp < state.player_max if effect.target == "player" else state.enemy_hp < state.enemy_max
		if effect.enabled(state.stacks("burn", effect.target) > 0, wounded):
			var request = Combat.Request.new(effect.operation, effect.amount, effect.target, item.definition.item_id, item.equipped_uid, effect.status)
			request.source_instance_id = "item:%d" % item.instance_id
			requests.append(request)
	var outcome: Combat.Outcome = Resolver.resolve(state, requests, [], false)
	for event in outcome.events:
		if event.changed: return outcome
	return null

func consume(id: int, state: Combat.State) -> Combat.Outcome:
	var outcome: Combat.Outcome = preview_use(id, state)
	if outcome != null: find(id).quantity -= 1
	return outcome

func equip(id: int, uid: int, party_uids: Array[int]) -> bool:
	var item: ItemInstance = find(id)
	if item == null or item.quantity <= 0 or item.definition.kind != "relic" or (uid != -1 and uid not in party_uids): return false
	# One relic per individual; transferring is explicit and never copies the item.
	for other in items:
		if uid != -1 and other != item and other.equipped_uid == uid: return false
	item.equipped_uid = uid
	return true

func detach_missing(party_uids: Array[int]) -> void:
	for item in items:
		if item.equipped_uid not in party_uids: item.equipped_uid = -1

func modify(requests: Array[Combat.Request]) -> void:
	# No event bus: one named phase and additive operations, once per equipped UID.
	var additions: Array[Combat.Request] = []
	for item in items:
		if item.definition.kind != "relic" or item.quantity <= 0 or item.equipped_uid < 0: continue
		for modifier in item.definition.modifiers:
			var triggered: bool = false
			for request in requests:
				if request.source_uid == item.equipped_uid and request.operation == modifier.requires_operation and request.amount > 0: triggered = true
			if triggered:
				var addition = Combat.Request.new(modifier.operation, modifier.amount, "enemy" if modifier.operation == "damage" else "player", item.definition.item_id, item.equipped_uid)
				addition.source_instance_id = "item:%d" % item.instance_id
				addition.phase = modifier.phase
				additions.append(addition)
	var insert_at: int = requests.size()
	for index in range(requests.size()):
		if requests[index].phase == "link":
			insert_at = index
			break
	for addition in additions:
		requests.insert(insert_at, addition)
		insert_at += 1
