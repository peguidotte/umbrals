class_name UmbralJourneyMenu
extends Control
## Receives only public checkpoint information; never reads or writes storage.
const UI = preload("res://scripts/ui/kit.gd")
const PlateButton = preload("res://scripts/ui/title_button.gd")
const TitleTheme = preload("res://scripts/ui/title_theme.gd")
const Content = preload("res://scripts/content.gd")
var continue_button: Button
var notice: Label
var panel: PanelContainer
var scroller: ScrollContainer
var public_checkpoint: Dictionary = {}
var choices: Array[Button] = []
var requested_text_scale: float = 1.0

func build(kit: RefCounted, saved: Dictionary, save_message: String, callbacks: Array[Callable], register: Callable, reduced: bool) -> void:
	name = "Overlay_journey"
	public_checkpoint = saved.duplicate(true)
	requested_text_scale = kit.text_scale
	theme = TitleTheme.make_theme(kit.make_theme())
	var shade = ColorRect.new()
	shade.color = Color(0.015, 0.009, 0.035, 0.5)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = PanelContainer.new()
	add_child(panel)
	scroller = ScrollContainer.new()
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroller)
	var body: VBoxContainer = UI.column(14)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.add_child(body)
	body.add_child(kit.label("JOGAR", 36, TitleTheme.PAPER))
	body.add_child(kit.paragraph("O bosque espera por você.", 20, Color("c4b8d9")))
	var has_save: bool = not saved.is_empty()
	var summary: String = checkpoint_summary(saved) if has_save else "Sua primeira expedição começa com um vínculo."
	body.add_child(kit.paragraph(summary, 23, TitleTheme.PAPER))
	if has_save:
		var roster: Array = saved.get("party", [])
		body.add_child(kit.label("EQUIPE SALVA · %d VÍNCULO%s" % [roster.size(), "S" if roster.size() != 1 else ""], 15, Color("c4b8d9")))
		var grid = GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 8)
		body.add_child(grid)
		for individual in roster:
			var display_name: String = Content.display_name(individual)
			var portrait: String = str(Content.SPECIES[individual.species].art[int(individual.stage) - 1])
			var row: HBoxContainer = UI.row(6)
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(row)
			row.add_child(UI.art(portrait, Vector2(54, 54)))
			var details: VBoxContainer = UI.column(1)
			row.add_child(details)
			details.add_child(kit.label(display_name, 16, TitleTheme.PAPER))
			details.add_child(kit.label("%d/%d HP" % [individual.hp, individual.max_hp], 15, Color("c4b8d9")))
			row.tooltip_text = "%s · %s" % [display_name, "Em campo" if int(individual.slot) >= 0 else "Reserva"]
	var labels = ["CONTINUAR EXPEDIÇÃO", "NOVA EXPEDIÇÃO", "TREINO DE BATALHA", "VOLTAR"]
	var ids = ["journey.continue", "journey.new", "journey.practice", "journey.back"]
	for i in range(ids.size()):
		var button = PlateButton.new()
		button.text = labels[i]
		button.accessibility_name = labels[i].capitalize()
		button.custom_minimum_size.y = 62 if i == 0 and has_save else 54
		button.primary = i == (0 if has_save else 1)
		button.reduced_motion = reduced
		button.add_theme_font_size_override("font_size", int(21 * kit.text_scale))
		if i == 0:
			continue_button = button
			button.disabled = not has_save
			button.tooltip_text = summary if has_save else "Nenhuma expedição salva neste dispositivo."
		body.add_child(button)
		choices.append(button)
		register.call(button, ids[i], "journey")
		button.pressed.connect(callbacks[i])
		if i == 2:
			notice = kit.paragraph(save_message, 16, Color("c4b8d9"))
			notice.visible = not save_message.is_empty() and not save_message.begins_with("Progresso salvo")
			body.add_child(notice)
	resized.connect(_layout)
	body.minimum_size_changed.connect(_layout)
	_layout.call_deferred()

static func checkpoint_summary(saved: Dictionary) -> String:
	var current: String = str(saved.get("current_node_id", ""))
	var phase: String = str(saved.get("phase", "map"))
	var titles = {"clearing": "Clareira", "thicket": "Mata fechada", "spring": "Nascente", "boss": "Guardião"}
	if phase == "combat": return "%s · Combate em andamento" % titles.get(current, "Bosque")
	if phase == "reward": return "%s · Recompensa à espera" % titles.get(current, "Bosque")
	var available: Array[String] = []
	for node in saved.get("nodes", []):
		if node.available: available.append(str(node.title))
	return "Bosque · Próxima parada: %s" % " ou ".join(available) if not available.is_empty() else "Bosque · Expedição em andamento"

func _layout() -> void:
	if not is_instance_valid(panel): return
	var window: Vector2 = Vector2(DisplayServer.window_get_size())
	var pixel_scale: float = window.y / maxf(1.0, size.y) if window.y > 0 else 1.0
	var zoom: float = minf(maxf(1.0, 0.67 / maxf(0.01, pixel_scale)), (size.x - 80) / 760)
	panel.scale = Vector2.ONE * zoom
	_adapt_text(panel, ceili(14.0 * requested_text_scale / maxf(0.01, pixel_scale * zoom)))
	var minimum_hit: float = maxf(54.0, 44.0 / maxf(0.01, pixel_scale * zoom))
	for button in choices:
		if not is_equal_approx(button.custom_minimum_size.y, minimum_hit): button.custom_minimum_size.y = minimum_hit
	var width: float = minf(760, (size.x - 80) / zoom)
	var height: float = minf(scroller.get_combined_minimum_size().y + 56, (size.y - 80) / zoom)
	# ScrollContainer minimum height excludes its scrolling content.
	if scroller.get_child_count() > 0: height = minf(scroller.get_child(0).get_combined_minimum_size().y + 56, (size.y - 80) / zoom)
	panel.size = Vector2(width, height)
	panel.position = Vector2(maxf(40, (size.x - 1672 * minf(size.x / 1672, size.y / 941)) * 0.5 + 94), (size.y - height * zoom) * 0.5)
	if size.x / maxf(1, size.y) < 1.15: panel.position.x = (size.x - width * zoom) * 0.5

func _adapt_text(node: Node, minimum_font: int) -> void:
	for child in node.get_children():
		if child is Label:
			if not child.has_meta("title_font_size"): child.set_meta("title_font_size", child.get_theme_font_size("font_size"))
			var font_size: int = maxi(int(child.get_meta("title_font_size")), minimum_font)
			if child.get_theme_font_size("font_size") != font_size: child.add_theme_font_size_override("font_size", font_size)
		_adapt_text(child, minimum_font)
