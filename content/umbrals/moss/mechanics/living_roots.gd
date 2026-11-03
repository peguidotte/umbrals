extends "res://scripts/domain/trait_behavior.gd"

func apply(effect: Models.PowerEffect, uid: int, strength: int, active_count: int, triggered: Dictionary, result: Models.CastEvaluation) -> void:
	if effect.block > 0 and not triggered.has(uid):
		effect.heal += strength
		triggered[uid] = true
		result.bonuses.append("Raízes Vivas +%d cura" % strength)

func is_implemented() -> bool:
	return true
