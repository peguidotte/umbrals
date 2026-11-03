extends "res://scripts/ui/screens/screen_view.gd"
const Rules = preload("res://scripts/rules.gd")
const Models = preload("res://scripts/domain/models.gd")
const Content = preload("res://scripts/content.gd")
var menu_stats: Label
var statistics: Dictionary

func build(values: Dictionary) -> void:
	statistics = values
	name = "TitleScreen"
	var column: VBoxContainer = UI.column(14)
	self.add_child(column)
	column.anchor_left = 0.12
	column.anchor_right = 0.12
	column.anchor_top = 0.16
	column.anchor_bottom = 0.86
	column.offset_right = 650
	column.add_child(ui.label("U M B R A L", 78, UI.tokens.paper, true))
	column.add_child(ui.label("E C O S   D O   B O S Q U E", 22, UI.tokens.gold))
	var breathing = Control.new()
	breathing.custom_minimum_size.y = 20
	column.add_child(breathing)
	var primary: Button = _button(column, "INICIAR EXPEDIÇÃO", request.bind("start_game", 42013), "menu.play", Ids.MENU, true)
	primary.custom_minimum_size.x = 410
	_button(column, "GRIMÓRIO DOS UMBRALS", request.bind("push", Ids.CODEX), "menu.codex", Ids.MENU)
	_button(column, "OPÇÕES", request.bind("push", Ids.SETTINGS), "menu.settings", Ids.MENU)
	_button(column, "COMO JOGAR", request.bind("push", Ids.HELP), "menu.help", Ids.MENU)
	_button(column, "CRÉDITOS", request.bind("push", Ids.CREDITS), "menu.credits", Ids.MENU)
	if not OS.has_feature("web"):
		_button(column, "SAIR", request.bind("quit"), "menu.quit", Ids.MENU)
	column.add_child(ui.paragraph("Três clareiras. Poderes próprios.\nUm vínculo que muda o destino.", 22, UI.tokens.muted))
	for child in column.get_children():
		if child is Button:
			child.alignment = HORIZONTAL_ALIGNMENT_LEFT
			child.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			child.custom_minimum_size.x = 450
			child.add_theme_font_size_override("font_size", int(24 * preferences.text_scale()))
			if child != primary:
				child.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
				child.add_theme_stylebox_override("hover", ui.style(Color(0.035, 0.07, 0.075, 0.45), Color.TRANSPARENT))
	var hero: TextureRect = UI.image(Content.SPECIES["ember"].form("ignivar").presentation.right.portrait_path, Vector2(390, 390))
	_at(hero, self, Vector2(0.76, 0.57), Vector2(390, 390))
	menu_stats = ui.label("", 18, UI.tokens.muted)
	self.add_child(menu_stats)
	menu_stats.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	menu_stats.offset_left = 34
	menu_stats.offset_top = -37
	menu_stats.offset_right = 800
	set_stats(statistics)
	var version: Label = ui.label("v" + Content.VERSION, 18, UI.tokens.gold)
	self.add_child(version)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.offset_left = -140
	version.offset_top = -37
	version.offset_right = -30
	navigation.set_group(Ids.MENU)

func set_stats(values: Dictionary) -> void:
	menu_stats.text = "%d vitórias  ·  %d expedições  ·  novos instintos a cada semente" % [values.wins, values.runs]
