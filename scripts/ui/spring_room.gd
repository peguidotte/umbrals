extends Control
## A contextual route stop. Drafts are view-local and never mutate the expedition.
signal control_created(control: Control, id: String)
signal event_requested(choice: String, details: Dictionary)
signal pause_requested
const UI = preload("res://scripts/ui/kit.gd")
const Content = preload("res://scripts/content.gd")
const Practice = preload("res://scripts/battle/technique_practice.gd")
const Status = preload("res://scripts/ui/expedition_status.gd")
var ui = UI.new()
var snapshot: Dictionary
var draft: Dictionary = {}
var choice: String = ""
var details: VBoxContainer
var confirmation: Label
var confirm_button: Button
var cancel_button: Button

func populate(data: Dictionary, text_scale: float) -> void:
	snapshot = data.duplicate(true)
	ui.text_scale = text_scale

func _ready() -> void:
	theme = ui.make_theme()
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ui.style(UI.INK, UI.GOLD, 20))
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column: VBoxContainer = UI.column(14)
	panel.add_child(column)
	var header: HBoxContainer = UI.row(16)
	column.add_child(header)
	var title: Label = ui.label("NASCENTE", 34, UI.GOLD, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var pause: Button = _button(header, "PAUSAR", pause_requested.emit, "map.pause")
	pause.size_flags_horizontal = Control.SIZE_SHRINK_END
	pause.custom_minimum_size.x = 170 * ui.text_scale
	var context = PanelContainer.new()
	context.add_theme_stylebox_override("panel", ui.style(UI.SURFACE, UI.BORDER, 12))
	column.add_child(context)
	var scene_row: HBoxContainer = UI.row(20)
	context.add_child(scene_row)
	var picture = TextureRect.new()
	picture.texture = UI.Assets.texture("attacks/rain")
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(100, 100)
	scene_row.add_child(picture)
	var prose: VBoxContainer = UI.column(6)
	prose.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene_row.add_child(prose)
	prose.add_child(ui.label("Uma pausa no caminho", 26, UI.PAPER, true))
	prose.add_child(ui.paragraph("O som da água acompanha os gestos dos Umbrais. O grupo pode descansar ou usar este intervalo para praticar uma técnica antes de seguir ao guardião.", 20))
	# Stay outside the scrolling draft so a failed checkpoint cannot be hidden
	# by choosing techniques, canceling, or changing text size.
	Status.add_save_notice(column, snapshot, ui, control_created.emit)
	var actions: HBoxContainer = UI.row(16)
	column.add_child(actions)
	_button(actions, "DESCANSAR\nRecuperar até 25% do HP máximo", _choose.bind("rest"), "event.rest")
	var practice: Button = _button(actions, "PRATICAR\nRedistribuir 1 cópia; abrir mão da cura", _choose.bind("practice"), "event.practice")
	practice.disabled = snapshot.event.practice.is_empty()
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	details = UI.column(10)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(details)
	confirmation = ui.paragraph("Escolha como passar este intervalo. Só a confirmação aplica a decisão.", 20, UI.PAPER)
	column.add_child(confirmation)
	var footer: HBoxContainer = UI.row(14)
	column.add_child(footer)
	cancel_button = _button(footer, "CANCELAR ESCOLHA", _choose.bind(""), "event.cancel")
	confirm_button = _button(footer, "CONFIRMAR E SEGUIR", _confirm, "event.confirm", true)
	_refresh()

func _button(parent: Node, text: String, callback: Callable, key: String, primary: bool = false) -> Button:
	var button: Button = ui.button(text, callback, key, primary)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 56 * ui.text_scale
	parent.add_child(button)
	control_created.emit(button, key)
	return button

func _choose(next_choice: String) -> void:
	choice = next_choice
	draft = {}
	_refresh("event." + (next_choice if not next_choice.is_empty() else "rest"))

func _select(field: String, value: Variant) -> void:
	draft[field] = value
	if field == "uid":
		draft.erase("from_power")
		draft.erase("to_power")
	elif field == "from_power": draft.erase("to_power")
	_refresh("event.%s.%s" % [field, str(value)])

func _refresh(focus_key: String = "event.rest") -> void:
	for child in details.get_children():
		details.remove_child(child)
		child.queue_free()
	confirm_button.disabled = true
	cancel_button.disabled = choice.is_empty()
	if choice == "rest":
		for unit in snapshot.party:
			var after: int = mini(int(unit.max_hp), int(unit.hp) + ceili(float(unit.max_hp) * 0.25)) if int(unit.hp) > 0 else 0
			details.add_child(ui.paragraph("%s #%d · HP %d → %d / %d" % [Content.display_name(unit), int(unit.uid), int(unit.hp), after, int(unit.max_hp)], 21, UI.PAPER))
		confirmation.text = "Descansar recupera os aliados vivos. Incapacitados continuam a 0 HP. As cópias permanecem iguais."
		confirm_button.text = "DESCANSAR E SEGUIR"
		confirm_button.disabled = false
	elif choice == "practice":
		_practice_details()
	else:
		details.add_child(ui.paragraph("A trilha da Mata fechada ficou para trás. Aqui, o intervalo permite uma única escolha antes do guardião.", 22))
		if snapshot.event.practice.is_empty(): details.add_child(ui.paragraph("Nenhum aliado vivo pode redistribuir cópias agora. O descanso continua disponível.", 20))
		confirmation.text = "Escolha como passar este intervalo. Só a confirmação aplica a decisão."
		confirm_button.text = "CONFIRMAR E SEGUIR"
	_focus.call_deferred(focus_key)

func _practice_details() -> void:
	details.add_child(ui.paragraph("1 · Quem pratica?", 22, UI.GOLD))
	var owners: HFlowContainer = HFlowContainer.new()
	details.add_child(owners)
	for option in snapshot.event.practice:
		var unit: Dictionary = _unit(int(option.uid))
		var owner_button: Button = _button(owners, ("✓ " if draft.get("uid") == option.uid else "") + "%s #%d" % [Content.display_name(unit), int(option.uid)], _select.bind("uid", int(option.uid)), "event.uid.%d" % int(option.uid))
		owner_button.icon = UI.BattleArt.texture(Content.art_binding(unit))
		owner_button.expand_icon = true
		owner_button.add_theme_constant_override("icon_max_width", 44)
	confirmation.text = "Escolha um aliado vivo e duas técnicas já conhecidas dele. A prática preserva dono e total de cartas; vale só nesta expedição."
	confirm_button.text = "PRATICAR E SEGUIR"
	if not draft.has("uid"): return
	var unit: Dictionary = _unit(int(draft.uid))
	var counts: Dictionary = Practice.counts(unit)
	details.add_child(ui.paragraph("2 · Retirar uma cópia de qual técnica? Mínimo: 1.", 22, UI.GOLD))
	var donors: HFlowContainer = HFlowContainer.new()
	details.add_child(donors)
	for power in counts:
		if counts[power] <= Practice.MIN_COPIES: continue
		_button(donors, ("✓ " if draft.get("from_power") == power else "") + "%s · %d → %d" % [_power_name(power), counts[power], counts[power] - 1], _select.bind("from_power", str(power)), "event.from_power." + power)
	if not draft.has("from_power"): return
	details.add_child(ui.paragraph("3 · Reforçar qual técnica? Máximo: 3.", 22, UI.GOLD))
	var targets: HFlowContainer = HFlowContainer.new()
	details.add_child(targets)
	for power in counts:
		if power == draft.from_power or counts[power] >= Practice.MAX_COPIES: continue
		_button(targets, ("✓ " if draft.get("to_power") == power else "") + "%s · %d → %d" % [_power_name(power), counts[power], counts[power] + 1], _select.bind("to_power", str(power)), "event.to_power." + power)
	if not Practice.valid(snapshot.party, draft): return
	confirmation.text = "%s #%d · %s %d → %d; %s %d → %d. Total: %d → %d cartas. HP: %d → %d (sem cura)." % [Content.display_name(unit), int(unit.uid), _power_name(draft.from_power), counts[draft.from_power], counts[draft.from_power] - 1, _power_name(draft.to_power), counts[draft.to_power], counts[draft.to_power] + 1, unit.cards.size(), unit.cards.size(), int(unit.hp), int(unit.hp)]
	confirm_button.disabled = false

func _power_name(power: String) -> String:
	return str(Content.POWERS[power].name).replace("\n", " ")

func _unit(uid: int) -> Dictionary:
	for unit in snapshot.party:
		if int(unit.uid) == uid: return unit
	return {}

func _focus(key: String) -> void:
	if not is_inside_tree(): return
	var controls: Array = []
	for control in find_children("*", "Button", true, false):
		if not control.disabled and control.is_visible_in_tree(): controls.append(control)
	UI.focus_chain(controls)
	for control in controls:
		if control.get_meta("ui_id", "") == key:
			control.grab_focus()
			return
	if not controls.is_empty(): controls[0].grab_focus()

func _confirm() -> void:
	if not confirm_button.disabled: event_requested.emit(choice, draft.duplicate(true))
