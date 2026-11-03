extends "res://scripts/domain/trait_behavior.gd"

func apply(effect: Models.PowerEffect, uid: int, strength: int, active_count: int, triggered: Dictionary, result: Models.CastEvaluation) -> void:
	if effect.damage > 0 and active_count > 1:
		var extra: int = strength * (active_count - 1)
		effect.damage += extra
		result.bonuses.append("Circuito Vivo +%d dano" % extra)

func is_implemented() -> bool:
	return true
