extends RefCounted
## Formats authored effects and evaluated values; never predicts combat consequences.
const Power = preload("res://scripts/catalog/power_definition.gd")
const Models = preload("res://scripts/domain/models.gd")

static func special_effects(power: Power) -> Array[String]:
	var lines: Array[String] = []
	for effect in power.effects:
		if effect.condition == "always" and (effect.operation in ["damage", "block", "heal"] or (effect.operation == "status" and effect.status.status_id == "burn")): continue
		var labels: Dictionary = {"damage": "dano", "block": "escudo", "heal": "cura", "draw": "compra"}
		var text: String = "%d %s" % [effect.amount, effect.status.display_name if effect.operation == "status" else labels.get(effect.operation, effect.operation)]
		if effect.condition == "target_burning": text = "Se alvo queimando: " + text
		if effect.condition == "target_wounded": text = "Se alvo ferido: " + text
		lines.append(text)
	return lines

static func card_lines(power: Power, score: Models.CastEvaluation) -> Array[String]:
	var first: String = "%d dano" % score.direct_damage if score.direct_damage > 0 else "%d escudo" % score.block if score.block > 0 else "%d cura" % score.heal if score.heal > 0 else ""
	var second: String = "+%d queimadura" % score.burn_added if score.burn_added > 0 else "%d escudo · %d cura" % [score.block, score.heal] if score.block > 0 and score.heal > 0 else "%d escudo" % score.block if score.direct_damage > 0 and score.block > 0 else ""
	var additional: Array[String] = special_effects(power)
	if first.is_empty(): first = additional.pop_front() if not additional.is_empty() else "Sem efeito imediato"
	if second.is_empty() and not additional.is_empty(): second = additional[0]
	return [first, second]
