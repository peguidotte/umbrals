extends RefCounted
## One pure executor for powers, enemy actions, statuses and consumables.
## Cast requests -> after_cast statuses -> retaliation -> after_retaliation statuses.
const Combat = preload("res://scripts/domain/combat_records.gd")

static func resolve(initial: Combat.State, cast: Array[Combat.Request], retaliation: Array[Combat.Request] = [], advance: bool = true) -> Combat.Outcome:
	var outcome = Combat.Outcome.new()
	outcome.state = initial.clone()
	for request in cast: apply(outcome, request)
	if advance:
		tick(outcome, "after_cast")
		# Previous enemy shield expires after this cast; its action may renew it.
		outcome.state.enemy_block = 0
		outcome.phase = "enemy_action"
		if outcome.state.enemy_hp > 0:
			for request in retaliation: apply(outcome, request)
		tick(outcome, "after_retaliation")
	return outcome

static func apply(outcome: Combat.Outcome, request: Combat.Request) -> void:
	var state: Combat.State = outcome.state
	var applied: int = 0
	var blocked: int = 0
	var status_changed: bool = false
	var value: int = maxi(0, request.amount)
	var player: bool = request.target == "player"
	match request.operation:
		"damage":
			var shield: int = state.player_block if player else state.enemy_block
			var absorbed: int = mini(shield, value)
			blocked = absorbed
			if player: state.player_block -= absorbed
			else: state.enemy_block -= absorbed
			applied = mini(state.player_hp if player else state.enemy_hp, value - absorbed)
			if player: state.player_hp -= applied
			else: state.enemy_hp -= applied
		"heal":
			applied = mini((state.player_max - state.player_hp) if player else (state.enemy_max - state.enemy_hp), value)
			if player: state.player_hp += applied
			else: state.enemy_hp += applied
		"block":
			applied = value
			if player: state.player_block += value
			else: state.enemy_block += value
		"draw":
			if player:
				applied = mini(value, maxi(0, state.draw_capacity - state.draw))
				state.draw += applied
		"status":
			var before: Array = state.statuses.map(func(entry: Combat.StatusInstance): return entry.to_dict())
			applied = add_status(state, request)
			status_changed = before != state.statuses.map(func(entry: Combat.StatusInstance): return entry.to_dict())
		"action": pass
	var event = Combat.Event.new(request, applied)
	event.phase = request.phase if outcome.phase == "cast" else outcome.phase
	event.blocked = blocked
	event.changed = applied != 0 or status_changed
	outcome.events.append(event)

static func add_status(state: Combat.State, request: Combat.Request) -> int:
	if request.status == null or request.amount <= 0: return 0
	var found: Combat.StatusInstance
	for entry in state.statuses:
		if entry.target == request.target and entry.definition.status_id == request.status.status_id: found = entry
	if found == null:
		found = Combat.StatusInstance.new()
		found.definition = request.status
		found.target = request.target
		state.statuses.append(found)
	var before: int = found.stacks
	match request.status.stacking:
		"add": found.stacks += request.amount
		"max": found.stacks = maxi(found.stacks, request.amount)
		"replace": found.stacks = request.amount
	found.stacks = mini(found.stacks, request.status.max_stacks)
	found.remaining = request.status.duration
	found.source_id = request.source_id
	found.source_instance_id = request.source_instance_id
	found.source_uid = request.source_uid
	return found.stacks - before

static func tick(outcome: Combat.Outcome, timing: String) -> void:
	outcome.phase = timing
	for entry in outcome.state.statuses.duplicate():
		var definition = entry.definition
		if definition.timing != timing: continue
		var request = Combat.Request.new(definition.tick_operation, entry.stacks * definition.per_stack, entry.target, entry.source_id, entry.source_uid, definition)
		request.source_instance_id = entry.source_instance_id
		apply(outcome, request)
		entry.stacks = maxi(0, entry.stacks - definition.decay)
		if entry.remaining > 0: entry.remaining -= 1
		if entry.stacks == 0 or entry.remaining == 0: outcome.state.statuses.erase(entry)
