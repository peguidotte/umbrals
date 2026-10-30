class_name ExpeditionMap
extends Control
## Pure presentation of the fixed expedition route. Entering a node is always
## requested separately through Confirm; inspecting/selecting never mutates run state.
signal node_requested(id: String)
signal pause_requested
signal formation_requested
signal selection_changed(id: String)
signal control_created(control: Control, id: String)

const UI = preload("res://scripts/ui/kit.gd")
const Content = preload("res://scripts/content.gd")

const NODE_IDS: Array[String] = ["clearing", "thicket", "spring", "boss"]
const SLOT_NAMES: Array[String] = ["Superior", "Central", "Inferior"]

var _snapshot: Dictionary = {}
var _text_scale: float = 1.0
var _selected_id: String = ""
var _built_wide: bool = true
var _ui: UmbralUI
var _root: VBoxContainer
var _route_scroll: ScrollContainer
var _route_host: Control
var _node_buttons: Dictionary = {}
var _node_data: Dictionary = {}
var _confirm_button: Button
var _focus_before_rebuild: String = ""
var _population_rebuild_queued: bool = false

func _ready() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_responsive_rebuild.call_deferred()
	_focus_initial.call_deferred()

func populate(snapshot: Dictionary, text_scale: float, selected_id: String = "") -> void:
	_snapshot = snapshot.duplicate(true)
	_text_scale = maxf(0.8, text_scale)
	_selected_id = selected_id if _selection_available_in_snapshot(selected_id) else _default_selection()
	_ui = UI.new()
	_ui.text_scale = _text_scale
	if _root != null and is_inside_tree():
		if not _population_rebuild_queued:
			_population_rebuild_queued = true
			_rebuild_after_population.call_deferred()
		return
	_build()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready() and not _snapshot.is_empty():
		_responsive_rebuild.call_deferred()

func _responsive_rebuild() -> void:
	if _snapshot.is_empty():
		return
	var wide: bool = size.x >= 980.0 and size.y >= 560.0
	if _root == null or wide != _built_wide:
		_built_wide = wide
		var focus: Control = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
		_focus_before_rebuild = str(focus.get_meta("ui_id", "")) if is_instance_valid(focus) else ""
		if is_instance_valid(focus) and is_ancestor_of(focus):
			focus.release_focus()
		_build()
		if not _focus_before_rebuild.is_empty():
			_restore_focus.call_deferred(_focus_before_rebuild)
		_focus_before_rebuild = ""

func _rebuild_after_population() -> void:
	_population_rebuild_queued = false
	if not is_inside_tree() or _snapshot.is_empty():
		return
	var focus: Control = get_viewport().gui_get_focus_owner()
	var focus_id: String = str(focus.get_meta("ui_id", "")) if is_instance_valid(focus) and is_ancestor_of(focus) else ""
	if is_instance_valid(focus) and is_ancestor_of(focus):
		focus.release_focus()
	_build()
	if not focus_id.is_empty():
		_restore_focus.call_deferred(focus_id)

