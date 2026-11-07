class_name UmbralSettingsMenu
extends Control
## Native settings controls over the approved forest and botanical frame.
const Gold = preload("res://scripts/ui/gold_theme.gd")
const ControlsTheme = preload("res://scripts/ui/gold_controls_theme.gd")
const RefArt = preload("res://scripts/ui/reference_art.gd")
const Assets = preload("res://scripts/assets/catalog.gd")
const UI = preload("res://scripts/ui/kit.gd")
const MODES = {
	"hidden": ["Oculta", "As intenções inimigas ficam escondidas."],
	"partial": ["Parcial", "Revela a categoria da ação que está por vir."],
	"full": ["Completa", "Revela força, alcance e alvo da ação."],
}
var preferences: RefCounted
var register: Callable
var panel: PanelContainer
var columns: GridContainer
var scroll: ScrollContainer
var text_scale: float = 1.0
var mode_buttons: Dictionary = {}
var mode_marks: Dictionary = {}
var more: Callable
var use_title_scene: bool = false
var heading_label: Label
var more_links: HFlowContainer
var registered_controls: Array[Control] = []
var footer_body: VBoxContainer
var crest_art: TextureRect
var footer_hint: Label
var font_copies: Dictionary = {}
var local_font_files: Array[FontFile] = []

func build(store: RefCounted, registry: Callable, back: Callable, secondary: Callable = Callable(), title_scene: bool = false) -> void:
	use_title_scene = title_scene
	more = secondary
	name = "Overlay_settings"
	preferences = store
	register = func(control: Control, key: String, screen: String) -> Control:
		registered_controls.append(control)
		return registry.call(control,key,screen)
	text_scale = preferences.text_scale()
	theme = ControlsTheme.make(text_scale)
	var forest: TextureRect = RefArt.image(self,Assets.texture("ui/living-title-scene" if use_title_scene else "ui/gold-menu-scene"),Rect2(Vector2.ZERO,size))
	forest.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	forest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var shade = ColorRect.new()
	shade.color = Color(0.015,0.035,0.04,0.35)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = PanelContainer.new()
	var surface: StyleBoxFlat = Gold.box(false,42)
	surface.content_margin_top = 28
	surface.content_margin_bottom = 52
	surface.bg_color = Color(0.025,0.06,0.065,0.96)
	surface.border_color = Color("8d805a")
	panel.add_theme_stylebox_override("panel",surface)
	add_child(panel)
	var frame = Gold.Frame.new()
	frame.inset = 0
	frame.corner = 54
	# A top-level Control keeps the frame independent of the content container.
	add_child(frame)
	var body: VBoxContainer = UI.column(18)
	panel.add_child(body)
	_build_header(body)
	body.add_child(Gold.line())
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	columns = GridContainer.new()
	columns.columns = 2
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("h_separation",64)
	columns.add_theme_constant_override("v_separation",30)
	scroll.add_child(columns)
	_build_content()
	body.add_child(Gold.line())
	_build_footer(body,back)
	_prepare_fonts(self)
	resized.connect(_layout.bind(frame))
	# Wrapped paragraphs report their final minimum after the first container pass.
	panel.minimum_size_changed.connect(_layout.bind(frame))
	_layout(frame)
	_layout.call_deferred(frame)

func _build_header(body: VBoxContainer) -> void:
	var heading: HBoxContainer = UI.row(24)
	body.add_child(heading)
	var title: VBoxContainer = UI.column(0)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	heading_label = Gold.label("Opções",int(66*text_scale),Gold.PAPER,true)
	title.add_child(heading_label)
	title.add_child(Gold.paragraph("Seu jeito de explorar o bosque.",int(20*text_scale)))
	var crest: TextureRect = RefArt.image(heading,RefArt.region("ui/gold-codex-art",Rect2(45,235,52,50)),Rect2())
	crest_art = crest
	crest.custom_minimum_size = Vector2(64,64)
	crest.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _build_content() -> void:
	var comfort: VBoxContainer = UI.column(8)
	comfort.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(comfort)
	_section(comfort,"Áudio")
	_volume(comfort,"music","Música")
	_volume(comfort,"sfx","Efeitos e interface")
	comfort.add_child(Gold.line())
	_section(comfort,"Acessibilidade")
	_toggle(comfort,"reduced_motion","Movimento reduzido","Desativa tremores e partículas.")
	_toggle(comfort,"flashes","Flashes de impacto","Permite clarões durante os golpes.")
	_toggle(comfort,"large_text","Texto ampliado","Aumenta os textos da interface.")
	var information: VBoxContainer = UI.column(14)
	information.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(information)
	_section(information,"Informação inimiga")
	information.add_child(Gold.paragraph("Escolha o que ver antes de conjurar.",int(19*text_scale)))
	var group = ButtonGroup.new()
	for mode in MODES: _mode(information,str(mode),group)
	information.add_child(Gold.paragraph("A IA é a mesma em todos os modos.\nDurante a batalha, a mudança vale na próxima rodada.",int(18*text_scale)))
	_sync_modes()

