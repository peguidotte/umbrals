extends Node
## Opt-in boot: loads the actual game, then replaces only its house renderer.
const Main = preload("res://scenes/main.tscn")
const PilotCanvas = preload("res://tools/studies/pietro_house/canvas.gd")
const Space = preload("res://scripts/ui/house_space.gd")
const Creature = preload("res://scripts/ui/creature_rig.gd")
const Art = preload("res://scripts/ui/battle_art.gd")
var app: Control
var room: Control
var canvas: Node2D
var brasa: Node2D
var slow: bool = false
var controls: Dictionary = {}
var overlay: CanvasLayer
var caption: Label
var initialized_host: bool = false
const START: Vector2 = Vector2(1540,Space.FLOOR_Y)
const BRASA: Vector2 = Vector2(2030,Space.FLOOR_Y)
const STUDY_SPEED: float = 100

func _ready() -> void:
	app = Main.instantiate()
	add_child(app)
	await get_tree().process_frame
	room = app.screen_host.refuge_root
	var old: Node2D = room.canvas
	canvas = PilotCanvas.new()
	canvas.point = START
	canvas.room = "living"
	room.add_child(canvas)
	room.move_child(canvas,0)
	room.canvas = canvas
	old.queue_free()
	room.entered = true
	# The host delegates the same physics callback, optionally slowing only this
	# experiment. Space.SPEED and the production room script are never changed.
	room.set_physics_process(false)
	_make_brasa()
	_make_controls()
	app.registry["menu.play"].pressed.emit()
	room.grab_focus()
	initialized_host = true

func _make_brasa() -> void:
	brasa = Creature.new()
	canvas.add_child(brasa)
	var texture: Texture2D = Art.texture("umbrals/ember")
	var profile: Dictionary = Art.ground_profile("umbrals/ember")
	var foot: Vector2 = Vector2(profile.foot[0],profile.foot[1])
	var scale_value: float = 230.0/maxf(1,foot.y-float(profile.visible_top))
	brasa.configure(texture,"ember",texture.get_size()*scale_value,foot*scale_value,false)
	brasa.position = BRASA-foot*scale_value
	brasa.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _make_controls() -> void:
	overlay = CanvasLayer.new()
	overlay.layer = 100
	add_child(overlay)
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 18
	panel.offset_right = -18
	panel.offset_top = -100
	panel.offset_bottom = -16
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("14242bef")
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel",style)
	overlay.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	panel.add_child(column)
	caption = Label.new()
	caption.add_theme_font_size_override("font_size",18)
	column.add_child(caption)
	var row: HBoxContainer = HBoxContainer.new()
	column.add_child(row)
	for entry in [["candidate","Pietro candidato"],["current","Pietro atual"],["pace","Caminhada lenta"],["frame","Enquadrar sala"]]:
		var button: Button = Button.new()
		button.text = entry[1]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",18)
		button.pressed.connect(select.bind(entry[0]))
		row.add_child(button)
		controls[entry[0]] = button

func select(key: String) -> void:
	if key=="candidate": canvas.candidate = true
	elif key=="current": canvas.candidate = false
	elif key=="pace": slow = not slow
	elif key=="frame":
		room._stop_walk()
		room.motion.waking = false
		room.motion.on_stairs = false
		room.motion.upper = false
		canvas.point = START
		canvas.rest_angle = 0
		canvas.on_stairs = false
		canvas.facing = Vector2.RIGHT
		canvas.last_point = START
		canvas.gather = 0
		canvas.cycle = 0.5
		room._room_changed()
		room.camera.follow(START,0,true)
		room._project()
	canvas.queue_redraw()
	room.grab_focus()

func _physics_process(delta: float) -> void:
	if not initialized_host: return
	var factor: float = STUDY_SPEED/Space.SPEED if slow and not room.motion.on_stairs and not room.motion.waking else 1
	room._physics_process(delta*factor)
	if room.active: canvas.advance(delta,room.reduced)
	brasa.paused = not room.active

func _process(_delta: float) -> void:
	if not initialized_host: return
	overlay.visible = room.active
	caption.text = "Experimento · casa e Brasa atuais · "+("Pietro candidato" if canvas.candidate else "Pietro atual")+" · "+("caminhada lenta" if slow else "velocidade atual da casa")
	controls.pace.text = "Velocidade da casa" if slow else "Caminhada lenta"
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.pietroHouseStudy="+JSON.stringify(public_state())+";",true)

func public_state() -> Dictionary:
	var buttons: Dictionary = {}
	for key in controls:
		var rect: Rect2 = controls[key].get_global_rect()
		buttons[key] = [rect.get_center().x,rect.get_center().y]
	return {"scope":"experimental renderer in real house; no promotion","base":"60b4e3045ebb9188f2a1f67771a8f6bf37d714f9","candidate":canvas.candidate,"slow":slow,"speed":STUDY_SPEED if slow else Space.SPEED,"cycle":canvas.cycle,"gather":canvas.gather,"pilot_scale":PilotCanvas.PILOT_SCALE,"travelled":canvas.travelled,"room":room.public_state(),"brasa":{"binding":"umbrals/ember","world_foot":[BRASA.x,BRASA.y],"idle_time":brasa.idle_time,"texture":brasa.texture.resource_path},"controls":buttons}
