extends Node2D
const Rig = preload("res://tools/studies/pietro_pixel/rig.gd")
const WORLD: String = "res://assets/world/pietro-pixel-study/versions/0.1.0/"
var rig: RefCounted = Rig.new()
var plate: Texture2D = load(WORLD + "plate.png") as Texture2D
var reference: Texture2D
var mode: String = "static"
var elapsed: float = 0
var anchor: Vector2 = Vector2(620,812)
var cycle: float = 0.5
var gather: float = 0
var stage: String = "static"
var buttons: Dictionary = {}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var path: String = WORLD + "review/approved-scene.png"
	# Review files stay outside the production importer. The standalone Web
	# project imports its own copy; the source-project study reads the raw PNG.
	reference = ImageTexture.create_from_image(Image.load_from_file(path)) if FileAccess.file_exists(path) else load(path) as Texture2D
	for entry in [["static","Comparar parado"],["walk","Caminhada curta"],["reference","Conceito aprovado"]]:
		var button: Button = Button.new()
		button.text = entry[1]
		button.position = Vector2(760 + buttons.size()*265,924)
		button.size = Vector2(250,52)
		button.add_theme_font_size_override("font_size",21)
		button.pressed.connect(select.bind(entry[0]))
		add_child(button)
		buttons[entry[0]] = button
	select("static")

func select(value: String) -> void:
	mode = value
	elapsed = 0
	_update_pose()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE: select("walk")
		elif event.keycode == KEY_1: select("static")
		elif event.keycode == KEY_2: select("reference")

func _process(delta: float) -> void:
	if mode == "walk" and stage != "finished":
		elapsed += delta
		_update_pose()

func _update_pose() -> void:
	anchor = Vector2(620,812)
	cycle = 0.5
	gather = 0
	stage = mode
	if mode == "walk":
		var warm: float = float(rig.data.walk.gather_seconds)
		var duration: float = float(rig.data.walk.period) * int(rig.data.walk.cycles)
		var stride: float = 4 * float(rig.data.walk.amplitude) * float(rig.data.scale)
		if elapsed < warm:
			anchor.x = float(rig.data.walk.start_x)
			gather = smoothstep(0,1,elapsed/warm)
			stage = "gather_in"
		elif elapsed < warm + duration:
			cycle += (elapsed-warm)/float(rig.data.walk.period)
			anchor.x = float(rig.data.walk.start_x)+(cycle-0.5)*stride
			gather = 1
			stage = "walking"
		elif elapsed < 2*warm+duration:
			gather = 1-smoothstep(0,1,(elapsed-warm-duration)/warm)
			stage = "gather_out"
		else: stage = "finished"
	rig.pose(cycle,gather)
	queue_redraw()
	if OS.has_feature("web"):
		var feet: Array = []
		for foot in rig.feet: feet.append([anchor.x+(foot.x-620)*float(rig.data.scale),anchor.y+(foot.y-1130)*float(rig.data.scale)])
		var controls: Dictionary = {}
		for key in buttons:
			var rect: Rect2 = buttons[key].get_global_rect()
			controls[key] = [rect.get_center().x,rect.get_center().y]
		JavaScriptBridge.eval("window.pietroStudy="+JSON.stringify({"mode":mode,"stage":stage,"time":elapsed,"cycle":cycle,"gather":gather,"anchor":[anchor.x,anchor.y],"feet":feet,"reach_error":rig.reach_error,"controls":controls})+";",true)

func _draw() -> void:
	draw_rect(Rect2(0,0,1600,1000),Color("121c2b"))
	var texture: Texture2D = reference if mode == "reference" else plate
	draw_texture_rect_region(texture,Rect2(7,8,1586,880),Rect2(0,0,texture.get_width(),880))
	if mode != "reference":
		var shadow: PackedVector2Array = []
		for point in [Vector2(-145,-3),Vector2(-110,-7),Vector2(100,-7),Vector2(100,-3),Vector2(145,-3),Vector2(145,4),Vector2(95,4),Vector2(95,8),Vector2(-125,8),Vector2(-125,3),Vector2(-145,3)]: shadow.append(anchor+Vector2(7,8)+point)
		draw_colored_polygon(shadow,Color(0.07,0.08,0.12,0.7))
		rig.draw(self,anchor+Vector2(7,8),gather<=0)
	draw_string(ThemeDB.fallback_font,Vector2(26,930),"Pietro + Brasa · piloto visual",HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("ffe4ad"))
	var caption: String = "Referência aprovada" if mode == "reference" else "Implementação candidata · aguarda avaliação do Pedro"
	draw_string(ThemeDB.fallback_font,Vector2(26,964),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("d8d4c8"))