func _build_footer(body: VBoxContainer, back: Callable) -> void:
	if more.is_valid():
		footer_body = body
		var links = HFlowContainer.new()
		more_links = links
		links.add_theme_constant_override("h_separation",10)
		links.add_theme_constant_override("v_separation",6)
		body.add_child(links)
		links.add_child(Gold.label("Mais",int(22*text_scale),Gold.GOLD,true))
		for entry: Array in [["Grimório","codex"],["Como jogar","help"],["Créditos","credits"],["Treino de batalha","practice"],["Abrigo","refuge"]]:
			var link: Button = Gold.button(entry[0])
			link.add_theme_font_size_override("font_size",int(21*text_scale))
			link.custom_minimum_size.y = 44
			links.add_child(link)
			register.call(link,"settings."+str(entry[1]),"settings")
			link.pressed.connect(more.bind(str(entry[1])))
	var footer = HFlowContainer.new()
	footer.add_theme_constant_override("h_separation",24)
	body.add_child(footer)
	var hint: Label = Gold.paragraph("Preferências deste dispositivo",int(18*text_scale))
	footer_hint = hint
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer.add_child(hint)
	var close: Button = Gold.button("Voltar",true)
	close.add_theme_font_size_override("font_size",int(27*text_scale))
	close.custom_minimum_size = Vector2(210,56)
	close.tooltip_text = "Voltar (Esc / B)"
	footer.add_child(close)
	register.call(close,"settings.back","settings")
	close.pressed.connect(back)

func _section(parent: Control, title: String) -> void:
	var label: Label = Gold.label(title,int(31*text_scale),Gold.GOLD,true)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)

func _volume(parent: Control, key: String, title: String) -> void:
	var box: VBoxContainer = UI.column(0)
	parent.add_child(box)
	var labels: HBoxContainer = UI.row()
	box.add_child(labels)
	var label: Label = Gold.label(title,int(22*text_scale))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels.add_child(label)
	var percentage: Label = Gold.label("%d%%"%roundi(float(preferences.values[key])*100),int(22*text_scale),Gold.GOLD)
	percentage.custom_minimum_size.x = 65
	percentage.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	labels.add_child(percentage)
	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = float(preferences.values[key])
	slider.custom_minimum_size.y = 34
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.accessibility_name = title
	box.add_child(slider)
	register.call(slider,"settings."+key,"settings")
	slider.focus_entered.connect(_reveal_volume.bind(slider,box))
	slider.value_changed.connect(func(value: float):
		percentage.text = "%d%%"%roundi(value*100)
		preferences.set_value(key,value))

func _toggle(parent: Control, key: String, title: String, description: String) -> void:
	var box: VBoxContainer = UI.column(0)
	parent.add_child(box)
	var check = CheckButton.new()
	check.accessibility_name = title
	check.button_pressed = bool(preferences.values[key])
	check.custom_minimum_size.y = 44
	check.accessibility_description = description
	box.add_child(check)
	var margin = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	check.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_right",80)
	var caption: Label = Gold.paragraph(title,int(22*text_scale),Gold.PAPER)
	margin.add_child(caption)
	caption.minimum_size_changed.connect(func(): check.custom_minimum_size.y = maxf(44,caption.get_minimum_size().y+4))
	register.call(check,"settings."+key,"settings")
	check.toggled.connect(func(value: bool): preferences.set_value(key,value))
	box.add_child(Gold.paragraph(description,int(17*text_scale)))

