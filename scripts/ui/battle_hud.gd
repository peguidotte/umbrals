extends Control
const Assets = preload("res://scripts/assets/catalog.gd")
## Battle composition and controls. Emits commands; never reads or mutates rules.
signal command_requested(command: String)
signal slot_requested(side: String, slot: int)
signal control_created(control: Control, key: String)
const UI = preload("res://scripts/ui/kit.gd")
const Actor = preload("res://scripts/ui/actor.gd")
const Effects = preload("res://scripts/ui/effects.gd")
const Hand = preload("res://scripts/ui/hand.gd")
var ui: RefCounted
var visual_layer: Control
var effects: Control
var actors: Array = []
var enemy_actors: Array = []
var reserve_buttons: Array = []
var hud_panel: PanelContainer
var round_label: Label
var progress_label: Label
var preview_label: Label
var notice_label: Label
var hand_view: Container
var energy_label: Label
var cast_button: Button
var redraw_button: Button
var plan_button: Button
var draw_label: Button
var discard_label: Button
var history_button: Button
var phase_label: Label
var command_strip: HBoxContainer
var command_buttons: Array = []

func build(user_interface: RefCounted, safe_margin: Callable) -> void:
	ui = user_interface
	name = "BattleScreen"
	visual_layer = Control.new()
	visual_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full(visual_layer, self)
	visual_layer.anchor_bottom = 1.0
	visual_layer.offset_bottom = -254
	for side in ["ally", "enemy"]:
		for slot in range(3):
			var actor = Actor.new()
			actor.enemy = side == "enemy"
			actor.slot = slot
			var x: float = (0.255 if slot == 1 else 0.235) if side == "ally" else (0.745 if slot == 1 else 0.765)
			_at(actor, visual_layer, Vector2(x, [0.18, 0.51, 0.84][slot]), Vector2(260, 210))
			control_created.emit(actor, ("party." if side == "ally" else "enemy.") + str(slot))
			actor.pressed.connect(func(): slot_requested.emit(side, slot))
			if side == "ally": actors.append(actor)
			else: enemy_actors.append(actor)
	effects = Effects.new()
	_full(effects, self)
	effects.visual_layer = visual_layer
	var top_margin = MarginContainer.new()
	self.add_child(top_margin)
	top_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_margin.offset_top = 18
	top_margin.offset_bottom = 65
	safe_margin.call(top_margin)
	var top: HBoxContainer = UI.row(12)
	top_margin.add_child(top)
	round_label = ui.label("", 20, UI.GOLD)
	top.add_child(round_label)
	progress_label = ui.label("", 17, UI.MUTED)
	top.add_child(progress_label)
	top.add_child(UI.spacer())
	_button(top, "GUIA", "help", "hud.help").custom_minimum_size = Vector2(95, 42)
	_button(top, "Ⅱ", "pause", "hud.pause").custom_minimum_size = Vector2(62, 42)
	phase_label = ui.label("PLANEJAMENTO", 18, UI.GOLD, false, true)
	_at(phase_label, self, Vector2(0.5, 0), Vector2(640, 28))
	phase_label.offset_top = 20
	phase_label.offset_bottom = 48
	command_strip = UI.row(8)
	_at(command_strip, self, Vector2(0.5, 0), Vector2(600, 86))
	command_strip.offset_top = 66
	command_strip.offset_bottom = 152
	for i in range(3):
		var command: Button = _button(command_strip, "", "plan", "hud.command.%d" % i)
		command.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		command.clip_text = true
		command.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		command.add_theme_font_size_override("font_size", int(16 * ui.text_scale))
		for state in ["normal", "hover", "pressed"]:
			command.add_theme_stylebox_override(state, ui.style(Color("102233"), Color("566283"), 8))
		command_buttons.append(command)
	var hints: VBoxContainer = UI.column(2)
	_at(hints, self, Vector2(0.5, 1), Vector2(600, 48))
	hints.offset_top = -296
	hints.offset_bottom = -248
	preview_label = ui.label("", 18, UI.PAPER, false, true)
	preview_label.clip_text = true
	preview_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hints.add_child(preview_label)
	notice_label = ui.label("", 15, UI.MUTED, false, true)
	hints.add_child(notice_label)
	hud_panel = PanelContainer.new()
	self.add_child(hud_panel)
	hud_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hud_panel.offset_top = -242
	hud_panel.add_theme_stylebox_override("panel", ui.style(Color("081523"), Color("566283"), 12))
	var hud: HBoxContainer = UI.row(15)
	hud_panel.add_child(hud)
	var reserves: VBoxContainer = UI.column(8)
	reserves.custom_minimum_size.x = 207
	hud.add_child(reserves)
	reserves.add_child(ui.label("RESERVAS", 16, UI.MUTED))
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	reserves.add_child(grid)
	for i in range(6):
		var button: Button = _button(grid, "—", "reserve.%d" % i, "reserve.%d" % i)
		button.custom_minimum_size = Vector2(65, 76)
		button.add_theme_font_size_override("font_size", 12)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 42)
		for state in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, ui.style(Color("0c1b2d"), Color("4d5c7b"), 2))
		reserve_buttons.append(button)
	hand_view = Hand.new()
	hand_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_view.custom_minimum_size = Vector2(540, 208)
	hud.add_child(hand_view)
	var actions: VBoxContainer = UI.column(9)
	actions.custom_minimum_size.x = 211
	hud.add_child(actions)
	energy_label = ui.label("", 18, UI.GOLD, false, true)
	actions.add_child(energy_label)
	cast_button = _button(actions, "CONJURAR", "cast", "hud.cast", true)
	cast_button.custom_minimum_size.y = 64
	cast_button.add_theme_stylebox_override("normal", ui.style(Color("ef987b"), UI.GOLD, 12))
	cast_button.add_theme_stylebox_override("hover", ui.style(Color("ffb497"), UI.PAPER, 12))
	cast_button.add_theme_stylebox_override("pressed", ui.style(Color("d98266"), UI.GOLD, 12))
	redraw_button = _button(actions, "RESORTEAR", "redraw", "hud.redraw")
	redraw_button.custom_minimum_size.y = 56
	redraw_button.add_theme_font_size_override("font_size", int(17 * ui.text_scale))
	for state in ["normal", "hover", "pressed"]:
		redraw_button.add_theme_stylebox_override(state, ui.style(Color("10201f"), Color("57604d"), 4))
	redraw_button.tooltip_text = "Descarta a mão inteira e passa a rodada. Os inimigos executam suas intenções."
	var tools: HBoxContainer = UI.row(6)
	actions.add_child(tools)
	plan_button = _button(tools, "PLANO", "plan", "hud.plan")
	history_button = _button(tools, "RESUMO", "history", "hud.history")
	for tool in [plan_button, history_button]:
		tool.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tool.clip_text = true
		tool.custom_minimum_size.y = 35
		tool.add_theme_font_size_override("font_size", 15)
		for state in ["normal", "hover", "pressed"]:
			tool.add_theme_stylebox_override(state, ui.style(Color("102233"), Color("566283"), 4))
	var pile_column: VBoxContainer = UI.column(10)
	pile_column.custom_minimum_size.x = 112
	hud.add_child(pile_column)
	var pouch: Button = _button(pile_column, "", "pouch", "hud.backpack")
	pouch.icon = Assets.texture("ui/backpack")
	pouch.expand_icon = true
	pouch.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	pouch.add_theme_constant_override("icon_max_width", 47)
	pouch.tooltip_text = "MOCHILA · consumíveis. Consultar não gasta ações."
	pouch.custom_minimum_size.y = 70
	pouch.add_theme_font_size_override("font_size", 15)
	draw_label = _button(pile_column, "", "draw", "hud.draw")
	discard_label = _button(pile_column, "", "discard", "hud.discard")
	for pile in [draw_label, discard_label]:
		pile.add_theme_font_size_override("font_size", 16)
		pile.custom_minimum_size.y = 52
		pile.tooltip_text = "Consultar os poderes nesta pilha é grátis. A ordem da compra não é revelada."
		for state in ["normal", "hover", "pressed"]:
			pile.add_theme_stylebox_override(state, ui.style(Color("0c1b2d"), Color("4d5c7b"), 2))

func _button(parent: Node, text: String, command: String, key: String, primary: bool = false) -> Button:
	var button: Button = ui.button(text, func(): command_requested.emit(command), key, primary)
	parent.add_child(button)
	control_created.emit(button, key)
	return button

func _full(node: Control, parent: Node) -> void:
	parent.add_child(node)
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _at(node: Control, parent: Control, anchor: Vector2, extent: Vector2) -> void:
	parent.add_child(node)
	node.anchor_left = anchor.x
	node.anchor_right = anchor.x
	node.anchor_top = anchor.y
	node.anchor_bottom = anchor.y
	node.offset_left = -extent.x * 0.5
	node.offset_right = extent.x * 0.5
	node.offset_top = -extent.y * 0.5
	node.offset_bottom = extent.y * 0.5
