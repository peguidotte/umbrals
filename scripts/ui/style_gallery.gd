extends Control
## Authoring scene for native and custom component states; no expedition is started.
const UI = preload("res://scripts/ui/kit.gd")
const Rules = preload("res://scripts/rules.gd")
const Models = preload("res://scripts/domain/models.gd")
const Card = preload("res://scripts/ui/power_card.gd")
const Vitals = preload("res://scripts/ui/vitals.gd")
var ui: UI = UI.new()
var large: bool = false
var panel: VBoxContainer

func _ready() -> void:
	build()

func build() -> void:
	if is_instance_valid(panel):
		remove_child(panel)
		panel.queue_free()
	ui.text_scale = 1.12 if large else 1.0
	theme = ui.make_theme()
	panel = UI.column(22)
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 70
	panel.offset_top = 40
	panel.offset_right = -70
	panel.offset_bottom = -40
	panel.add_child(ui.label("Componentes do bosque", 38, UI.tokens.paper, true))
	panel.add_child(ui.paragraph("Theme e desenho customizado usam content/styles/moonlit.tres · normal, selecionado, foco e desabilitado.", 21))
	var row: HBoxContainer = UI.row(20)
	panel.add_child(row)
	row.add_child(ui.button("NORMAL", func(): pass, "gallery.normal"))
	row.add_child(ui.button("PRIMÁRIO", func(): pass, "gallery.primary", true))
	var disabled: Button = ui.button("DESABILITADO", func(): pass, "gallery.disabled")
	disabled.disabled = true
	row.add_child(disabled)
	row.add_child(UI.spacer())
	row.add_child(ui.button("TEXTO AMPLIADO" if not large else "TEXTO PADRÃO", toggle, "gallery.large"))
	var states: HBoxContainer = UI.row(40)
	panel.add_child(states)
	var individual = Rules.make_umbral("ember", "fierce", 1)
	var team: Array[Models.Individual] = [individual]
	var focus: Card
	for index in range(4):
		var column: VBoxContainer = UI.column(12)
		states.add_child(column)
		column.add_child(ui.label(["Normal", "Selecionado", "Foco", "Desabilitado"][index], 22))
		var frame = Control.new()
		frame.custom_minimum_size = UI.tokens.card.size + Vector2(20, 55)
		column.add_child(frame)
		var card = Card.new()
		frame.add_child(card)
		card.configure(Models.CardInstance.new("fireball", 1, index), individual, team, ui.text_scale, true)
		card.size = UI.tokens.card.size
		card.place(Vector2(10, 40), 0)
		card.set_chosen(index == 1)
		card.disabled = index == 3
		if index == 2: focus = card
	var vital = Vitals.new()
	vital.custom_minimum_size = Vector2(360, 90)
	panel.add_child(vital)
	vital.text_scale = ui.text_scale
	vital.update_health(28, 40, 19)
	panel.add_child(ui.paragraph("A borda indica o foco; o visto indica seleção. A barra mostra a previsão de fôlego. A galeria usa movimento reduzido para comparação estática.", 22))
	focus.grab_focus.call_deferred()

func toggle() -> void:
	large = not large
	build()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UI.tokens.ink)
