extends RefCounted
const Models = preload("res://scripts/domain/models.gd")
## Pure species behavior. Implementations cannot access Content, nodes, files or RNG.
func apply(_effect: Models.PowerEffect, _uid: int, _strength: int, _active_count: int, _triggered: Dictionary, _result: Models.CastEvaluation) -> void:
	pass

func is_implemented() -> bool:
	return false
