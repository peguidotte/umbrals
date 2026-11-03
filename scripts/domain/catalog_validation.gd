extends RefCounted
## Pure validation of typed authored resources; disk/assets are checked by tools/content_checks.gd.
const Content = preload("res://scripts/content.gd")
const Species = preload("res://scripts/catalog/species_definition.gd")
const Trait = preload("res://scripts/domain/trait_behavior.gd")
const Contracts = preload("res://scripts/domain/content_contracts.gd")
const Visuals = preload("res://scripts/catalog/presentation_validation.gd")

static func valid_id(id: String) -> bool:
	return not id.is_empty() and id.is_valid_identifier() and id == id.to_lower()

static func validate(entries: Array[Species], encounters: Array = Content.ENCOUNTERS) -> Array[String]:
	var errors: Array[String] = []
	var species_ids: Dictionary = {}
	if entries.is_empty() or encounters.is_empty(): errors.append("Catalog must not be empty")
	for species in entries:
		if species == null:
			errors.append("Null species")
			continue
		if not valid_id(species.species_id) or species_ids.has(species.species_id): errors.append("Invalid/duplicate species ID")
		species_ids[species.species_id] = true
		if not species.ready_for_play: errors.append("Registered species is still a draft: " + species.species_id)
		if species.element.is_empty() or not valid_id(species.trait_id) or "TODO" in species.trait_description or species.description.is_empty() or "TODO" in species.description or "TODO" in species.trait_name or species.trait_name.is_empty() or species.trait_description.count("%d") != 1: errors.append("Missing species/trait description")
		if species.trait_script == null:
			errors.append("Missing trait implementation")
		else:
			var behavior: RefCounted = species.trait_script.new()
			if not behavior is Trait or not behavior.is_implemented(): errors.append("Trait must implement the pure trait contract")
		if species.passive_pool.is_empty(): errors.append("Missing passive pool")
		for passive in species.passive_pool:
			if not Content.PASSIVES.has(passive): errors.append("Unknown passive: " + passive)
		var forms: Dictionary = {}
		for shape in species.forms:
			if shape == null:
				errors.append("Null form")
				continue
			if not valid_id(shape.form_id) or forms.has(shape.form_id): errors.append("Invalid/duplicate form ID")
			forms[shape.form_id] = shape
			if shape.display_name.is_empty() or "TODO" in shape.display_name or "TODO" in shape.description or shape.description.is_empty() or shape.trait_strength < 0 or shape.copies_per_power <= 0: errors.append("Invalid form characteristics")
			if shape.powers.is_empty(): errors.append("Form needs explicit powers")
			var powers: Dictionary = {}
			for power in shape.powers:
				if power == null or power.identity == null:
					errors.append("Null power")
					continue
				if not valid_id(power.power_id) or powers.has(power.power_id): errors.append("Invalid/duplicate power ID")
				powers[power.power_id] = true
				if power.identity == null or power.identity.description.is_empty() or "TODO" in power.identity.description or power.name.is_empty() or "TODO" in power.name or power.art_path.is_empty(): errors.append("Power needs name/art")
				errors.append_array(Contracts.effects(power.effects))
				for value in [power.cost]:
					if value < 0: errors.append("Power values must be nonnegative")
				if power.action_id not in ["attack_ranged", "attack_melee", "defend", "heal"]: errors.append("Unsupported power action")
			errors.append_array(Visuals.validate(shape.presentation))
		if not forms.has(species.initial_form_id): errors.append("Initial form is missing")
		for shape in forms.values():
			var transitions: Dictionary = {}
			for edge in shape.evolutions:
				if edge == null:
					errors.append("Null evolution")
					continue
				if not valid_id(edge.transition_id) or transitions.has(edge.transition_id): errors.append("Invalid/duplicate transition ID")
				transitions[edge.transition_id] = true
				if not forms.has(edge.target_form_id): errors.append("Evolution target does not belong to species")
				if edge.min_encounter < 0 or edge.health_cost < 0 or (not edge.required_passive.is_empty() and edge.required_passive not in species.passive_pool): errors.append("Invalid evolution requirements")
		var visited: Dictionary = {}
		_walk(species.initial_form_id, forms, {}, visited, errors)
		if visited.size() != forms.size(): errors.append("Unreachable forms in " + species.species_id)
	errors.append_array(Contracts.expedition(encounters, species_ids.keys()))
	errors.append_array(Contracts.items(Content.ITEMS.items))

	return errors

static func _walk(id: String, forms: Dictionary, active: Dictionary, visited: Dictionary, errors: Array[String]) -> void:
	if active.has(id):
		errors.append("Evolution cycle at " + id)
		return
	if visited.has(id) or not forms.has(id): return
	active[id] = true
	visited[id] = true
	for edge in forms[id].evolutions:
		if edge != null: _walk(edge.target_form_id, forms, active, visited, errors)
	active.erase(id)
