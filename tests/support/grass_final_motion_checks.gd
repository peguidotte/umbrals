extends RefCounted
## Final-form views keep their own anatomy, target slots and authored floor.
const Actor = preload("res://scripts/ui/actor.gd")
const Rules = preload("res://scripts/rules.gd")
const Motion = preload("res://scripts/ui/battle_motion.gd")
const Art = preload("res://scripts/ui/battle_art.gd")
const Assets = preload("res://scripts/assets/catalog.gd")

static func run(app: Control, expect: Callable) -> void:
	for form_id: String in ["moss", "verdalio"]:
		var binding: String = "umbrals/" + form_id
		expect.call(Art.view_name(binding, true) == "back" and Art.texture(binding, "back") != Art.texture(binding), "Smaller grass forms select their own dorsal source")
		expect.call(not Motion.form(form_id, "back").is_empty() and Motion.form(form_id, "back") != Motion.form(form_id), "Dorsal motion has a separate anatomical definition")
	for form_id: String in ["foslash", "folivel"]:
		var unit: Dictionary = Rules.make_umbral("moss", "resilient", 1, form_id)
		var actor: Control = Actor.new()
		actor.size = Vector2(230, 230)
		app.get_tree().root.add_child(actor)
		var bounds: Rect2 = actor.get_global_rect()
		var binding: String = "umbrals/" + form_id
		expect.call(Art.texture(binding) == Assets.texture(binding), "Final form uses its explicitly pinned portrait")
		expect.call(str(Motion.form(form_id).anatomy.name).to_lower() == form_id, "Final form has its own anatomical definition")
		var views: Array[String] = ["front"]
		if form_id == "folivel": views.append("back")
		if form_id == "foslash":
			expect.call(Art.view_name(binding, true) == "front" and Motion.form(form_id, "back").is_empty(), "Missing Foslash rear does not inherit front anatomy")
		else:
			expect.call(Art.view_name(binding, true) == "back" and Art.texture(binding, "back") != Art.texture(binding), "Folivel selects an authored dorsal source")
		for view: String in views:
			for mirrored: bool in [false, true]:
				actor.enemy = mirrored
				actor.set_identity(unit)
				# Exercise all four view/facing combinations without changing game state.
				actor.art_view = view
				actor.portrait.texture = Art.texture(binding, view)
				actor.ground_profile = Art.ground_profile(binding, view)
				actor.portrait.flip_h = mirrored
				actor._pivot()
				expect.call(actor.rig.art_view == view and actor.rig.definition == Motion.form(form_id, view), "Rig selects the exact requested view anatomy")
				actor.rig.idle_time = 0.8
				actor.rig._refresh()
				var foot_at: Vector2 = actor.rig.to_global(actor.rig.project(actor.rig.foot))
				expect.call(foot_at.distance_to(actor.visual_ground()) < 0.25, "Own floor stays planted in each view and facing")
				for variant: int in [3, 4, 5]:
					actor.rig.seek_cast(variant, float(Motion.spec(variant).release), Vector2.ZERO)
					var primary: Vector2 = actor.emission_point(variant)
					var secondary: Vector2 = actor.emission_point(variant, true)
					expect.call(primary.is_finite() and secondary.is_finite() and primary.distance_to(secondary) > 4, "Leaf control follows two distinct own forepaws")
					expect.call(actor.get_global_rect() == bounds, "Own cast leaves the targetable slot fixed")
					actor.rig.seek_cast(variant, 3.2, Vector2.ZERO)
					expect.call(actor.rig.pose == Motion.neutral(), "Own cast returns to rest")
				actor.stop_motion()
				actor.rig.lifecycle.enter()
				expect.call(actor.rig.lifecycle.active(), "Each integrated view has an authored entry clip")
				actor.rig.lifecycle.set_incapacitated(true)
				expect.call(actor.rig.lifecycle.state == "ko", "Each integrated view has its own reversible KO clip")
		actor.queue_free()
		await app.get_tree().process_frame
		await preload("res://tests/support/foli_lifecycle_checks.gd").run(app, expect, Callable(), form_id)
