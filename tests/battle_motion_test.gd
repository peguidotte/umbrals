extends SceneTree
## Actual committed powers exercise contact timing, pause, cancellation and variants.
const Events = preload("res://scripts/ui/attack_events.gd")
const Motion = preload("res://scripts/ui/battle_motion.gd")
var checks: int = 0
var failed: int = 0
var app: Control

func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + description)

func _init() -> void:
	call_deferred("_run")

func settle(limit: float = 18.0) -> void:
	var deadline: int = Time.get_ticks_msec() + int(limit * 1000)
	while app.runtime.turn.busy and Time.get_ticks_msec() < deadline: await process_frame
	expect(not app.runtime.turn.busy, "Presentation returns control within its bounded duration")

func cast_fireball() -> bool:
	for i in range(app.game.hand.size()):
		if app.game.hand[i].power == "fireball":
			app.runtime.turn.select(i)
			app.runtime.turn.cast()
			return true
	return false

func synthetic(kind: String, target: int, power: String = "thorn_lash") -> Dictionary:
	return {"kind": kind, "actor_side": "ally", "actor_uid": 1, "power": power, "target_side": "enemy", "target_uid": target}

func _run() -> void:
	var area: Array = [synthetic("attack", 100), synthetic("condition", 100), synthetic("attack", 101), synthetic("block", 1), synthetic("attack", 100), synthetic("attack", 101)]
	var group: Dictionary = Events.collect(area, 0)
	expect(int(group.next) == 4 and group.events.size() == 4, "Two area targets and their effects share one gesture, while a repeated card remains separate")
	var singles: Array = [synthetic("attack", 100, "fireball"), synthetic("condition", 100, "fireball"), synthetic("attack", 101, "fireball")]
	expect(int(Events.collect(singles, 0).next) == 2, "Two single-target copies are never merged, even with different recipients")
	var unrelated: Array = area.slice(0, 2)
	var opponent: Dictionary = synthetic("attack", 1)
	opponent.actor_side = "enemy"
	opponent.actor_uid = 200
	unrelated.append(opponent)
	expect(int(Events.collect(unrelated, 0).next) == 2, "Interleaved enemy initiative ends the current presentation group")
	Motion.ensure_loaded()
	expect(Motion.data.forms.size() == 8 and Motion.choreography.specs.size() == 15, "The approved eight forms and fifteen clocks load through exact pinned dependencies")
	for id in Motion.data.forms:
		var rest: Array = Motion.sample(id, "attacks", 1, 0)
		var final: Array = Motion.sample(id, "attacks", 1, 3.1)
		expect(is_equal_approx(float(rest[0]), float(final[0])) and is_equal_approx(float(rest[1]), float(final[1])), "Cast returns its root to the floor: " + id)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.preferences.set_value("reduced_motion", false)
	app._start_game(42013, "ember")
	await process_frame
	var hud: Control = app.screen_host.battle_root.hud
	var source: Control = hud.actors[1]
	var target: Control = hud.enemy_actors[1]
	var rect: Rect2 = source.get_global_rect()
	var old_socket: Vector2 = source.emission_point(0)
	source.rig.seek_cast(0, 0.72, Vector2.ZERO)
	expect(source.emission_point(0).distance_to(old_socket) > 1 and source.get_global_rect() == rect, "Posed emission moves with the body while targetable slot geometry stays fixed")
	source.stop_motion()
	var hp: int = int(target.identity.hp)
	expect(cast_fireball(), "Commit a real owned fireball through the application turn")
	var rng_after_commit: int = app.game.rng.state
	await create_timer(0.25).timeout
	expect(app.runtime.turn.busy and hud.effects.choreography.active and hud.effects.choreography.current_variant == 0 and int(target.identity.hp) == hp, "The owned fireball starts its approved variant without exposing future HP during the windup")
	var clock: float = hud.effects.choreography.renderer.clock
	app._push("pause")
	await create_timer(0.20).timeout
	expect(is_equal_approx(hud.effects.choreography.renderer.clock, clock) and int(target.identity.hp) == hp, "Pause freezes the action clock before contact without applying a snapshot")
	expect(hud.effects.choreography.voice.stream_paused, "Pause suspends the original attack voice on the SFX pool")
	app._pop()
	await create_timer(1.05).timeout
	expect(int(target.identity.hp) < hp, "The actual target snapshot is visible after contact")
	await settle()
	expect(app.game.rng.state == rng_after_commit, "Meshes, sound, particles and reaction choice never consume gameplay RNG")
	expect(int(hud.effects.choreography.cycles.get("ally:1:fireball", 0)) == 1 and hud.effects.hits > 0, "Native fireball completes one approved gesture with real impact feedback before enemy initiative")
	var initial_cycles: int = int(hud.effects.choreography.cycles.get("ally:1:fireball", 0))
	for repeat in range(2):
		expect(cast_fireball(), "A subsequent owned copy can be conjured")
		await settle()
	expect(int(hud.effects.choreography.cycles.get("ally:1:fireball", 0)) == initial_cycles + 2, "Repeated powers rotate presentation variants independently of the card/deck model")
	expect(app.audio.voices.size() == 4, "Synchronized performances reuse the four bounded SFX voices")
	expect(cast_fireball(), "Start a cancellable committed attack")
	await create_timer(0.18).timeout
	app._return_menu()
	await process_frame
	expect(not hud.effects.choreography.active and not source.rig.managed and not app.runtime.turn.busy, "Leaving combat cancels sound and managed poses and releases the committed turn")
	app._start_game(42013, "ember")
	await process_frame
	hud = app.screen_host.battle_root.hud
	expect(cast_fireball(), "Begin another action before changing accessibility")
	await create_timer(0.18).timeout
	app.preferences.set_value("reduced_motion", true)
	await settle(2.0)
	expect(hud.effects.trauma == 0 and hud.effects.particles.is_empty() and not hud.effects.choreography.active, "Enabling reduced motion clears an in-flight performance immediately and finishes snapshots")
	for body in hud.actors + hud.enemy_actors:
		expect(not body.rig.managed, "Accessibility cancellation releases every managed actor")
	await lifecycle_checks()
	await lifecycle_deploy_checks()
	await lifecycle_alignment_checks()
	app.feedback.cancel()
	app.audio.shutdown()
	await create_timer(0.12).timeout
	app.queue_free()
	await process_frame
	print(JSON.stringify({"suite": "battle_motion", "checks": checks, "failed": failed}))
	quit(0 if failed == 0 else 1)

