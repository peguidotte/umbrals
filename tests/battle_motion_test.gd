extends SceneTree
## Actual committed powers exercise contact timing, pause, cancellation and variants.
const Events = preload("res://scripts/ui/attack_events.gd")
const Motion = preload("res://scripts/ui/battle_motion.gd")
const BattleArt = preload("res://scripts/ui/battle_art.gd")
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

func electric_art() -> void:
	for id in ["volt", "tempestral", "auravel", "zuldar"]:
		var form: Dictionary = Motion.form(id)
		expect(form.has("parts") and Motion.part(9, id) == ("secondary" if id == "auravel" else "quills") and Motion.part(10, id) == "crest", "Electric casts name the new attached anatomy: " + id)
		expect(Motion.sample(id, "states", 6, .2) != Motion.sample(id, "states", 0, .2), "Authored gait is independent of idle and dash: " + id)
		var ally: AtlasTexture = BattleArt.texture("umbrals/" + id)
		var enemy: AtlasTexture = BattleArt.texture("umbrals/" + id, true)
		expect("electric-" in ally.atlas.resource_path and ally.atlas != enemy.atlas, "Both sides use new separately drawn source pixels: " + id)
		for view in [ally, enemy]:
			var image: Image = view.atlas.get_image()
			for part in ["mouth", "quills", "crest", "fore", "shoulder", "flank", "secondary"]:
				var uv: Array = form.anatomy[part]
				expect(image.get_pixel(int(float(uv[0]) * image.get_width()), int(float(uv[1]) * image.get_height())).a > .9, "Anatomical origin lies on visible sprite pixels: " + id + "/" + part + "/" + view.atlas.resource_path)
	app._start_game(42013, "volt")
	await process_frame
	var source: Control = app.screen_host.battle_root.hud.actors[1]
	var original: Dictionary = source.identity.duplicate(true)
	var rng: int = app.game.rng.state
	var bounds: Rect2 = source.get_global_rect()
	source.rig.seek_cast(9, .84, Vector2.ZERO)
	source.rig._refresh()
	for binding in source.rig.skin_bindings:
		expect(source.rig._cached_skin(binding).distance_to(source.rig._skin(binding.uv)) < .00001, "Cached skinning preserves the original deformation")
	var uv: Array = Motion.form("volt").anatomy.quills
	expect(source.emission_point(9).is_equal_approx(source.rig.to_global(source.rig.project(Vector2(float(uv[0]), float(uv[1]))))), "Emission follows the actual quill mesh deformation")
	source.stop_motion()
	source.rig.play_state(6)
	source.rig.elapsed = .2
	source.rig._refresh()
	expect(source.rig.pose != Motion.neutral() and source.get_global_rect() == bounds, "Gait animates the rig without moving the interactive slot")
	for time in [.05, .2, .4, .6]:
		source.rig.elapsed = time
		source.rig._refresh()
		for point in source.rig.definition.walk_contacts:
			if fposmod(time / .8 + float(point[2]), 1.0) >= .6: continue
			var at: Vector2 = Vector2(float(point[0]), float(point[1]))
			expect(source.rig.project(at).distance_to(at * source.rig.display_size) < .05, "A stance paw remains on its authored support point")
	for form_id in ["volt", "tempestral", "auravel", "zuldar"]:
		for mirror in [false, true]:
			source.enemy = mirror
			var posed: Dictionary = original.duplicate(true)
			posed.form_id = form_id
			source.set_identity(posed)
			for group in ["states", "attacks"]:
				for index in ([0, 3, 6] if group == "states" else [9, 13, 14]):
					source.rig.mode = group
					source.rig.clip = index
					source.rig.elapsed = .5 if group == "states" else 1.1
					source.rig.jump_scale = .63
					source.rig.dash = Vector2(240, -18)
					source.rig._refresh()
					var error: float = 0
					for binding in source.rig.skin_bindings:
						error = maxf(error, source.rig._project_cached(binding).distance_to(source.rig.project(binding.uv)))
					expect(error < .0001, "Cached projection matches direct sockets on all 225 vertices: " + form_id + "/" + str(mirror) + "/" + group + "/" + str(index))
					if group == "states" and index == 6:
						var mesh_vertices = source.rig.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
						for point in source.rig.definition.walk_contacts:
							var at: Vector2 = Vector2(float(point[0]), float(point[1]))
							var found: int = -1
							for vertex in range(source.rig.skin_bindings.size()):
								if source.rig.skin_bindings[vertex].uv.is_equal_approx(at): found = vertex
							expect(found >= 0, "A support point exists on the rendered mesh: " + form_id)
							if found < 0 or fposmod(source.rig.elapsed / .8 + float(point[2]), 1.0) >= .6: continue
							var target: Vector2 = Vector2(1.0 - at.x if mirror else at.x, at.y) * source.rig.display_size
							var actual: Vector2 = Vector2(mesh_vertices[found].x, mesh_vertices[found].y)
							expect(actual.distance_to(target) < .05, "The rendered paw vertex stays planted during stance: " + form_id)

	source.enemy = false
	source.set_identity(original)
	var fallen: Dictionary = original.duplicate(true)
	fallen.hp = 0
	source.set_identity(fallen)
	source.rig.ko_elapsed = .7
	source.rig._refresh()
	expect(source.rig.incapacitated and source.rig.ko_texture != null and source.rig.ko_mix > .99, "KO settles into the authored closed-eye pose")
	source.rig.reaction_weight = .3
	source.rig.seek_reaction(9, .4)
	expect(source.rig.ko_mix > .99, "Resistance cannot lift an already incapacitated body")
	source.stop_motion()
	expect(source.rig.ko_mix > .99, "Presentation cancellation retains the incapacitated pose")
	source.reduced_motion = true
	expect(source.rig.ko_mix > .99, "Reduced motion shows the final KO pose without collapse animation")
	source.reduced_motion = false
	source.set_identity(original, 1.0, true)
	source.rig._process(.35)
	expect(source.rig.ko_mix > .1 and source.rig.ko_mix < .9, "Revival transitions continuously from the authored resting pose")
	source.rig._process(.5)
	source.stop_motion()
	expect(not source.rig.incapacitated and is_equal_approx(source.rig.ko_mix, 0), "Revival clears the KO pose")
	for adult in ["auravel", "zuldar"]:
		var adult_data: Dictionary = original.duplicate(true)
		adult_data.form_id = adult
		source.set_identity(adult_data)
		source.rig.play_state(6)
		for time in [.05, .2, .4, .6]:
			source.rig.elapsed = time
			source.rig._refresh()
			for point in source.rig.definition.walk_contacts:
				if fposmod(time / .8 + float(point[2]), 1.0) >= .6: continue
				var at: Vector2 = Vector2(float(point[0]), float(point[1]))
				expect(source.rig.project(at).distance_to(at * source.rig.display_size) < .05, "Adult stance contact stays planted: " + adult)
		fallen = adult_data.duplicate(true)
		fallen.hp = 0
		source.set_identity(fallen)
		source.rig.ko_elapsed = .75
		source.rig._refresh()
		expect(source.rig.ko_texture != null and source.rig.ko_mix > .99, "Adult settles into a distinct drawn resting pose: " + adult)
		source.set_identity(adult_data, 1.0, true)
		source.rig._process(.35)
		expect(source.rig.ko_mix > .1 and source.rig.ko_mix < .9, "Adult recovery uses the continuous pose transition: " + adult)
		source.rig._process(.5)
	source.set_identity(original)
	expect(app.game.rng.state == rng and app.game.party[0].hp == original.hp, "Presentation tests consume no gameplay RNG and never mutate the live individual")
	app._return_menu()
	await process_frame

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
	for proxy in {"owl": "volt", "spore": "moss", "stag": "ignivar"}:
		var donor: String = {"owl": "volt", "spore": "moss", "stag": "ignivar"}[proxy]
		for state in [0, 3]:
			expect(Motion.sample(proxy, "states", state, .4) == Motion.data.forms[donor].states[str(state)][12], "Legacy illustration keeps its pinned proxy tracks: " + proxy + "/" + str(state))
	expect(Motion.sample("owl", "states", 0, .4) != Motion.sample("volt", "states", 0, .4), "Owl never inherits the new hedgehog presentation")
	expect(Motion.data.forms.size() == 8 and Motion.choreography.specs.size() == 15, "The approved eight forms and fifteen clocks load through exact pinned dependencies")
	for id in Motion.data.forms:
		var rest: Array = Motion.sample(id, "attacks", 1, 0)
		var final: Array = Motion.sample(id, "attacks", 1, 3.1)
		expect(is_equal_approx(float(rest[0]), float(final[0])) and is_equal_approx(float(rest[1]), float(final[1])), "Cast returns its root to the floor: " + id)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.preferences.set_value("reduced_motion", false)
	await electric_art()
	await preload("res://tests/support/combined_presentation_checks.gd").run(app, expect)
	await preload("res://tests/support/foli_motion_checks.gd").run(app, expect)
	await preload("res://tests/support/foli_lifecycle_checks.gd").run(app, expect)
	await preload("res://tests/support/folife_motion_checks.gd").run(app, expect)
	await preload("res://tests/support/grass_final_motion_checks.gd").run(app, expect)
	await preload("res://tests/support/grass_leaf_blade_checks.gd").run(app, expect)
	app._start_game(42013, "ember")
	await process_frame
	var hud: Control = app.screen_host.battle_root.hud
	var source: Control = hud.actors[1]
	var target: Control = hud.enemy_actors[1]
	source.rig.set_incapacitated(true)
	source.rig.seek_reaction(0, 2.1)
	source.rig.managed = false
	source.rig._process(.04)
	expect(source.rig.mode == "states" and source.rig.clip == 0, "Older forms without a KO clip stop completed reactions and retain their still-state behavior")
	source.rig.set_incapacitated(false)
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
	app.feedback.cancel()
	app.audio.shutdown()
	await create_timer(0.12).timeout
	app.queue_free()
	await process_frame
	print(JSON.stringify({"suite": "battle_motion", "checks": checks, "failed": failed}))
	quit(0 if failed == 0 else 1)
