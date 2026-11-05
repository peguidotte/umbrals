extends RefCounted
const Fixtures = preload("res://tests/support/scenario_fixtures.gd")
const Water = preload("res://tests/support/aquatic_union_checks.gd")

static func run(app: Control, expect: Callable) -> void:
	app._return_menu()
	var fixture: Dictionary = Fixtures.make("motion_lonelo")
	fixture.snapshot.checkpoint_id = "lonelo-companion-combat"
	expect.call(app.session.run_save.save(fixture.snapshot), "Companion motion begins from real persisted checkpoint")
	app._continue_expedition()
	await app.get_tree().process_frame
	var hud: Control = app.screen_host.battle_root.hud
	var choreography: Node2D = hud.effects.choreography
	var before: int = int(choreography.cycles.get("ally:1:tidal_splash", 0))
	var selected: bool = Water._select(app, "tidal_splash")
	expect.call(selected, "Lonelo selects an actual owned single-target water copy")
	if not selected: return
	app.runtime.turn.cast()
	var deadline: int = Time.get_ticks_msec() + 20000
	while app.runtime.turn.busy and Time.get_ticks_msec() < deadline: await app.get_tree().process_frame
	expect.call(not app.runtime.turn.busy and int(choreography.cycles.get("ally:1:tidal_splash", 0)) == before + 2, "One real commit presents two separate water gestures")
	var hits: Array = app.game.last_result.events.filter(func(e: Dictionary) -> bool: return e.kind == "attack" and e.actor_side == "ally")
	expect.call(hits.size() == 2 and hits[1].get("companion", false), "Actual scene presents the companion event, not an invented visual repeat")
	for actor: Control in hud.enemy_actors:
		if actor.identity.is_empty(): continue
		for target: Dictionary in app.game.enemies:
			if target.uid == actor.identity.uid: expect.call(target.hp == actor.identity.hp and target.block == actor.identity.block, "Final visible HP and shield match both resolved strikes")
	app._return_menu()
	app.feedback.cancel()