func lifecycle_checks() -> void:
	app._return_menu()
	app.preferences.set_value("reduced_motion", false)
	var fixture: Dictionary = preload("res://tests/support/scenario_fixtures.gd").make("brasa_lifecycle")
	var run = preload("res://scripts/expedition/expedition.gd").new()
	expect(run.restore(fixture.snapshot), "Brasa lifecycle uses a valid existing expedition checkpoint")
	app._start_game()
	app.session.expedition = run
	app.session.expedition_active = true
	app.runtime.bind_game(run.battle)
	app._sync_battle()
	app.screens.reset("battle")
	app._sync_phase()
	await process_frame
	var hud: Control = app.screen_host.battle_root.hud
	var body: Control = hud.actors[1]
	var bounds: Rect2 = body.get_global_rect()
	expect(app.game.queue_swap(3, 1), "Plan a real reserve Brasa into the occupied central slot")
	expect(int(body.identity.uid) == 3 and not body.rig.lifecycle.active(), "Planning does not move an actor or start locomotion")
	app.runtime.turn.cast()
	var committed_rng: int = app.game.rng.state
	var deadline: int = Time.get_ticks_msec() + 2000
	while int(body.identity.get("uid", -1)) != 1 and Time.get_ticks_msec() < deadline: await process_frame
	expect(int(body.identity.uid) == 1 and body.rig.lifecycle.state == "walk", "Committed substitution plays the incoming form's authored walk")
	var first_position: Vector2 = body.rig.lifecycle.position
	await create_timer(0.15).timeout
	expect(body.rig.lifecycle.sprite.frame > 0 and body.rig.lifecycle.position.distance_to(first_position) > 1 and body.get_global_rect() == bounds, "Leg poses and visual root advance while slot targeting stays fixed")
	var clock: float = body.rig.lifecycle.elapsed
	app._push("pause")
	await create_timer(0.12).timeout
	expect(is_equal_approx(body.rig.lifecycle.elapsed, clock), "Pause freezes an active entry walk")
	app._pop()
	await settle()
	expect(app.game.rng.state == committed_rng, "Walk and KO do not consume gameplay RNG after commit")
	expect(int(body.identity.hp) == 0 and body.rig.lifecycle.incapacitated and body.rig.lifecycle.state == "ko", "An actual damaging hit triggers KO on the same individual")
	await create_timer(0.65).timeout
	expect(body.rig.lifecycle.sprite.frame == 3, "KO settles and holds its last pose")
	body.stop_motion()
	expect(body.rig.lifecycle.state == "ko" and body.rig.lifecycle.sprite.frame == 3, "Presentation cancellation cannot stand an incapacitated creature up")
	var restored_body: Control = preload("res://scripts/ui/actor.gd").new()
	restored_body.size = Vector2(230, 230)
	root.add_child(restored_body)
	restored_body.set_identity(body.identity)
	expect(restored_body.rig.lifecycle.state == "ko" and restored_body.rig.lifecycle.sprite.frame == 3, "A restored incapacitated snapshot starts at rest without replaying a fall")
	restored_body.queue_free()
	app.preferences.set_value("reduced_motion", true)
	expect(body.rig.lifecycle.sprite.frame == 3, "Reduced motion preserves the readable KO pose")
	app.preferences.set_value("reduced_motion", false)
	if app.screens.top() == "ko_replacement": app.commands.finish_ko()
	expect(app.game.queue_item("revive", 1), "Queue an owned revival through the existing item rules")
	app.runtime.turn.cast()
	deadline = Time.get_ticks_msec() + 2000
	while int(body.identity.hp) == 0 and Time.get_ticks_msec() < deadline: await process_frame
	expect(int(body.identity.hp) > 0 and body.rig.lifecycle.state == "revive", "A committed revival traverses recovery poses before returning to standing")
	await settle()
	await create_timer(0.8).timeout
	expect(int(body.identity.hp) > 0 and not body.rig.lifecycle.incapacitated and not body.rig.lifecycle.active(), "A real revival releases KO and restores normal idle/casts")