func _mode(parent: Control, mode: String, group: ButtonGroup) -> void:
	var choice = Button.new()
	choice.toggle_mode = true
	choice.button_group = group
	choice.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	choice.accessibility_name = str(MODES[mode][0])+". "+str(MODES[mode][1])
	choice.custom_minimum_size.y = 90*text_scale
	parent.add_child(choice)
	var margin = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choice.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,20)
	for side in ["top","bottom"]: margin.add_theme_constant_override("margin_"+side,12)
	var content: VBoxContainer = UI.column(2)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(content)
	var row: HBoxContainer = UI.row(12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(row)
	var label: Label = Gold.label(str(MODES[mode][0]),int(29*text_scale),Gold.PAPER,true)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var mark: Label = Gold.label("",int(17*text_scale),Gold.GOLD)
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(mark)
	content.add_child(Gold.paragraph(str(MODES[mode][1]),int(18*text_scale)))
	margin.minimum_size_changed.connect(func(): choice.custom_minimum_size.y = maxf(90*text_scale,margin.get_combined_minimum_size().y))
	mode_buttons[mode] = choice
	mode_marks[mode] = mark
	register.call(choice,"settings.info."+mode,"settings")
	choice.pressed.connect(func():
		preferences.set_value("information_mode",mode)
		_sync_modes())

func _sync_modes() -> void:
	for mode in mode_buttons:
		var active: bool = str(preferences.values.information_mode) == mode
		mode_buttons[mode].set_pressed_no_signal(active)
		mode_marks[mode].text = "✓ Em uso" if active else ""

func _layout(frame: Control) -> void:
	var pixel_scale: float = maxf(0.05,get_viewport().get_stretch_transform().get_scale().x) if is_inside_tree() else 1.0
	var zoom: float = maxf(1.0,1.0/pixel_scale)
	var width: float = minf(1320,size.x/zoom-24)
	var compact: bool = width < 1040
	# Font auto-oversampling follows the root canvas, not this local zoom. Keep
	# local font rasters at native density instead of enlarging a 5px glyph.
	for file: FontFile in local_font_files:
		var density: float = 1.0 if zoom > 1.0 else 0.0
		if not is_equal_approx(file.oversampling,density): file.oversampling = density
	var surface: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	var safe_edge: float = maxf(12.0,44.0/zoom)
	surface.content_margin_left = safe_edge if compact else 42
	surface.content_margin_right = surface.content_margin_left
	surface.content_margin_top = 18 if compact else 28
	surface.content_margin_bottom = maxf(18.0,safe_edge) if compact else 52
	footer_hint.visible = not compact
	frame.corner = 24 if compact else 54
	for control: Control in registered_controls:
		if control is HSlider: control.custom_minimum_size.y = 44 if compact else 34
	var height: float = minf(852,size.y/zoom-24)
	panel.scale = Vector2.ONE*zoom
	panel.position = (size-Vector2(width,height)*zoom)*0.5
	panel.size = Vector2(width,height)
	frame.scale = panel.scale
	frame.position = panel.position
	frame.size = panel.size
	columns.columns = 2 if width >= 1040 else 1
	if is_instance_valid(more_links):
		var holder: Control = columns.get_child(1) if width < 1040 else footer_body
		if more_links.get_parent() != holder:
			more_links.reparent(holder)
			if holder == footer_body: footer_body.move_child(more_links,footer_body.get_child_count()-2)
			if is_inside_tree():
				UI.focus_chain(registered_controls)
				var focused: Control = get_viewport().gui_get_focus_owner()
				if is_instance_valid(focused) and scroll.is_ancestor_of(focused): scroll.ensure_control_visible.call_deferred(focused)
	if is_instance_valid(heading_label): heading_label.add_theme_font_size_override("font_size",roundi(minf(66.0,maxf(36.0,width*0.15))*text_scale))
	if is_instance_valid(crest_art): crest_art.visible = width >= 600
	if is_inside_tree():
		var focused: Control = get_viewport().gui_get_focus_owner()
		if is_instance_valid(focused) and focused is HSlider and is_ancestor_of(focused): _reveal_volume(focused,focused.get_parent())

func _reveal_volume(slider: Control, field: Control) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(slider) and slider.is_inside_tree() and slider.has_focus(): scroll.ensure_control_visible(field)

func _prepare_fonts(node: Node) -> void:
	if node is Label or node is BaseButton:
		var source: Font = node.get_theme_font("font")
		if not font_copies.has(source):
			var local: Font = source.duplicate() as Font
			if local is FontVariation and local.base_font is FontFile:
				local.base_font = local.base_font.duplicate() as FontFile
				local_font_files.append(local.base_font)
			elif local is FontFile: local_font_files.append(local)
			font_copies[source] = local
		node.add_theme_font_override("font",font_copies[source])
	for child: Node in node.get_children(): _prepare_fonts(child)
