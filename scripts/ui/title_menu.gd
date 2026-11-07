class_name UmbralTitleMenu
extends Control
## Public save projection in; navigation intents out. No storage or gameplay RNG.
const Assets = preload("res://scripts/assets/catalog.gd")
const Action = preload("res://scripts/ui/title_action.gd")
const Actor = preload("res://scripts/ui/title_actor.gd")
const Gold = preload("res://scripts/ui/gold_theme.gd")
const LABELS = ["Continuar","Novo jogo","Opções","Sair"]
const KEYS = ["menu.continue","menu.play","menu.settings","menu.quit"]
signal card_awakened
signal navigation_requested
var buttons: Array[Button] = []
var actors: Array[Control] = []
var input_active: bool = true:
	set(value):
		input_active = value
		for actor: Control in actors: actor.set_active(value)
var reduced_motion: bool = false
var frozen: bool = false
var text_scale: float = 1.0
var water_material: ShaderMaterial
var water_clock: float = 0.0
var background: TextureRect
var canvas: Control
var logo: TextureRect
var scroller: ScrollContainer
var body: VBoxContainer
var actions: GridContainer
var notice: Label
var profile: String = "wide"
var save_status: String = "checking"
var _selected: int = -1
var _columns: int = 4

func build(callbacks: Array[Callable], register: Callable) -> void:
	name = "TitleScreen"
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background = _image("ui/living-title-scene",self)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	water_material = ShaderMaterial.new()
	water_material.shader = load(Assets.file_path("ui/living-title","1.0.0","water")) as Shader
	background.material = water_material
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	for species: String in ["ember","moss","dew","volt"]:
		var actor = Actor.new()
		canvas.add_child(actor)
		actor.build(species)
		actor.activated.connect(card_awakened.emit)
		actors.append(actor)
	logo = _image("ui/living-title-logo",self)
	scroller = ScrollContainer.new()
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroller.follow_focus = true
	add_child(scroller)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.add_child(body)
	actions = GridContainer.new()
	actions.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(actions)
	for i in range(4):
		if i == 3 and OS.has_feature("web"): continue
		var button = Action.new()
		button.text = LABELS[i]
		button.accessibility_name = LABELS[i]
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		actions.add_child(button)
		button.pressed.connect(func():
			if input_active and not button.disabled: callbacks[i].call())
		button.focus_entered.connect(_select.bind(i))
		button.mouse_entered.connect(_select.bind(i))
		register.call(button,KEYS[i],"menu")
		buttons.append(button)
	for actor: Control in actors: register.call(actor,"menu.actor."+actor.species,"menu")
	notice = Label.new()
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice.add_theme_color_override("font_color",Color("e7edf8"))
	notice.add_theme_color_override("font_outline_color",Color("081b39"))
	body.add_child(notice)
	resized.connect(_layout)
	_layout()

func set_checkpoint(available: bool, status: String, message: String) -> void:
	save_status = status
	buttons[0].disabled = not (available and status in ["ok","recovered"])
	buttons[1].disabled = status == "incompatible"
	notice.text = message
	match status:
		"missing","cleared": notice.text = "Nenhuma expedição salva neste dispositivo."
		"checking": notice.text = "Verificando expedição…"
		"corrupt": notice.text = "Não foi possível ler a expedição salva."
		"incompatible": notice.text = "Esta expedição foi criada em uma versão incompatível."
		"io_error": notice.text = "Não foi possível acessar a expedição salva."
		"ok": notice.text = ""
	notice.accessibility_name = notice.text
	buttons[0].accessibility_description = notice.text
	_layout()

func _select(index: int) -> void:
	if not input_active or buttons[index].disabled: return
	if _selected != index:
		_selected = index
		navigation_requested.emit()

