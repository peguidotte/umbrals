extends RefCounted
## Behavior checks for the independently pinned Foli presentation.
const Motion = preload("res://scripts/ui/battle_motion.gd")
const Assets = preload("res://scripts/assets/catalog.gd")
const Art = preload("res://scripts/ui/battle_art.gd")

static func run(app: Control, expect: Callable) -> void:
	app._start_game(42013, "moss")
	await app.get_tree().process_frame
	var hud: Control = app.screen_host.battle_root.hud
	var actor: Control = hud.actors[1]
	var body: Dictionary = actor.identity.duplicate(true)
	var slot_rect: Rect2 = actor.get_global_rect()
	expect.call(Art.texture("umbrals/moss") == Assets.texture("umbrals/moss"), "Foli battle and portrait use the deliberately pinned hare, not the old moss atlas")
	expect.call(Motion.form("moss").profile.name == "Foli" and Motion.form("verdalio").profile.name != "Foli", "The Foli override does not replace Folife's separate legacy profile")
	var legacy: Array = Motion.data.forms.moss.states["0"][24]
	expect.call(Motion.sample("spore", "states", 0, 0.8) == legacy, "An enemy's material fallback retains its historical motion rather than inheriting Foli's new override")
	var authored: Array = Motion.sample("moss", "states", 0, 0.8)
	expect.call(authored != Motion.neutral() and authored[0] == 0 and authored[1] == 0 and authored[3] == 1 and authored[4] == 1, "Idle moves anatomical parts without translating or scaling planted feet")
	for mirrored: bool in [false, true]:
		actor.enemy = mirrored
		actor.set_identity(body)
		actor.rig.idle_time = 0.8
		actor.rig._refresh()
		var floor_at: Vector2 = actor.rig.to_global(actor.rig.project(actor.rig.foot))
		expect.call(floor_at.distance_to(actor.visual_ground()) < 0.25, "Foli's planted floor survives idle and mirrored layout")
		for variant: int in [3, 4, 5]:
			actor.rig.seek_cast(variant, float(Motion.spec(variant).release), Vector2.ZERO)
			var emission: Vector2 = actor.emission_point(variant)
			expect.call(emission.is_finite() and actor.get_global_rect() == slot_rect, "Each Foli forest socket follows its pose without moving the targetable slot")
			var local: Vector2 = emission - actor.visual_ground()
			expect.call(local.x < 0 if mirrored else local.x > 0, "Foli casts toward the opposing group after mirroring")
			actor.rig.seek_cast(variant, 3.2, Vector2.ZERO)
			expect.call(actor.rig.pose == Motion.neutral(), "Foli cast settles back to its authored resting pose")
	actor.enemy = false
	actor.set_identity(body)
	actor.rig.seek_cast(3, 0.5, Vector2.ZERO)
	actor.stop_motion()
	expect.call(not actor.rig.managed and actor.rig.clip == 0, "Cancellation releases Foli's own managed pose")
	actor.reduced_motion = true
	actor.rig.seek_cast(3, 0.9, Vector2.ZERO)
	expect.call(actor.rig.pose == Motion.neutral(), "Reduced motion applies immediately to Foli's authored override")
	actor.stop_motion()
	actor.reduced_motion = false
	var selected: bool = false
	for i in range(app.game.hand.size()):
		if app.game.hand[i].power == "thorn_lash":
			app.runtime.turn.select(i)
			selected = true
			break
	expect.call(selected, "The Foli pilot still uses a real owned forest power")
	app.runtime.turn.cast()
	var rng_after_commit: int = app.game.rng.state
	await app.get_tree().create_timer(0.25).timeout
	expect.call(app.runtime.turn.busy and hud.effects.choreography.current_variant == 3 and actor.rig.form_id == "moss", "A real Foli cast uses its own rig and the first forest performance")
	app._push("pause")
	var time: float = actor.rig.elapsed
	await app.get_tree().create_timer(0.15).timeout
	expect.call(is_equal_approx(actor.rig.elapsed, time), "Pause freezes Foli's managed attack clock")
	app._pop()
	var deadline: int = Time.get_ticks_msec() + 18000
	while app.runtime.turn.busy and Time.get_ticks_msec() < deadline: await app.get_tree().process_frame
	expect.call(not app.runtime.turn.busy and not actor.rig.managed, "Real Foli feedback ends and returns input")
	expect.call(app.game.rng.state == rng_after_commit, "Foli animation and sockets consume no gameplay randomness")
	app.feedback.cancel()
