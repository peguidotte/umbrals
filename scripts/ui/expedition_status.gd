extends RefCounted
## Presentation of expedition party, inventory and save status.

const UI = preload("res://scripts/ui/kit.gd")
const Content = preload("res://scripts/content.gd")
const SLOT_NAMES: Array[String] = ["Superior", "Central", "Inferior"]

static func add_party_status(root: VBoxContainer, snapshot: Dictionary, text_scale: float, ui: UmbralUI, register: Callable) -> void:
	var party: Array = snapshot.get("party", [])
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", ui.style(UI.SURFACE, UI.BORDER, 9))
	root.add_child(panel)
	var content := UI.column(5)
	panel.add_child(content)
	content.add_child(ui.label("TIME · FORMAÇÃO E HP", 16, UI.GOLD))
	var members := HFlowContainer.new()
	members.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	members.add_theme_constant_override("h_separation", int(12 * text_scale))
	members.add_theme_constant_override("v_separation", int(6 * text_scale))
	content.add_child(members)
	if party.is_empty():
		members.add_child(ui.label("Time indisponível", 17, UI.MUTED))
		return
	for individual_variant in party:
		if not individual_variant is Dictionary:
			continue
		var individual: Dictionary = individual_variant
		var hp: int = int(individual.get("hp", 0))
		var max_hp: int = maxi(1, int(individual.get("max_hp", individual.get("hp_max", 1))))
		var slot: int = int(individual.get("slot", -1))
		var active: bool = slot >= 0
		var state: String = (SLOT_NAMES[clampi(slot, 0, 2)] if active else "Reserva")
		if hp <= 0:
			state = "Incapacitado"
		var portrait_row := UI.row(8)
		members.add_child(portrait_row)
		portrait_row.add_child(UI.art(Content.art_binding(individual), Vector2(48, 48)))
		var item := ui.label("%s\n%s · %d/%d HP" % [str(individual.get("name", Content.display_name(individual))) + " · " + str(individual.uid), state, hp, max_hp], 17, UI.PAPER)
		item.custom_minimum_size = Vector2(155.0 * text_scale, 42.0 * text_scale)
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		portrait_row.add_child(item)
		register.call(item, "map.party.%s" % str(individual.get("uid", members.get_child_count())))

static func add_inventory_status(root: VBoxContainer, snapshot: Dictionary, ui: UmbralUI, register: Callable) -> void:
	var inventory_variant: Variant = snapshot.get("inventory", {})
	var inventory: Dictionary = inventory_variant if inventory_variant is Dictionary else {}
	var summary: Array[String] = []
	for item_id in inventory.keys():
		var quantity: int = int(inventory[item_id])
		if quantity > 0:
			summary.append("%s ×%d" % [item_name(str(item_id)), quantity])
	var line: String = "MOCHILA · " + (" · ".join(summary) if not summary.is_empty() else "sem consumíveis")
	var label := ui.label(line, 16, UI.MUTED)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(label)
	register.call(label, "map.inventory")
	var save_notice: String = str(snapshot.get("save_notice", "")).strip_edges()
	if not save_notice.is_empty():
		var notice := ui.paragraph(save_notice, 15, UI.MUTED)
		notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		root.add_child(notice)
		register.call(notice, "map.save_notice")

static func item_name(item_id: String) -> String:
	match item_id:
		"potion": return "Poção"
		"revive": return "Reanimação"
		_: return str(Content.CONSUMABLES.get(item_id, {}).get("name", item_id.capitalize()))

