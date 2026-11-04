extends RefCounted
## Groups public effects of one technique, without merging repeated card copies.
const Content = preload("res://scripts/content.gd")

static func collect(events: Array, start: int) -> Dictionary:
	var first: Dictionary = events[start]
	var definition: Dictionary = Content.POWERS.get(str(first.get("power", "")), {})
	var single: bool = str(definition.get("scope", "single")) == "single" and first.get("actor_side", "ally") != "enemy"
	var targets: Dictionary = {}
	var grouped: Array = []
	var cursor: int = start
	while cursor < events.size():
		var event: Dictionary = events[cursor]
		if event.get("actor_uid", -1) != first.get("actor_uid", -1) or event.get("actor_side", "") != first.get("actor_side", "") or event.get("power", "") != first.get("power", ""): break
		if event.get("kind", "") in ["burn", "canceled", "swap"]: break
		if event.get("kind", "") == "attack":
			var key: String = "%s:%d" % [str(event.get("target_side", "")), int(event.get("target_uid", -1))]
			if not grouped.is_empty() and (single or targets.has(key)): break
			targets[key] = true
		grouped.append(event)
		cursor += 1
	return {"events": grouped, "next": cursor}

static func actor(event: Dictionary, context: Dictionary, target: bool = false) -> Control:
	var side: String = str(event.get("target_side" if target else "actor_side", "ally"))
	var slot: int = int(event.get("target_slot" if target else "actor_slot", -1))
	var uid: int = int(event.get("target_uid" if target else "actor_uid", -1))
	var list: Array = context.enemy_actors if side == "enemy" else context.actors
	if slot < 0 or slot >= list.size() or not is_instance_valid(list[slot]): return null
	var body: Control = list[slot]
	return body if not body.identity.is_empty() and int(body.identity.uid) == uid else null
