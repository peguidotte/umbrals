extends SceneTree
## Renders the real native mesh, exact atlas and deformed sockets. No main scene or save service.
const Assets = preload("res://scripts/assets/catalog.gd")
const Rig = preload("res://tools/brasa_pilot/pilot_rig.gd")
const FPS: int = 30
const FRAME_COUNT: int = 97
const CELLS: Array[String] = ["Idle existente", "Walk: blocking pendente", "Dano existente", "Boca", "Cauda", "Pata"]
var stage: Node2D
var rigs: Array[Node2D] = []
var output_dir: String = ""
var projections: Array = []
var guides: Guides
var source_hashes: Dictionary = {}

class Guides extends Node2D:
	var points: Array[Vector2] = []
	func _draw() -> void:
		for point in points:
			draw_circle(point, 5, Color("75ffe5"), false, 2)
			draw_line(point - Vector2(9, 0), point + Vector2(9, 0), Color.WHITE, 1)
			draw_line(point - Vector2(0, 9), point + Vector2(0, 9), Color.WHITE, 1)
		for row in range(2):
			for column in range(3):
				var foot: Vector2 = Vector2(196.1509 + column * 415, 333.5849 + row * 292)
				draw_line(foot - Vector2(83, 0), foot + Vector2(83, 0), Color(0.7, 0.85, 0.9, 0.5), 1)
				draw_circle(foot, 3, Color("ffd879"))

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output_dir = arg.trim_prefix("--output=")
	if output_dir.is_empty():
		push_error("Pass -- --output=<artifact-directory>")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	var ignore: FileAccess = FileAccess.open(output_dir.path_join(".gdignore"), FileAccess.WRITE)
	ignore.close()
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	stage = Node2D.new()
	root.add_child(stage)
	var backdrop: Sprite2D = Sprite2D.new()
	backdrop.texture = load(Assets.file_path("world/battle-clearing-depth", "1.0.0", "background"))
	backdrop.centered = false
	backdrop.scale = Vector2(1280, 720) / backdrop.texture.get_size()
	stage.add_child(backdrop)
	var label: Label = Label.new()
	label.text = "BRASA · piloto nativo · arte existente · 30 FPS\nWalk é estudo de malha; derrota e transferência de referências seguem pendentes."
	label.position = Vector2(24, 18)
	label.add_theme_font_size_override("font_size", 20)
	stage.add_child(label)
	var atlas_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Assets.file_path("characters/battle-creatures", "1.0.0", "atlas")))
	var rect: Array = atlas_data.regions.ember
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = load(Assets.file_path("characters/battle-creatures", "1.0.0", "texture"))
	atlas.region = Rect2(float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3]))
	atlas.filter_clip = true
	var walk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Assets.file_path("characters/brasa-pilot", "0.1.0", "walk")))
	for source_path in [
		"tools/brasa_pilot/preview.gd", "tools/brasa_pilot/pilot_rig.gd", "scripts/ui/creature_rig.gd",
		"scripts/ui/battle_motion.gd", "assets/catalog.json", "assets/runtime-lock.json",
		"assets/characters/brasa-pilot/versions/0.1.0/walk.json",
		"assets/characters/brasa-pilot/versions/0.1.0/manifest.json",
		"assets/characters/battle-motion/versions/1.0.0/motion.json",
		"assets/characters/battle-creatures/versions/1.0.0/atlas.json",
		"assets/characters/battle-creatures/versions/1.0.0/texture.png",
		"assets/world/battle-clearing-depth/versions/1.0.0/background.png",
	]:
		source_hashes[source_path] = FileAccess.get_sha256("res://" + source_path)
	for cell in range(6):
		var origin: Vector2 = Vector2(70 + (cell % 3) * 415, 112 + floori(cell / 3.0) * 292)
		var caption: Label = Label.new()
		caption.text = CELLS[cell]
		caption.position = origin
		caption.add_theme_font_size_override("font_size", 19)
		stage.add_child(caption)
		var rig: Node2D = Rig.new()
		rig.position = origin + Vector2(22, 48)
		rig.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rig.paused = true
		rig.configure(atlas, "ember", Vector2(184, 180.5283), Vector2(104.1509, 173.5849), false)
		rig.walk_frames = walk.forms.ember.states["6"]
		stage.add_child(rig)
		rigs.append(rig)
	guides = Guides.new()
	stage.add_child(guides)
	call_deferred("_capture")

func _capture() -> void:
	await process_frame
	for frame in range(FRAME_COUNT):
		var time: float = float(frame) / FPS
		var metrics: Dictionary = {"frame": frame, "seconds": time, "sockets": []}
		guides.points.clear()
		for cell in range(6):
			var rig: Node2D = rigs[cell]
			rig.show_walk = cell == 1
			rig.walk_time = time
			rig.mode = "attacks" if cell >= 3 else "states"
			rig.clip = cell - 3 if cell >= 3 else 3 if cell == 2 else 0
			rig.elapsed = time
			rig.idle_time = time
			rig._refresh()
			if cell >= 3:
				var socket: Vector2 = rig.socket(cell - 3)
				guides.points.append(socket)
				metrics.sockets.append({"part": ["mouth", "tail", "fore"][cell - 3], "x": socket.x, "y": socket.y})
		projections.append(metrics)
		guides.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var picture: Image = root.get_texture().get_image()
		var saved: Error = picture.save_png(output_dir.path_join("frame-%03d.png" % frame))
		if saved != OK:
			push_error("Frame save failed: " + str(saved))
			quit(2)
			return
	var report: FileAccess = FileAccess.open(output_dir.path_join("native-projections.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify({"engine": Engine.get_version_info(), "frames": FRAME_COUNT,
		"source_hashes": source_hashes, "samples": projections}, "\t"))
	report.close()
	print("BRASA_NATIVE_CAPTURE frames=", FRAME_COUNT, " sockets=", FRAME_COUNT * 3)
	quit(0)
