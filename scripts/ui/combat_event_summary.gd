extends RefCounted
## Presentation groups committed events without recalculating any combat rule.
const Combat = preload("res://scripts/domain/combat_records.gd")
var damage: int = 0
var healing: int = 0
var incoming: int = 0
var burn: int = 0
var actions: Dictionary[int, Combat.Event] = {}

func _init(events: Array[Combat.Event]) -> void:
	var priority: Dictionary = {"heal": 0, "defend": 1, "attack_melee": 2, "attack_ranged": 3}
	for event in events:
		if event.kind == "damage":
			if event.target == "enemy":
				damage += event.applied
				if event.status_id == "burn": burn += event.applied
			else: incoming += event.applied
		elif event.kind == "heal" and event.target == "player": healing += event.applied
		elif event.kind == "action" and event.source_uid >= 0:
			if not actions.has(event.source_uid) or priority[event.action_id] > priority[actions[event.source_uid].action_id]: actions[event.source_uid] = event
