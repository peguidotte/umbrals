extends RefCounted
const Combat = preload("res://scripts/domain/combat_records.gd")
## Runtime records. Dictionaries belong to catalog definitions and serialization boundaries.

class Individual extends RefCounted:
	var uid: int
	var species_id: String
	var passive: String
	var form_id: String
	func _init(species_id: String = "", passive_id: String = "", id: int = 0, form: String = "") -> void:
		self.species_id = species_id
		passive = passive_id
		uid = id
		form_id = form
	func to_dict() -> Dictionary:
		return {"uid": uid, "species_id": species_id, "passive": passive, "form_id": form_id}
	func clone() -> Individual:
		return Individual.new(species_id, passive, uid, form_id)

class PowerEffect extends RefCounted:
	var damage: int
	var block: int
	var heal: int
	var burn: int
	func _init(d: int, b: int, h: int, fire: int) -> void:
		damage = d
		block = b
		heal = h
		burn = fire

class CardInstance extends RefCounted:
	var instance_id: String
	var owner: int
	var power: String
	func _init(power_id: String = "", owner_uid: int = 0, copy_number: int = 0) -> void:
		power = power_id
		owner = owner_uid
		instance_id = "%d:%s:%d" % [owner, power, copy_number]
	func to_dict() -> Dictionary:
		return {"instance_id": instance_id, "owner": owner, "power": power}

class RewardOffer extends RefCounted:
	var kind: String
	var uid: int = -1
	var umbral: Individual
	var source_form_id: String
	var target_form_id: String
	var transition_id: String
	func _init(reward_kind: String, individual: Individual = null, target_uid: int = -1, target: String = "", source: String = "", transition: String = "") -> void:
		kind = reward_kind
		umbral = individual
		uid = target_uid
		target_form_id = target
		source_form_id = source
		transition_id = transition
	func to_dict() -> Dictionary:
		return {"kind": kind, "umbral": umbral.to_dict()} if umbral != null else {"kind": kind, "uid": uid, "source_form_id": source_form_id, "target_form_id": target_form_id, "transition_id": transition_id}

class CastEvaluation extends RefCounted:
	var requests: Array[Combat.Request] = []
	var valid: bool = false
	var reason: String = "Selecione seus poderes"
	var name: String = "Prepare sua conjuração"
	var energy: int = 0
	var damage: int = 0
	var direct_damage: int = 0
	var burn_added: int = 0
	var burn_tick: int = 0
	var block: int = 0
	var heal: int = 0
	var bonuses: Array[String] = []
	var events: Array[String] = []
	func to_dict() -> Dictionary:
		return {"valid": valid, "reason": reason, "name": name, "energy": energy, "damage": damage, "direct_damage": direct_damage, "burn_added": burn_added, "burn_tick": burn_tick, "block": block, "heal": heal, "bonuses": bonuses.duplicate(), "events": events.duplicate()}

class ResolutionResult extends RefCounted:
	var combat_events: Array[Combat.Event] = []
	var state_after: Combat.State
	var extra_draw: int = 0
	var evaluation: CastEvaluation
	var ok: bool = false
	var reason: String = "invalid_phase"
	var incoming: int = 0
	var applied_damage: int = 0
	var effective_heal: int = 0
	var player_hp_after: int = 0
	var enemy_hp_after: int = 0
	var burn_after: int = 0
	var plays_after: int = 0
	var phase: String = ""
	func to_dict() -> Dictionary:
		var data: Dictionary = evaluation.to_dict() if evaluation != null else {}
		data.merge({"ok": ok, "reason": reason, "incoming": incoming, "applied_damage": applied_damage, "effective_heal": effective_heal, "player_hp_after": player_hp_after, "enemy_hp_after": enemy_hp_after, "burn_after": burn_after, "plays_after": plays_after, "phase": phase, "combat_events": combat_events.map(func(event: Combat.Event): return event.to_dict()), "extra_draw": extra_draw}, true)
		return data

static func records(items: Array) -> Array:
	var result: Array = []
	for item in items: result.append(item.to_dict())
	return result