func _build() -> void:
	_root = UI.column(14)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.add_theme_constant_override("separation", int(14 * _text_scale))
	_root.add_theme_stylebox_override("panel", _ui.style(Color("101b20"), Color("57604d"), 16))
	var frame := PanelContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(_root)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	add_child(frame)
	theme = _ui.make_theme()
	_node_buttons.clear()
	_node_data.clear()

	var heading := UI.row(12)
	_root.add_child(heading)
	var title := _ui.label("TRILHA DA EXPEDIÇÃO", 30, UI.GOLD, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var biome: String = str(_snapshot.get("biome", "Bosque"))
	heading.add_child(_ui.label(biome, 18, UI.MUTED))
	control_created.emit(title, "map.title")

	_add_party_status()
	_add_inventory_status()
	_add_route()
	_add_selection_detail()
	_add_actions()
	if is_inside_tree():
		_apply_focus_order()
		var initial: Control = _node_buttons.get(_selected_id, _confirm_button)
		if is_instance_valid(initial) and not initial.has_focus():
			initial.grab_focus.call_deferred()

func _add_party_status() -> void:
	var party: Array = _snapshot.get("party", [])
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _ui.style(Color("172526"), Color("536453"), 9))
	_root.add_child(panel)
	var content := UI.column(5)
	panel.add_child(content)
	content.add_child(_ui.label("TIME · FORMAÇÃO E HP", 16, UI.GOLD))
	var members := HFlowContainer.new()
	members.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	members.add_theme_constant_override("h_separation", int(12 * _text_scale))
	members.add_theme_constant_override("v_separation", int(6 * _text_scale))
	content.add_child(members)
	if party.is_empty():
		members.add_child(_ui.label("Time indisponível", 17, UI.MUTED))
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
		var item := _ui.label("%s\n%s · %d/%d HP" % [str(individual.get("name", Content.display_name(individual))), state, hp, max_hp], 17, UI.PAPER)
		item.custom_minimum_size = Vector2(190.0 * _text_scale, 42.0 * _text_scale)
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		members.add_child(item)
		control_created.emit(item, "map.party.%s" % str(individual.get("uid", members.get_child_count())))

func _add_inventory_status() -> void:
	var inventory_variant: Variant = _snapshot.get("inventory", {})
	var inventory: Dictionary = inventory_variant if inventory_variant is Dictionary else {}
	var summary: Array[String] = []
	for item_id in inventory.keys():
		var quantity: int = int(inventory[item_id])
		if quantity > 0:
			summary.append("%s ×%d" % [_item_name(str(item_id)), quantity])
	var line: String = "MOCHILA · " + (" · ".join(summary) if not summary.is_empty() else "sem consumíveis")
	var label := _ui.label(line, 16, UI.MUTED)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root.add_child(label)
	control_created.emit(label, "map.inventory")
	var save_notice: String = str(_snapshot.get("save_notice", "")).strip_edges()
	if not save_notice.is_empty():
		var notice := _ui.paragraph(save_notice, 15, UI.MUTED)
		notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_root.add_child(notice)
		control_created.emit(notice, "map.save_notice")

func _add_route() -> void:
	_route_scroll = ScrollContainer.new()
	_route_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_route_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_route_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_route_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_route_scroll.custom_minimum_size.y = 190.0 * _text_scale
	_root.add_child(_route_scroll)
	if _built_wide:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", int(22 * _text_scale))
		_route_host = row
		_route_scroll.add_child(row)
		_add_wide_route(row)
	else:
		var column := UI.column(10)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_route_host = column
		_route_scroll.add_child(column)
		_add_vertical_route(column)

func _add_wide_route(row: HBoxContainer) -> void:
	var nodes: Dictionary = _nodes_by_id()
	var clearing := _depth_column("PARTIDA", [nodes.get("clearing", {})])
	var choices := _depth_column("CAMINHO", [nodes.get("thicket", {}), nodes.get("spring", {})])
	var boss := _depth_column("DESFECHO", [nodes.get("boss", {})])
	for column in [clearing, choices, boss]:
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.size_flags_stretch_ratio = 1.0
		row.add_child(column)

func _add_vertical_route(column: VBoxContainer) -> void:
	var nodes: Dictionary = _nodes_by_id()
	for entry in [["PARTIDA", "clearing"], ["CAMINHOS ALTERNATIVOS", "thicket", "spring"], ["DESFECHO", "boss"]]:
		var depth_nodes: Array[Dictionary] = []
		for i in range(1, entry.size()):
			depth_nodes.append(nodes.get(str(entry[i]), {}))
		column.add_child(_depth_column(str(entry[0]), depth_nodes))

