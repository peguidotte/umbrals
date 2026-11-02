extends SceneTree
var app: Control
func _init() -> void: call_deferred("run")
func capture(name: String) -> void:
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/gold-reference/"+name+".png")
func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.visual_capture = true
	app.preferences.values.reduced_motion = true
	app.menu_root.apply_preferences(true,true,1.0)
	await capture("menu")
	# An explicit visual fixture, isolated from user storage; discoveries are not fabricated in production.
	app.codex_progress.mark("umbrals","ember")
	app.codex_progress.mark("umbrals","moss")
	app.codex_progress.mark("umbrals","ignivar")
	app.codex_progress.mark("powers","fireball")
	app._push("codex")
	await capture("codex")
	app.registry["codex.entry.moss"].pressed.emit()
	await capture("musgo")
	app.registry["codex.entry.volt"].pressed.emit()
	await capture("unknown")
	app.audio.shutdown()
	root.remove_child(app)
	app.queue_free()
	await create_timer(0.25).timeout
	for frame in range(5): await process_frame
	call_deferred("quit")
