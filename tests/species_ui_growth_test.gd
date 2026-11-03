extends SceneTree
const Content = preload("res://scripts/content.gd")
const Models = preload("res://scripts/domain/models.gd")
const Rewards = preload("res://scripts/ui/screens/reward_screen.gd")
const Evolution = preload("res://scripts/catalog/evolution_definition.gd")
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
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app._on_view_action("start_game", 42013)
	var index: int = -1
	for i in range(app.game.hand.size()):
		if app.game.hand[i].power == "fireball": index = i; break
	var old_id: int = app.battle.cards[index].get_instance_id()
	var hand_before: Array = app.game.snapshot().hand
	app.game.party[0].form_id = "ignivar"
	app._sync_battle()
	expect(app.game.snapshot().hand == hand_before, "Fixture changes form without changing card instance IDs")
	expect(app.battle.cards[index].power.damage == 17 and app.battle.cards[index].get_instance_id() != old_id, "Form-only changes refresh displayed power stats")
	for i in range(7):
		var species: Content.Species = Content.SPECIES.ember.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
		species.species_id = "ui_fixture_%d" % i
		if i == 0: species.forms[0].powers.resize(1)
		var terminal: Content.Form = species.forms[-1].duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
		terminal.form_id = "extra"
		terminal.display_name = "Uma terceira forma com um nome comprido"
		species.forms.append(terminal)
		var branch = Evolution.new()
		branch.transition_id = "to_extra"
		branch.target_form_id = "extra"
		species.forms[0].evolutions.append(branch)
		app.game.catalog.species[species.species_id] = species
	expect(Rewards.capture_description(Models.Individual.new("ui_fixture_0", "fierce", 100, "ember"), app.game.catalog) == "Adiciona um poder ao grimório.", "Capture copy follows the authored power count")
	app._on_view_action("push", "codex")
	await process_frame
	await process_frame
	expect(app.game.catalog.species.size() == 10 and app.navigation.controls.has("codex.list"), "Ten species with branched forms get a scrollable codex")
	var scroll: ScrollContainer = app.navigation.controls["codex.list"]
	expect(scroll.get_combined_minimum_size().x < app.overlay.size.x and scroll.size.x <= app.overlay.size.x, "Long evolution paths wrap inside the codex canvas")
	expect(scroll.get_child(0).get_child_count() == 10, "Every species remains represented in the growing grid")
	app._on_view_action("pop", null)
	await create_timer(0.65).timeout
	app.feedback.cancel()
	app.audio.shutdown()
	await create_timer(0.15).timeout
	root.remove_child(app)
	app.queue_free()
	await process_frame
	await process_frame
	print(JSON.stringify({"suite": "species_ui_growth", "checks": checks, "failed": failed}))
	quit(0 if failed == 0 else 1)
