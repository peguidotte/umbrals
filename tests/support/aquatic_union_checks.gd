extends RefCounted
## Private validated checkpoints exercise both water forms through normal resume and commits.
const Fixtures = preload("res://tests/support/scenario_fixtures.gd")
const Aquatic = preload("res://scripts/ui/aquatic_art.gd")
const Motion = preload("res://scripts/ui/battle_motion.gd")

static func _water_started(app: Control, source: Control, choreography: Node2D) -> bool:
	var deadline: int = Time.get_ticks_msec() + 18000
	while app.runtime.turn.busy and Time.get_ticks_msec() < deadline:
		if choreography.active and source.rig.managed and choreography.current_variant in [6, 7, 8]: return true
		await app.get_tree().process_frame
	return false

static func _select(app: Control, power: String) -> bool:
	for index: int in range(app.game.hand.size()):
		if app.game.hand[index].power == power:
			app.runtime.turn.select(index)
			return true
	return false

static func run(app: Control, expect: Callable) -> void:
	for form_id: String in ["dew", "mareveu"]:
		app._return_menu()
		app.preferences.set_value("reduced_motion", false)
		var fixture: Dictionary = Fixtures.make("motion_" + form_id)
		expect.call(not fixture.is_empty(), "Current validated water checkpoint exists: " + form_id)
		if fixture.is_empty(): continue
		fixture.snapshot["checkpoint_id"] = "native-water-union-" + form_id
		var saved: bool = app.session.run_save.save(fixture.snapshot)
		expect.call(saved, "Water checkpoint uses the real isolated two-slot save: " + form_id)
		if not saved: continue
		app._continue_expedition()
		await app.get_tree().process_frame
		var hud: Control = app.screen_host.battle_root.hud
		var source: Control = hud.actors[int(app.game.party[0].slot)]
		expect.call(app.runtime.turn.game == app.game and app.game.party[0].form_id == form_id and source.identity.form_id == form_id, "Resume binds commands and visible water owner to the same actual form: " + form_id)
		expect.call(source.rig.art_view == source.art_view and source.rig.source == Aquatic.region(form_id), "Both water forms retain the named-view rig contract and own source body")
		var bounds: Rect2 = source.get_global_rect()
		var rng: int = app.game.rng.state
		for mirrored: bool in [false, true]:
			source.rig.flipped = mirrored
			var dash: Vector2 = Vector2(-300 if mirrored else 300, 0)
			for variant: int in [6, 7, 8]:
				source.rig.seek_cast(variant, 0, dash)
				var home: Vector2 = Aquatic.orb_center(source.rig)
				source.rig.seek_cast(variant, float(Motion.spec(variant).contact), dash)
				var unit: float = maxf(source.rig.display_size.x, source.rig.display_size.y) / 166.0
				var offset: Vector2 = Vector2(-80 if mirrored else 80, -50) * unit
				var contact: Vector2 = source.rig.project(source.rig.foot) + dash + offset
				expect.call(Aquatic.orb_center(source.rig).distance_to(contact) < .01, "Each water form reaches the ground-relative contact on both sides: " + form_id)
				expect.call(source.emission_point(variant).distance_to(source.rig.to_global(Aquatic.orb_center(source.rig))) < .01, "Every water variation emits from its independent sphere: " + form_id)
				source.rig.seek_cast(variant, float(Motion.spec(variant).end), dash)
				expect.call(Aquatic.orb_center(source.rig).distance_to(home) < .1, "Both water forms return their sphere after every variation: " + form_id)
				source.stop_motion()
		source.rig.flipped = false
		expect.call(source.get_global_rect() == bounds and app.game.rng.state == rng, "Water presentation sampling preserves hit area and gameplay RNG: " + form_id)
		var before: Array[int] = []
		for actor: Control in hud.enemy_actors: before.append(int(actor.identity.hp))
		var selected: bool = _select(app, "rain_sweep")
		expect.call(selected, "The restored owner has a real multi-target water copy: " + form_id)
		if not selected: continue
		var cycles_before: int = int(hud.effects.choreography.cycles.get("ally:1:rain_sweep", 0))
		app.runtime.turn.cast()
		var committed_rng: int = app.game.rng.state
		var choreography: Node2D = hud.effects.choreography
		var started: bool = await _water_started(app, source, choreography)
		expect.call(started and int(choreography.cycles.get("ally:1:rain_sweep", 0)) == cycles_before + 1, "A real owned area-water commit starts exactly one sphere gesture: " + form_id)
		if not started: continue
		expect.call(choreography.renderer.target_points.size() == 2, "The actual water gesture retains both recipients: " + form_id)
		var frozen: float = choreography.renderer.clock
		app._push("pause")
		await app.get_tree().create_timer(.12).timeout
		expect.call(is_equal_approx(choreography.renderer.clock, frozen), "Pause freezes the shared multi-target water clock: " + form_id)
		app._pop()
		var deadline: int = Time.get_ticks_msec() + 18000
		while app.runtime.turn.busy and Time.get_ticks_msec() < deadline: await app.get_tree().process_frame
		expect.call(not app.runtime.turn.busy, "Both water forms finish the real committed area attack")
		var recipients: Array[int] = []
		for event: Dictionary in app.game.last_result.get("events", []):
			if event.get("kind") == "attack" and event.get("power") == "rain_sweep" and event.get("actor_uid") == 1:
				recipients.append(int(event.target_uid))
		expect.call(recipients.size() == 2 and recipients[0] != recipients[1], "One real area-water copy resolves against two distinct owners even when damage is blocked: " + form_id)
		var wet: int = 0
		for index: int in range(hud.enemy_actors.size()):
			var shown: Dictionary = hud.enemy_actors[index].identity
			var actual: Dictionary = app.game.enemies[index]
			expect.call(shown.hp == actual.hp and shown.statuses == actual.statuses, "Water target snapshots match the resolved rules, including blocked HP and statuses: " + form_id)
			if int(shown.uid) in recipients:
				if int(shown.statuses.get("wet", 0)) > 0: wet += 1
			else:
				expect.call(shown.hp == before[index] and not shown.statuses.has("wet"), "Area water leaves the unselected third target unaffected")
		expect.call(wet == 2 and not source.rig.managed and source.get_global_rect() == bounds, "Both recipients retain the water condition and the sphere releases its unchanged hit area: " + form_id)
		expect.call(app.game.rng.state == committed_rng, "Both water forms finish animation without extra gameplay RNG")
		selected = _select(app, "tidal_splash")
		expect.call(selected, "A second owned water cast remains available for cancellation")
		if selected:
			app.runtime.turn.cast()
			started = await _water_started(app, source, choreography)
			expect.call(started, "The cancellation check reaches an actual in-flight water sphere: " + form_id)
			app._return_menu()
			await app.get_tree().process_frame
			expect.call(not choreography.active and not source.rig.managed and not app.runtime.turn.busy, "Leaving combat cancels both water forms without a stale action clock")
		app.feedback.cancel()
