extends Node2D
## Diagnostic scene only. Uses the production actor/rig and its real process clock.
const Actor = preload("res://scripts/ui/actor.gd")
const Rules = preload("res://scripts/rules.gd")
const Assets = preload("res://scripts/assets/catalog.gd")
var bodies: Array = []
var phase: String = "ready"
var waiting: float = 0.0
var samples: Array = []
var tick: int = 0
var destination: String = ""
var autoplay: bool = false
var label: Label

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): destination = arg.trim_prefix("--output=")
		if arg == "--autoplay": autoplay = true
	var background: Sprite2D = Sprite2D.new()
	background.texture = load(Assets.file_path("world/battle-clearing-depth", "1.0.0", "background"))
	background.centered = false
	background.scale = Vector2(1600, 900) / background.texture.get_size()
	add_child(background)
	for enemy in [false, true]:
		for slot in range(3):
			var body: Control = Actor.new()
			body.enemy = enemy
			body.slot = slot
			body.size = Vector2(230, 230)
			body.position = Vector2(180 + slot * 510, 180 if not enemy else 470)
			add_child(body)
			body.still = true
			body.set_identity(Rules.make_umbral("ember", "vital", 1))
			body.rig.paused = true
			body.rig.still = true
			bodies.append(body)
			var title: Label = Label.new()
			title.text = "%s · %.2f px" % ["Esquerda →" if not enemy else "← Direita", 118.0 * [0.90, 1.0, 1.07][slot]]
			title.position = body.position - Vector2(10, 30)
			title.add_theme_font_size_override("font_size", 24)
			add_child(title)
	label = Label.new()
	label.position = Vector2(40, 28)
	label.add_theme_font_size_override("font_size", 26)
	add_child(label)
	var play: Button = Button.new()
	play.text = "Reproduzir"
	play.position = Vector2(660, 818)
	play.size = Vector2(280, 58)
	play.pressed.connect(func():
		if phase == "ready": _start())
	add_child(play)
	if autoplay: call_deferred("_start")

func _start() -> void:
	phase = "walk"
	for body in bodies: body.rig.enter_field()

func _process(delta: float) -> void:
	if bodies.is_empty(): return
	var values: Array = []
	for body in bodies:
		var life: Node2D = body.rig.lifecycle
		life.advance(delta, false, false)
		body.rig.queue_redraw()
		var item: Dictionary = {"state": life.state, "animation": str(life.sprite.animation),
			"frame": life.sprite.frame, "position": [life.position.x, life.position.y],
			"mesh_alpha": life.mesh_weight(), "sprite_alpha": life.sprite.modulate.a,
			"mirror": body.enemy, "slot": body.slot, "floor_y": body.visual_ground().y}
		var timeline: Array = life.profile.timelines.get(str(life.sprite.animation), [])
		if life.state == "walk":
			var row: Dictionary = timeline[life.sprite.frame]
			var point: Vector2 = life.sprite.to_global(Vector2(float(row.contact[0]), float(row.contact[1])))
			item["contact"] = [point.x, point.y]
			item["support"] = row.support
		values.append(item)
	if phase != "ready" and phase != "done": samples.append({"tick": tick, "delta": delta, "wall_msec": Time.get_ticks_msec(), "phase": phase, "bodies": values})
	var first: Node2D = bodies[0].rig.lifecycle
	if phase == "walk" and not first.active(): phase = "idle"; waiting = 0
	elif phase in ["idle", "held", "recovered"]:
		waiting += delta
		if waiting >= 0.8:
			if phase == "idle":
				phase = "ko"
				for body in bodies: body.rig.set_incapacitated(true)
			elif phase == "held":
				phase = "revive"
				for body in bodies: body.rig.set_incapacitated(false)
			else: _finish()
	elif phase == "ko" and first.sprite.frame == 3: phase = "held"; waiting = 0
	elif phase == "revive" and not first.active(): phase = "recovered"; waiting = 0
	label.text = "BRASA · estudo de contato 1.1.0 · " + phase + "\nEntrada → ligação ao idle → KO mantido → levantar próprio. Revisão independente pendente."
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.brasaReview=" + JSON.stringify({"phase": phase, "samples": samples, "bodies": values}), true)
	tick += 1

func _finish() -> void:
	phase = "done"
	if not destination.is_empty():
		DirAccess.make_dir_recursive_absolute(destination)
		var file: FileAccess = FileAccess.open(destination.path_join("samples.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify({"engine": Engine.get_version_info(), "samples": samples}, "\t"))
		file.close()
	if autoplay: get_tree().quit()
