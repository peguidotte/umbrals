extends RefCounted
const Models = preload("res://scripts/domain/models.gd")
const Combat = preload("res://scripts/domain/combat_records.gd")
const Mechanics = preload("res://scripts/domain/mechanics.gd")
const Content = preload("res://scripts/content.gd")
const Ids = preload("res://scripts/domain/ids.gd")

static func evaluate(cards: Array[Models.CardInstance], companions: Array[Models.Individual], existing_burn: int = 0, wounded: bool = false, initial: Combat.State = null, catalog: Content.Catalog = null) -> Models.CastEvaluation:
	if catalog == null: catalog = Content.DEFAULT
	var result = Models.CastEvaluation.new()
	if cards.is_empty() or cards.size() > 3: return result
	var owners: Dictionary = {}
	for umbral in companions:
		if umbral == null or catalog.form(umbral) == null or not catalog.passives.has(umbral.passive) or owners.has(umbral.uid):
			result.reason = "Indivíduo inválido"
			return result
		owners[umbral.uid] = umbral
	var active: Dictionary = {}
	var unique_cards: Dictionary = {}
	for card in cards:
		if card == null or unique_cards.has(card.instance_id) or not owners.has(card.owner):
			result.reason = "Poder inválido"
			return result
		if catalog.form(owners[card.owner]).power(card.power) == null:
			result.reason = "Este Umbral ainda não conhece esse poder"
			return result
		unique_cards[card.instance_id] = true
		active[card.owner] = true
	var protected_moss: Dictionary = {}
	var discounted: Dictionary = {}
	# Canonical source order makes attribution and once-per-owner traits reproducible.
	var ordered: Array[Models.CardInstance] = cards.duplicate()
	ordered.sort_custom(func(a: Models.CardInstance, b: Models.CardInstance): return a.instance_id < b.instance_id)
	for card in ordered:
		var umbral: Models.Individual = owners[card.owner]
		var power: Content.Power = catalog.power_stats(card.power, umbral)
		var source_start: int = result.requests.size()
		var base = Models.PowerEffect.new(0, 0, 0, 0)
		for definition in power.effects:
			var burning: bool = existing_burn > 0 if initial == null else initial.stacks("burn", definition.target) > 0
			var target_wounded: bool = wounded
			if initial != null: target_wounded = initial.player_hp < initial.player_max if definition.target == "player" else initial.enemy_hp < initial.enemy_max
			if not definition.enabled(burning, target_wounded): continue
			if (definition.operation == "damage" and definition.target == "enemy") or (definition.operation in ["block", "heal"] and definition.target == "player"):
				base.set(definition.operation, base.get(definition.operation) + definition.amount)
			elif definition.operation == "status" and (definition.status != null and definition.status.status_id == "burn" and definition.target == "enemy"): base.burn += definition.amount
			else: result.requests.append(Combat.Request.new(definition.operation, definition.amount, definition.target, power.power_id, umbral.uid, definition.status))
		result.energy += power.cost
		var effect: Models.PowerEffect = Mechanics.apply(umbral, base.damage, base.block, base.heal, base.burn, active.size(), discounted, protected_moss, result, catalog)
		result.direct_damage += effect.damage
		result.block += effect.block
		result.heal += effect.heal
		result.burn_added += effect.burn
		for operation in ["damage", "block", "heal", "burn"]:
			var amount: int = effect.get(operation)
			if amount <= 0: continue
			result.requests.append(Combat.Request.new("status" if operation == "burn" else operation, amount, "player" if operation in ["block", "heal"] else "enemy", power.power_id, umbral.uid, Content.Power.BURN if operation == "burn" else null))
		var action = Combat.Request.new("action", 0, "enemy", power.power_id, umbral.uid)
		action.action_id = power.action_id
		action.sound_id = catalog.form(umbral).presentation.sound_id
		result.requests.append(action)
		for index in range(source_start, result.requests.size()): result.requests[index].source_instance_id = card.instance_id
	if active.size() == 3:
		result.direct_damage += 6
		var link = Combat.Request.new("damage", 6, "enemy", Ids.TRIPLE_LINK)
		link.phase = "link"
		result.requests.append(link)
		result.bonuses.append("Vínculo triplo +6 dano")
		result.events.append(Ids.TRIPLE_LINK)
	result.burn_tick = existing_burn + result.burn_added
	result.damage = result.direct_damage + result.burn_tick
	result.name = "Vínculo triplo" if active.size() == 3 else "Conjuração conjunta" if active.size() == 2 else "Poder de " + catalog.display_name(owners[active.keys()[0]])
	result.valid = int(result.energy) <= 3
	result.reason = "" if result.valid else "Energia insuficiente"
	return result
