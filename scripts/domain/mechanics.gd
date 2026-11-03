extends RefCounted
## Explicit mechanics, not a plugin framework. Never mutates the individual or uses RNG.
const Catalog = preload("res://scripts/catalog/game_catalog.gd")
const PASSIVES = ["fierce", "resilient", "vital", "ardent", "swift"]
const Models = preload("res://scripts/domain/models.gd")

static func apply(umbral: Models.Individual, damage: int, block: int, heal: int, burn: int, active_count: int, discounted: Dictionary, protected_moss: Dictionary, result: Models.CastEvaluation, catalog: Catalog) -> Models.PowerEffect:
	if umbral.passive == "fierce" and damage > 0: damage += 3
	if umbral.passive == "resilient" and block > 0: block += 3
	if umbral.passive == "vital" and heal > 0: heal += 2
	if umbral.passive == "ardent" and damage > 0: burn += 2
	if umbral.passive == "swift" and not discounted.has(int(umbral.uid)):
		result.energy -= 1
		discounted[int(umbral.uid)] = true
		result.bonuses.append("%s: Ágil −1 energia" % catalog.display_name(umbral))
	var effect = Models.PowerEffect.new(damage, block, heal, burn)
	var species = catalog.species[umbral.species_id]
	var behavior: RefCounted = species.trait_script.new()
	behavior.apply(effect, umbral.uid, catalog.form(umbral).trait_strength, active_count, protected_moss, result)
	return effect
