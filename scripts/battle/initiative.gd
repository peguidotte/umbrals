extends RefCounted
## One queue vocabulary for player planning and committed resolution.
const Content = preload("res://scripts/content.gd")

static func by_uid(roster: Array, uid: int) -> Dictionary:
	for individual in roster:
		if int(individual.uid) == uid: return individual
	return {}

static func player_entries(cards: Array, party: Array, swaps: Array, items: Array) -> Array:
	var entries: Array = []
	for card in cards:
		var owner: Dictionary = by_uid(party, int(card.owner))
		if owner.is_empty() or not Content.POWERS.has(card.power): continue
		var stats: Dictionary = Content.power_stats(str(card.power), int(owner.stage))
		entries.append({"kind": "power", "side": "ally", "actor_uid": int(owner.uid), "actor_slot": int(owner.slot), "card": card.duplicate(true), "priority": int(stats.get("priority", 0)), "speed": int(owner.speed), "execution_order": int(stats.get("order", 0)), "key": "ally:power:" + str(card.instance_id)})
	for swap in swaps:
		var outgoing: Dictionary = by_uid(party, int(swap.out_uid))
		entries.append({"kind": "swap", "side": "ally", "actor_uid": int(swap.out_uid), "actor_slot": int(swap.slot), "swap": swap.duplicate(true), "priority": 100, "speed": int(outgoing.get("speed", 0)), "key": "ally:swap:%d" % int(swap.slot)})
	for item_index in range(items.size()):
		var item: Dictionary = items[item_index]
		entries.append({"kind": "item", "side": "ally", "actor_uid": -1, "actor_slot": -1, "order": item.duplicate(true), "item_index": item_index, "priority": 90, "speed": 0, "key": "ally:item:%s:%d" % [item.item, int(item.uid)]})
	return entries

static func precedes(a: Dictionary, b: Dictionary) -> bool:
	if int(a.priority) != int(b.priority): return int(a.priority) > int(b.priority)
	if int(a.speed) != int(b.speed): return int(a.speed) > int(b.speed)
	if int(a.get("tie", 0)) != int(b.get("tie", 0)): return int(a.get("tie", 0)) < int(b.get("tie", 0))
	if int(a.get("execution_order", 0)) != int(b.get("execution_order", 0)): return int(a.get("execution_order", 0)) < int(b.get("execution_order", 0))
	return str(a.key) < str(b.key)

static func commit(player: Array, enemy_plan: Array, enemies: Array, rng: RandomNumberGenerator) -> Array:
	var queue: Array = player.duplicate(true)
	for planned in enemy_plan:
		var opponent: Dictionary = by_uid(enemies, int(planned.actor_uid))
		queue.append({"kind": "enemy", "side": "enemy", "actor_uid": int(planned.actor_uid), "actor_slot": int(planned.actor_slot), "intent": planned.duplicate(true), "priority": int(planned.get("priority", 0)), "speed": int(opponent.get("speed", 0)), "key": "enemy:%d" % int(planned.actor_uid)})
	# Canonical keys keep seeded ties independent of selection/click order.
	queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.key) < str(b.key))
	var owner_ties: Dictionary = {}
	for entry in queue:
		var owner_key: String = "%s:%d" % [entry.side, int(entry.actor_uid)]
		if not owner_ties.has(owner_key): owner_ties[owner_key] = rng.randi()
		entry.tie = owner_ties[owner_key]
	queue.sort_custom(precedes)
	return queue
