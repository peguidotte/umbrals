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
	app._return_menu()
	app.preferences.set_value("reduced_motion", false)
	app._start_game(42013, "dew")
	await process_frame
	hud = app.screen_host.battle_root.hud
	source = hud.actors[1]
	var aquatic = preload("res://scripts/ui/aquatic_art.gd")
	expect(source.rig.source == aquatic.region("dew"), "Lonlon uses the separate approved-direction otter body")
	var body_rect: Rect2 = source.get_global_rect()
	var aquatic_rng: int = app.game.rng.state
	# visual=1 freezes ambient idle only, never a committed performance.
	source.rig.still = true
	for variant in range(6, 9):
		var spec: Dictionary = Motion.spec(variant)
		source.rig.seek_cast(variant, 0.0, Vector2(300, 0))
		var home: Vector2 = aquatic.orb_center(source.rig)
		source.rig.seek_cast(variant, float(spec.contact), Vector2(300, 0))
		expect(aquatic.orb_center(source.rig).x > home.x + 200, "Water sphere leaves the otter toward the actual target for variant %d" % variant)
		var unit: float = maxf(source.rig.display_size.x, source.rig.display_size.y) / 166.0
		var destination: Vector2 = source.rig.project(source.rig.foot) + Vector2(300 + 80 * unit, -50 * unit)
		expect(aquatic.orb_center(source.rig).distance_to(destination) < 0.01, "Sphere contact is relative to the target ground, not its elevated home")
		expect(source.emission_point(variant).distance_to(source.rig.to_global(aquatic.orb_center(source.rig))) < 0.01, "Water emission follows the separate sphere")
		source.rig.seek_cast(variant, float(spec.end), Vector2(300, 0))
		expect(aquatic.orb_center(source.rig).distance_to(home) < 0.1, "Water sphere returns after variant %d" % variant)
		source.stop_motion()
	source.rig.still = false
	source.rig.flipped = true
	source.rig.seek_cast(6, 0.0, Vector2(-300, 0))
	var mirrored_home: Vector2 = aquatic.orb_center(source.rig)
	source.rig.seek_cast(6, float(Motion.spec(6).contact), Vector2(-300, 0))
	expect(aquatic.orb_center(source.rig).x < mirrored_home.x - 200, "Opposing water sphere travels left without changing combat coordinates")
	source.rig.flipped = false
	source.stop_motion()
	expect(source.get_global_rect() == body_rect and app.game.rng.state == aquatic_rng, "Sphere travel cannot move the targetable slot or consume gameplay RNG")
	var water_index: int = -1
	for i in range(app.game.hand.size()):
		if app.game.hand[i].power == "tidal_splash": water_index = i; break
	expect(water_index >= 0, "A real owned water power is available")
	if water_index >= 0:
		app.runtime.turn.select(water_index)
		app.runtime.turn.cast()
		await create_timer(0.3).timeout
		expect(hud.effects.choreography.active and source.rig.managed, "Real water action drives the independent sphere clock")
		app.preferences.set_value("reduced_motion", true)
		await settle(2.0)
		expect(not source.rig.managed and source.rig.mode == "states", "Reduced motion restores sphere and body after a real water cast")
		var fixed: Vector2 = aquatic.orb_center(source.rig)
		await create_timer(0.15).timeout
		expect(aquatic.orb_center(source.rig).is_equal_approx(fixed), "Reduced-motion sphere remains still")
	app.feedback.cancel()
	app.audio.shutdown()
	await create_timer(0.12).timeout
	app.queue_free()
	await process_frame
	print(JSON.stringify({"suite": "battle_motion", "checks": checks, "failed": failed}))
	quit(0 if failed == 0 else 1)