func lifecycle_deploy_checks() -> void:
	app._return_menu()
	app.preferences.set_value("reduced_motion", false)
	var fixture: Dictionary = preload("res://tests/support/scenario_fixtures.gd").make("brasa_lifecycle")
	var run = preload("res://scripts/expedition/expedition.gd").new()
	expect(run.restore(fixture.snapshot), "Fresh deploy uses the same validated checkpoint")
	app._start_game()
	app.session.expedition = run
	app.session.expedition_active = true
	app.runtime.bind_game(run.battle)
	app._sync_battle()
	app.screens.reset("battle")
	app._sync_phase()
	await process_frame
	var body: Control = app.screen_host.battle_root.hud.actors[2]
	expect(body.identity.is_empty() and app.game.queue_deploy(2, 1), "Plan Brasa into an actually empty field slot")
	app.runtime.turn.cast()
	var deadline: int = Time.get_ticks_msec() + 2000
	while int(body.identity.get("uid", -1)) != 1 and Time.get_ticks_msec() < deadline: await process_frame
	expect(body.rig.lifecycle.state == "walk", "The committed deploy event plays entry even without a previous occupant")
	app.preferences.set_value("reduced_motion", true)
	expect(not body.rig.lifecycle.active(), "Reduced motion immediately cancels an in-flight entry walk")
	await settle(2.0)

