extends RefCounted
## Inspection consumes only the visible intent projection supplied by the caller.
const Content = preload("res://scripts/content.gd")
const UI = preload("res://scripts/ui/kit.gd")
const BattleArt = preload("res://scripts/ui/battle_art.gd")
const PowerCard = preload("res://scripts/ui/power_card.gd")
const Conditions = preload("res://scripts/battle/conditions.gd")
const CardPreview = preload("res://scripts/ui/card_preview.gd")
signal back_requested
var ui = UI.new()
var register: Callable

func _button(parent: Node, text: String, action: Callable, key: String) -> Button:
	var button: Button = ui.button(text, action, key, true)
	parent.add_child(button)
	register.call(button, key, "inspect")
	return button

func build(inspection: Dictionary, party: Array, enemies: Array, public_intents: Array, power_effect: Dictionary, viewport_size: Vector2, frame: VBoxContainer, registry: Callable, large: float = 1.0) -> void:
	register = registry
	var individual: Dictionary = inspection.umbral
	var species: Dictionary = Content.SPECIES.get(individual.get("species", ""), {})
	var enemy: bool = bool(inspection.get("enemy", false))
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = minf(520, viewport_size.y - 320)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.focus_mode = Control.FOCUS_ALL
	frame.add_child(scroll)
	var body: VBoxContainer = UI.column(16)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	var row: HBoxContainer = UI.row(28)
	body.add_child(row)
	var art_id: String = str(individual.get("art", "umbrals/ember")) if enemy or species.is_empty() else Content.art_binding(individual)
	var portrait: Control = CardPreview.create(inspection.card, individual, party, Vector2(280, 420), large) if inspection.has("card") else null
	if portrait == null:
		portrait = UI.art(str(Content.POWERS[inspection.card.power].art) if inspection.has("card") else art_id, Vector2(210, 200))
		if not inspection.has("card"): portrait.texture = BattleArt.texture(art_id)
	row.add_child(portrait)
	var details: VBoxContainer = UI.column(12)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(details)
	details.add_child(ui.label("HP %d/%d · ATQ %d · DEF %d · VEL %d" % [int(individual.get("hp", 0)), int(individual.get("max_hp", 0)), int(individual.get("attack", 0)), int(individual.get("defense", 0)), int(individual.get("speed", 0))], 23, UI.GOLD))
	details.add_child(ui.paragraph("Resistências: " + Content.resistance_text(individual), 20))
	if not enemy and not species.is_empty():
		details.add_child(ui.label("TRAIT  " + str(Content.form_definition(individual.species, Content.form_id(individual)).trait), 24, UI.GOLD))
		details.add_child(ui.paragraph(Content.trait_text(individual), 21, UI.PAPER))
	if not enemy and Content.PASSIVES.has(individual.get("passive", "")):
		var passive: Dictionary = Content.PASSIVES[individual.passive]
		details.add_child(ui.label("PASSIVA  " + passive.name, 23, UI.LEAF))
		details.add_child(ui.paragraph(passive.description, 21))
	var conditions: Array[String] = Conditions.labels(individual, true)
	if not conditions.is_empty():
		for id in Conditions.DEFINITIONS:
			if int(individual.get("statuses", {}).get(id, 0)) <= 0: continue
			var source: Dictionary = individual.get("status_sources", {}).get(id, {})
			var roster: Array = party if source.get("side", "ally") == "ally" else enemies
			for unit in roster:
				if int(unit.uid) == int(source.get("uid", -1)):
					conditions.append("Fonte de %s: %s · %s" % [Conditions.DEFINITIONS[id].name, str(unit.name) if unit.has("name") else Content.display_name(unit), "reserva" if int(unit.slot) < 0 else "vaga " + ["superior", "central", "inferior"][clampi(int(unit.slot), 0, 2)]])
		body.add_child(ui.paragraph("\n".join(conditions), 18))
	if inspection.has("card"):
		var power: Dictionary = power_effect
		body.add_child(ui.paragraph("Natureza do golpe: " + Content.NATURES[power.nature].name + " · Aprendizado: " + {"nature": "por natureza", "lineage": "linhagem", "universal": "universal"}[power.learning] + "\n" + PowerCard.effect_text(power), 20, UI.GOLD))
		body.add_child(ui.paragraph("%d ação(ões) · potência %d · escudo %d · cura %d\nAlcance: %s. A velocidade ordena a execução; estados e defesa modificam o resultado." % [int(power.cost), floori(float(power.damage) * float(power.get("attack_multiplier", 1.0))), int(power.block), int(power.heal), {"single": "individual", "upper_pair": "superior + centro", "lower_pair": "centro + inferior", "all": "todos"}.get(str(power.get("scope", "single")), "individual")], 21))
	elif enemy:
		for intent in public_intents:
			if int(intent.slot) != int(individual.slot) or not intent.has("nature"): continue
			var known: Array[String] = []
			if Content.NATURES.has(str(intent.nature)): known.append("Natureza anunciada: " + Content.NATURES[str(intent.nature)].name)
			for id in intent.get("conditions", {}):
				known.append("Anuncia %s %d: %s" % [Conditions.DEFINITIONS[id].name, int(intent.conditions[id]), Conditions.DEFINITIONS[id].description])
			if not known.is_empty(): body.add_child(ui.paragraph("\n".join(known), 20, UI.GOLD))
		body.add_child(ui.paragraph("A intenção mostrada sobre o adversário respeita seu modo de informação. Inspecionar não revela planos ocultos.", 20))
	else:
		var names: Array[String] = []
		for power_id in individual.get("known_powers", species.get("powers", [])): names.append(str(Content.POWERS[power_id].name).replace("\n", " "))
		body.add_child(ui.paragraph("PODERES\n" + " · ".join(names), 21))
	_button(frame, "VOLTAR", back_requested.emit, "inspect.back")

