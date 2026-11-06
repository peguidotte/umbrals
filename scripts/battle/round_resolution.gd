extends RefCounted
## Resolves one committed round against explicitly supplied battle data.
const BattleCommand = preload("res://scripts/domain/models/battle_command.gd")
const ItemEffects = preload("res://scripts/battle/item_effects/registry.gd")
const BattleEvent = preload("res://scripts/domain/models/battle_event.gd")
const Companion = preload("res://scripts/battle/aquatic_companion.gd")
const Content = preload("res://scripts/content.gd")
const Traits = preload("res://scripts/battle/traits.gd")
const Targeting = preload("res://scripts/battle/targeting.gd")
const Conditions = preload("res://scripts/battle/conditions.gd")
const Reactions = preload("res://scripts/battle/reactions.gd")
const PowerEvaluation = preload("res://scripts/battle/power_evaluation.gd")

var party: Array
var enemies: Array
var inventory: Dictionary
var declined_replacements: Dictionary
var round_number: int
var catalog_revision: int

func _init(allies: Array, opponents: Array, items: Dictionary, declined: Dictionary, current_round: int, revision: int = 0) -> void:
	party = allies
	enemies = opponents
	inventory = items
	declined_replacements = declined
	round_number = current_round
	catalog_revision = revision

func _by_uid(roster: Array, uid: int) -> Dictionary:
	for individual in roster:
		if int(individual.uid) == uid: return individual
	return {}

func _party_by_uid(uid: int) -> Dictionary:
	return _by_uid(party, uid)

func _at_slot(roster: Array, slot: int) -> Dictionary:
	return Targeting.at_slot(roster, slot)

func _active_count() -> int:
	var count: int = 0
	for individual in party:
		if int(individual.get("slot", -1)) >= 0 and int(individual.get("hp", 0)) > 0: count += 1
	return count

func resolve(queue: Array) -> Dictionary:
	var events: Array = []
	var moss_used: Dictionary = {}
	var applied_damage: int = 0
	for queued_entry in queue:
		var parsed: Dictionary = BattleCommand.try_from_dict(queued_entry)
		assert(parsed.ok, "Invalid committed battle command")
		var command = parsed.value
		var entry: Dictionary = command.to_dict()
		if command.kind == "swap":
			_resolve_swap(entry, events)
		elif command.kind == "item":
			_resolve_item(entry, events)
		else:
			var roster: Array = party if command.side == "ally" else enemies
			var owner: Dictionary = _by_uid(roster, command.actor_uid)
			if owner.is_empty() or int(owner.hp) <= 0 or int(owner.slot) < 0 or int(owner.get("can_act_round", 1)) > round_number:
				events.append(_event("canceled", entry, owner, "ally" if entry.side == "enemy" else "enemy", {}, "", 0))
				events.back().reason = "dono ausente" if owner.is_empty() else "incapacitado" if int(owner.hp) <= 0 else "na reserva" if int(owner.slot) < 0 else "age na próxima rodada"
				continue
			applied_damage += _resolve_power(entry, owner, events, moss_used)
	_tick_statuses(events)
	for event in events:
		if event.kind == "burn" and event.target_side == "enemy": applied_damage += int(event.amount)
	return {"events": events, "applied_damage": applied_damage}

func _event(kind: String, entry: Dictionary, owner: Dictionary, target_side: String, target: Dictionary, power: String, amount: int) -> Dictionary:
	var snapshot: Dictionary = {}
	for key in ["uid", "species", "name", "art", "form_id", "passive", "hp", "max_hp", "attack", "defense", "speed", "block", "statuses", "status_sources", "resistances", "slot", "can_act_round"]:
		if target.has(key): snapshot[key] = target[key].duplicate(true) if target[key] is Dictionary else target[key]
	var event: Dictionary = {"kind": kind, "actor_uid": int(owner.get("uid", entry.get("actor_uid", -1))), "actor_side": str(entry.get("side", "ally")), "actor_slot": int(owner.get("slot", entry.get("actor_slot", -1))), "target_uid": int(target.get("uid", -1)), "target_side": target_side, "target_slot": int(target.get("slot", -1)), "power": power, "amount": amount, "target_state": snapshot}
	event.actor_name = str(owner.name) if owner.has("name") else Content.display_name(owner) if owner.has("species") else "Umbral"
	event.target_name = str(target.name) if target.has("name") else Content.display_name(target) if target.has("species") else "Umbral"
	var parsed: Dictionary = BattleEvent.try_from_dict(event)
	assert(parsed.ok, "Invalid battle event")
	return parsed.value.to_dict()

func _resolve_swap(entry: Dictionary, events: Array) -> void:
	var swap: Dictionary = entry.swap
	var incoming: Dictionary = _party_by_uid(int(swap.in_uid))
	var outgoing: Dictionary = _party_by_uid(int(swap.out_uid))
	if incoming.is_empty() or int(incoming.hp) <= 0 or int(incoming.slot) >= 0: return
	if not outgoing.is_empty():
		if int(outgoing.slot) != int(swap.slot): return
		if int(outgoing.hp) <= 0 and not declined_replacements.has(int(outgoing.uid)): return
		outgoing.slot = -1
	incoming.slot = int(swap.slot)
	incoming.can_act_round = round_number + 1
	var event: Dictionary = _event("swap", entry, incoming, "ally", incoming, "", 0)
	event.out_uid = int(swap.out_uid)
	events.append(event)

