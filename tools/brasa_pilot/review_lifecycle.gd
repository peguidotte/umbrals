extends SceneTree
const Assets = preload("res://scripts/assets/catalog.gd")
const Rig = preload("res://scripts/ui/creature_rig.gd")
const Lifecycle = preload("res://scripts/ui/creature_lifecycle.gd")
var bodies: Array = []
var destination: String = ""
var samples: Array = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): destination = arg.trim_prefix("--output=")
	if destination.is_empty(): quit(2); return
	DirAccess.make_dir_recursive_absolute(destination)
	var ignore: FileAccess = FileAccess.open(destination.path_join(".gdignore"), FileAccess.WRITE)
	ignore.close()
	root.size = Vector2i(1600, 900)
	root.content_scale_size = Vector2i(1600, 900)
	var stage: Node2D = Node2D.new()
	root.add_child(stage)
	var background: Sprite2D = Sprite2D.new()
	background.texture = load(Assets.file_path("world/battle-clearing-depth", "1.0.0", "background"))
	background.centered = false
	background.scale = Vector2(1600, 900) / background.texture.get_size()
	stage.add_child(background)
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = load(Assets.file_path("characters/battle-creatures", "1.0.0", "texture"))
	atlas.region = Rect2(40, 54, 371, 364)
	for i in range(3):
		var group: Node2D = Node2D.new()
		group.position = [Vector2(180, 300), Vector2(650, 300), Vector2(1120, 280)][i]
		group.scale = Vector2.ONE * (3 if i == 2 else 1)
		stage.add_child(group)
		var image: Node2D = Rig.new()
		image.paused = true
		var dimensions: Vector2 = Vector2(371, 364) * (118.0 / 339)
		var pivot: Vector2 = Vector2(210, 350) * (118.0 / 339)
		image.configure(atlas, "ember", dimensions, pivot, i == 1)
		group.add_child(image)
		var life: Node2D = Lifecycle.new()
		group.add_child(life)
		life.configure("ember", dimensions, pivot, i == 1, {"id": "characters/brasa-lifecycle", "version": "0.2.0"})
		life.enter()
		if life.sprite.sprite_frames == null or not life.sprite.sprite_frames.has_animation("walk"):
			push_error("Candidate walk was not imported; no evidence can be recorded")
			quit(2)
			return
		bodies.append({"image": image, "life": life})
		var label: Label = Label.new()
		label.text = ["118 px · tamanho real", "118 px · espelhado", "Detalhe 3×"][i]
		label.position = group.position - Vector2(70, 60)
		label.add_theme_font_size_override("font_size", 22)
		stage.add_child(label)
	var title: Label = Label.new()
	title.text = "BRASA · poses de locomoção e KO · candidato\nEntrada com passos → repouso → incapacitação reversível; sem mudanças de regras."
	title.position = Vector2(35, 30)
	title.add_theme_font_size_override("font_size", 25)
	stage.add_child(title)
	call_deferred("capture")

func capture() -> void:
	await process_frame
	for frame in range(60):
		var t: float = frame / 30.0
		var values: Array = []
		for body in bodies:
			if frame == 30: body.life.set_incapacitated(true)
			body.life.advance(0 if frame in [0, 30] else 1.0 / 30, false, false)
			body.image.visible = not body.life.active()
			values.append({"state": body.life.state, "frame": body.life.sprite.frame, "position": [body.life.position.x, body.life.position.y]})
		samples.append({"seconds": t, "bodies": values})
		await process_frame
		await RenderingServer.frame_post_draw
		var result: Error = root.get_texture().get_image().save_png(destination.path_join("frame-%03d.png" % frame))
		if result != OK: quit(2); return
	var file: FileAccess = FileAccess.open(destination.path_join("samples.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(samples, "\t"))
	file.close()
	print("BRASA_POSE_REVIEW frames=60 native_height=118")
	quit()
