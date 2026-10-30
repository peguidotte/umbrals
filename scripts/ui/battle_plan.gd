extends VBoxContainer
## A command editor, independent of session flow and private enemy plans.
signal remove_requested(kind: String, id: int)
signal target_requested(index: int, slot: int)
signal inspect_requested(index: int)
signal control_created(control: Control, id: String)
const Content = preload("res://scripts/content.gd")
const Targeting = preload("res://scripts/battle/targeting.gd")
const Reactions = preload("res://scripts/battle/reactions.gd")
const UI = preload("res://scripts/ui/kit.gd")

func populate(entries: Array, hand: Array, party: Array, enemies: Array, text_scale: float) -> void:
	var ui = UI.new()
	ui.text_scale = text_scale
	add_theme_constant_override("separation", 12)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 280
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var list: VBoxContainer = UI.column(8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	if entries.is_empty(): list.add_child(ui.paragraph("Nenhum comando planejado. Selecione poderes, traga uma reserva ou escolha um item.", 22))
	for entry in entries:
		var row: HBoxContainer = UI.row(12)
		list.add_child(row)
		var description: VBoxContainer = UI.column(2)
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(description)
		var kind: String = str(entry.kind)
		var id: int = int(entry.actor_slot)
		var title: String = ""
		var detail: String = "1 ação"
		if kind == "power":
			var card: Dictionary = entry.card
			id = hand.find(card)
			# Copies may differ by transient fields; identity is the physical instance.
			for i in range(hand.size()):
				if hand[i].instance_id == card.instance_id: id = i
			var owner: Dictionary = _by_uid(party, int(card.owner))
			var power: Dictionary = Content.power_stats(str(card.power), int(owner.stage))
			title = str(power.name).replace("\n", " ") + " · " + Content.display_name(owner)
			detail = "%s · %d ação(ões) · %s · VEL %d" % [Content.NATURES[power.nature].name, int(power.cost), "Prioridade" if int(entry.priority) > 0 else "Normal", int(entry.speed)]
			if str(power.get("scope", "single")) == "single" and power.get("target", "enemy") != "self":
				var selector = OptionButton.new()
				selector.custom_minimum_size = Vector2(290, 54)
				selector.add_theme_font_size_override("font_size", int(17 * text_scale))
				var roster: Array = enemies if power.get("target", "enemy") == "enemy" else party
				var options: Array[int] = Targeting.options(power, owner, party, enemies)
				for slot in options:
					var target: Dictionary = Targeting.at_slot(roster, slot)
					selector.add_item((str(target.name) if target.has("name") else Content.display_name(target)) + " · " + Targeting.SLOT_NAMES[slot], slot)
				selector.select(selector.get_item_index(int(card.get("target_slot", 1))))
				var popup: PopupMenu = selector.get_popup()
				popup.about_to_popup.connect(func(): popup.call_deferred("set_focused_item", selector.selected))
				selector.item_selected.connect(func(option: int): target_requested.emit(id, selector.get_item_id(option)))
				row.add_child(selector)
				control_created.emit(selector, "plan.target.%d" % id)
			else:
				detail += " · " + ("Si próprio" if power.get("target", "enemy") == "self" else str(Targeting.SCOPE_NAMES[power.scope]))
			if Targeting.options(power, owner, party, enemies).is_empty(): detail += " · Sem alvo no alcance"
			var inspect: Button = ui.button("i", func(): inspect_requested.emit(id), "plan.inspect.%d" % id)
			inspect.custom_minimum_size = Vector2(46, 54)
			inspect.tooltip_text = "Detalhes do poder, efeitos e combinações"
			row.add_child(inspect)
			control_created.emit(inspect, "plan.inspect.%d" % id)
		elif kind == "swap":
			var incoming: Dictionary = _by_uid(party, int(entry.swap.in_uid))
			title = "Trazer " + Content.display_name(incoming) + " · vaga " + Targeting.SLOT_NAMES[id]
			detail += " · Antes dos golpes · Cartas na próxima compra"
		else:
			id = int(entry.item_index)
			var target: Dictionary = _by_uid(party, int(entry.order.uid))
			title = str(Content.CONSUMABLES[entry.order.item].name) + " · " + Content.display_name(target)
			detail = "%d ação(ões) · Antes dos golpes" % int(Content.CONSUMABLES[entry.order.item].cost)
			if Content.CONSUMABLES[entry.order.item].has("revive_ratio"): detail += " · Se ativo, age na próxima rodada"
		description.add_child(ui.label(title, 21, UI.PAPER))
		description.add_child(ui.label(detail, 16, UI.MUTED))
		var remove: Button = ui.button("RETIRAR", func(): remove_requested.emit(kind, id), "plan.remove.%s.%d" % [kind, id])
		remove.add_theme_font_size_override("font_size", int(16 * text_scale))
		row.add_child(remove)
		control_created.emit(remove, "plan.remove.%s.%d" % [kind, id])
	for note in combo_notes(entries, enemies): list.add_child(ui.paragraph(note, 18, UI.GOLD))

static func combo_notes(entries: Array, enemies: Array) -> Array[String]:
	var notes: Array[String] = []
	for lightning in entries:
		if lightning.kind != "power" or Content.POWERS[lightning.card.power].get("nature", "") != "lightning": continue
		var electric: Dictionary = Content.POWERS[lightning.card.power]
		for water in entries:
			if water.kind != "power" or int(Content.POWERS[water.card.power].conditions.get("wet", 0)) <= 0: continue
			var aquatic: Dictionary = Content.POWERS[water.card.power]
			var shared_target: bool = false
			for slot in Targeting.slots(str(electric.scope), int(lightning.card.get("target_slot", 1))):
				var target: Dictionary = Targeting.at_slot(enemies, int(slot))
				if slot in Targeting.slots(str(aquatic.scope), int(water.card.get("target_slot", 1))) and not target.is_empty() and int(target.hp) > 0: shared_target = true
			if not shared_target: continue
			var before: bool = int(water.priority) > int(lightning.priority) or (int(water.priority) == int(lightning.priority) and int(water.speed) > int(lightning.speed))
			var equal: bool = int(water.priority) == int(lightning.priority) and int(water.speed) == int(lightning.speed)
			var note: String = "Água antes do raio: o combo depende de ambos executarem e do alvo sobreviver."
			if equal: note = "Água e raio empatam em velocidade: a ordem entre donos será sorteada."
			elif not before: note = "Raio antes da água: dano dobrado exige Encharcado já aplicado."
			if not note in notes: notes.append(note)
	for entry in entries:
		if entry.kind != "power": continue
		var power: Dictionary = Content.POWERS[entry.card.power]
		if int(power.damage) <= 0: continue
		for slot in Targeting.slots(str(power.scope), int(entry.card.get("target_slot", 1))):
			var target: Dictionary = Targeting.at_slot(enemies, int(slot))
			if target.is_empty() or int(target.hp) <= 0: continue
			var reaction: Dictionary = Reactions.choose(power, target)
			if not reaction.is_empty():
				var note: String = "%s: %s + %s, se a condição ainda existir ao executar. Outras ações e Provocar podem mudar o alvo." % [reaction.name, {"wet": "Encharcado", "seed": "Semeado"}[reaction.condition], Content.NATURES[power.nature].name]
				if not note in notes: notes.append(note)
		if int(power.conditions.get("seed", 0)) > 0:
			var note: String = "Semeadura prepara Semeado; outro golpe de Bosque/Água/Fogo consome a semente. Benefícios seguem a fonte original."
			if not note in notes: notes.append(note)
		if int(power.conditions.get("electrified", 0)) > 0:
			var note: String = "Interferência enfraquece o próximo ataque; se ele já tiver executado, afeta um posterior. Não remove ações."
			if not note in notes: notes.append(note)

	for setup in entries:
		if setup.kind != "power": continue
		var seed: Dictionary = Content.POWERS[setup.card.power]
		if int(seed.conditions.get("seed", 0)) <= 0: continue
		for follow in entries:
			if follow.kind != "power": continue
			var trigger: Dictionary = Content.POWERS[follow.card.power]
			# A second Semeadura already has its own preparation explanation.
			if int(trigger.conditions.get("seed", 0)) > 0: continue
			var reaction: Dictionary = Reactions.choose(trigger, {"statuses": {"seed": 1}})
			if reaction.is_empty(): continue
			var shared: bool = false
			for slot in Targeting.slots(str(seed.scope), int(setup.card.get("target_slot", 1))):
				var target: Dictionary = Targeting.at_slot(enemies, int(slot))
				if slot in Targeting.slots(str(trigger.scope), int(follow.card.get("target_slot", 1))) and not target.is_empty() and int(target.hp) > 0: shared = true
			if not shared: continue
			var before: bool = int(setup.priority) > int(follow.priority) or (int(setup.priority) == int(follow.priority) and int(setup.speed) > int(follow.speed))
			var equal: bool = int(setup.priority) == int(follow.priority) and int(setup.speed) == int(follow.speed)
			var note: String = reaction.name + ": semear antes de " + Content.NATURES[trigger.nature].name + ", se ambos executarem e a semente não for consumida antes."
			if equal: note = reaction.name + ": velocidades empatadas; não conte com a preparação no mesmo turno sem uma ordem definida."
			elif not before: note = reaction.name + ": " + Content.NATURES[trigger.nature].name + " vem antes de Semeadura; a reação exige Semeado já aplicado."
			if not note in notes: notes.append(note)
	return notes

static func _by_uid(roster: Array, uid: int) -> Dictionary:
	for individual in roster:
		if int(individual.uid) == uid: return individual
	return {}