func _resolve_item(entry: Dictionary, events: Array) -> void:
	var order: Dictionary = entry.order
	var target: Dictionary = _party_by_uid(int(order.uid))
	if target.is_empty() or int(inventory.get(order.item, 0)) <= 0: return
	var definition: Dictionary = Content.CONSUMABLES[order.item]
	var result: Dictionary = ItemEffects.resolve(Content.item_effect(str(order.item)), target, definition)
	if not result.valid: return
	target.hp = int(result.new_hp)
	if bool(result.revived):
		declined_replacements.erase(int(target.uid))
		target.can_act_round = round_number + 1
		target.statuses = {}
		target.status_sources = {}
	events.append(_event(str(result.event_kind), entry, {}, "ally", target, str(result.event_power), int(result.amount)))
	inventory[order.item] = int(inventory[order.item]) - 1

func _scope_slots(scope: String, target_slot: int) -> Array:
	return Targeting.slots(scope, target_slot)

func _resolve_power(entry: Dictionary, owner: Dictionary, events: Array, moss_used: Dictionary) -> int:
	var stats: Dictionary
	var power: String
	if entry.kind == "enemy":
		stats = entry.intent.duplicate(true)
		if int(stats.get("damage", 0)) > 0:
			stats.damage = maxi(0, int(stats.damage) + int(owner.get("attack", 10)) - 10) + int(owner.statuses.get("charge", 0))
		stats.attack_multiplier = Conditions.attack_multiplier(owner)
		power = str(stats.power)
		stats.target = "self" if str(stats.category) in ["defend", "prepare"] else "enemy"
		if str(stats.category) == "prepare":
			Conditions.apply(owner, "charge", int(stats.get("charge", 0)), {"uid": int(owner.uid), "side": entry.side})
			events.append(_event("prepare", entry, owner, str(entry.side), owner, power, int(stats.get("charge", 0))))
		# Old custom enemy patterns remain readable; authored techniques use conditions.
		if not stats.has("conditions"): stats.conditions = {}
		for id in ["burn", "wet"]:
			if int(stats.get(id, 0)) > 0: stats.conditions[id] = int(stats[id])
	else:
		power = str(entry.card.power)
		stats = PowerEvaluation.power_effect(entry.card, owner, _active_count(), not moss_used.has(int(owner.uid)))
		stats.target_slot = int(entry.card.get("target_slot", owner.slot))
		if Traits.once_per_round(owner) and int(stats.block) > 0: moss_used[int(owner.uid)] = true
	var offensive: bool = int(stats.get("damage", 0)) > 0
	if offensive:
		# Spend once per technique, before iterating area targets. Support keeps both.
		for id in ["charge", "electrified"]:
			if int(owner.statuses.get(id, 0)) > 0:
				Conditions.consume(owner, id)
				var spent: Dictionary = _event("condition_spent", entry, owner, str(entry.side), owner, power, 0)
				spent.condition = id
				events.append(spent)
	var hostile: bool = str(stats.get("target", "enemy")) == "enemy"
	var target_side: String = ("enemy" if entry.side == "ally" else "ally") if hostile else str(entry.side)
	var targets: Array = enemies if target_side == "enemy" else party
	var target_slot: int = int(stats.get("target_slot", owner.slot))
	if str(stats.get("target", "enemy")) == "self": target_slot = int(owner.slot)
	var scope: String = str(stats.get("scope", "single"))
	if hostile and scope == "single":
		for individual in targets:
			if int(individual.get("slot", -1)) >= 0 and int(individual.hp) > 0 and int(individual.statuses.get("taunt", 0)) > 0:
				target_slot = int(individual.slot)
				break
	var applied_damage: int = 0
	for slot in _scope_slots(scope, target_slot):
		var target: Dictionary = _at_slot(targets, int(slot))
		if target.is_empty() or int(target.hp) <= 0: continue
		var reaction: Dictionary = Reactions.choose(stats, target)
		var seed_before: bool = int(target.statuses.get("seed", 0)) > 0
		var beneficiary: Dictionary = target.get("status_sources", {}).get("seed", {}).duplicate(true)
		if not reaction.is_empty() and bool(reaction.consume): Conditions.consume(target, str(reaction.condition))
		if offensive:
			var raw: float = float(stats.damage) * float(stats.get("attack_multiplier", 1.0)) * float(reaction.get("multiplier", 1.0))
			var resistance: int = clampi(int(Content.resistances(target).get(str(stats.get("nature", "")), 0)), 0, 100)
			raw *= 1.0 - float(resistance) / 100.0
			var damage: int = maxi(0, floori(raw) - int(target.defense))
			var absorbed: int = mini(int(target.block), damage)
			target.block -= absorbed
			damage = mini(int(target.hp), damage - absorbed)
			target.hp -= damage
			var hit: Dictionary = _event("attack", entry, owner, target_side, target, power, damage)
			hit.blocked = absorbed
			hit.amplified = reaction.get("id", "") == "conduction"
			hit.nature = str(stats.get("nature", ""))
			hit.resistance = resistance
			hit.weakened = float(stats.get("attack_multiplier", 1.0)) < 1.0
			events.append(hit)
			if target_side == "enemy": applied_damage += damage
		if not reaction.is_empty(): _apply_reaction(reaction, beneficiary, entry, owner, target_side, target, power, events, moss_used)
		if int(target.hp) <= 0:
			events.append(_event("ko", entry, owner, target_side, target, power, 0))
			continue
		for id in stats.get("conditions", {}):
			# A preexisting seed is used or refreshed, never replanted by this same hit.
			if id in ["taunt", "charge"] or (id == "seed" and seed_before): continue
			Conditions.apply(target, id, int(stats.conditions[id]), {"uid": int(owner.uid), "side": entry.side})
			var applied: Dictionary = _event("wet" if id == "wet" else "condition", entry, owner, target_side, target, power, int(stats.conditions[id]))
			applied.condition = id
			events.append(applied)
		if Companion.available(owner, stats, catalog_revision):
			var followup: Dictionary = Companion.strike(target, float(stats.get("attack_multiplier", 1.0)))
			var companion_event: Dictionary = _event("attack", entry, owner, target_side, target, power, int(followup.amount))
			companion_event.merge(followup, true)
			events.append(companion_event)
			if target_side == "enemy": applied_damage += int(followup.amount)
			if int(target.hp) <= 0: events.append(_event("ko", entry, owner, target_side, target, power, 0))
		if not hostile: _apply_support(stats, entry, owner, target_side, target, power, events)
	if hostile and (int(stats.get("block", 0)) > 0 or int(stats.get("heal", 0)) > 0 or int(stats.get("taunt", 0)) > 0):
		_apply_support(stats, entry, owner, str(entry.side), owner, power, events)
	return applied_damage