func lifecycle_foot(body: Control) -> Vector2:
	var life: Node2D = body.rig.lifecycle
	var pivot: Array = life.manifest.animations[life.sprite.animation].pivot
	return life.sprite.to_global(Vector2(float(pivot[0]), float(pivot[1])))

func lifecycle_alignment_checks() -> void:
	for enemy in [false, true]:
		for slot in range(3):
			var body: Control = preload("res://scripts/ui/actor.gd").new()
			body.enemy = enemy
			body.slot = slot
			body.position = Vector2(200, 120)
			body.size = Vector2(230, 230)
			root.add_child(body)
			body.rig.paused = true
			body.rig.still = true
			body.set_identity(preload("res://scripts/rules.gd").make_umbral("ember", "vital", 1))
			var bounds: Rect2 = body.get_global_rect()
			var floor: Vector2 = body.visual_ground()
			var label: String = "%s slot %d" % ["enemy" if enemy else "ally", slot]
			body.rig.set_incapacitated(true, false)
			var error: float = lifecycle_foot(body).distance_to(floor)
			expect(error < 0.05, "KO shares the target slot floor: %s (%.3f px)" % [label, error])
			body.rig.set_incapacitated(false, false)
			expect(not body.rig.lifecycle.active() and body.rig.to_global(body.rig.project(body.rig.foot)).distance_to(floor) < 0.05, "Restored mesh returns to the same floor: " + label)
			body.rig.enter_field()
			body.rig.lifecycle.advance(0.799, false, false)
			error = lifecycle_foot(body).distance_to(floor)
			expect(error < 0.2, "Last entry pose approaches the mesh floor: %s (%.3f px)" % [label, error])
			body.rig.lifecycle.advance(0.02, false, false)
			expect(body.rig.lifecycle.mesh_weight() > 0 and body.rig.lifecycle.mesh_weight() < 1, "Entry blends its last pose into the existing mesh: " + label)
			body.rig.lifecycle.advance(0.12, false, false)
			expect(not body.rig.lifecycle.active() and body.get_global_rect() == bounds, "Entry returns to idle without moving target geometry: " + label)
			body.rig.set_incapacitated(true, false)
			body.rig.set_incapacitated(false, true)
			expect(body.rig.lifecycle.state == "revive" and body.rig.lifecycle.sprite.frame == 3, "Event revival starts from the held lying pose: " + label)
			body.rig.lifecycle.advance(0.31, false, false)
			var clock: float = body.rig.lifecycle.elapsed
			body.rig.lifecycle.advance(0.3, true, false)
			expect(body.rig.lifecycle.sprite.frame == 1 and is_equal_approx(body.rig.lifecycle.elapsed, clock), "Recovery reverses the existing KO poses and respects pause: " + label)
			body.rig.lifecycle.advance(0.30, false, false)
			expect(body.rig.lifecycle.state == "settle" and lifecycle_foot(body).distance_to(floor) < 0.05, "Recovery blends back at the same floor: " + label)
			body.rig.lifecycle.advance(0, false, true)
			expect(not body.rig.lifecycle.active() and body.rig.to_global(body.rig.project(body.rig.foot)).distance_to(floor) < 0.05, "Reduced motion settles recovery immediately at the mesh floor: " + label)
			body.rig.set_incapacitated(true, false)
			body.rig.set_incapacitated(false, true)
			body.rig.seek_cast(0, 0.1, Vector2.ZERO)
			expect(not body.rig.lifecycle.active(), "A new cast can preempt cosmetic recovery without waiting: " + label)
			body.queue_free()
	await process_frame
