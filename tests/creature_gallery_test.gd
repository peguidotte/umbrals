extends SceneTree
const Content = preload("res://scripts/content.gd")
const Clip = preload("res://scripts/catalog/clip_definition.gd")
var checks: int = 0
var failed: int = 0
var releases: int = 0

func expect(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failed += 1
		printerr("FAIL: " + description)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var gallery = load("res://scenes/creature_gallery.tscn").instantiate()
	root.add_child(gallery)
	await process_frame
	gallery.actor.motion.set_process(false)
	gallery.actor.action_released.connect(func(_action: String, _point: Vector2): releases += 1)
	for species in Content.DATABASE.species:
		for shape in species.forms:
			gallery.select_form(species.species_id, shape.form_id)
			for facing in ["left", "right"]:
				gallery.actor.set_facing(facing)
				for action in Clip.ACTIONS:
					expect(gallery.actor.play_action(action), "Every form/direction implements every required action")
					var before: int = releases
					var clip = gallery.actor.motion.current
					var has_event: bool = not clip.release_point.is_empty()
					if has_event and clip.release_time > 0:
						gallery.actor.motion._process(clip.release_time * 0.5)
						expect(releases == before, "Release does not fire before its declared time")
					gallery.actor.motion._process(clip.release_time * 0.5 + 0.001 if has_event else clip.duration * 0.5)
					expect(releases == before + (1 if has_event else 0), "Only declared release events fire at their declared time")
					gallery.actor.motion._process(clip.duration + 0.01)
					expect(gallery.actor.motion.action == (action if action in ["idle", "move"] else "idle"), "Finite clips return to idle; looping clips remain active")
					gallery.actor.cancel_action()
					expect(gallery.actor.portrait.scale == Vector2.ONE, "Cancellation restores the resting transform")
				expect(gallery.actor.emission_point("mouth").is_finite(), "Both directions resolve emission anchors to canvas coordinates")
	var framed = Content.SPECIES.ember.forms[0].presentation.right.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	var attack = framed.clip("attack_ranged")
	attack.mode = "frames"
	attack.frames = PackedStringArray([Content.SPECIES.ember.forms[0].presentation.right.portrait_path, Content.SPECIES.ember.forms[1].presentation.right.portrait_path])
	gallery.actor.motion.configure(gallery.actor.portrait, framed, 1)
	gallery.actor.play_action("attack_ranged")
	gallery.actor.motion._process(attack.duration * 0.75)
	expect(gallery.actor.portrait.texture == load(attack.frames[1]), "Authored frame clips advance their actual textures")
	gallery.actor.cancel_action()
	framed.clip("idle").duration = 2.0
	gallery.actor.motion.phase_offset = 0.0
	gallery.actor.motion.idle_clock = 0.0
	gallery.actor.play_action("idle")
	gallery.actor.motion._process(0.25)
	expect(is_equal_approx(gallery.actor.portrait.position.y, 2.12132034), "Idle speed follows its authored duration")
	expect(gallery.actor.portrait.texture == load(framed.portrait_path), "Frame cancellation restores the portrait")
	expect(gallery.form_picker.item_count == Content.DATABASE.species[-1].forms.size(), "Gallery discovers the complete current form list")
	root.remove_child(gallery)
	gallery.queue_free()
	await process_frame
	print(JSON.stringify({"suite": "creature_gallery", "checks": checks, "failed": failed}))
	quit(0 if failed == 0 else 1)
