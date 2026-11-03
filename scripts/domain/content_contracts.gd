extends RefCounted
## Pure semantic checks. Export enums alone do not reject malformed authored values.
const Effect = preload("res://scripts/catalog/effect_definition.gd")
const Item = preload("res://scripts/catalog/item_definition.gd")

static func effects(definitions: Array[Effect]) -> Array[String]:
	var errors: Array[String] = []
	if definitions.is_empty(): errors.append("Effects must not be empty")
	for effect in definitions:
		if effect == null:
			errors.append("Null effect")
			continue
		if effect.operation not in ["damage", "heal", "block", "status", "draw"]: errors.append("Unknown effect operation")
		if effect.target not in ["player", "enemy"] or effect.amount < 0: errors.append("Invalid effect target/amount")
		if effect.condition not in ["always", "target_burning", "target_wounded"]: errors.append("Unknown effect condition")
		if effect.operation == "draw" and effect.target != "player": errors.append("Only player can draw powers")
		if effect.operation == "status":
			var status = effect.status
			if status == null: errors.append("Status effect requires definition")
			elif status.status_id.is_empty() or status.display_name.is_empty() or status.duration == 0 or status.duration < -1 or status.per_stack < 0 or status.decay < 0 or status.max_stacks <= 0 or status.stacking not in ["add", "max", "replace"] or status.timing not in ["after_cast", "after_retaliation"] or status.tick_operation not in ["damage", "heal"]: errors.append("Invalid status definition")
	return errors

static func expedition(encounters: Array, species_ids: Array) -> Array[String]:
	var errors: Array[String] = []
	var seen: Dictionary = {}
	for encounter in encounters:
		if encounter == null or encounter.enemy == null:
			errors.append("Encounter requires enemy")
			continue
		if encounter.encounter_id.is_empty() or seen.has(encounter.encounter_id): errors.append("Duplicate/missing encounter ID")
		seen[encounter.encounter_id] = true
		if encounter.enemy.hp <= 0 or encounter.enemy.name.is_empty() or encounter.enemy.art_path.is_empty(): errors.append("Invalid enemy characteristics")
		if encounter.enemy.actions.is_empty(): errors.append("Encounter needs intentions")
		var actions: Dictionary = {}
		for action in encounter.enemy.actions:
			if action == null:
				errors.append("Null enemy action")
				continue
			if action.action_id.is_empty() or actions.has(action.action_id): errors.append("Duplicate/missing enemy action ID")
			actions[action.action_id] = true
			errors.append_array(effects(action.effects))
		if encounter.environment == null or encounter.environment.environment_id.is_empty() or encounter.environment.background_path.is_empty(): errors.append("Missing environment")
		if encounter.rewards == null:
			errors.append("Missing reward table")
		else:
			var table = encounter.rewards
			if table.table_id.is_empty() or table.heal < 0: errors.append("Invalid reward table")
			if not table.guaranteed_missing_species.is_empty() and table.guaranteed_missing_species not in species_ids: errors.append("Unknown guaranteed capture species")
			var pool: Dictionary = {}
			for id in table.capture_pool:
				if id not in species_ids or pool.has(id): errors.append("Unknown/duplicate reward species")
				pool[id] = true
	return errors

static func items(definitions: Array[Item]) -> Array[String]:
	var errors: Array[String] = []
	var seen: Dictionary = {}
	for item in definitions:
		if item == null:
			errors.append("Null item")
			continue
		if item.item_id.is_empty() or seen.has(item.item_id): errors.append("Duplicate/missing item ID")
		seen[item.item_id] = true
		if item.starting_quantity < 0 or item.display_name.is_empty() or item.description.is_empty(): errors.append("Invalid item characteristics")
		if item.kind == "consumable":
			errors.append_array(effects(item.effects))
			if not item.modifiers.is_empty(): errors.append("Consumable cannot equip modifiers")
		elif item.kind == "relic":
			if item.modifiers.is_empty() or not item.effects.is_empty(): errors.append("Relic requires modifiers only")
			for modifier in item.modifiers:
				if modifier == null or modifier.phase != "after_traits" or modifier.amount < 0 or modifier.operation not in ["damage", "heal", "block"] or modifier.requires_operation not in ["damage", "heal", "block"]: errors.append("Invalid relic modifier")
		else: errors.append("Unknown item kind")
	return errors
