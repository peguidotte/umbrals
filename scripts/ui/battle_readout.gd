extends RefCounted
## Public presentation only: own plans and effects that have already happened.
const Content = preload("res://scripts/content.gd")
const Targeting = preload("res://scripts/battle/targeting.gd")
const Conditions = preload("res://scripts/battle/conditions.gd")

static func name_of(individual: Dictionary) -> String:
	if individual.is_empty(): return "Umbral"
	return str(individual.name) if individual.has("name") else Content.display_name(individual)

static func plan_entry(entry: Dictionary, party: Array, _enemies: Array) -> String:
	var owner: Dictionary = _by_uid(party, int(entry.actor_uid))
	if entry.kind == "swap":
		var incoming: Dictionary = _by_uid(party, int(entry.swap.in_uid))
		return "Entrada em campo\n%s → %s\n1 ação · troca" % [name_of(incoming), Targeting.SLOT_NAMES[int(entry.actor_slot)]]
	if entry.kind == "item":
		var item: Dictionary = Content.CONSUMABLES[entry.order.item]
		return "%s\n→ %s\n%d ação · item" % [item.name, name_of(_by_uid(party, int(entry.order.uid))), int(item.cost)]
	var card: Dictionary = entry.card
	var power: Dictionary = Content.power_stats(str(card.power), int(owner.get("stage", 1)))
	var target: String = "si próprio"
	if power.get("target", "enemy") != "self":
		if power.scope == "single":
			target = Targeting.SLOT_NAMES[int(card.get("target_slot", 1))]
		else: target = {"upper_pair": "sup+cen", "lower_pair": "cen+inf", "all": "todos"}.get(power.scope, "todos")
	var timing: String = "prioritário" if int(entry.priority) > 0 else "VEL %d" % int(entry.speed)
	return "%s\n%s → %s\n%d ação · %s" % [str(power.name).replace("\n", " "), name_of(owner), target, int(power.cost), timing]

static func event_line(event: Dictionary) -> String:
	var actor: String = str(event.get("actor_name", "Umbral"))
	var target: String = str(event.get("target_name", "Umbral"))
	var amount: int = int(event.get("amount", 0))
	var power: String = str(event.get("power", ""))
	var technique: String = str(Content.POWERS[power].name).replace("\n", " ") if Content.POWERS.has(power) else "Ataque"
	match str(event.get("kind", "")):
		"attack":
			var modifiers: Array[String] = []
			if int(event.get("blocked", 0)) > 0: modifiers.append("%d absorvido pelo escudo" % int(event.blocked))
			if int(event.get("resistance", 0)) > 0: modifiers.append("resistência %d%%" % int(event.resistance))
			if bool(event.get("weakened", false)): modifiers.append("enfraquecido −25%")
			if bool(event.get("amplified", false)): modifiers.append("Condução ×2")
			return "%s · %s → %s: −%d HP%s" % [actor, technique, target, amount, " · " + ", ".join(modifiers) if not modifiers.is_empty() else ""]
		"reaction": return "%s → %s: %s" % [actor, target, str(event.get("label", "Reação"))]
		"condition": return "%s → %s: %s %d" % [actor, target, str(Conditions.DEFINITIONS.get(str(event.get("condition", "")), {}).get("name", "Condição")), amount]
		"condition_spent": return actor + ": " + str(Conditions.DEFINITIONS.get(str(event.get("condition", "")), {}).get("name", "Condição")) + " consumido pelo ataque"
		"block": return "%s: +%d escudo" % [target, amount]
		"heal": return "%s: +%d HP" % [target, amount]
		"revive": return target + ": reanimado; poderes na próxima rodada se estiver em campo"
		"burn": return "%s: −%d HP por Queima" % [target, amount]
		"swap": return target + ": entrou no campo; cartas na próxima compra"
		"ko": return target + ": incapacitado"
		"prepare": return "%s: +%d Carga para o próximo ataque" % [target, amount]
		"canceled": return actor + ": não agiu · " + str(event.get("reason", "indisponível"))
	return ""

static func _by_uid(roster: Array, uid: int) -> Dictionary:
	for individual in roster:
		if int(individual.uid) == uid: return individual
	return {}
