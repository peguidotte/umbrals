extends "res://scripts/ui/screens/modal_view.gd"
## Static definitions are read-only. Every change is an intent to the session command boundary.

func render_screen() -> void:
	var body: VBoxContainer = _modal_frame("Bolsa da expedição", "Fôlego %d/%d · Itens e equipamento não avançam a rodada." % [game.player_hp, game.max_hp], 1000)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 420
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	body.add_child(scroll)
	var list: VBoxContainer = UI.column(16)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for item in game.inventory.items:
		var definition = item.definition
		list.add_child(ui.label("%s  ×%d" % [definition.display_name, item.quantity], 26, UI.tokens.gold, true))
		list.add_child(ui.paragraph(definition.description, 20))
		if definition.kind == "consumable":
			var outcome = game.inventory.preview_use(item.instance_id, game.combat_state())
			var label: String = "USAR" if outcome != null else "SEM EFEITO AGORA" if item.quantity > 0 else "ESGOTADO"
			if outcome != null: label += " · +%d FÔLEGO" % outcome.total("heal", "player")
			var use: Button = _button(list, label, request.bind("use_item", item.instance_id), "inventory.use.%d" % item.instance_id, screen)
			use.disabled = outcome == null or game.phase != Ids.BATTLE
		else:
			var equipped = game.umbral_by_uid(item.equipped_uid)
			list.add_child(ui.label("Equipado: " + (game.catalog.display_name(equipped) if equipped != null else "ninguém"), 20))
			var row = HFlowContainer.new()
			row.add_theme_constant_override("h_separation", 12)
			row.add_theme_constant_override("v_separation", 12)
			list.add_child(row)
			for individual in game.party:
				var button: Button = _button(row, game.catalog.display_name(individual), request.bind("equip_item", [item.instance_id, individual.uid]), "inventory.equip.%d.%d" % [item.instance_id, individual.uid], screen)
				button.disabled = item.equipped_uid == individual.uid or item.quantity <= 0
			var remove: Button = _button(row, "RETIRAR", request.bind("equip_item", [item.instance_id, -1]), "inventory.remove.%d" % item.instance_id, screen)
			remove.disabled = item.equipped_uid == -1
	_button(body, "VOLTAR", request.bind("pop"), "inventory.back", screen, true)
