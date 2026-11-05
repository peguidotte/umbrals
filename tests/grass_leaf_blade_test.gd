extends SceneTree
## Optional focused runner; full acceptance calls the same helper.
var checks: int = 0
var failed: int = 0

func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + description)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var app: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	await preload("res://tests/support/grass_leaf_blade_checks.gd").run(app, expect)
	app.feedback.cancel()
	app.audio.shutdown()
	await create_timer(0.12).timeout
	app.queue_free()
	await process_frame
	print(JSON.stringify({"suite": "grass_leaf_blade", "checks": checks, "failed": failed}))
	quit(0 if failed == 0 else 1)
