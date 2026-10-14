extends SceneTree
## Exercise actual initialization and graceful audio teardown, not a forced mid-stream exit.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await create_timer(0.15).timeout
	var conditions: Array = [app.screens.top() == "menu", app.registry.has("menu.play"), app.audio.voices.size() == 4]
	var ok: bool = not false in conditions
	print(JSON.stringify({"suite": "scene_startup", "checks": conditions.size(), "failed": conditions.count(false)}))
	app.audio.shutdown()
	await create_timer(0.12).timeout
	root.remove_child(app)
	app.queue_free()
	await process_frame
	quit(0 if ok else 1)