func _apply_reaction(reaction: Dictionary, source: Dictionary, entry: Dictionary, owner: Dictionary, side: String, target: Dictionary, power: String, events: Array, moss_used: Dictionary) -> void:
	if int(target.hp) > 0 and int(reaction.get("burn", 0)) > 0:
		Conditions.apply(target, "burn", int(reaction.burn), {"uid": int(owner.uid), "side": entry.side})
	var event: Dictionary = _event("reaction", entry, owner, side, target, power, 0)
	event.reaction = str(reaction.id)
	event.label = str(reaction.name)
	event.condition = str(reaction.condition)
	events.append(event)
	if source.is_empty() or (int(reaction.get("block", 0)) <= 0 and int(reaction.get("heal", 0)) <= 0): return
	var beneficiary_side: String = str(source.get("side", "ally"))
	var beneficiary: Dictionary = _by_uid(party if beneficiary_side == "ally" else enemies, int(source.get("uid", -1)))
	if beneficiary.is_empty() or int(beneficiary.hp) <= 0: return
	var support: Dictionary = {"block": int(reaction.get("block", 0)), "heal": int(reaction.get("heal", 0))}
	if support.block > 0 and Traits.once_per_round(beneficiary) and not moss_used.has(int(beneficiary.uid)):
		support.heal += Traits.strength(beneficiary)
		moss_used[int(beneficiary.uid)] = true
	_apply_support(support, entry, owner, beneficiary_side, beneficiary, power, events)

func _apply_support(stats: Dictionary, entry: Dictionary, owner: Dictionary, side: String, target: Dictionary, power: String, events: Array) -> void:
	if int(stats.get("block", 0)) > 0:
		target.block += int(stats.block)
		events.append(_event("block", entry, owner, side, target, power, int(stats.block)))
	if int(stats.get("heal", 0)) > 0:
		var healing: int = mini(int(stats.heal), int(target.max_hp) - int(target.hp))
		target.hp += healing
		events.append(_event("heal", entry, owner, side, target, power, healing))
	if int(stats.get("taunt", 0)) > 0:
		Conditions.apply(target, "taunt", int(stats.taunt), {"uid": int(owner.uid), "side": entry.side})
		events.append(_event("condition", entry, owner, side, target, power, int(stats.taunt)))
		events.back().condition = "taunt"

func _tick_statuses(events: Array) -> void:
	for side in ["ally", "enemy"]:
		var roster: Array = party if side == "ally" else enemies
		for target in roster:
			if int(target.get("slot", -1)) < 0 or int(target.hp) <= 0: continue
			var burn: int = int(target.statuses.get("burn", 0))
			if burn > 0:
				var damage: int = mini(int(target.hp), burn)
				target.hp -= damage
				var entry: Dictionary = {"side": side, "actor_uid": int(target.uid), "actor_slot": int(target.slot)}
				events.append(_event("burn", entry, target, side, target, "burn", damage))
				if int(target.hp) <= 0: events.append(_event("ko", entry, target, side, target, "burn", 0))
			Conditions.tick(target)