func _depth_column(heading_text: String, entries: Array) -> VBoxContainer:
	var column := UI.column(8)
	column.add_theme_stylebox_override("panel", _ui.style(Color("142123", 0.88), Color("384e45"), 9))
	column.add_child(_ui.label(heading_text, 15, UI.GOLD))
	for entry_variant in entries:
		if not entry_variant is Dictionary or entry_variant.is_empty():
			continue
		var node: Dictionary = entry_variant
		var id: String = str(node.get("id", ""))
		if not NODE_IDS.has(id):
			continue
		_node_data[id] = node
		var button := _ui.button(_node_button_text(node, id == _selected_id), func(): _select_node(id), "map.node." + id)
		button.custom_minimum_size = Vector2(220 * _text_scale, 76 * _text_scale)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = bool(node.get("locked", false)) or not bool(node.get("available", false))
		button.add_theme_font_size_override("font_size", int(18 * _text_scale))
		column.add_child(button)
		_node_buttons[id] = button
		control_created.emit(button, "map.node." + id)
	return column

func _add_selection_detail() -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _ui.style(Color("101b20"), Color("736c4f"), 10))
	_root.add_child(panel)
	var content := UI.column(4)
	panel.add_child(content)
	var detail := _ui.paragraph(_selected_summary(), 17, UI.PAPER)
	detail.name = "SelectionDetail"
	content.add_child(detail)
	control_created.emit(detail, "map.selection.detail")

func _add_actions() -> void:
	var actions := UI.row(12)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.add_child(actions)
	actions.add_child(UI.spacer())
	var formation := _ui.button("FORMAÇÃO", func(): formation_requested.emit(), "map.formation")
	formation.custom_minimum_size = Vector2(170 * _text_scale, 58 * _text_scale)
	actions.add_child(formation)
	control_created.emit(formation, "map.formation")
	var pause := _ui.button("PAUSAR", func(): pause_requested.emit(), "map.pause")
	pause.custom_minimum_size = Vector2(150 * _text_scale, 58 * _text_scale)
	actions.add_child(pause)
	control_created.emit(pause, "map.pause")
	_confirm_button = _ui.button("SEGUIR CAMINHO", _confirm_selection, "map.confirm", true)
	_confirm_button.custom_minimum_size = Vector2(250 * _text_scale, 58 * _text_scale)
	_confirm_button.disabled = not _is_selected_available()
	actions.add_child(_confirm_button)
	control_created.emit(_confirm_button, "map.confirm")

func _apply_focus_order() -> void:
	if not is_inside_tree():
		return
	var controls: Array[Control] = []
	for id in NODE_IDS:
		var button: Button = _node_buttons.get(id)
		if is_instance_valid(button) and not button.disabled:
			controls.append(button)
	if is_instance_valid(_confirm_button):
		controls.append(_confirm_button)
	for child in _root.find_children("*", "Button", true, false):
		var button: Button = child
		if str(button.get_meta("ui_id", "")) in ["map.formation", "map.pause"]:
			controls.append(button)
	UI.focus_chain(controls)

func _focus_initial() -> void:
	if not is_inside_tree() or _snapshot.is_empty():
		return
	_apply_focus_order()
	var initial: Control = _node_buttons.get(_selected_id, _confirm_button)
	if is_instance_valid(initial) and not initial.has_focus():
		initial.grab_focus()

func _select_node(id: String) -> void:
	if not _node_data.has(id) or not _is_node_available(_node_data[id]):
		return
	_selected_id = id
	for node_id in _node_buttons:
		var button: Button = _node_buttons[node_id]
		button.text = _node_button_text(_node_data[node_id], node_id == id)
	if is_instance_valid(_confirm_button):
		_confirm_button.disabled = not _is_selected_available()
	var detail: Label = find_child("SelectionDetail", true, false) as Label
	if is_instance_valid(detail):
		detail.text = _selected_summary()
	selection_changed.emit(id)

func _confirm_selection() -> void:
	if _is_selected_available():
		node_requested.emit(_selected_id)

