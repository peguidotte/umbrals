extends RefCounted

const CardInstance = preload("res://scripts/domain/models/card_instance.gd")
const Content = preload("res://scripts/content.gd")
const Traits = preload("res://scripts/battle/traits.gd")
const Conditions = preload("res://scripts/battle/conditions.gd")
const Companion = preload("res://scripts/battle/aquatic_companion.gd")
const Initiative = preload("res://scripts/battle/initiative.gd")
const CatalogRevision = preload("res://scripts/battle/catalog_revision.gd")

static func power_effect(card: Dictionary, individual: Dictionary, companion_count: int, trait_available: bool = true) -> Dictionary:
	var stats: Dictionary = Content.power_stats(str(card.power), individual)
	var damage: int = int(stats.get("damage", 0))
	var block: int = int(stats.get("block", 0))
	var heal: int = int(stats.get("heal", 0))
	var burn: int = int(stats.get("burn", 0))
	if damage > 0:
		damage = maxi(0, damage + int(individual.get("attack", 10)) - 10)
		if individual.get("passive", "") == "fierce": damage += 3
		if individual.get("passive", "") == "ardent": burn += 2
	if individual.get("passive", "") == "resilient" and block > 0: block += 3
	if individual.get("passive", "") == "vital" and heal > 0: heal += 2
	var modified: Dictionary = Traits.power(individual, damage, block, heal, burn, companion_count, trait_available)
	damage = int(modified.damage)
	heal = int(modified.heal)
	burn = int(modified.burn)
	stats.damage = damage + (int(individual.get("statuses", {}).get("charge", 0)) if damage > 0 else 0)
	stats.attack_multiplier = Conditions.attack_multiplier(individual)
	if burn > 0: stats.conditions.burn = burn
	stats.block = block
	stats.heal = heal
	stats.burn = burn
	return stats

static func evaluate(cards: Array, companions: Array, existing_burn: int = 0, revision: int = 0) -> Dictionary:
	var result: Dictionary = {"valid": false, "reason": "Selecione poderes, uma troca ou um item", "name": "Prepare sua conjuração", "actions": 0, "energy": 0, "damage": 0, "direct_damage": 0, "burn_added": 0, "burn_tick": existing_burn, "block": 0, "heal": 0, "bonuses": []}
	if cards.is_empty(): return result
	var sequential_preview: bool = CatalogRevision.includes(revision, Companion.REVISION)
	var owners: Dictionary = {}
	# Consume one-shot modifiers only in detached public owner data.
	for individual in companions: owners[int(individual.uid)] = individual.duplicate(true) if sequential_preview else individual
	var seen: Dictionary = {}
	var participating: Dictionary = {}
	var moss_used: Dictionary = {}
	for card in cards:
		var parsed: Dictionary = CardInstance.try_from_dict(card)
		if not parsed.ok:
			result.reason = "Poder inválido"
			return result
		var instance = parsed.value
		if seen.has(instance.instance_id) or not owners.has(instance.owner) or not Content.POWERS.has(instance.power):
			result.reason = "Poder inválido"
			return result
		var individual: Dictionary = owners[instance.owner]
		if int(individual.get("hp", 1)) <= 0 or int(individual.get("slot", 0)) < 0:
			result.reason = "Umbral incapacitado ou na reserva"
			return result
		var known: Array = individual.get("known_powers", Content.SPECIES[individual.species].powers)
		if not instance.power in known:
			result.reason = "Este Umbral não conhece esse poder"
			return result
		seen[instance.instance_id] = true
		participating[instance.owner] = true
	var able_count: int = 0
	for individual in companions:
		if int(individual.get("slot", 0)) >= 0 and int(individual.get("hp", 1)) > 0: able_count += 1
	# Old graphs preserve even the forecast fields persisted in last_result.
	var preview_cards: Array = cards
	if sequential_preview:
		var ordered: Array = Initiative.player_entries(cards, owners.values(), [], [])
		ordered.sort_custom(Initiative.precedes)
		preview_cards = ordered.map(func(entry: Dictionary) -> Dictionary: return entry.card)
	for card: Dictionary in preview_cards:
		var individual: Dictionary = owners[int(card.owner)]
		var stats: Dictionary = power_effect(card, individual, able_count, not moss_used.has(int(individual.uid)))
		if Traits.once_per_round(individual) and int(stats.block) > 0: moss_used[int(individual.uid)] = true
		result.actions += int(stats.cost)
		result.direct_damage += floori(float(stats.damage) * float(stats.attack_multiplier))
		if Companion.available(individual, stats, revision):
			result.direct_damage += floori(Companion.BASE_POWER * float(stats.attack_multiplier))
			result.bonuses.append(Companion.description())
		result.block += int(stats.block)
		result.heal += int(stats.heal)
		result.burn_added += int(stats.burn)
		if sequential_preview and int(stats.damage) > 0:
			for id: String in ["charge", "electrified"]: Conditions.consume(individual, id)
	result.energy = result.actions
	result.damage = result.direct_damage
	result.name = "Conjuração conjunta" if participating.size() > 1 else "Poder de " + Content.display_name(owners[participating.keys()[0]])
	result.valid = int(result.actions) <= 3
	result.reason = "" if result.valid else "Ações insuficientes"
	return result

