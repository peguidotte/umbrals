extends Control
## Disposable visual review of production actors. This scene never enters release exports.
const Actor = preload("res://scripts/ui/actor.gd")
const Content = preload("res://scripts/content.gd")
const Assets = preload("res://scripts/assets/catalog.gd")
const UI = preload("res://scripts/ui/kit.gd")
var actors: Array[Control] = []
var phase: int = 0
var title: Label
var original: Array[Dictionary] = []

func _ready() -> void:
	var background := TextureRect.new()
	background.texture = Assets.texture("world/battle-clearing-depth")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	title = UI.new().label("", 30, UI.PAPER, true, true)
	title.position = Vector2(180, 35)
	title.size = Vector2(1240, 55)
	add_child(title)
	var note: Label = UI.new().label("CENA DE REVISÃO · Atores no tamanho de batalha · Espaço: próximo estado · Sem simulação de regras", 18, UI.PAPER, false, true)
	note.position = Vector2(100, 835)
	note.size = Vector2(1400, 40)
	add_child(note)
	for index in range(4):
		var id: String = "volt" if index < 2 else "tempestral"
		var body: Control = Actor.new()
		body.enemy = index % 2 == 1
		body.slot = 1
		body.position = Vector2(360 if index % 2 == 0 else 1020, 130 if index < 2 else 460)
		body.size = Vector2(220, 260)
		add_child(body)
		var stats: Dictionary = Content.form_definition("volt", id).get("stats", {})
		var data: Dictionary = {"uid": index + 1, "species": "volt", "form_id": id, "hp": int(stats.get("max_hp", 36)), "max_hp": int(stats.get("max_hp", 36)), "speed": int(stats.get("speed", 18)), "statuses": {}}
		body.set_identity(data)
		actors.append(body)
		original.append(data)
	_apply()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		phase = (phase + 1) % 7
		_apply()

func _apply() -> void:
	title.text = ["Repouso · respiração e orelhas", "Movimento · passada em quatro patas", "Dano · recuo e recuperação", "Carga · espinhos presos ao corpo", "Incapacitado · queda e apoio", "Reanimado · retorna ao repouso", "Movimento reduzido · KO estático"][phase]
	for index in range(actors.size()):
		var body: Control = actors[index]
		body.reduced_motion = phase == 6
		var data: Dictionary = original[index].duplicate(true)
		if phase in [4, 6]: data.hp = 0
		body.set_identity(data)
		body.stop_motion()
		if phase == 1: body.rig.play_state(6)
		elif phase == 2: body.rig.play_state(3)
		elif phase == 3: body.rig.play_state(1)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.electricPreviewPhase = " + str(phase))