func _default_selection() -> String:
	var nodes: Dictionary = _nodes_by_id()
	for id in NODE_IDS:
		var node: Dictionary = nodes.get(id, {})
		if bool(node.get("available", false)) and not bool(node.get("locked", false)):
			return id
	return "clearing" if nodes.has("clearing") else ""

func _selection_available_in_snapshot(id: String) -> bool:
	if id.is_empty():
		return false
	var node: Dictionary = _nodes_by_id().get(id, {})
	return not node.is_empty() and _is_node_available(node) and not bool(node.get("completed", false))

func _is_selected_available() -> bool:
	if not _node_data.has(_selected_id):
		return false
	var node: Dictionary = _node_data[_selected_id]
	return bool(node.get("available", false)) and not bool(node.get("locked", false)) and not bool(node.get("completed", false))

func _nodes_by_id() -> Dictionary:
	var result: Dictionary = {}
	for variant in _snapshot.get("nodes", []):
		if variant is Dictionary:
			result[str(variant.get("id", ""))] = variant
	return result

func _node_button_text(node: Dictionary, selected: bool = false) -> String:
	var id: String = str(node.get("id", ""))
	var title: String = str(node.get("title", id.capitalize()))
	var state: String = "CONCLUÍDO" if bool(node.get("completed", false)) else ("ROTA NÃO ESCOLHIDA" if _is_unchosen_route(id) else ("DISPONÍVEL" if bool(node.get("available", false)) and not bool(node.get("locked", false)) else "BLOQUEADO"))
	var kind: String = str(node.get("kind", "battle"))
	var type_label: String = "DESCANSO" if kind == "rest" else ("CHEFE · COMBATE" if kind == "boss" else "COMBATE")
	var prefix: String = "◆ " if selected else ""
	return "%s%s\n%s · %s" % [prefix, title, type_label, state]

func _selected_summary() -> String:
	var node: Dictionary = _node_data.get(_selected_id, _nodes_by_id().get(_selected_id, {}))
	if node.is_empty():
		return "Selecione um ponto da trilha para ver seus detalhes."
	var kind: String = str(node.get("kind", "battle"))
	var detail: String = str(node.get("description", ""))
	if kind == "rest":
		detail = "Descanso: cura 25% do HP máximo dos integrantes vivos. Custo: abrir mão do combate e de sua recompensa."
	else:
		if kind == "boss":
			detail = "Combate de chefe: há risco de dano e incapacitação. Vencer conclui a expedição."
		else:
			detail = "Combate: há risco de dano e incapacitação. Vitória oferece a recompensa normal do encontro."
		if kind != "boss" and not str(node.get("description", "")).is_empty():
			detail += " " + str(node.description)
	var state: String = "Concluído" if bool(node.get("completed", false)) else ("Disponível" if _is_node_available(node) else "Bloqueado")
	return "%s · %s\n%s" % [str(node.get("title", "Nó")), state, detail]

func _is_node_available(node: Dictionary) -> bool:
	return bool(node.get("available", false)) and not bool(node.get("locked", false))

func _is_unchosen_route(id: String) -> bool:
	if id not in ["thicket", "spring"]:
		return false
	var sibling_id: String = "spring" if id == "thicket" else "thicket"
	var sibling: Dictionary = _nodes_by_id().get(sibling_id, {})
	return bool(sibling.get("completed", false))

func _item_name(item_id: String) -> String:
	match item_id:
		"potion": return "Poção"
		"revive": return "Reanimação"
		_: return item_id.capitalize()

func _restore_focus(ui_id: String) -> void:
	if not is_inside_tree():
		return
	var controls := find_children("*", "Control", true, false)
	for candidate in controls:
		if str(candidate.get_meta("ui_id", "")) == ui_id and candidate.focus_mode != Control.FOCUS_NONE:
			if candidate is BaseButton and (candidate as BaseButton).disabled:
				continue
			(candidate as Control).grab_focus()
			return
	var fallback: Control = _node_buttons.get(_selected_id, _confirm_button)
	if is_instance_valid(fallback):
		fallback.grab_focus()
