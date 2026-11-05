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
var automatic: bool = false
var started_us: int = 0
var frame_times: Array = []
var captured: Dictionary = {}
var output: String = ""
var phase_frames: Dictionary = {}

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
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "--native-review":
		automatic = true
		output = args[1]
		DirAccess.make_dir_recursive_absolute(output)
		started_us = Time.get_ticks_usec()

func _process(_delta: float) -> void:
	if not automatic:
		if OS.has_feature("web"):
			var now: int = Time.get_ticks_usec()
			frame_times.append(now)
			if frame_times.size() > 1 and now - int(frame_times[0]) >= 2000000:
				JavaScriptBridge.eval("window.electricCadence = " + JSON.stringify({"phase": phase, "frames": frame_times.size(), "fps": frame_times.size() * 1000000.0 / (now - int(frame_times[0]))}))
				frame_times.clear()
		return
	var now: int = Time.get_ticks_usec()
	frame_times.append(now)
	var seconds: float = float(now - started_us) / 1000000.0
	var next: int = int(seconds / 3.2)
	if next < 7: phase_frames[next] = int(phase_frames.get(next, 0)) + 1
	if next >= 7:
		automatic = false
		var intervals: Array = []
		for index in range(1, frame_times.size()): intervals.append(float(frame_times[index] - frame_times[index - 1]) / 1000.0)
		intervals.sort()
		var report: Dictionary = {"kind": "Native real-time actor review; no fixed-fps or movie mode", "frames": frame_times.size(), "seconds": seconds, "average_fps": frame_times.size() / seconds, "p95_frame_ms": intervals[int(intervals.size() * .95)], "renderer": RenderingServer.get_video_adapter_name()}
		var phases: Dictionary = {}
		for index in phase_frames: phases[index] = float(phase_frames[index]) / 3.2
		report["phase_fps"] = phases
		var file: FileAccess = FileAccess.open(output.path_join("cadence.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify(report))
		print(JSON.stringify(report))
		get_tree().quit()
		return
	if next != phase:
		phase = next
		_apply()
	var age: float = fmod(seconds, 3.2)
	if not captured.has(phase) and age >= (.15 if phase == 2 else .9):
		captured[phase] = true
		_capture(phase)

func _capture(index: int) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join("state-%d.png" % index))

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		phase = (phase + 1) % 7
		_apply()

func _apply() -> void:
	if OS.has_feature("web"):
		frame_times.clear()
		JavaScriptBridge.eval("window.electricCadence = null")
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
