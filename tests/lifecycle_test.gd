extends SceneTree
const Planner = preload("res://scripts/domain/selection_planner.gd")
## Regression cases crossing asynchronous feedback, view replacement and session lifetime.
var app: Control
var checks: int = 0
var failed: int = 0

func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + description)

func cast() -> void:
	for index in Planner.choose(app.game.hand, app.game.project, app.game.intent_damage()): app.game.toggle(index)
	app._on_view_action("cast", null)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.preferences.set_value("reduced_motion", false)
	app._on_view_action("start_game", 42013)
	cast()
	expect(app.feedback.busy and app.game.actions == 1, "A cast resolves once before visual feedback finishes")
	app._on_view_action("return_menu", null)
	app._on_view_action("start_game", 42014)
	await create_timer(0.65).timeout
	expect(not app.feedback.busy and app.game.actions == 0 and app.screens.top() == "battle", "Old callbacks cannot touch a new session")
	expect(app.feedback.labels.is_empty() and app.feedback.tweens.is_empty(), "Cancellation releases transient feedback resources")
	cast()
	var old_view: WeakRef = weakref(app.battle)
	app.preferences.set_value("large_text", true)
	await process_frame
	expect(old_view.get_ref() == null and not app.feedback.busy, "Text scaling replaces views and cancels feedback safely")
	await create_timer(0.65).timeout
	expect(app.game.actions == 1 and app.screens.top() == "battle", "Rebuilding presentation preserves the already resolved action")
	for node in app.navigation.controls.values():
		expect(is_instance_valid(node) and node.is_inside_tree(), "Navigation contains only current controls after rebuild")
	cast()
	app.preferences.set_value("reduced_motion", true)
	expect(not app.feedback.busy and app.battle.effects.particles.is_empty(), "Enabling reduced motion stops current feedback immediately")
	for actor in app.battle.actors:
		expect(actor.portrait.scale == Vector2.ONE, "Cancel returns current actors to their resting scale")
	app._on_view_action("push", "pause")
	app._on_view_action("push", "settings")
	expect(app.navigation.controls.has("settings.music"), "Settings register their own controls")
	app._on_view_action("pop", null)
	await process_frame
	expect(not app.navigation.controls.has("settings.music") and app.navigation.controls.has("pause.resume"), "Leaving an overlay unregisters its controls and restores the parent")
	app.feedback.cancel()
	app.audio.shutdown()
	await create_timer(0.15).timeout
	root.remove_child(app)
	app.queue_free()
	await process_frame
	print(JSON.stringify({"suite": "session_lifecycle", "checks": checks, "failed": failed}))
	quit(0 if failed == 0 else 1)
