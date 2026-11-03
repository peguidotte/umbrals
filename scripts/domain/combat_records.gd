extends RefCounted
const Status = preload("res://scripts/catalog/status_definition.gd")

class Request extends RefCounted:
	var phase: String = "cast"
	var operation: String
	var amount: int
	var target: String
	var source_instance_id: String = ""
	var source_id: String
	var source_uid: int
	var status: Resource
	var action_id: String = ""
	var sound_id: String = ""
	func _init(op: String, value: int, destination: String, source: String = "", uid: int = -1, condition: Resource = null) -> void:
		operation = op
		amount = value
		target = destination
		source_id = source
		source_uid = uid
		status = condition

class Event extends RefCounted:
	var phase: String = "cast"
	var kind: String
	var source_instance_id: String = ""
	var source_id: String
	var source_uid: int
	var target: String
	var blocked: int = 0
	var changed: bool = false
	var requested: int
	var applied: int
	var status_id: String = ""
	var action_id: String = ""
	var sound_id: String = ""
	func _init(request: Request, value: int) -> void:
		kind = request.operation
		source_id = request.source_id
		source_instance_id = request.source_instance_id
		source_uid = request.source_uid
		target = request.target
		requested = request.amount
		applied = value
		if request.status != null: status_id = request.status.status_id
		action_id = request.action_id
		sound_id = request.sound_id
	func to_dict() -> Dictionary:
		return {"phase": phase, "kind": kind, "source_id": source_id, "source_instance_id": source_instance_id, "source_uid": source_uid, "target": target, "requested": requested, "blocked": blocked, "changed": changed, "applied": applied, "status_id": status_id, "action_id": action_id, "sound_id": sound_id}

class StatusInstance extends RefCounted:
	var definition: Resource
	var target: String
	var stacks: int
	var remaining: int
	var source_instance_id: String = ""
	var source_id: String
	var source_uid: int
	func clone() -> StatusInstance:
		var copy = StatusInstance.new()
		copy.definition = definition
		copy.target = target
		copy.stacks = stacks
		copy.remaining = remaining
		copy.source_id = source_id
		copy.source_instance_id = source_instance_id
		copy.source_uid = source_uid
		return copy
	func to_dict() -> Dictionary:
		return {"status_id": definition.status_id, "target": target, "stacks": stacks, "remaining": remaining, "source_id": source_id, "source_instance_id": source_instance_id, "source_uid": source_uid}

class State extends RefCounted:
	var player_hp: int
	var player_max: int
	var enemy_hp: int
	var enemy_max: int
	var player_block: int = 0
	var enemy_block: int = 0
	var draw: int = 0
	var draw_capacity: int = 0
	var statuses: Array[StatusInstance] = []
	func clone() -> State:
		var copy = State.new()
		copy.player_hp = player_hp
		copy.player_max = player_max
		copy.enemy_hp = enemy_hp
		copy.enemy_max = enemy_max
		copy.enemy_block = enemy_block
		copy.player_block = player_block
		copy.draw_capacity = draw_capacity
		for status in statuses: copy.statuses.append(status.clone())
		return copy
	func to_dict() -> Dictionary:
		return {"player_hp": player_hp, "player_max": player_max, "enemy_hp": enemy_hp, "enemy_max": enemy_max, "player_block": player_block, "enemy_block": enemy_block, "draw": draw, "draw_capacity": draw_capacity, "statuses": statuses.map(func(entry: StatusInstance): return entry.to_dict())}
	func stacks(id: String, target: String = "enemy") -> int:
		for status in statuses:
			if status.target == target and status.definition.status_id == id: return status.stacks
		return 0

class Outcome extends RefCounted:
	var phase: String = "cast"
	var state: State
	var events: Array[Event] = []
	func total(kind: String, target: String) -> int:
		var amount: int = 0
		for event in events:
			if event.kind == kind and event.target == target: amount += event.applied
		return amount
