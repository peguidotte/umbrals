extends RefCounted
## Pure behavior registry. Species choose behavior IDs in their authored forms.
const Content = preload("res://scripts/content.gd")
static var HANDLERS: Dictionary = {"combustion": _combustion, "living_roots": _living_roots, "living_circuit": _living_circuit, "marked_tide": _marked_tide}

static func definition(individual: Dictionary) -> Dictionary:
	return Content.form_definition(str(individual.species), Content.form_id(individual))

static func strength(individual: Dictionary) -> int:
	return int(definition(individual).get("trait_value", 0))

static func once_per_round(individual: Dictionary) -> bool:
	return str(definition(individual).get("trait_id", "")) == "living_roots"

static func power(individual: Dictionary, damage: int, block: int, heal: int, burn: int, companions: int, available: bool) -> Dictionary:
	var values: Dictionary = {"damage": damage, "block": block, "heal": heal, "burn": burn}
	var id: String = str(definition(individual).get("trait_id", ""))
	if HANDLERS.has(id): HANDLERS[id].call(values, strength(individual), companions, available)
	return values

static func _combustion(values: Dictionary, amount: int, _companions: int, _available: bool) -> void:
	if int(values.damage) > 0: values.burn += amount

static func _living_roots(values: Dictionary, amount: int, _companions: int, available: bool) -> void:
	if int(values.block) > 0 and available: values.heal += amount

static func _living_circuit(values: Dictionary, amount: int, companions: int, _available: bool) -> void:
	if int(values.damage) > 0: values.damage += amount * maxi(0, companions - 1)

static func _marked_tide(_values: Dictionary, _amount: int, _companions: int, _available: bool) -> void:
	# Its Wet duration is authored in the form's move profile.
	pass
