extends "res://scripts/domain/trait_behavior.gd"

func apply(effect: Models.PowerEffect, uid: int, strength: int, active_count: int, triggered: Dictionary, result: Models.CastEvaluation) -> void:
	if effect.damage > 0:
		effect.burn += strength
		result.bonuses.append("Combustão +%d queimadura" % strength)

func is_implemented() -> bool:
	return true