func _image(binding: String, parent: Control) -> TextureRect:
	var node = TextureRect.new()
	node.texture = Assets.texture(binding)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func _layout() -> void:
	if not is_instance_valid(logo) or size.x <= 0 or size.y <= 0: return
	var pixel_scale: float = maxf(0.05,get_viewport().get_stretch_transform().get_scale().x) if is_inside_tree() else 1.0
	var unit: float = maxf(1.0,1.0/pixel_scale)
	var font_size: int = roundi(maxf(32.0,20.0*unit)*text_scale)
	var padding: float = maxf(40.0,32.0*unit)
	var target_height: float = maxf(56.0,48.0*unit)*text_scale
	var gap: float = maxf(28.0,12.0*unit)
	var widths: Array[float] = []
	var total: float = 0
	for button: Button in buttons:
		var width: float = Gold.display_font().get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x+padding
		widths.append(width)
		total += width
		button.add_theme_font_size_override("font_size",font_size)
		button.add_theme_constant_override("outline_size",maxi(2,roundi(2.0*unit)))
		button.indicator_scale = unit
		button.custom_minimum_size = Vector2(width,target_height)
		button.queue_redraw()
	total += gap*(buttons.size()-1)
	var available: float = size.x-32.0*unit
	var aspect: float = size.x/size.y
	profile = "wide" if aspect >= 1.55 and total <= available else "middle" if aspect >= 1.15 else "portrait"
	_columns = buttons.size() if profile == "wide" else 2
	if widths.max()*2.0+gap > available or (profile == "portrait" and OS.has_feature("web")): _columns = 1
	actions.columns = _columns
	actions.add_theme_constant_override("h_separation",roundi(gap))
	actions.add_theme_constant_override("v_separation",roundi(8.0*unit))
	body.add_theme_constant_override("separation",roundi(6.0*unit))
	var logo_width: float = minf(available,maxf(200.0*unit,minf(size.x,size.y*1.95)*0.25))
	logo.size = Vector2(logo_width,logo_width*0.28)
	logo.position = Vector2((size.x-logo_width)*0.5,maxf(12.0*unit,size.y*0.02))
	var top: float = size.y*0.225-target_height*0.5 if profile == "wide" else logo.position.y+logo.size.y+18.0*unit
	top = maxf(top,logo.position.y+logo.size.y+12.0*unit)
	var rows: int = ceili(float(buttons.size())/_columns)
	var menu_height: float = rows*target_height+(rows-1)*8.0*unit
	notice.add_theme_font_size_override("font_size",roundi(maxf(18.0,14.0*unit)*text_scale))
	notice.add_theme_constant_override("outline_size",maxi(2,roundi(unit)))
	notice.visible = not notice.text.is_empty()
	if notice.visible: menu_height += 40.0*unit*text_scale
	scroller.position = Vector2(16.0*unit,top)
	scroller.size = Vector2(available,minf(menu_height+8.0*unit,maxf(1.0,size.y-top-12.0*unit)))
	var stage_width: float = minf(size.x,size.y*1.95)
	canvas.position = Vector2((size.x-stage_width)*0.5,0)
	canvas.size = Vector2(stage_width,size.y)
	water_material.set_shader_parameter("sky_fraction",clampf((scroller.position.y+scroller.size.y+12.0*unit)/size.y,0.26,0.65) if profile == "middle" else 0.26)
	var scene_top: float = scroller.position.y+scroller.size.y+18.0*unit
	var scene_height: float = maxf(1.0,size.y-scene_top)
	var feet: Array[Vector2] = [Vector2(0.20,0.50),Vector2(0.30,0.895),Vector2(0.625,0.735),Vector2(0.855,0.845)]
	var heights: Array[float] = [0.255,0.34,0.22,0.30]
	if profile != "wide":
		feet = [Vector2(0.24,0.36),Vector2(0.25,0.93),Vector2(0.63,0.60),Vector2(0.80,0.91)]
	if profile == "portrait":
		feet = [Vector2(0.24,0.67),Vector2(0.25,0.90),Vector2(0.63,0.76),Vector2(0.80,0.90)]
	var ultrawide: bool = aspect>2.05
	background.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	background.position = Vector2.ZERO
	background.size = size
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture = Assets.texture("ui/living-title-portrait" if profile == "portrait" else "ui/living-title-scene")
	if ultrawide:
		background.texture = Assets.texture("ui/living-title-ultrawide")
		background.stretch_mode = TextureRect.STRETCH_SCALE
		background.size = Vector2(size.y*32.0/9.0,size.y)
		background.position.x = (size.x-background.size.x)*0.5
		feet[2].y = 0.705
		feet[3].y = 0.83
	water_material.set_shader_parameter("water_start",0.72 if profile == "portrait" else 0.59)
	for i in range(actors.size()):
		var height: float = size.y*heights[i] if profile == "wide" else minf(stage_width*0.36,scene_height*(0.33 if i != 1 else 0.40))
		var point: Vector2 = Vector2(feet[i].x*stage_width,feet[i].y*size.y) if profile == "wide" else Vector2(feet[i].x*stage_width,scene_top+feet[i].y*scene_height)
		if profile == "portrait": point.y = maxf(feet[i].y*size.y,scene_top+height*1.08)
		actors[i].place(point,height,profile == "middle" or (profile == "portrait" and point.y>feet[i].y*size.y+1.0))
	refresh_focus()

func refresh_focus() -> void:
	if not is_inside_tree(): return
	var controls: Array[Control] = []
	for button: Button in buttons:
		if not button.disabled: controls.append(button)
	controls.append_array(actors)
	for i in range(controls.size()):
		controls[i].focus_next = controls[(i+1)%controls.size()].get_path()
		controls[i].focus_previous = controls[posmod(i-1,controls.size())].get_path()
	for i in range(buttons.size()):
		for direction: String in ["left","right","top","bottom"]:
			var step: int = -1 if direction == "left" else 1 if direction == "right" else -_columns if direction == "top" else _columns
			var candidate: int = posmod(i+step,buttons.size())
			for attempt in range(buttons.size()):
				if not buttons[candidate].disabled: break
				candidate = posmod(candidate+(1 if step>0 else -1),buttons.size())
			if direction in ["top","bottom"] and _columns>1:
				var rows: int = ceili(float(buttons.size())/_columns)
				var row: int = posmod(floori(float(i)/_columns)+(1 if direction=="bottom" else -1),rows)
				candidate = i
				for offset in range(_columns):
					var neighbor: int = row*_columns+posmod(i%_columns+offset,_columns)
					if neighbor<buttons.size() and not buttons[neighbor].disabled:
						candidate = neighbor
						break
			buttons[i].set("focus_neighbor_"+direction,buttons[candidate].get_path())

func apply_preferences(reduced: bool, freeze: bool, scale_value: float, flashes: bool = false) -> void:
	reduced_motion = reduced
	frozen = freeze
	text_scale = scale_value
	if water_material != null: water_material.set_shader_parameter("moving",not (reduced or freeze))
	for actor: Control in actors: actor.apply_preferences(reduced,freeze,flashes)
	_layout()

func effect_state() -> Dictionary:
	var poses: Array = []
	for actor: Control in actors: poses.append(actor.public_state())
	return {"reduced_motion":reduced_motion,"frozen":frozen,"clock":0.0,"card_poses":poses,"background":"ui/living-title-scene","portrait":profile=="portrait","profile":profile,"columns":_columns,"save_status":save_status}

func _process(delta: float) -> void:
	if not is_visible_in_tree() or not input_active or reduced_motion or frozen: return
	water_clock = fmod(water_clock+minf(delta,0.05),3600.0)
	water_material.set_shader_parameter("phase",water_clock)
