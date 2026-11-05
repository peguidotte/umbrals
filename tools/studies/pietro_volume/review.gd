extends Node2D
## Diagnostic pose comparison; never loaded by the playable game.
const Rig = preload("res://tools/studies/pietro_pixel/rig.gd")
var rigs: Array = []
var cycle: float = 0
var running: bool = false

func _ready() -> void:
	for version in ["0.3.0","0.4.0"]:
		var rig = Rig.new("res://assets/characters/pietro-pixel-pilot/versions/"+version+"/")
		rig.data.scale = 0.7
		rigs.append(rig)
	_refresh()

func _process(delta: float) -> void:
	if running:
		cycle = fposmod(cycle+delta*1.5,1)
		_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo(): return
	if event.keycode==KEY_SPACE: running = not running
	if event.keycode==KEY_RIGHT: cycle = fposmod(cycle+0.025,1); running = false
	if event.keycode==KEY_LEFT: cycle = fposmod(cycle-0.025,1); running = false
	_refresh()

func _refresh() -> void:
	for rig in rigs: rig.pose(cycle,1)
	queue_redraw()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.pietroPoseState="+JSON.stringify({"cycle":cycle,"running":running})+";",true)

func _draw() -> void:
	draw_rect(Rect2(0,0,1400,1000),Color("333d3b"))
	for x in range(0,1400,40):
		for y in range(0,1000,40):
			if (x/40+y/40)%2==0: draw_rect(Rect2(x,y,40,40),Color("394340"))
	var font: Font = ThemeDB.fallback_font
	draw_string(font,Vector2(40,45),"Diagnóstico de volume · mesma fase / mesmos pixels aprovados",HORIZONTAL_ALIGNMENT_LEFT,-1,24)
	draw_string(font,Vector2(115,100),"Anterior 0.3 — pinçamento",HORIZONTAL_ALIGNMENT_LEFT,-1,22)
	draw_string(font,Vector2(785,100),"Candidata 0.4 — volume contínuo",HORIZONTAL_ALIGNMENT_LEFT,-1,22)
	draw_line(Vector2(0,900),Vector2(1400,900),Color("87968b"),2)
	for i in range(2): rigs[i].draw(self,Vector2(350+i*680,900))
	draw_string(font,Vector2(40,970),"Fase %.3f · Espaço: 3 passos/s · Setas: quadro controlado"%cycle,HORIZONTAL_ALIGNMENT_LEFT,-1,22)
