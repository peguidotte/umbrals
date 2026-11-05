extends RefCounted
## Focused real-scene presentation contracts. Rules still own every committed hit.
const Leaves = preload("res://scripts/ui/leaf_blade_vfx.gd")
const Motion = preload("res://scripts/ui/battle_motion.gd")
const Assets = preload("res://scripts/assets/catalog.gd")

static func _select_lash(app: Control) -> bool:
	for k: int in range(app.game.hand.size()):
		if str(app.game.hand[k].power) == "thorn_lash":
			app.runtime.turn.select(k)
			return true
	return false

static func _settle(app: Control, expect: Callable, limit: float = 18.0) -> void:
	var deadline: int = Time.get_ticks_msec() + int(limit * 1000.0)
	while app.runtime.turn.busy and Time.get_ticks_msec() < deadline: await app.get_tree().process_frame
	expect.call(not app.runtime.turn.busy, "Leaf-blade feedback returns input within the existing bounded turn duration")

static func run(app: Control, expect: Callable) -> void:
	var leaves: RefCounted = Leaves.new()
	var profile: Dictionary = {"profile": "leaf_blades", "binding": "attacks/grass-leaf-blades", "blade_scale": 1.0}
	var configured: bool = leaves.configure(profile)
	expect.call(configured, "Leaf effects load a deliberately pinned atlas and presentation data")
	if not configured:
		return
	expect.call(leaves.atlas == Assets.texture("attacks/grass-leaf-blades"), "The renderer uses the exact selected effect release")
	for index: int in [3, 4, 5]:
		var expected_count: int = 1 if index == 3 else 3
		for mirrored: bool in [false, true]:
			var from: Vector2 = Vector2(610, 215) if mirrored else Vector2(120, 215)
			var to: Vector2 = Vector2(120, 300) if mirrored else Vector2(610, 300)
			var start: Array[Dictionary] = leaves.sample_blades(index, 0.0, from, to, 1.0)
			var middle: Array[Dictionary] = leaves.sample_blades(index, 0.5, from, to, 1.0)
			var finish: Array[Dictionary] = leaves.sample_blades(index, 1.0, from, to, 1.0)
			expect.call(start.size() == expected_count, "The three existing forest variations have their authored leaf counts")
			for k: int in range(start.size()):
				expect.call(Vector2(start[k].at).distance_to(from) < 0.001, "Every detached blade launches at the frozen anatomical release point")
				expect.call(Vector2(finish[k].at).distance_to(to) < 0.001, "Guided foliage reaches the actual target in either direction")
				expect.call(Vector2(middle[k].at).is_finite() and is_finite(float(middle[k].angle)), "Mirrored curved leaf paths remain finite")
			if expected_count > 1:
				expect.call(Vector2(middle[0].at).distance_to(middle[1].at) > 4.0, "The foliage fan has separate readable paths between launch and contact")
	app.preferences.set_value("reduced_motion", false)
	app._start_game(42013, "moss")
	await app.get_tree().process_frame
	var hud: Control = app.screen_host.battle_root.hud
	var source: Control = hud.actors[1]
	var target: Control = hud.enemy_actors[1]
	expect.call(str(source.rig.definition.get("attack_presentation", {}).get("profile", "")) == "leaf_blades", "The actual rendered Foli view opts into leaf presentation through authored metadata")
	var bounds: Rect2 = source.get_global_rect()
	for variant: int in [3, 4, 5]:
		source.rig.seek_cast(variant, float(Motion.spec(variant).release), Vector2.ZERO)
		var fore: Vector2 = source.rig.to_global(source.rig.project(Vector2(source.rig.definition.anatomy.fore[0], source.rig.definition.anatomy.fore[1])))
		expect.call(source.emission_point(variant).distance_to(fore) < 0.001, "All leaf casts emit at the posed forepaw rather than old root or crest origins")
		expect.call(source.get_global_rect() == bounds, "Leaf sockets leave the targetable slot unchanged")
	source.stop_motion()
	var target_hp: int = int(target.identity.hp)
	expect.call(_select_lash(app), "A real owned thorn_lash remains selectable")
	app.runtime.turn.cast()
	var rng_committed: int = app.game.rng.state
	await app.get_tree().create_timer(0.25).timeout
	var choreography: Node2D = hud.effects.choreography
	expect.call(choreography.active and choreography.renderer.presentation_profile == "leaf_blades", "A real committed existing power selects the dedicated leaf renderer")
	expect.call(int(target.identity.hp) == target_hp, "Windup does not expose or apply the future damage snapshot")
	var frozen_release: Vector2 = choreography.renderer.release_point
	var frozen_clock: float = choreography.renderer.clock
	app._push("pause")
	await app.get_tree().create_timer(0.15).timeout
	expect.call(is_equal_approx(choreography.renderer.clock, frozen_clock) and choreography.renderer.release_point == frozen_release, "Pause freezes the same action clock and frozen blade origin")
	app._pop()
	var variant: int = choreography.current_variant
	var performance: int = choreography.started
	var contact: float = float(Motion.spec(variant).contact)
	var contact_deadline: int = Time.get_ticks_msec() + 2000
	var hidden_until_contact: bool = true
	# Prior checks retain presentation cycles; observe this cast's actual contact.
	while choreography.active and choreography.started == performance and choreography.renderer.clock < contact and Time.get_ticks_msec() < contact_deadline:
		hidden_until_contact = hidden_until_contact and int(target.identity.hp) == target_hp
		await app.get_tree().process_frame
	print(JSON.stringify({"check": "leaf_contact", "variant": variant, "contact": contact, "clock": choreography.renderer.clock, "hp_before": target_hp, "hp_after": target.identity.hp}))
	expect.call(hidden_until_contact and choreography.started == performance and choreography.current_variant == variant and int(target.identity.hp) < target_hp and choreography.renderer.clock >= contact, "The actual target HP snapshot changes at the existing contact phase after leaf travel")
	expect.call(choreography.renderer.release_point == frozen_release and choreography.current_source == "fore", "Moving cast poses retain the frozen leaf origin and report the actual anatomical socket")
	app.preferences.set_value("reduced_motion", true)
	await _settle(app, expect, 2.0)
	expect.call(not choreography.active and choreography.renderer.presentation_profile.is_empty() and not source.rig.managed, "Reduced motion clears the leaf renderer and releases its posed actor")
	expect.call(app.game.rng.state == rng_committed, "Leaf art, sampling and accessibility cancellation consume no gameplay RNG")
	app.preferences.set_value("reduced_motion", false)
	app._start_game(42013, "moss")
	await app.get_tree().process_frame
	hud = app.screen_host.battle_root.hud
	expect.call(_select_lash(app), "A fresh real forest cast can be canceled")
	app.runtime.turn.cast()
	await app.get_tree().create_timer(0.18).timeout
	app._return_menu()
	await app.get_tree().process_frame
	expect.call(not hud.effects.choreography.active and hud.effects.choreography.renderer.presentation_profile.is_empty() and not app.runtime.turn.busy, "Leaving combat cancels leaf presentation without a stale turn")
	app.feedback.cancel()
